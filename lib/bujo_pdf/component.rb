# frozen_string_literal: true

module BujoPdf
  # Base class for page-level components.
  #
  # Components are reusable page elements that compose sub-components into
  # cohesive sections. They sit between Pages and SubComponents in the
  # architecture hierarchy:
  #
  #   Page (structure) → Component (section) → SubComponent (primitive)
  #
  # Plan 05 Enhancement: Content Area Support
  # ------------------------------------------
  # Components can now receive content area constraints from their parent page.
  # This enables components to:
  # - Position themselves relative to content area, not full page
  # - Respect layout boundaries automatically
  # - Work within different page layouts without modification
  #
  # Key Concepts:
  # - **Content Area**: The region where content should be rendered (from page layout)
  # - **Grid System**: The underlying grid for positioning (43×55 boxes)
  # - **Sub-Components**: Low-level rendering primitives (WeekColumn, Fieldset, etc.)
  #
  # @example Component without content area (legacy)
  #   class MyComponent < Component
  #     def initialize(pdf, grid_system)
  #       super(pdf, grid_system)
  #     end
  #
  #     def render
  #       # Position using full page coordinates
  #       box = @grid.rect(5, 10, 20, 15)
  #       @pdf.text_box "Hello", at: [box[:x], box[:y]]
  #     end
  #   end
  #
  # @example Component with content area
  #   class MyComponent < Component
  #     def initialize(pdf, grid_system, content_area:)
  #       super(pdf, grid_system, content_area: content_area)
  #     end
  #
  #     def render
  #       # Position relative to content area
  #       box = content_rect(0, 0, 20, 15)  # 20 boxes wide, 15 tall, at content start
  #       @pdf.text_box "Hello", at: [box[:x], box[:y]]
  #     end
  #   end
  class Component
    # @return [Prawn::Document] The PDF document
    attr_reader :pdf

    # @return [GridSystem] The grid system for positioning
    attr_reader :grid

    # @return [Hash, nil] Content area constraints from page layout
    attr_reader :content_area

    # @return [Hash] Component configuration options
    attr_reader :options

    # Initialize a new component.
    #
    # @param pdf [Prawn::Document] The PDF document to render into
    # @param grid_system [GridSystem] The grid system for positioning
    # @param content_area [Hash, nil] Optional content area constraints from page
    # @option content_area [Integer] :col Starting column in page coordinates
    # @option content_area [Integer] :row Starting row in page coordinates
    # @option content_area [Integer] :width_boxes Width in grid boxes
    # @option content_area [Integer] :height_boxes Height in grid boxes
    # @option content_area [Float] :x Starting x in points
    # @option content_area [Float] :y Starting y in points
    # @option content_area [Float] :width_pt Width in points
    # @option content_area [Float] :height_pt Height in points
    # @param options [Hash] Additional component configuration
    def initialize(pdf, grid_system, content_area: nil, **options)
      @pdf = pdf
      @grid = grid_system
      @content_area = content_area
      @options = options

      validate_configuration
    end

    # Render the component (must be implemented by subclasses).
    #
    # This is where the component draws its content. Use grid positioning
    # methods and sub-component factories to build the component.
    #
    # When a content area is provided, use content_col(), content_row(),
    # and content_rect() to position elements relative to the content area.
    #
    # @raise [NotImplementedError] if not overridden by subclass
    # @return [void]
    def render
      raise NotImplementedError, "#{self.class} must implement #render"
    end

    # Get the rendering context.
    #
    # The context provides information about the current page being rendered,
    # such as the page type, page number, year, week info, etc.
    #
    # For backward compatibility, this returns @options which may be either:
    # - A RenderContext object (new system)
    # - A Hash (legacy system)
    #
    # Components can access context data using either:
    # - `context.year` (if RenderContext)
    # - `context[:year]` (works with both)
    #
    # @return [RenderContext, Hash] The rendering context
    def context
      @options
    end

    protected

    # Validate component configuration.
    #
    # Override in subclasses to validate required options are present.
    #
    # @return [void]
    def validate_configuration
      # Default: no validation, subclasses can override
    end

    # Validate that required options are present in context.
    #
    # This is a convenience helper for subclasses that need to ensure specific
    # options are provided. Call this from your validate_configuration method.
    #
    # @param keys [Array<Symbol>] Required option keys
    # @raise [ArgumentError] if any required keys are missing
    # @return [void]
    #
    # @example Basic validation
    #   def validate_configuration
    #     require_options(:year, :total_weeks, :current_week_num)
    #   end
    #
    # @example Validation with custom message
    #   def validate_configuration
    #     require_options(:content_start_col, :notes_start_row)
    #   rescue ArgumentError => e
    #     raise ArgumentError, "CornellNotes configuration error: #{e.message}"
    #   end
    def require_options(*keys)
      missing_keys = keys - context.keys

      unless missing_keys.empty?
        raise ArgumentError, "#{self.class.name} requires: #{missing_keys.join(', ')}"
      end
    end

    # Style Context Managers
    # ----------------------
    # These helpers manage temporary style changes (colors, fonts) and automatically
    # restore the previous state after the block executes.

    # Execute block with temporary fill color, then restore previous color.
    #
    # This prevents the common bug of setting a color and forgetting to reset it,
    # which can affect subsequent rendering operations.
    #
    # @param color [String] 6-digit hex color code
    # @yield Block to execute with color applied
    # @return [void]
    #
    # @example Draw gray text without manual reset
    #   with_fill_color('888888') do
    #     @pdf.text "Gray text"
    #   end
    #   # Color automatically restored to previous value
    #
    # @example Nested color changes
    #   with_fill_color('888888') do
    #     @pdf.text "Gray"
    #     with_fill_color('FF0000') do
    #       @pdf.text "Red"
    #     end
    #     @pdf.text "Gray again"
    #   end
    def with_fill_color(color)
      original = @pdf.fill_color
      @pdf.fill_color color
      yield
    ensure
      @pdf.fill_color original
    end

    # Execute block with temporary stroke color, then restore previous color.
    #
    # @param color [String] 6-digit hex color code
    # @yield Block to execute with color applied
    # @return [void]
    #
    # @example Draw border with custom color
    #   with_stroke_color('CCCCCC') do
    #     @pdf.stroke_bounds
    #   end
    def with_stroke_color(color)
      original = @pdf.stroke_color
      @pdf.stroke_color color
      yield
    ensure
      @pdf.stroke_color original
    end

    # Execute block with temporary font settings, then restore previous font.
    #
    # @param family [String] Font family name
    # @param size [Integer, nil] Font size (optional)
    # @yield Block to execute with font applied
    # @return [void]
    #
    # @example Bold text with automatic restoration
    #   with_font("Helvetica-Bold", 14) do
    #     @pdf.text "Bold title"
    #   end
    #   # Font automatically restored to previous family and size
    #
    # @example Change family only, preserve size
    #   with_font("Helvetica-Bold") do
    #     @pdf.text "Bold text at current size"
    #   end
    def with_font(family, size = nil)
      original_family = @pdf.font.family
      original_size = @pdf.font_size

      if size
        @pdf.font family, size: size
      else
        @pdf.font family
      end

      yield
    ensure
      @pdf.font original_family, size: original_size
    end

    # Convenience method to check if rendering a specific page.
    #
    # This method provides a safe way to check the current page even when
    # using the legacy hash-based context system. It will work with both
    # RenderContext objects and plain hashes.
    #
    # @param key [Symbol, String] Page key to check
    # @return [Boolean] True if current page matches key
    #
    # @example
    #   if current_page?(:year_events)
    #     @pdf.font "Helvetica-Bold"  # Bold for current page
    #   end
    def current_page?(key)
      context.respond_to?(:current_page?) ? context.current_page?(key) : false
    end

    # Content Area Positioning Helpers
    # ---------------------------------
    # These methods help position elements relative to the content area
    # when a content area constraint is provided by the page.

    # Get column position relative to content area.
    #
    # If content area is defined, returns page column offset from content start.
    # If no content area, returns the offset as-is (full page coordinates).
    #
    # @param offset [Integer] Column offset from content area start
    # @return [Integer] Column in page grid coordinates
    def content_col(offset = 0)
      content_area ? content_area[:col] + offset : offset
    end

    # Get row position relative to content area.
    #
    # If content area is defined, returns page row offset from content start.
    # If no content area, returns the offset as-is (full page coordinates).
    #
    # @param offset [Integer] Row offset from content area start
    # @return [Integer] Row in page grid coordinates
    def content_row(offset = 0)
      content_area ? content_area[:row] + offset : offset
    end

    # Get available width for component.
    #
    # If content area is defined, returns content area width.
    # If no content area, returns full page width (43 boxes).
    #
    # @return [Integer] Available width in grid boxes
    def available_width
      content_area ? content_area[:width_boxes] : 43
    end

    # Get available height for component.
    #
    # If content area is defined, returns content area height.
    # If no content area, returns full page height (55 boxes).
    #
    # @return [Integer] Available height in grid boxes
    def available_height
      content_area ? content_area[:height_boxes] : 55
    end

    # Get a rectangle within the content area using content-relative coordinates.
    #
    # This is the primary method for positioning component elements when
    # working with content area constraints.
    #
    # @param col_offset [Integer] Column offset from content area start
    # @param row_offset [Integer] Row offset from content area start
    # @param width_boxes [Integer] Width in grid boxes
    # @param height_boxes [Integer] Height in grid boxes
    # @return [Hash] Rectangle with :x, :y, :width, :height keys
    #
    # @example Position a box at content area start
    #   box = content_rect(0, 0, 20, 10)
    #   @pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
    #     @pdf.text "Content"
    #   end
    #
    # @example Position a box 5 boxes from content start
    #   box = content_rect(5, 2, 15, 8)
    #   @pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
    #     @pdf.text "Content"
    #   end
    def content_rect(col_offset, row_offset, width_boxes, height_boxes)
      @grid.rect(
        content_col(col_offset),
        content_row(row_offset),
        width_boxes,
        height_boxes
      )
    end

    # Sub-Component Factory Methods
    # ------------------------------
    # These methods create sub-component instances for use in component rendering.
    # They provide a convenient interface to the sub-component library.

    # Create a generic sub-component instance.
    #
    # @param klass [Class] The sub-component class to instantiate
    # @param options [Hash] Options to pass to sub-component constructor
    # @return [Object] The sub-component instance
    def create_sub_component(klass, **options)
      klass.new(@pdf, @grid, **options)
    end

    # Create a WeekColumn sub-component.
    #
    # @param options [Hash] Options for WeekColumn
    # @return [SubComponent::WeekColumn] The week column instance
    def create_week_column(**options)
      require_relative 'sub_components/week_column'
      create_sub_component(SubComponent::WeekColumn, **options)
    end

    # Create a Fieldset sub-component.
    #
    # @param options [Hash] Options for Fieldset
    # @return [SubComponent::Fieldset] The fieldset instance
    def create_fieldset(**options)
      require_relative 'sub_components/fieldset'
      create_sub_component(SubComponent::Fieldset, **options)
    end

    # Create a DayHeader sub-component.
    #
    # @param options [Hash] Options for DayHeader
    # @return [SubComponent::DayHeader] The day header instance
    def create_day_header(**options)
      require_relative 'sub_components/day_header'
      create_sub_component(SubComponent::DayHeader, **options)
    end

    # Convenience Delegators
    # ----------------------
    # These methods delegate to the grid system for convenience.

    # Convert grid column to x-coordinate.
    #
    # @param col [Integer, Float] Grid column
    # @return [Float] X-coordinate in points
    def grid_x(col)
      @grid.x(col)
    end

    # Convert grid row to y-coordinate.
    #
    # @param row [Integer, Float] Grid row
    # @return [Float] Y-coordinate in points
    def grid_y(row)
      @grid.y(row)
    end

    # Convert grid boxes to width in points.
    #
    # @param boxes [Integer, Float] Number of grid boxes
    # @return [Float] Width in points
    def grid_width(boxes)
      @grid.width(boxes)
    end

    # Convert grid boxes to height in points.
    #
    # @param boxes [Integer, Float] Number of grid boxes
    # @return [Float] Height in points
    def grid_height(boxes)
      @grid.height(boxes)
    end

    # Get a rectangle in page grid coordinates.
    #
    # Use this for positioning in full page coordinates. For content-relative
    # positioning, use content_rect() instead.
    #
    # @param col [Integer] Grid column
    # @param row [Integer] Grid row
    # @param width_boxes [Integer] Width in grid boxes
    # @param height_boxes [Integer] Height in grid boxes
    # @return [Hash] Rectangle with :x, :y, :width, :height keys
    def grid_rect(col, row, width_boxes, height_boxes)
      @grid.rect(col, row, width_boxes, height_boxes)
    end
  end
end
