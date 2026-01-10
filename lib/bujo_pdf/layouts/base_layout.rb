# frozen_string_literal: true

require_relative 'chrome_spec'
require_relative '../sidebars/sidebar_registry'

module BujoPdf
  module Layouts
    # Abstract base class for all layout types.
    #
    # Layouts define the structure of a page by specifying:
    # - Content area boundaries (where page-specific content goes)
    # - Layout components to render (sidebars, navigation, backgrounds)
    # - Lifecycle hooks for rendering before/after page content
    #
    # When initialized with a ChromeSpec, the layout automatically:
    # - Calculates content area based on active chrome regions
    # - Renders sidebars via SidebarRegistry lookup in render_before
    #
    # Subclasses must implement:
    # - content_area: Return content area specification (unless using chrome_spec)
    #
    # Subclasses may optionally override:
    # - render_before(page): Render layout components before page content
    # - render_after(page): Render layout components after page content
    #
    # @abstract Subclasses must implement {#content_area} (unless chrome_spec provided)
    #
    # @example Creating a custom layout
    #   class MyLayout < BaseLayout
    #     def content_area
    #       { col: 5, row: 5, width_boxes: 33, height_boxes: 45 }
    #     end
    #
    #     def render_before(page)
    #       # Draw sidebars, backgrounds, etc.
    #     end
    #   end
    #
    # @example Using a layout with ChromeSpec
    #   spec = ChromeSpec.new(left: :week_sidebar, right: :tab_sidebar)
    #   layout = BaseLayout.new(pdf, grid, chrome_spec: spec)
    #   layout.content_area  # => { col: 2, row: 0, width_boxes: 40, height_boxes: 55 }
    #
    # @example Using a layout in a page
    #   class MyPage < Pages::Base
    #     def setup
    #       use_layout :my_layout, option1: value1
    #     end
    #   end
    class BaseLayout
      # Default page dimensions in grid boxes
      PAGE_WIDTH_BOXES = 43
      PAGE_HEIGHT_BOXES = 55

      attr_reader :pdf, :grid_system, :options, :chrome_spec

      # Initialize a new layout instance.
      #
      # @param pdf [Prawn::Document] PDF document to render into
      # @param grid_system [Utilities::GridSystem] Grid system for positioning
      # @param chrome_spec [ChromeSpec, nil] Optional chrome configuration
      # @param options [Hash] Layout-specific options
      def initialize(pdf, grid_system, chrome_spec: nil, **options)
        @pdf = pdf
        @grid_system = grid_system
        @chrome_spec = chrome_spec
        @options = options
      end

      # Get the content area specification.
      #
      # Returns a hash with grid coordinates defining where page content
      # should be positioned. The content area excludes sidebars and other
      # layout chrome elements.
      #
      # When a ChromeSpec is provided, the content area is calculated
      # automatically based on active chrome regions. Otherwise, subclasses
      # must implement this method.
      #
      # @abstract Subclasses must implement this method (unless chrome_spec provided)
      # @raise [NotImplementedError] if not implemented by subclass and no chrome_spec
      # @return [Hash] Content area with keys :col, :row, :width_boxes, :height_boxes
      #
      # @example Full page content area
      #   { col: 0, row: 0, width_boxes: 43, height_boxes: 55 }
      #
      # @example Content area with sidebars
      #   { col: 3, row: 0, width_boxes: 39, height_boxes: 55 }
      def content_area
        if @chrome_spec
          @chrome_spec.content_area(PAGE_WIDTH_BOXES, PAGE_HEIGHT_BOXES)
        else
          raise NotImplementedError, "#{self.class} must implement #content_area"
        end
      end

      # Render layout components before page content.
      #
      # This method is called after the page background (dot grid) is drawn
      # but before the page's render method is called. Use this to draw
      # sidebars, navigation chrome, or other layout elements that should
      # appear behind the page content.
      #
      # When a ChromeSpec is provided, this method automatically iterates
      # through active regions and renders each configured sidebar using
      # the SidebarRegistry for lookup.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_before(page)
        return unless @chrome_spec

        @chrome_spec.active_regions.each do |region, config|
          render_chrome_region(region, config, page)
        end
      end

      # Render layout components after page content.
      #
      # This method is called after the page's render method completes.
      # Use this to draw overlays, borders, or other elements that should
      # appear on top of the page content.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_after(page)
        # Default: no-op, subclasses can override
      end

      protected

      # Helper to access page context.
      #
      # Provides access to the RenderContext from the page, which contains
      # contextual information like year, week number, etc.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [RenderContext] The page's render context
      def page_context(page)
        page.context
      end

      # Render a single chrome region.
      #
      # Handles different configuration types:
      # - Symbol: Look up sidebar class from registry, instantiate with defaults
      # - Hash: Look up sidebar class, pass options to constructor
      # - Proc: Call directly with canvas and page
      #
      # @param region [Symbol] The region being rendered (:left, :right, :top, :bottom)
      # @param config [Symbol, Hash, Proc] The chrome configuration
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_chrome_region(region, config, page)
        case config
        when Symbol
          render_sidebar_by_name(config, {}, page)
        when Hash
          component = config[:component] || config[:sidebar]
          sidebar_options = config.reject { |k, _| [:component, :sidebar, :width, :height].include?(k) }
          render_sidebar_by_name(component, sidebar_options, page) if component
        when Proc
          config.call(canvas, page)
        end
      end

      # Render a sidebar by looking it up first in PDF-local namespace, then global registry.
      #
      # PDF-local inline sidebars (defined with `sidebar` in the PDF definition) take
      # precedence over globally registered sidebar classes. This allows recipes to
      # override built-in sidebars or define custom sidebars scoped to that PDF.
      #
      # @param name [Symbol] The sidebar type identifier
      # @param sidebar_options [Hash] Options to pass to the sidebar constructor
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_sidebar_by_name(name, sidebar_options, page)
        ctx = page_context(page)
        sidebar_definitions = ctx&.sidebar_definitions || ctx&.[](:sidebar_definitions)

        # Check PDF-local namespace first
        if sidebar_definitions && sidebar_definitions.key?(name)
          sidebar = instantiate_inline_sidebar(sidebar_definitions[name], page)
          sidebar.render
          return
        end

        # Fall back to global registry
        sidebar_class = Sidebars::SidebarRegistry.lookup(name)
        return unless sidebar_class

        sidebar = instantiate_sidebar(sidebar_class, sidebar_options, page)
        sidebar.render
      end

      # Instantiate an inline sidebar from a SidebarDefinition.
      #
      # Creates an InlineSidebar instance using the definition's parameters
      # and body block. The sidebar receives the page context for rendering.
      #
      # @param definition [PdfDSL::SidebarDefinition] The sidebar definition
      # @param page [Pages::Base] The page being rendered
      # @return [Sidebars::InlineSidebar] The instantiated inline sidebar
      def instantiate_inline_sidebar(definition, page)
        require_relative '../sidebars/inline_sidebar'

        Sidebars::InlineSidebar.new(
          canvas: canvas,
          position: definition.position,
          width: definition.width,
          body_block: definition.body_block,
          context: page_context(page)
        )
      end

      # Instantiate a sidebar with appropriate options.
      #
      # Builds the standard constructor options (canvas, page_context) and
      # merges any additional options from the chrome configuration.
      #
      # @param sidebar_class [Class] The sidebar class to instantiate
      # @param sidebar_options [Hash] Additional options for the sidebar
      # @param page [Pages::Base] The page being rendered
      # @return [SidebarBase] The instantiated sidebar
      def instantiate_sidebar(sidebar_class, sidebar_options, page)
        # Build base options that all sidebars need
        base_options = {
          canvas: canvas,
          page_context: page_context(page)
        }

        # Merge page context values that sidebars commonly need
        ctx = page_context(page)
        if ctx
          base_options[:year] = ctx[:year] if ctx[:year]
          base_options[:total_weeks] = ctx[:total_weeks] if ctx[:total_weeks]
        end

        # Merge in sidebar-specific options from config
        all_options = base_options.merge(sidebar_options)

        # Filter options to only those the sidebar accepts
        accepted_params = sidebar_class.instance_method(:initialize).parameters
        param_names = accepted_params.map { |_, name| name }

        filtered_options = all_options.select { |key, _| param_names.include?(key) }

        sidebar_class.new(**filtered_options)
      end

      # Get or create a Canvas for rendering.
      #
      # @return [Canvas] Canvas wrapping pdf and grid_system
      def canvas
        @canvas ||= Canvas.new(@pdf, @grid_system)
      end
    end
  end
end
