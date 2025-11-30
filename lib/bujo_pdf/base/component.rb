# frozen_string_literal: true

module BujoPdf
  # Base class for page-level components.
  #
  # Components are reusable page elements that can compose other components into
  # cohesive sections. There are two main component types:
  #
  # 1. **Component** - uses render() method, typically for sections
  # 2. **SubComponentBase** - uses render_at(col, row, width, height) for positioned primitives
  #
  # Components receive a Canvas object that bundles the PDF document with its
  # grid system. This simplifies component interfaces by passing one object
  # instead of separate pdf/grid parameters.
  #
  # Key Concepts:
  # - **Canvas**: Bundles pdf + grid together (see Canvas class)
  # - **Content Area**: Optional region where content should be rendered
  # - **Grid System**: The underlying grid for positioning (43x55 boxes)
  #
  # @example Basic component
  #   class MyComponent < Component
  #     def initialize(canvas:, title:)
  #       super(canvas: canvas)
  #       @title = title
  #     end
  #
  #     def render
  #       box = grid.rect(5, 10, 20, 15)
  #       pdf.text_box @title, at: [box[:x], box[:y]]
  #     end
  #   end
  #
  # @example Component with content area
  #   class MyComponent < Component
  #     def initialize(canvas:, content_area:)
  #       super(canvas: canvas, content_area: content_area)
  #     end
  #
  #     def render
  #       # Position relative to content area
  #       box = content_rect(0, 0, 20, 15)
  #       pdf.text_box "Hello", at: [box[:x], box[:y]]
  #     end
  #   end
  class Component
    # @return [Canvas] The canvas wrapping pdf and grid
    attr_reader :canvas

    # @return [Hash, nil] Content area constraints from page layout
    attr_reader :content_area

    # Initialize a new component.
    #
    # @param canvas [Canvas] The canvas wrapping pdf and grid
    # @param content_area [Hash, nil] Optional content area constraints from page
    # @option content_area [Integer] :col Starting column in page coordinates
    # @option content_area [Integer] :row Starting row in page coordinates
    # @option content_area [Integer] :width_boxes Width in grid boxes
    # @option content_area [Integer] :height_boxes Height in grid boxes
    # @option content_area [Float] :x Starting x in points
    # @option content_area [Float] :y Starting y in points
    # @option content_area [Float] :width_pt Width in points
    # @option content_area [Float] :height_pt Height in points
    def initialize(canvas:, content_area: nil)
      @canvas = canvas
      @content_area = content_area
    end

    # Convenience accessor for the PDF document.
    #
    # @return [Prawn::Document] The PDF document
    def pdf = @canvas.pdf

    # Convenience accessor for the grid system.
    #
    # @return [GridSystem] The grid system for positioning
    def grid = @canvas.grid

    # Render the component (must be implemented by subclasses).
    #
    # This is where the component draws its content. Use grid positioning
    # methods to build the component.
    #
    # When a content area is provided, use content_col(), content_row(),
    # and content_rect() to position elements relative to the content area.
    #
    # @raise [NotImplementedError] if not overridden by subclass
    # @return [void]
    def render
      raise NotImplementedError, "#{self.class} must implement #render"
    end

    protected

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
    #     pdf.text "Gray text"
    #   end
    #   # Color automatically restored to previous value
    #
    # @example Nested color changes
    #   with_fill_color('888888') do
    #     pdf.text "Gray"
    #     with_fill_color('FF0000') do
    #       pdf.text "Red"
    #     end
    #     pdf.text "Gray again"
    #   end
    def with_fill_color(color)
      original = pdf.fill_color
      pdf.fill_color color
      yield
    ensure
      pdf.fill_color original
    end

    # Execute block with temporary stroke color, then restore previous color.
    #
    # @param color [String] 6-digit hex color code
    # @yield Block to execute with color applied
    # @return [void]
    #
    # @example Draw border with custom color
    #   with_stroke_color('CCCCCC') do
    #     pdf.stroke_bounds
    #   end
    def with_stroke_color(color)
      original = pdf.stroke_color
      pdf.stroke_color color
      yield
    ensure
      pdf.stroke_color original
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
    #     pdf.text "Bold title"
    #   end
    #   # Font automatically restored to previous family and size
    #
    # @example Change family only, preserve size
    #   with_font("Helvetica-Bold") do
    #     pdf.text "Bold text at current size"
    #   end
    def with_font(family, size = nil)
      original_family = pdf.font.family
      original_size = pdf.font_size

      if size
        pdf.font family, size: size
      else
        pdf.font family
      end

      yield
    ensure
      pdf.font original_family, size: original_size
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
    #   pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
    #     pdf.text "Content"
    #   end
    #
    # @example Position a box 5 boxes from content start
    #   box = content_rect(5, 2, 15, 8)
    #   pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
    #     pdf.text "Content"
    #   end
    def content_rect(col_offset, row_offset, width_boxes, height_boxes)
      grid.rect(
        content_col(col_offset),
        content_row(row_offset),
        width_boxes,
        height_boxes
      )
    end

    # Convenience Delegators
    # ----------------------
    # These methods delegate to the grid system for convenience.

    # Convert grid column to x-coordinate.
    #
    # @param col [Integer, Float] Grid column
    # @return [Float] X-coordinate in points
    def grid_x(col)
      grid.x(col)
    end

    # Convert grid row to y-coordinate.
    #
    # @param row [Integer, Float] Grid row
    # @return [Float] Y-coordinate in points
    def grid_y(row)
      grid.y(row)
    end

    # Convert grid boxes to width in points.
    #
    # @param boxes [Integer, Float] Number of grid boxes
    # @return [Float] Width in points
    def grid_width(boxes)
      grid.width(boxes)
    end

    # Convert grid boxes to height in points.
    #
    # @param boxes [Integer, Float] Number of grid boxes
    # @return [Float] Height in points
    def grid_height(boxes)
      grid.height(boxes)
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
      grid.rect(col, row, width_boxes, height_boxes)
    end
  end
end
