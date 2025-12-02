# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative 'ruled_lines'

module BujoPdf
  module Components
    # TodoList renders a configurable to-do list with bullet/checkbox markers.
    #
    # This component creates consistent to-do lists for bullet journal pages.
    # Each row has a marker column (bullet, checkbox, or circle) and an
    # empty space for handwritten items.
    #
    # Key features:
    # - Grid-based sizing (width in boxes, rows for item count)
    # - Configurable bullet styles (:bullet, :checkbox, :circle)
    # - Optional row dividers (none, solid, dashed)
    # - Theme-aware colors
    #
    # Example usage (standard canvas/grid interface):
    #   todo = TodoList.new(
    #     canvas: canvas,
    #     col: 5,
    #     row: 10,
    #     width: 20,
    #     rows: 8,
    #     bullet_style: :bullet,
    #     divider: :dashed
    #   )
    #   todo.render
    #
    class TodoList < Component
      include RuledLines::Mixin
      # Default bullet radius in points (larger than 1pt dot grid dots)
      BULLET_RADIUS = 2.0

      # Default checkbox size in points
      CHECKBOX_SIZE = 8.0

      # Default circle radius in points
      CIRCLE_RADIUS = 4.0

      # Width of marker column in boxes
      MARKER_COLUMN_BOXES = 1

      # Initialize a new TodoList component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column in grid coordinates
      # @param row [Integer] Starting row in grid coordinates
      # @param width [Integer] Width in grid boxes
      # @param rows [Integer] Number of to-do items (rows)
      # @param bullet_style [Symbol] Marker style :bullet, :checkbox, or :circle (default: :bullet)
      # @param divider [Symbol] Row divider style :none, :solid, or :dashed (default: :none)
      # @param divider_color [String, nil] Hex color for dividers (default: theme BORDERS color)
      # @param bullet_color [String, nil] Hex color for bullets (default: theme TEXT_BLACK)
      def initialize(canvas:, col:, row:, width:, rows:, bullet_style: :bullet,
                     divider: :none, divider_color: nil, bullet_color: nil)
        super(canvas: canvas)
        @col = col
        @row = row
        @width_boxes = width
        @rows = rows
        @bullet_style = bullet_style
        @divider = divider
        @divider_color = divider_color
        @bullet_color = bullet_color

        @row_height = Styling::Grid::DOT_SPACING
        validate_parameters
      end

      # Render the todo list
      #
      # Draws the markers and optional dividers for each row.
      # Dividers are rendered using the RuledLines component for consistency.
      #
      # @return [void]
      def render
        # Draw dividers first (if any) so markers draw on top
        draw_dividers if @divider != :none

        # Draw markers for each row
        @rows.times do |row_index|
          row_y = grid.y(@row + row_index)
          draw_marker(row_y)
        end
      end

      # Get the bounding rectangle for a specific row
      #
      # @param row_index [Integer] Row index (0-based)
      # @return [Hash] Rectangle with :x, :y, :width, :height keys in points
      # @raise [ArgumentError] if row_index is out of range
      def row_rect(row_index)
        raise ArgumentError, "row_index must be 0-#{@rows - 1}, got #{row_index}" unless (0...@rows).cover?(row_index)

        grid.rect(@col, @row + row_index, @width_boxes, 1)
      end

      # Get the text area rectangle (excluding marker column) for a row
      #
      # @param row_index [Integer] Row index (0-based)
      # @return [Hash] Rectangle with :x, :y, :width, :height keys in points
      def text_rect(row_index)
        raise ArgumentError, "row_index must be 0-#{@rows - 1}, got #{row_index}" unless (0...@rows).cover?(row_index)

        grid.rect(@col + MARKER_COLUMN_BOXES, @row + row_index, @width_boxes - MARKER_COLUMN_BOXES, 1)
      end

      # Total height of the todo list in points
      #
      # @return [Float] Height in points
      def height
        @rows * @row_height
      end

      private

      # Validate constructor parameters
      #
      # @raise [ArgumentError] if any parameters are invalid
      # @return [void]
      def validate_parameters
        raise ArgumentError, 'canvas is required' if @canvas.nil?
        raise ArgumentError, 'width must be positive' if @width_boxes <= 0
        raise ArgumentError, 'rows must be positive' if @rows <= 0
        raise ArgumentError, 'bullet_style must be :bullet, :checkbox, or :circle' unless %i[bullet checkbox circle].include?(@bullet_style)
        raise ArgumentError, 'divider must be :none, :solid, or :dashed' unless %i[none solid dashed].include?(@divider)
      end

      # Draw a marker (bullet, checkbox, or circle) for a row
      #
      # @param row_y [Float] Top Y coordinate of the row
      # @return [void]
      def draw_marker(row_y)
        # Center of first box in the row
        marker_center_x = grid.x(@col) + (@row_height / 2)
        marker_center_y = row_y - (@row_height / 2)

        pdf.save_graphics_state do
          pdf.fill_color(bullet_color)
          pdf.stroke_color(bullet_color)

          case @bullet_style
          when :bullet
            draw_bullet(marker_center_x, marker_center_y)
          when :checkbox
            draw_checkbox(marker_center_x, marker_center_y)
          when :circle
            draw_circle(marker_center_x, marker_center_y)
          end
        end
      end

      # Draw a filled bullet dot
      #
      # @param cx [Float] Center x
      # @param cy [Float] Center y
      # @return [void]
      def draw_bullet(cx, cy)
        pdf.fill_circle([cx, cy], BULLET_RADIUS)
      end

      # Draw an empty checkbox square
      #
      # @param cx [Float] Center x
      # @param cy [Float] Center y
      # @return [void]
      def draw_checkbox(cx, cy)
        half = CHECKBOX_SIZE / 2
        pdf.line_width = 0.5
        pdf.stroke_rectangle([cx - half, cy + half], CHECKBOX_SIZE, CHECKBOX_SIZE)
      end

      # Draw an empty circle
      #
      # @param cx [Float] Center x
      # @param cy [Float] Center y
      # @return [void]
      def draw_circle(cx, cy)
        pdf.line_width = 0.5
        pdf.stroke_circle([cx, cy], CIRCLE_RADIUS)
      end

      # Draw divider lines between rows using RuledLines component
      #
      # Dividers are drawn between rows (not after the last row).
      # Uses RuledLines for consistency and code reuse.
      #
      # @return [void]
      def draw_dividers
        # Number of dividers is one less than number of rows
        return if @rows <= 1

        divider_count = @rows - 1
        divider_col = @col + MARKER_COLUMN_BOXES
        divider_width = @width_boxes - MARKER_COLUMN_BOXES

        # Map divider style to dash pattern
        dash_pattern = @divider == :dashed ? [3, 2] : nil

        ruled_lines(
          divider_col,
          @row,
          divider_width,
          divider_count,
          color: divider_color,
          stroke: 0.5,
          dash: dash_pattern,
          redraw_dots: false
        )
      end

      # Get the effective bullet color
      #
      # @return [String] Hex color
      def bullet_color
        @bullet_color || Styling::Colors.TEXT_BLACK
      end

      # Get the effective divider color
      #
      # @return [String] Hex color
      def divider_color
        @divider_color || Styling::Colors.BORDERS
      end
    end
  end
end
