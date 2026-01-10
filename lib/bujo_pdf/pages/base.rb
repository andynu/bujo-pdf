# frozen_string_literal: true

require 'ostruct'
require_relative '../utilities/styling'
require_relative '../utilities/grid_system'
require_relative '../utilities/dot_grid'
require_relative '../utilities/diagnostics'
require_relative '../dsl/runtime/render_context'
require_relative '../components/all'
require_relative 'page_registry'

module BujoPdf
  module Pages
    # Abstract base class for all page types in the planner.
    #
    # This class defines a standard lifecycle for page generation using the
    # Template Method pattern. Subclasses implement specific rendering logic
    # by overriding the hook methods: setup, render, and finalize.
    #
    # Plan 05 Enhancement: Layout Support
    # -----------------------------------
    # Pages can now specify a Layout to separate chrome (sidebars, navigation)
    # from content. The layout defines:
    # - Content area boundaries (where page-specific content goes)
    # - Sidebar positions (left, right, top, bottom)
    # - Background type (dot grid, ruled, blank)
    # - Debug mode for diagnostic overlays
    #
    # Lifecycle:
    #   1. initialize(pdf, context, layout:) - Create page with PDF, context, and optional layout
    #   2. setup - Prepare page-specific state and calculations
    #   3. setup_page - Draw background (dot grid, etc.) - NEW
    #   4. render_chrome - Draw sidebars and navigation (outside content area) - NEW
    #   5. render - Draw the actual page content (within content area)
    #   6. finalize_page - Post-render tasks - NEW
    #   7. finalize - Legacy hook for backward compatibility
    #
    # Example (Legacy, no layout):
    #   class MyPage < Base
    #     def render
    #       draw_dot_grid
    #       @pdf.text "Hello World"
    #     end
    #   end
    #
    #   page = MyPage.new(pdf, { year: 2025 })
    #   page.generate
    #
    # Example (With layout - using new declarative system):
    #   class MyPage < Base
    #     def setup
    #       use_layout :standard_with_sidebars, current_week: @week_num
    #     end
    #
    #     def render
    #       # Draw content - within content area
    #     end
    #   end
    class Base
      include Styling::Colors
      include Components::All
      include PageRegistry

      attr_reader :pdf, :context, :grid_system, :grid, :layout, :content_area, :new_layout

      # Initialize a new page instance.
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [RenderContext, Hash] Rendering context
      # @param layout [Layout, nil] Optional legacy layout specification (deprecated)
      def initialize(pdf, context, layout: nil)
        @pdf = pdf
        # Accept both RenderContext objects and hashes for backward compatibility
        @context = context.is_a?(RenderContext) ? context : wrap_context_hash(context)
        @grid_system = GridSystem.new(pdf)
        @grid = @grid_system  # Alias for component compatibility
        @layout = layout || default_layout  # Legacy layout system
        @new_layout = nil  # New declarative layout system (set via use_layout)
        @components = []

        # Calculate content area from layout
        @content_area = calculate_content_area
      end

      # Generate the page (template method).
      #
      # This method orchestrates the page generation lifecycle. Subclasses
      # should NOT override this method. Instead, override the hook methods:
      # setup, setup_page, render_chrome, render, finalize_page, and finalize.
      #
      # @return [void]
      def generate
        setup              # Page-specific state setup

        # If new layout system is used, default to full_page if not specified
        # But check for PDF-level chrome config first
        if @new_layout.nil?
          require_relative '../layouts/layout_factory'

          # Check if PDF-level chrome config exists
          pdf_chrome = convert_chrome_config_to_hash(context.chrome_config)
          if pdf_chrome
            # Use configurable layout with PDF chrome
            @new_layout = Layouts::LayoutFactory.create(
              :configurable,
              @pdf,
              @grid_system,
              chrome: pdf_chrome,
              page_context: @context
            )
          else
            # No chrome config, use full page layout
            @new_layout = Layouts::LayoutFactory.create(:full_page, @pdf, @grid_system)
          end
          # Update content area from new layout
          @content_area = calculate_content_area_from_new_layout
        end

        setup_page         # Background, grid (NEW)

        # Render layout chrome (sidebars) using new system
        @new_layout.render_before(self)

        render_chrome      # Legacy chrome rendering hook
        render             # Main content
        finalize_page      # Post-render tasks (NEW)

        # Render layout overlays using new system
        @new_layout.render_after(self)

        finalize           # Legacy hook
      end

      protected

      # Hook: Prepare page-specific state and calculations.
      #
      # Override this method to set up any state needed for rendering,
      # such as calculating positions, preparing data structures, or
      # setting named destinations.
      #
      # @return [void]
      def setup
        # Default: no-op, subclasses can override
      end

      # Hook: Set up page-level elements (background, grid).
      #
      # Called after setup, before render_chrome. Override to customize
      # background rendering or add page-level decorations.
      #
      # Default implementation draws background based on layout settings.
      #
      # @return [void]
      def setup_page
        draw_background if @layout.background_enabled?
        draw_debug_grid_if_enabled
      end

      # Hook: Render chrome elements (sidebars, navigation).
      #
      # Chrome elements are UI components that appear outside the content
      # area, such as sidebars, navigation bars, tabs, etc.
      #
      # Override this method to draw chrome elements. Use full page grid
      # coordinates, not content area coordinates.
      #
      # @return [void]
      def render_chrome
        # Default: no-op, subclasses can override
      end

      # Hook: Draw the actual page content.
      #
      # This method MUST be implemented by subclasses. This is where the
      # actual page rendering logic goes.
      #
      # When using layouts, content should be positioned within the content
      # area defined by the layout. Use content_col(), content_row() helpers
      # to position elements relative to the content area.
      #
      # @raise [NotImplementedError] if not overridden by subclass
      # @return [void]
      def render
        raise NotImplementedError, "#{self.class} must implement #render"
      end

      # Hook: Finalize page rendering.
      #
      # Called after render, before finalize. Override to add page-level
      # elements that should appear on top of content (footer, watermarks, etc.).
      #
      # @return [void]
      def finalize_page
        draw_footer if @layout.footer_enabled?
      end

      # Hook: Post-render tasks (legacy).
      #
      # Override this method to perform tasks after the main rendering is
      # complete, such as adding link annotations or updating bookmarks.
      #
      # Note: This is the legacy finalize hook for backward compatibility.
      # New code should use finalize_page instead.
      #
      # @return [void]
      def finalize
        # Default: no-op, subclasses can override
      end

      # Declare which layout to use for this page (new declarative layout system).
      #
      # Should be called in setup() method of subclasses. This is the new preferred
      # way to specify layouts that automatically handle sidebar rendering.
      #
      # If not called, defaults to FullPageLayout.
      #
      # @param layout_name [Symbol] Layout name (:full_page, :standard_with_sidebars)
      # @param options [Hash] Layout-specific options (current_week, highlight_tab, etc.)
      # @return [void]
      #
      # @example Weekly page with current week highlighting
      #   def setup
      #     use_layout :standard_with_sidebars, current_week: @week_num
      #   end
      #
      # @example Year overview page with tab highlighting
      #   def setup
      #     use_layout :standard_with_sidebars,
      #       current_week: nil,
      #       highlight_tab: :year_events
      #   end
      def use_layout(layout_name, **options)
        require_relative '../layouts/layout_factory'

        # Merge context values only if they exist (not nil)
        merged_options = options.dup
        merged_options[:year] ||= context[:year] if context[:year]
        merged_options[:total_weeks] ||= context[:total_weeks] if context[:total_weeks]
        merged_options[:page_context] = @context  # Pass context for page detection

        # If no explicit chrome provided, check for PDF-level chrome config
        unless merged_options.key?(:chrome)
          pdf_chrome = convert_chrome_config_to_hash(context.chrome_config)
          merged_options[:chrome] = pdf_chrome if pdf_chrome
        end

        @new_layout = Layouts::LayoutFactory.create(
          layout_name,
          @pdf,
          @grid_system,
          **merged_options
        )
        # Update content area from new layout
        @content_area = calculate_content_area_from_new_layout
      end

      # Get the default layout options for this page type (legacy system).
      #
      # Override in subclasses to provide specific default layout options.
      # The default is a full-page layout with no sidebars.
      #
      # @return [OpenStruct] Default layout with background/debug/footer options
      def default_layout
        OpenStruct.new(
          background_enabled?: true,
          background_type: :dot_grid,
          debug_mode?: false,
          footer_enabled?: false,
          content_area_spec: { col: 0, row: 0, width: 43, height: 55 }
        )
      end

      # Calculate content area from layout specification (legacy system).
      #
      # Converts layout's grid-based content area spec to a hash with both
      # grid coordinates (col, row, width_boxes, height_boxes) and point
      # coordinates (x, y, width_pt, height_pt).
      #
      # @return [Hash] Content area with grid and point coordinates
      def calculate_content_area
        area = @layout.content_area_spec
        {
          col: area[:col],
          row: area[:row],
          width_boxes: area[:width],
          height_boxes: area[:height],
          # Computed point values
          x: @grid_system.x(area[:col]),
          y: @grid_system.y(area[:row]),
          width_pt: @grid_system.width(area[:width]),
          height_pt: @grid_system.height(area[:height])
        }
      end

      # Calculate content area from new layout system.
      #
      # Converts new layout's content area to the same format as legacy system
      # for backward compatibility.
      #
      # @return [Hash] Content area with grid and point coordinates
      def calculate_content_area_from_new_layout
        area = @new_layout.content_area
        {
          col: area[:col],
          row: area[:row],
          width_boxes: area[:width_boxes],
          height_boxes: area[:height_boxes],
          # Computed point values
          x: @grid_system.x(area[:col]),
          y: @grid_system.y(area[:row]),
          width_pt: @grid_system.width(area[:width_boxes]),
          height_pt: @grid_system.height(area[:height_boxes])
        }
      end

      # Draw background based on layout settings.
      #
      # @return [void]
      def draw_background
        # Draw page background color if not white
        bg_color = color_background
        unless bg_color == 'FFFFFF'
          @pdf.fill_color bg_color
          @pdf.fill_rectangle [0, Styling::Grid::PAGE_HEIGHT], Styling::Grid::PAGE_WIDTH, Styling::Grid::PAGE_HEIGHT
          @pdf.fill_color color_text_black  # Reset to text color
        end

        # Draw background pattern (dots, rules, etc.)
        case @layout.background_type
        when :dot_grid
          @pdf.stamp("page_dots")
        when :ruled
          # Future: ruled lines background
        when :blank
          # Nothing
        end
      end

      # Draw debug grid if layout debug mode is enabled.
      #
      # @return [void]
      def draw_debug_grid_if_enabled
        if @layout.debug_mode?
          Diagnostics.draw_grid(@pdf, @grid_system, enabled: true, label_every: 5)
        end
      end

      # Draw footer (placeholder for future implementation).
      #
      # @return [void]
      def draw_footer
        # Future: footer rendering
      end

      # Draw page set label in the footer area.
      #
      # No-op when not inside a page_set block. When inside a set,
      # renders the interpolated label (e.g., "Index 1 of 4").
      #
      # @param col [Integer] Column position (default: 2)
      # @param row [Integer] Row position (default: 54, near bottom)
      # @param width [Integer] Width in grid boxes (default: 39)
      # @return [void]
      #
      # @example Default footer position
      #   draw_set_label  # Renders "Index 1 of 4" centered at row 54
      #
      # @example Custom position
      #   draw_set_label(col: 5, row: 53, width: 30)
      def draw_set_label(col: 2, row: 54, width: 39)
        return unless context.set?

        text(col, row, context.set.label,
             size: 9, color: '999999', width: width,
             align: :center, valign: :bottom)
      end

      # Add a component to be rendered.
      #
      # Components are rendered in the order they are added, during the
      # render_components call.
      #
      # @param component [Object] A component with a #render method
      # @return [void]
      def add_component(component)
        @components << component
      end

      # Render all added components.
      #
      # Call this method in your render implementation to render all
      # components that have been added via add_component.
      #
      # @return [void]
      def render_components
        @components.each(&:render)
      end

      # Set a named destination for this page.
      #
      # Named destinations allow internal links to jump to specific pages.
      # The destination is set at the top of the current page.
      #
      # @param name [String] The destination name (e.g., 'week_1')
      # @return [void]
      def set_destination(name)
        @pdf.add_dest(name, @pdf.dest_xyz(0, @pdf.bounds.top))
      end

      # Helper to access styling utilities.
      #
      # @return [Module] The Styling utilities module
      def styling
        Styling
      end

      # Get the title to use in the PDF outline (bookmarks).
      #
      # By default, uses the title from PageRegistry. Override in subclasses
      # when the outline title should differ from the registered title.
      #
      # @return [String, nil] The outline title, or nil if no title
      def outline_title
        self.class.generate_title(context.to_h)
      end

      # Draw dot grid across the entire page.
      #
      # This method uses the page_dots stamp if available (much more efficient),
      # otherwise it falls back to drawing dots directly.
      #
      # @param width [Numeric, nil] Width to draw dots (ignored if stamp exists)
      # @param height [Numeric, nil] Height to draw dots (ignored if stamp exists)
      # @return [void]
      def draw_dot_grid(width = nil, height = nil)
        # Use stamp for efficiency (reduces file size by ~90%)
        @pdf.stamp("page_dots")
      end

      # Draw a grid of the specified type across the entire page.
      #
      # Uses pre-created stamps for efficiency. Available grid types:
      # - :dots - Standard dot grid (5mm)
      # - :graph - Square grid with lines
      # - :lined - Ruled lines with margin
      # - :isometric - Isometric grid (30-60-90°)
      # - :perspective - Perspective grid
      # - :hexagon - Hexagon grid
      #
      # @param type [Symbol] Grid type to draw
      # @return [void]
      # @raise [ArgumentError] if grid type is not supported
      def draw_grid(type)
        # Use 'page_dots' for dots (backward compatibility), 'grid_<type>' for others
        stamp_name = type == :dots ? 'page_dots' : "grid_#{type}"
        @pdf.stamp(stamp_name)
      end

      # Draw diagnostic grid overlay for layout debugging.
      #
      # This is a convenience method that delegates to the Diagnostics utility.
      # The diagnostic grid is enabled by default.
      #
      # @param label_every [Integer] Show labels every N grid lines
      # @return [void]
      def draw_diagnostic_grid(label_every: 5)
        Diagnostics.draw_grid(@pdf, @grid_system, enabled: true, label_every: label_every)
      end

      # Content Area Helpers
      # --------------------
      # These helpers make it easier to work with content area constraints
      # when positioning elements in the render method.

      # Get content area starting column.
      #
      # @param offset [Integer] Optional offset from content area start
      # @return [Integer] Column in page grid coordinates
      def content_col(offset = 0)
        @content_area[:col] + offset
      end

      # Get content area starting row.
      #
      # @param offset [Integer] Optional offset from content area start
      # @return [Integer] Row in page grid coordinates
      def content_row(offset = 0)
        @content_area[:row] + offset
      end

      # Get content area width in grid boxes.
      #
      # @return [Integer] Width in grid boxes
      def content_width
        @content_area[:width_boxes]
      end

      # Get content area height in grid boxes.
      #
      # @return [Integer] Height in grid boxes
      def content_height
        @content_area[:height_boxes]
      end

      # Get a rectangle within the content area using content-relative coordinates.
      #
      # This is useful when you want to position something relative to the
      # content area rather than the full page.
      #
      # @param col_offset [Integer] Column offset from content area start
      # @param row_offset [Integer] Row offset from content area start
      # @param width_boxes [Integer] Width in grid boxes
      # @param height_boxes [Integer] Height in grid boxes
      # @return [Hash] Rectangle with :x, :y, :width, :height keys
      #
      # @example
      #   # Get a box 5 boxes from content start, 10 boxes wide
      #   box = content_rect(5, 2, 10, 5)
      #   @pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
      #     # Draw content
      #   end
      def content_rect(col_offset, row_offset, width_boxes, height_boxes)
        @grid_system.rect(
          content_col(col_offset),
          content_row(row_offset),
          width_boxes,
          height_boxes
        )
      end

      private

      # Wrap a context hash in a RenderContext for backward compatibility.
      #
      # This method enables the new RenderContext system while maintaining
      # compatibility with code that still passes plain hashes as context.
      #
      # @param hash [Hash] Context hash
      # @return [RenderContext] Wrapped context
      def wrap_context_hash(hash)
        # Extract known keys and pass rest as **data
        RenderContext.new(
          page_key: hash[:page_key] || :unknown,
          page_number: hash[:page_number] || 0,
          year: hash[:year],
          week_num: hash[:week_num],
          week_start: hash[:week_start],
          week_end: hash[:week_end],
          total_weeks: hash[:total_weeks],
          total_pages: hash[:total_pages],
          chrome_config: hash[:chrome_config],
          **hash.except(:page_key, :page_number, :year, :week_num,
                        :week_start, :week_end, :total_weeks, :total_pages, :chrome_config)
        )
      end

      # Convert a ChromeBuilder config to a hash suitable for LayoutFactory.
      #
      # Transforms PdfDSL::ChromeBuilder's SidebarConfig objects into the
      # format expected by LayoutFactory.build_chrome_spec.
      #
      # @param chrome_config [PdfDSL::ChromeBuilder, nil] PDF-level chrome configuration
      # @return [Hash, nil] Chrome hash with :left, :right, :top, :bottom keys, or nil
      #
      # @example
      #   # ChromeBuilder with left: :week_sidebar, right: :tab_sidebar
      #   convert_chrome_config_to_hash(chrome_config)
      #   # => { left: :week_sidebar, right: :tab_sidebar }
      def convert_chrome_config_to_hash(chrome_config)
        return nil if chrome_config.nil?
        return nil if chrome_config.empty?

        result = {}

        # Convert each region's SidebarConfig to appropriate format
        %i[left right top bottom].each do |region|
          config = chrome_config.send("#{region}_config")
          next unless config

          result[region] = convert_sidebar_config(config)
        end

        result.empty? ? nil : result
      end

      # Convert a SidebarConfig to the format expected by ChromeSpec/LayoutFactory.
      #
      # @param config [PdfDSL::ChromeBuilder::SidebarConfig] Sidebar configuration
      # @return [Symbol, Hash] Simple symbol or hash with component and options
      def convert_sidebar_config(config)
        # If no options and no tabs, just return the sidebar name
        if config.options.empty? && !config.tabs?
          config.sidebar_name
        else
          # Build a hash with component name and options
          result = { component: config.sidebar_name }
          result.merge!(config.options)

          # Include tabs if present
          result[:tabs] = config.tabs if config.tabs?

          result
        end
      end
    end
  end
end
