# frozen_string_literal: true

require_relative '../base/component'

module BujoPdf
  module Components
    # GridRuler draws column and row numbers along the edges of the page.
    #
    # This is a diagnostic component for page design. Include it temporarily
    # to visualize the grid coordinate system, then comment out when done.
    #
    # Features:
    # - Column numbers along row 0 (top edge)
    # - Row numbers along column 0 (left edge)
    # - Division markers at 1/3, 1/2, 2/3 positions showing the denominator
    #
    # Usage:
    #   # In a page's render method:
    #   GridRuler.new(canvas: canvas).render
    #
    #   # Or render only columns or rows:
    #   GridRuler.new(canvas: canvas).render_columns
    #   GridRuler.new(canvas: canvas).render_rows
    #
    class GridRuler < Component
      # Default styling
      FONT_SIZE = 6
      COLOR = 'FF0000'  # Red for visibility
      DIVISION_COLOR = '0000FF'  # Blue for division markers

      def initialize(canvas:, font_size: FONT_SIZE, color: COLOR)
        super(canvas: canvas)
        @font_size = font_size
        @color = color
      end

      # Render both column and row numbers with division markers
      def render
        render_columns
        render_rows
        render_division_markers
      end

      # Draw column numbers along row 0 (top edge)
      def render_columns
        pdf.fill_color @color
        pdf.font_size @font_size

        grid.cols.times do |col|
          x = grid.x(col)
          y = grid.y(0)

          # Center the number in the box
          pdf.text_box col.to_s,
                        at: [x, y],
                        width: grid.dot_spacing,
                        height: grid.dot_spacing,
                        align: :center,
                        valign: :center,
                        overflow: :shrink_to_fit
        end

        reset_color
      end

      # Draw row numbers along column 0 (left edge)
      def render_rows
        pdf.fill_color @color
        pdf.font_size @font_size

        grid.rows.times do |row|
          x = grid.x(0)
          y = grid.y(row)

          # Center the number in the box
          pdf.text_box row.to_s,
                        at: [x, y],
                        width: grid.dot_spacing,
                        height: grid.dot_spacing,
                        align: :center,
                        valign: :center,
                        overflow: :shrink_to_fit
        end

        reset_color
      end

      # Draw division markers at 1/3, 1/2, 2/3 positions using dots
      # The number of dots indicates the denominator (2 dots = 1/2, 3 dots = 1/3 or 2/3)
      def render_division_markers
        pdf.fill_color DIVISION_COLOR

        dot_radius = 1.5

        # Column divisions (along row 1, below the column numbers)
        col_divisions = [
          { pos: grid.cols / 3, dots: 3 },
          { pos: grid.cols / 2, dots: 2 },
          { pos: (grid.cols * 2) / 3, dots: 3 }
        ]

        col_divisions.each do |div|
          center_x = grid.x(div[:pos]) + (grid.dot_spacing / 2)
          center_y = grid.y(1) - (grid.dot_spacing / 2)
          draw_dots_vertical(center_x, center_y, div[:dots], dot_radius)
        end

        # Row divisions (along column 1, right of the row numbers)
        row_divisions = [
          { pos: grid.rows / 3, dots: 3 },
          { pos: grid.rows / 2, dots: 2 },
          { pos: (grid.rows * 2) / 3, dots: 3 }
        ]

        row_divisions.each do |div|
          center_x = grid.x(1) + (grid.dot_spacing / 2)
          center_y = grid.y(div[:pos]) - (grid.dot_spacing / 2)
          draw_dots_horizontal(center_x, center_y, div[:dots], dot_radius)
        end

        reset_color
      end

      # Draw dots stacked vertically
      def draw_dots_vertical(center_x, center_y, count, radius)
        spacing = radius * 3
        total_height = (count - 1) * spacing
        start_y = center_y + (total_height / 2)

        count.times do |i|
          pdf.fill_circle [center_x, start_y - (i * spacing)], radius
        end
      end

      # Draw dots arranged horizontally
      def draw_dots_horizontal(center_x, center_y, count, radius)
        spacing = radius * 3
        total_width = (count - 1) * spacing
        start_x = center_x - (total_width / 2)

        count.times do |i|
          pdf.fill_circle [start_x + (i * spacing), center_y], radius
        end
      end

      private

      def reset_color
        pdf.fill_color '000000'
      end
    end
  end
end
