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

        # Create grid stamps for all grid types for efficiency
        create_grid_stamps(pdf)

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

      # Create stamps for all grid types for efficient rendering.
      #
      # Creates a reusable stamp for each supported grid type. This reduces
      # PDF file size significantly when multiple pages use the same grid.
      #
      # Stamp naming convention:
      # - :dots -> 'page_dots' (for backward compatibility)
      # - :graph -> 'grid_graph'
      # - :lined -> 'grid_lined'
      # - :isometric -> 'grid_isometric'
      # - :perspective -> 'grid_perspective'
      # - :hexagon -> 'grid_hexagon'
      #
      # @param pdf [Prawn::Document] The PDF document
      def create_grid_stamps(pdf)
        require_relative '../utilities/dot_grid'
        require_relative '../utilities/grid_factory'

        Utilities::GridFactory.supported_types.each do |type|
          # Use 'page_dots' for dots (backward compatibility), 'grid_<type>' for others
          stamp_name = type == :dots ? 'page_dots' : "grid_#{type}"
          options = grid_stamp_options(type)
          DotGrid.create_stamp(pdf, stamp_name, type: type, **options)
        end
      end

      # Get default options for creating stamps for each grid type.
      #
      # Different grid types have different rendering defaults that need
      # to match the original page implementations.
      #
      # @param type [Symbol] Grid type
      # @return [Hash] Options to pass to the renderer
      def grid_stamp_options(type)
        case type
        when :perspective
          # 1-point perspective with guide rectangles (matching original PerspectiveGridPage)
          { num_points: 1, draw_guide_rectangles: true, num_converging: 24, line_width: 0.35 }
        when :hexagon
          # Flat-top orientation with slightly thicker lines (matching original HexagonGridPage)
          { line_width: 0.35, orientation: :flat_top }
        when :isometric
          # Standard isometric with default line width
          { line_width: 0.25 }
        else
          {}
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
          sidebar_overrides: declaration_context.sidebar_overrides,
          chrome_config: declaration_context.chrome_config,
          sidebar_definitions: declaration_context.sidebar_definitions
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

        # Apply per-page chrome override if specified
        context[:chrome_config] = resolve_page_chrome(
          page_decl.chrome,
          base_context[:chrome_config]
        )

        # Create link resolver for this page
        context[:link_resolver] = LinkResolver.new(
          @link_registry,
          current_page: page_decl.type,
          current_params: context.slice(:week_num, :month, :year)
        )

        context
      end

      # Resolve effective chrome configuration for a page.
      #
      # Merges per-page chrome with PDF-level chrome according to these rules:
      # - nil: Inherit PDF-level chrome unchanged
      # - false: Full opt-out, no chrome (returns nil)
      # - Hash: Merge with PDF chrome (per-region overrides)
      #   - { left: :month_sidebar } -> replace left sidebar
      #   - { right: false } -> disable right sidebar
      #
      # @param page_chrome [false, Hash, nil] Per-page chrome specification
      # @param pdf_chrome [ChromeBuilder, nil] PDF-level chrome configuration
      # @return [ChromeBuilder, nil] Effective chrome for this page
      def resolve_page_chrome(page_chrome, pdf_chrome)
        case page_chrome
        when nil
          # Inherit PDF-level chrome unchanged
          pdf_chrome
        when false
          # Full opt-out - no chrome at all
          nil
        when Hash
          # Merge with PDF chrome
          merge_chrome_configs(pdf_chrome, page_chrome)
        else
          # Unknown type - inherit PDF chrome
          pdf_chrome
        end
      end

      # Merge page-level chrome overrides with PDF-level chrome.
      #
      # Creates a new ChromeBuilder with PDF chrome as base and page overrides applied.
      # Each region can be:
      # - false: Disable that region
      # - Symbol: Replace sidebar with this type
      # - Hash: Replace with {component: type, ...options}
      #
      # @param pdf_chrome [ChromeBuilder, nil] PDF-level chrome configuration
      # @param page_overrides [Hash] Per-page region overrides
      # @return [ChromeBuilder, nil] Merged chrome configuration
      def merge_chrome_configs(pdf_chrome, page_overrides)
        return nil if pdf_chrome.nil? && page_overrides.all? { |_, v| v == false }

        merged = ChromeBuilder.new

        %i[left right top bottom].each do |region|
          override = page_overrides[region]
          pdf_config = pdf_chrome&.send("#{region}_config")

          if override == false
            # Explicitly disabled - leave nil
            next
          elsif override
            # Override provided - use it
            apply_chrome_override(merged, region, override)
          elsif pdf_config
            # No override - copy from PDF chrome
            copy_chrome_config(merged, region, pdf_config)
          end
        end

        merged.empty? ? nil : merged
      end

      # Apply a chrome override to a region.
      #
      # @param builder [ChromeBuilder] Builder to modify
      # @param region [Symbol] Region (:left, :right, :top, :bottom)
      # @param override [Symbol, Hash] Override specification
      def apply_chrome_override(builder, region, override)
        case override
        when Symbol
          builder.send(region, override)
        when Hash
          component = override[:component] || override.keys.first
          options = override.except(:component)
          builder.send(region, component, **options)
        end
      end

      # Copy chrome configuration from one builder to another.
      #
      # @param builder [ChromeBuilder] Target builder
      # @param region [Symbol] Region to copy
      # @param config [SidebarConfig] Configuration to copy
      def copy_chrome_config(builder, region, config)
        if region == :right && config.tabs?
          # Right sidebar with tabs needs special handling
          builder.right(config.sidebar_name, **config.options) do
            config.tabs.each do |tab|
              tab(tab.label, dest: tab.dest, **tab.options)
            end
          end
        else
          builder.send(region, config.sidebar_name, **config.options)
        end
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
