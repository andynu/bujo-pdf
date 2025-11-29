# frozen_string_literal: true

require_relative '../utilities/styling'

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
    # Example usage:
    #   todo = TodoList.new(
    #     pdf: @pdf,
    #     x: 100,
    #     y: 700,
    #     width: 200,
    #     rows: 8,
    #     bullet_style: :bullet,
    #     divider: :dashed
    #   )
    #   todo.render
    #
    # Or using grid coordinates via the class method:
    #   todo = TodoList.from_grid(
    #     pdf: @pdf,
    #     grid: grid,
    #     col: 5,
    #     row: 10,
    #     width_boxes: 20,
    #     rows: 8
    #   )
    class TodoList
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
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param x [Float] Left edge x-coordinate in points
      # @param y [Float] Top edge y-coordinate in points
      # @param width [Float] Total width in points
      # @param rows [Integer] Number of to-do items (rows)
      # @param bullet_style [Symbol] Marker style :bullet, :checkbox, or :circle (default: :bullet)
      # @param divider [Symbol] Row divider style :none, :solid, or :dashed (default: :none)
      # @param divider_color [String, nil] Hex color for dividers (default: theme BORDERS color)
      # @param bullet_color [String, nil] Hex color for bullets (default: theme TEXT_BLACK)
      def initialize(pdf:, x:, y:, width:, rows:, bullet_style: :bullet,
                     divider: :none, divider_color: nil, bullet_color: nil)
        @pdf = pdf
        @x = x
        @y = y
        @width = width
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
      #
      # @return [void]
      def render
        @rows.times do |row_index|
          row_y = @y - (row_index * @row_height)
          draw_marker(row_index, row_y)
          draw_divider(row_index, row_y) if @divider != :none
        end
      end

      # Get the bounding rectangle for a specific row
      #
      # @param row_index [Integer] Row index (0-based)
      # @return [Hash] Rectangle with :x, :y, :width, :height keys in points
      # @raise [ArgumentError] if row_index is out of range
      def row_rect(row_index)
        raise ArgumentError, "row_index must be 0-#{@rows - 1}, got #{row_index}" unless (0...@rows).cover?(row_index)

        {
          x: @x,
          y: @y - (row_index * @row_height),
          width: @width,
          height: @row_height
        }
      end

      # Get the text area rectangle (excluding marker column) for a row
      #
      # @param row_index [Integer] Row index (0-based)
      # @return [Hash] Rectangle with :x, :y, :width, :height keys in points
      def text_rect(row_index)
        rect = row_rect(row_index)
        marker_width = MARKER_COLUMN_BOXES * @row_height
        {
          x: rect[:x] + marker_width,
          y: rect[:y],
          width: rect[:width] - marker_width,
          height: rect[:height]
        }
      end

      # Total height of the todo list in points
      #
      # @return [Float] Height in points
      def height
        @rows * @row_height
      end

      # Create a TodoList using grid coordinates
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param grid [GridSystem] The grid system instance
      # @param col [Integer] Starting column in grid coordinates
      # @param row [Integer] Starting row in grid coordinates
      # @param width_boxes [Integer] Width in grid boxes
      # @param rows [Integer] Number of to-do items
      # @param opts [Hash] Additional options to pass to TodoList constructor
      # @return [TodoList] New TodoList instance
      def self.from_grid(pdf:, grid:, col:, row:, width_boxes:, rows:, **opts)
        new(
          pdf: pdf,
          x: grid.x(col),
          y: grid.y(row),
          width: grid.width(width_boxes),
          rows: rows,
          **opts
        )
      end

      private

      # Validate constructor parameters
      #
      # @raise [ArgumentError] if any parameters are invalid
      # @return [void]
      def validate_parameters
        raise ArgumentError, 'pdf is required' if @pdf.nil?
        raise ArgumentError, 'width must be positive' if @width <= 0
        raise ArgumentError, 'rows must be positive' if @rows <= 0
        raise ArgumentError, 'bullet_style must be :bullet, :checkbox, or :circle' unless %i[bullet checkbox circle].include?(@bullet_style)
        raise ArgumentError, 'divider must be :none, :solid, or :dashed' unless %i[none solid dashed].include?(@divider)
      end

      # Draw a marker (bullet, checkbox, or circle) for a row
      #
      # @param row_index [Integer] Row index
      # @param row_y [Float] Top Y coordinate of the row
      # @return [void]
      def draw_marker(row_index, row_y)
        marker_center_x = @x + (@row_height / 2)
        marker_center_y = row_y - (@row_height / 2)

        @pdf.save_graphics_state do
          @pdf.fill_color(bullet_color)
          @pdf.stroke_color(bullet_color)

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
        @pdf.fill_circle([cx, cy], BULLET_RADIUS)
      end

      # Draw an empty checkbox square
      #
      # @param cx [Float] Center x
      # @param cy [Float] Center y
      # @return [void]
      def draw_checkbox(cx, cy)
        half = CHECKBOX_SIZE / 2
        @pdf.line_width = 0.5
        @pdf.stroke_rectangle([cx - half, cy + half], CHECKBOX_SIZE, CHECKBOX_SIZE)
      end

      # Draw an empty circle
      #
      # @param cx [Float] Center x
      # @param cy [Float] Center y
      # @return [void]
      def draw_circle(cx, cy)
        @pdf.line_width = 0.5
        @pdf.stroke_circle([cx, cy], CIRCLE_RADIUS)
      end

      # Draw a divider line at the bottom of a row
      #
      # @param row_index [Integer] Row index
      # @param row_y [Float] Top Y coordinate of the row
      # @return [void]
      def draw_divider(row_index, row_y)
        # Don't draw divider after last row
        return if row_index >= @rows - 1

        line_y = row_y - @row_height
        marker_width = MARKER_COLUMN_BOXES * @row_height
        line_start_x = @x + marker_width

        @pdf.save_graphics_state do
          @pdf.stroke_color(divider_color)
          @pdf.line_width = 0.5

          case @divider
          when :solid
            @pdf.stroke_line([line_start_x, line_y], [@x + @width, line_y])
          when :dashed
            @pdf.dash(3, space: 2)
            @pdf.stroke_line([line_start_x, line_y], [@x + @width, line_y])
            @pdf.undash
          end
        end
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
