# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/styling'

module SubComponent
  # Fieldset draws HTML-like fieldset borders with legend labels
  #
  # This component creates a bordered box with a legend label that "breaks" the border.
  # The legend can be positioned on any of the four edges (top, right, bottom, left)
  # and can be rotated for vertical orientations.
  #
  # @example Basic top-left fieldset
  #   fieldset = SubComponent::Fieldset.new(pdf, grid_system,
  #     legend: "Winter",
  #     position: :top_left
  #   )
  #   fieldset.render_at(5, 10, 20, 30)
  #
  # @example Vertical label on right edge
  #   fieldset = SubComponent::Fieldset.new(pdf, grid_system,
  #     legend: "Summer",
  #     position: :top_right  # Rotated clockwise (-90°)
  #   )
  #   fieldset.render_at(25, 10, 20, 30)
  class Fieldset < Base
    # Default configuration values
    DEFAULTS = {
      position: :top_left,          # :top_left, :top_center, :top_right, :bottom_left, :bottom_right
      legend_padding: 5,            # Padding inside legend box
      font_size: 12,                # Legend font size
      border_color: nil,            # Will use Styling::Colors.BORDERS if nil
      text_color: nil,              # Will use Styling::Colors.TEXT_BLACK if nil
      inset_boxes: 0.5,             # Border inset from outer edge (in grid boxes)
      legend_offset_x: 0,           # Fine-tuning offset
      legend_offset_y: 0            # Fine-tuning offset
    }.freeze

    # Render the fieldset at the specified grid position
    #
    # @param col [Float] Starting column in grid coordinates
    # @param row [Float] Starting row in grid coordinates
    # @param width_boxes [Float] Width in grid boxes
    # @param height_boxes [Float] Height in grid boxes
    def render_at(col, row, width_boxes, height_boxes)
      legend = option(:legend)
      raise ArgumentError, "legend required" unless legend

      box = @grid.rect(col, row, width_boxes, height_boxes)

      # Calculate inset border
      inset = @grid.width(option(:inset_boxes, DEFAULTS[:inset_boxes]))
      border = {
        x: box[:x] + inset,
        y: box[:y] - inset,
        width: box[:width] - (inset * 2),
        height: box[:height] - (inset * 2)
      }

      # Set up font and measure legend
      @pdf.font "Helvetica-Bold", size: option(:font_size, DEFAULTS[:font_size])
      legend_width = @pdf.width_of(legend)
      legend_padding = option(:legend_padding, DEFAULTS[:legend_padding])
      legend_total_width = legend_width + (legend_padding * 2)

      # Draw based on position
      position = option(:position, DEFAULTS[:position])
      case position
      when :top_left
        draw_top_left(box, border, legend, legend_width, legend_total_width, legend_padding)
      when :top_center
        draw_top_center(box, border, legend, legend_width, legend_total_width, legend_padding)
      when :top_right
        draw_top_right(box, border, legend, legend_width, legend_total_width, legend_padding)
      when :bottom_left
        draw_bottom_left(box, border, legend, legend_width, legend_total_width, legend_padding)
      when :bottom_right
        draw_bottom_right(box, border, legend, legend_width, legend_total_width, legend_padding)
      else
        raise ArgumentError, "Invalid position: #{position}"
      end

      # Reset colors
      @pdf.stroke_color Styling::Colors.TEXT_BLACK
      @pdf.fill_color Styling::Colors.TEXT_BLACK
    end

    private

    # Draw fieldset with legend on top edge, left side
    def draw_top_left(box, border, legend, legend_width, legend_total_width, legend_padding)
      border_color = option(:border_color, DEFAULTS[:border_color])
      text_color = option(:text_color, DEFAULTS[:text_color])
      font_size = option(:font_size, DEFAULTS[:font_size])

      # Legend position: inset 1 box from left
      legend_x_start = box[:x] + @grid.width(1)
      legend_y = box[:y]

      # Draw border with gap for legend on top edge
      @pdf.stroke_color border_color
      @pdf.stroke_line [border[:x], border[:y]], [legend_x_start, border[:y]]
      @pdf.stroke_line [legend_x_start + legend_total_width, border[:y]], [border[:x] + border[:width], border[:y]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y]], [border[:x] + border[:width], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y] - border[:height]], [border[:x], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x], border[:y] - border[:height]], [border[:x], border[:y]]

      # Draw legend text
      @pdf.fill_color text_color
      @pdf.text_box legend,
                    at: [legend_x_start + legend_padding, legend_y],
                    width: legend_width,
                    height: font_size + 4,
                    valign: :center
    end

    # Draw fieldset with legend centered on top edge
    def draw_top_center(box, border, legend, legend_width, legend_total_width, legend_padding)
      border_color = option(:border_color, DEFAULTS[:border_color])
      text_color = option(:text_color, DEFAULTS[:text_color])
      font_size = option(:font_size, DEFAULTS[:font_size])
      legend_offset_x = option(:legend_offset_x, DEFAULTS[:legend_offset_x])

      # Legend position: centered on top edge with optional offset
      legend_x_start = box[:x] + (box[:width] / 2) - (legend_total_width / 2) + legend_offset_x
      legend_y = box[:y] + (font_size / 2)

      # Draw border with gap for legend on top edge
      @pdf.stroke_color border_color
      @pdf.stroke_line [border[:x], border[:y]], [legend_x_start, border[:y]]
      @pdf.stroke_line [legend_x_start + legend_total_width, border[:y]], [border[:x] + border[:width], border[:y]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y]], [border[:x] + border[:width], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y] - border[:height]], [border[:x], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x], border[:y] - border[:height]], [border[:x], border[:y]]

      # Draw legend text
      @pdf.fill_color text_color
      @pdf.text_box legend,
                    at: [legend_x_start + legend_padding, legend_y],
                    width: legend_width,
                    height: font_size + 4,
                    valign: :center
    end

    # Draw fieldset with legend on right edge, top (rotated clockwise -90°)
    def draw_top_right(box, border, legend, legend_width, legend_total_width, legend_padding)
      border_color = option(:border_color, DEFAULTS[:border_color])
      text_color = option(:text_color, DEFAULTS[:text_color])
      font_size = option(:font_size, DEFAULTS[:font_size])

      # Legend position: inset 1 box from top, on right edge
      legend_y_start = box[:y] - @grid.height(1)
      legend_x = box[:x] + box[:width]

      # Draw border with gap for legend on right edge
      @pdf.stroke_color border_color
      @pdf.stroke_line [border[:x], border[:y]], [border[:x] + border[:width], border[:y]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y]], [border[:x] + border[:width], legend_y_start]
      @pdf.stroke_line [border[:x] + border[:width], legend_y_start - legend_total_width], [border[:x] + border[:width], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y] - border[:height]], [border[:x], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x], border[:y] - border[:height]], [border[:x], border[:y]]

      # Draw legend text (rotated clockwise -90°, reads top-to-bottom)
      center_x = legend_x
      center_y = legend_y_start - legend_padding - (legend_width / 2)
      @pdf.rotate(-90, origin: [center_x, center_y]) do
        @pdf.fill_color text_color
        @pdf.text_box legend,
                      at: [center_x - (legend_width / 2), center_y + (font_size / 2)],
                      width: legend_width,
                      height: font_size + 4,
                      valign: :center
      end
    end

    # Draw fieldset with legend on bottom edge, left side
    def draw_bottom_left(box, border, legend, legend_width, legend_total_width, legend_padding)
      border_color = option(:border_color, DEFAULTS[:border_color])
      text_color = option(:text_color, DEFAULTS[:text_color])
      font_size = option(:font_size, DEFAULTS[:font_size])

      # Legend position: inset 1 box from left, on bottom edge
      legend_x_start = box[:x] + @grid.width(1)
      legend_y = box[:y] - box[:height]

      # Draw border with gap for legend on bottom edge
      @pdf.stroke_color border_color
      @pdf.stroke_line [border[:x], border[:y]], [border[:x] + border[:width], border[:y]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y]], [border[:x] + border[:width], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y] - border[:height]], [legend_x_start + legend_total_width, border[:y] - border[:height]]
      @pdf.stroke_line [legend_x_start, border[:y] - border[:height]], [border[:x], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x], border[:y] - border[:height]], [border[:x], border[:y]]

      # Draw legend text
      @pdf.fill_color text_color
      @pdf.text_box legend,
                    at: [legend_x_start + legend_padding, legend_y],
                    width: legend_width,
                    height: font_size + 4,
                    valign: :center
    end

    # Draw fieldset with legend on left edge, bottom (rotated counter-clockwise +90°)
    def draw_bottom_right(box, border, legend, legend_width, legend_total_width, legend_padding)
      border_color = option(:border_color, DEFAULTS[:border_color])
      text_color = option(:text_color, DEFAULTS[:text_color])
      font_size = option(:font_size, DEFAULTS[:font_size])
      legend_offset_x = option(:legend_offset_x, DEFAULTS[:legend_offset_x])
      legend_offset_y = option(:legend_offset_y, DEFAULTS[:legend_offset_y])

      # Legend position: inset 1 box from bottom, on left edge
      legend_y_start = box[:y] - box[:height] + @grid.height(1)
      legend_x = box[:x] + legend_offset_x

      # Draw border with gap for legend on left edge
      @pdf.stroke_color border_color
      @pdf.stroke_line [border[:x], border[:y]], [border[:x] + border[:width], border[:y]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y]], [border[:x] + border[:width], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x] + border[:width], border[:y] - border[:height]], [border[:x], border[:y] - border[:height]]
      @pdf.stroke_line [border[:x], border[:y] - border[:height]], [border[:x], legend_y_start + legend_offset_y]
      @pdf.stroke_line [border[:x], legend_y_start + legend_total_width + legend_offset_y], [border[:x], border[:y]]

      # Draw legend text (rotated counter-clockwise +90°, reads bottom-to-top)
      center_x = legend_x
      center_y = legend_y_start + legend_padding + (legend_width / 2) + legend_offset_y
      @pdf.rotate(90, origin: [center_x, center_y]) do
        @pdf.fill_color text_color
        @pdf.text_box legend,
                      at: [center_x - (legend_width / 2), center_y + (font_size / 2)],
                      width: legend_width,
                      height: font_size + 4,
                      valign: :center
      end
    end
  end
end
