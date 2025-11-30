# frozen_string_literal: true

require_relative 'context'
require_relative 'definition'
require_relative 'registry'

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

        # Load date configuration from dates.yml if it exists
        date_config = load_date_configuration(year)

        # Load calendar events from calendars.yml if it exists
        event_store = load_calendar_events(year)

        {
          year: year,
          total_weeks: total_weeks,
          total_pages: declaration_context.pages.length,
          link_registry: @link_registry,
          date_config: date_config,
          event_store: event_store,
          sidebar_overrides: declaration_context.sidebar_overrides
        }
      end

      # Load date configuration from dates.yml.
      #
      # @param year [Integer] The year for date validation
      # @return [BujoPdf::DateConfiguration, nil] Date configuration or nil if not available
      def load_date_configuration(year)
        config_path = 'config/dates.yml'
        return nil unless File.exist?(config_path)

        BujoPdf::DateConfiguration.new(config_path, year: year)
      end

      # Load calendar events from iCal sources configured in calendars.yml.
      #
      # @param year [Integer] The year to filter events for
      # @return [BujoPdf::CalendarIntegration::EventStore, nil] Event store or nil if not available
      def load_calendar_events(year)
        BujoPdf::CalendarIntegration.load_events(year: year)
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
          page_key: page_decl.id || page_decl.type,
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
      # All PDF definitions should use the DSL's outline declarations
      # (outline: true, outline: 'Title', or outline_entry/outline_section).
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param pages [Array<PageDeclaration>] All page declarations
      # @param base_context [Hash] Base render context with year info (unused, kept for API compatibility)
      # @param outline_entries [Array<OutlineDeclaration>] Declared outline entries
      def build_outline(pdf, pages, base_context, outline_entries = [])
        return if outline_entries.empty?

        pages_by_dest = build_pages_by_dest(pages)

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
          outline_entries.each do |entry|
            render_entry.call(entry, self)
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
          title = resolve_page_title(page_decl, dest_key)
          hash[dest_key] = {
            page_number: index + 1,
            title: title
          }
        end
      end

      # Resolve the title for a page declaration.
      #
      # Priority:
      # 1. Explicit outline_title on the declaration
      # 2. collection_title param (for collection pages)
      # 3. Page class's registered title via PageRegistry
      # 4. Fallback: humanized destination key
      #
      # @param page_decl [PageDeclaration] The page declaration
      # @param dest_key [String] The destination key
      # @return [String] The resolved title
      def resolve_page_title(page_decl, dest_key)
        # 1. Explicit outline_title on the declaration
        return page_decl.outline_title if page_decl.outline_title

        # 2. collection_title param (for collection pages)
        return page_decl.params[:collection_title] if page_decl.params[:collection_title]

        # 3. Page class's registered title via PageRegistry
        page_class = PageFactory.registry[page_decl.type]
        if page_class&.respond_to?(:generate_title)
          # Expand DSL value objects to params that PageRegistry expects
          expanded_params = expand_dsl_params(page_decl.params)
          begin
            generated_title = page_class.generate_title(expanded_params)
            return generated_title if generated_title
          rescue KeyError
            # Title requires params not available - fall through to fallback
          end
        end

        # 4. Fallback: humanized destination key
        dest_key.tr('_', ' ').split.map(&:capitalize).join(' ')
      end

      # Expand DSL value objects (Week, Month) to their component params.
      #
      # Mirrors the expansion done in build_page_context.
      #
      # @param params [Hash] Page declaration params
      # @return [Hash] Expanded params with week_num, month, etc.
      def expand_dsl_params(params)
        expanded = params.dup

        params.each do |key, value|
          case value
          when Week
            expanded[:week_num] = value.number
            expanded[:week_start] = value.start_date
            expanded[:week_end] = value.end_date
          when Month
            expanded[:month] = value.number
            expanded[:month_name] = value.name
          end
        end

        expanded
      end
    end
  end
end
