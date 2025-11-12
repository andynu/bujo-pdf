# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/styling'

module SubComponent
  # RuledLines draws horizontal ruled lines for writing
  #
  # This component creates evenly-spaced horizontal lines suitable for note-taking.
  # Lines can be configured for spacing, color, style, and margins.
  #
  # @example Basic ruled lines
  #   lines = SubComponent::RuledLines.new(pdf, grid_system,
  #     line_spacing_boxes: 1.5,
  #     line_count: 10
  #   )
  #   lines.render_at(5, 10, 20, 15)
  #
  # @example With margins
  #   lines = SubComponent::RuledLines.new(pdf, grid_system,
  #     line_spacing_boxes: 1.5,
  #     margin_left_boxes: 0.5,
  #     margin_right_boxes: 0.5
  #   )
  #   lines.render_at(5, 10, 20, 15)
  class RuledLines < Base
    # Default configuration values
    DEFAULTS = {
      line_spacing_boxes: 1.5,      # Spacing between lines in grid boxes
      line_count: nil,               # Number of lines (auto-calculated if nil)
      line_color: Styling::Colors::BORDERS,
      line_width: 0.5,               # Line stroke width in points
      margin_left_boxes: 0,          # Left margin in grid boxes
      margin_right_boxes: 0,         # Right margin in grid boxes
      skip_first: false,             # Skip first line
      line_style: :solid,            # :solid, :dashed, :dotted
      start_offset_boxes: 0          # Offset from top in grid boxes
    }.freeze

    # Render ruled lines at the specified grid position
    #
    # @param col [Float] Starting column in grid coordinates
    # @param row [Float] Starting row in grid coordinates
    # @param width_boxes [Float] Width in grid boxes
    # @param height_boxes [Float] Height in grid boxes
    def render_at(col, row, width_boxes, height_boxes)
      in_grid_box(col, row, width_boxes, height_boxes) do
        box = @grid.rect(col, row, width_boxes, height_boxes)
        draw_lines(box[:width], box[:height])
      end
    end

    private

    # Draw the ruled lines
    def draw_lines(width, height)
      line_spacing_boxes = option(:line_spacing_boxes, DEFAULTS[:line_spacing_boxes])
      line_count = option(:line_count, DEFAULTS[:line_count])
      line_color = option(:line_color, DEFAULTS[:line_color])
      line_width = option(:line_width, DEFAULTS[:line_width])
      margin_left = @grid.width(option(:margin_left_boxes, DEFAULTS[:margin_left_boxes]))
      margin_right = @grid.width(option(:margin_right_boxes, DEFAULTS[:margin_right_boxes]))
      skip_first = option(:skip_first, DEFAULTS[:skip_first])
      line_style = option(:line_style, DEFAULTS[:line_style])
      start_offset = @grid.height(option(:start_offset_boxes, DEFAULTS[:start_offset_boxes]))

      # Calculate line spacing and count
      line_spacing = @grid.height(line_spacing_boxes)
      available_height = height - start_offset

      # Auto-calculate line count if not specified
      count = line_count || (available_height / line_spacing).floor

      # Set line style
      @pdf.stroke_color line_color
      @pdf.line_width line_width

      case line_style
      when :dashed
        @pdf.dash(3, space: 2)
      when :dotted
        @pdf.dash(1, space: 2)
      end

      # Draw lines
      start_index = skip_first ? 1 : 0
      count.times do |i|
        next if i < start_index

        y_pos = height - start_offset - (i * line_spacing)
        break if y_pos < 0  # Don't draw lines below the box

        x_start = margin_left
        x_end = width - margin_right

        @pdf.stroke_horizontal_line x_start, x_end, at: y_pos
      end

      # Reset line style
      @pdf.undash if line_style != :solid
      @pdf.line_width 1
      @pdf.stroke_color '000000'
    end
  end
end
