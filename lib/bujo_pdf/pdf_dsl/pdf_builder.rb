# frozen_string_literal: true

require_relative 'declaration_context'
require_relative 'pdf_definition'
require_relative 'link_registry'

module BujoPdf
  module PdfDSL
    # PdfBuilder orchestrates the PDF generation process using two passes.
    #
    # The builder uses a two-pass architecture:
    # 1. Declaration pass - Evaluate definition, collect pages, build link registry
    # 2. Render pass - Generate pages with resolved cross-references
    #
    # This allows pages to reference each other (prev/next week, year overview
    # links to weeks) because all destinations are known before rendering.
    #
    # @example Basic usage
    #   definition = PdfDefinition.new(:my_planner) { |year:| ... }
    #   builder = PdfBuilder.new
    #   builder.build(definition, year: 2025)
    #
    # @example With output path
    #   builder.build(definition, year: 2025, output: 'my_planner.pdf')
    #
    class PdfBuilder
      attr_reader :link_registry

      # Build a PDF from a definition.
      #
      # @param definition [PdfDefinition] The PDF definition to build
      # @param output [String, nil] Optional output file path
      # @param params [Hash] Parameters to pass to the definition
      # @return [Prawn::Document, String] The PDF document or output path
      def build(definition, output: nil, **params)
        # Phase 1: Declaration pass
        context = DeclarationContext.new
        definition.evaluate(context, **params)

        # Build link registry from declarations
        @link_registry = build_link_registry(context)

        # Set theme if specified
        apply_theme(context.theme_name) if context.theme_name

        # Create PDF document
        pdf = create_document(context)

        # Create dot grid stamp for efficiency
        create_dot_grid_stamp(pdf)

        # Build render context base
        base_context = build_base_context(params, context)

        # Phase 2: Render pass - generate pages with resolved links
        render_pages(pdf, context.pages, base_context)

        # Build PDF outline/bookmarks
        build_outline(pdf, context.pages, base_context, context.outline_entries)

        # Output
        if output
          pdf.render_file(output)
          output
        else
          pdf
        end
      ensure
        # Reset theme to avoid side effects
        reset_theme if context&.theme_name
      end

      private

      # Build the link registry from declarations.
      #
      # Registers all pages and groups for link resolution during render.
      #
      # @param context [DeclarationContext] The declaration context
      # @return [LinkRegistry] The populated link registry
      def build_link_registry(context)
        registry = LinkRegistry.new

        # Register all pages with their page numbers
        context.pages.each_with_index do |page_decl, index|
          registry.register(page_decl, page_number: index + 1)
        end

        # Register all groups
        context.groups.each do |group_decl|
          registry.register_group(group_decl)
        end

        registry
      end

      # Apply the specified theme.
      #
      # @param theme_name [Symbol] Theme name
      def apply_theme(theme_name)
        BujoPdf::Themes.set(theme_name)
      end

      # Reset theme to default.
      def reset_theme
        BujoPdf::Themes.reset!
      end

      # Create a new Prawn document.
      #
      # @param context [DeclarationContext] The declaration context
      # @return [Prawn::Document] A new PDF document
      def create_document(context)
        Prawn::Document.new(
          page_size: 'LETTER',
          margin: 0,
          info: context.prawn_metadata
        )
      end

      # Create the dot grid stamp for efficient rendering.
      #
      # @param pdf [Prawn::Document] The PDF document
      def create_dot_grid_stamp(pdf)
        require_relative '../utilities/dot_grid'

        pdf.create_stamp('page_dots') do
          DotGrid.draw(
            pdf,
            Styling::Grid::PAGE_WIDTH,
            Styling::Grid::PAGE_HEIGHT
          )
        end
      end

      # Build the base render context.
      #
      # @param params [Hash] Parameters from build call
      # @param declaration_context [DeclarationContext] The declaration context
      # @return [Hash] Base context for rendering
      def build_base_context(params, declaration_context)
        year = params[:year] || Date.today.year
        total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(year)

        {
          year: year,
          total_weeks: total_weeks,
          total_pages: declaration_context.pages.length,
          link_registry: @link_registry
        }
      end

      # Render all declared pages.
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param pages [Array<PageDeclaration>] Page declarations
      # @param base_context [Hash] Base render context
      def render_pages(pdf, pages, base_context)
        pages.each_with_index do |page_decl, index|
          # Start new page for all but first
          pdf.start_new_page if index > 0

          # Build page-specific context
          page_context = build_page_context(page_decl, base_context, index)

          # Create and render page
          render_page(pdf, page_decl, page_context)
        end
      end

      # Build context for a specific page.
      #
      # @param page_decl [PageDeclaration] The page declaration
      # @param base_context [Hash] Base render context
      # @param index [Integer] Page index (0-based)
      # @return [Hash] Page-specific context
      def build_page_context(page_decl, base_context, index)
        context = base_context.merge(
          page_key: page_decl.type,
          page_number: index + 1
        )

        # Merge page-specific parameters
        page_decl.params.each do |key, value|
          case value
          when Week
            context[:week_num] = value.number
            context[:week_start] = value.start_date
            context[:week_end] = value.end_date
          when Month
            context[:month] = value.number
            context[:month_name] = value.name
          else
            context[key] = value
          end
        end

        # Create link resolver for this page
        context[:link_resolver] = LinkResolver.new(
          @link_registry,
          current_page: page_decl.type,
          current_params: context.slice(:week_num, :month, :year)
        )

        context
      end

      # Render a single page.
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param page_decl [PageDeclaration, InlinePageDeclaration] The page declaration
      # @param context [Hash] Render context
      def render_page(pdf, page_decl, context)
        # Handle inline pages
        if page_decl.respond_to?(:inline?) && page_decl.inline?
          render_inline_page(pdf, page_decl, context)
          return
        end

        page_type = page_decl.type

        # Handle weekly pages specially
        if page_type == :weekly && context[:week_num]
          page = PageFactory.create_weekly_page(context[:week_num], pdf, context)
        else
          page = PageFactory.create(page_type, pdf, context)
        end

        page.generate
      rescue ArgumentError => e
        raise ArgumentError, "Failed to create page '#{page_decl.type}': #{e.message}"
      end

      # Render an inline page.
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param page_decl [InlinePageDeclaration] The inline page declaration
      # @param context [Hash] Render context
      def render_inline_page(pdf, page_decl, context)
        require_relative '../pages/inline_page'

        # Apply theme override if specified
        original_theme = nil
        if page_decl.theme_override
          original_theme = BujoPdf::Themes.current_theme_name
          BujoPdf::Themes.set(page_decl.theme_override)
        end

        page = Pages::InlinePage.new(pdf, context, inline_declaration: page_decl)
        page.generate
      ensure
        # Restore original theme if we changed it
        if original_theme
          BujoPdf::Themes.set(original_theme)
        end
      end

      # Build PDF outline/bookmarks for navigation.
      #
      # Uses declarative outline entries collected during definition evaluation.
      # Falls back to hardcoded structure if no outline entries are declared.
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param pages [Array<PageDeclaration>] All page declarations
      # @param base_context [Hash] Base render context with year info
      # @param outline_entries [Array<OutlineDeclaration>] Declared outline entries
      def build_outline(pdf, pages, base_context, outline_entries = [])
        pages_by_dest = build_pages_by_dest(pages)

        if outline_entries.any?
          build_declarative_outline(pdf, outline_entries, pages_by_dest)
        else
          build_legacy_outline(pdf, pages_by_dest, base_context[:year])
        end
      end

      # Build outline from declarative entries.
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param entries [Array<OutlineDeclaration>] Outline entries
      # @param pages_by_dest [Hash<String, Hash>] Map of dest key to page info
      def build_declarative_outline(pdf, entries, pages_by_dest)
        # Define a recursive renderer that works within Prawn's outline DSL scope
        render_entry = nil
        render_entry = ->(entry, outline_scope) do
          dest_key = entry.dest.to_s if entry.dest
          page_info = pages_by_dest[dest_key] if dest_key

          if entry.section?
            # Section with children
            if page_info
              outline_scope.section entry.title, destination: page_info[:page_number] do
                entry.children.each { |child| render_entry.call(child, outline_scope) }
              end
            else
              outline_scope.section entry.title do
                entry.children.each { |child| render_entry.call(child, outline_scope) }
              end
            end
          elsif page_info
            # Simple page entry
            outline_scope.page destination: page_info[:page_number], title: entry.title
          end
          # Skip entries without valid destinations
        end

        pdf.outline.define do
          entries.each do |entry|
            render_entry.call(entry, self)
          end
        end
      end

      # Build legacy hardcoded outline for backward compatibility.
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param pages_by_dest [Hash<String, Hash>] Map of dest key to page info
      # @param year [Integer] The planner year
      def build_legacy_outline(pdf, pages_by_dest, year)
        pdf.outline.define do
          # Front matter
          if (p = pages_by_dest['seasonal'])
            page destination: p[:page_number], title: 'Seasonal Calendar'
          end
          if (p = pages_by_dest['index_1'])
            page destination: p[:page_number], title: 'Index'
          end
          if (p = pages_by_dest['future_log_1'])
            page destination: p[:page_number], title: 'Future Log'
          end

          # Year overview
          if (p = pages_by_dest['year_events'])
            page destination: p[:page_number], title: 'Year at a Glance - Events'
          end
          if (p = pages_by_dest['year_highlights'])
            page destination: p[:page_number], title: 'Year at a Glance - Highlights'
          end
          if (p = pages_by_dest['multi_year'])
            page destination: p[:page_number], title: 'Multi-Year Overview'
          end

          # Planning pages
          if (p = pages_by_dest['quarter_1'])
            page destination: p[:page_number], title: 'Quarterly Planning'
          end
          if (p = pages_by_dest['review_1'])
            page destination: p[:page_number], title: 'Monthly Reviews'
          end

          # Months (link to first week of each month)
          (1..12).each do |month|
            month_name = Date::MONTHNAMES[month]
            weeks = BujoPdf::Utilities::DateCalculator.weeks_for_month(year, month)
            if weeks.any? && (p = pages_by_dest["week_#{weeks.first}"])
              page destination: p[:page_number], title: "#{month_name} #{year}"
            end
          end

          # Grids
          if (p = pages_by_dest['grid_showcase'])
            page destination: p[:page_number], title: 'Grid Types Showcase'
          end
          if (p = pages_by_dest['grids_overview'])
            page destination: p[:page_number], title: '  - Basic Grids Overview'
          end
          if (p = pages_by_dest['grid_dot'])
            page destination: p[:page_number], title: '  - Dot Grid (5mm)'
          end
          if (p = pages_by_dest['grid_graph'])
            page destination: p[:page_number], title: '  - Graph Grid (5mm)'
          end
          if (p = pages_by_dest['grid_lined'])
            page destination: p[:page_number], title: '  - Ruled Lines (10mm)'
          end
          if (p = pages_by_dest['grid_isometric'])
            page destination: p[:page_number], title: '  - Isometric Grid'
          end
          if (p = pages_by_dest['grid_perspective'])
            page destination: p[:page_number], title: '  - Perspective Grid'
          end
          if (p = pages_by_dest['grid_hexagon'])
            page destination: p[:page_number], title: '  - Hexagon Grid'
          end

          # Templates
          if (p = pages_by_dest['tracker_example'])
            page destination: p[:page_number], title: 'Tracker Ideas'
          end
          if (p = pages_by_dest['reference'])
            page destination: p[:page_number], title: 'Calibration & Reference'
          end
          if (p = pages_by_dest['daily_wheel'])
            page destination: p[:page_number], title: 'Daily Wheel'
          end
          if (p = pages_by_dest['year_wheel'])
            page destination: p[:page_number], title: 'Year Wheel'
          end

          # Collections
          pages_by_dest.each do |dest, p|
            next unless dest.start_with?('collection_')

            page destination: p[:page_number], title: p[:title]
          end
        end
      end

      # Build a lookup hash of pages by destination key.
      #
      # @param pages [Array<PageDeclaration>] All page declarations
      # @return [Hash<String, Hash>] Map of dest key to page info
      def build_pages_by_dest(pages)
        pages.each_with_index.each_with_object({}) do |(page_decl, index), hash|
          dest_key = page_decl.destination_key
          # For collection pages, get title from params
          title = page_decl.params[:collection_title] || dest_key.tr('_', ' ').split.map(&:capitalize).join(' ')
          hash[dest_key] = {
            page_number: index + 1,
            title: title
          }
        end
      end
    end
  end
end
