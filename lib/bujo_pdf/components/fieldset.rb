# frozen_string_literal: true

require_relative '../base/component'
require_relative 'text'
require_relative '../utilities/styling'

module BujoPdf
  module Components
    # Fieldset draws HTML-like fieldset borders with legend labels
    #
    # This component creates a bordered box with a legend label that "breaks" the border.
    # The legend can be positioned on any of the four edges (top, right, bottom, left)
    # and can be rotated for vertical orientations.
    #
    # @example Basic top-left fieldset
    #   canvas = Canvas.new(pdf, grid)
    #   fieldset = BujoPdf::Components::Fieldset.new(
    #     canvas: canvas,
    #     col: 5, row: 10, width: 20, height: 30,
    #     legend: "Winter",
    #     position: :top_left
    #   )
    #   fieldset.render
    #
    # @example Vertical label on right edge
    #   fieldset = BujoPdf::Components::Fieldset.new(
    #     canvas: canvas,
    #     col: 25, row: 10, width: 20, height: 30,
    #     legend: "Summer",
    #     position: :top_right  # Rotated clockwise (-90deg)
    #   )
    #   fieldset.render
    class Fieldset < Component
      include Text::Mixin

      # Mixin providing the fieldset verb for pages and components
      module Mixin
        # Render a fieldset (bordered box with legend) at grid coordinates
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Starting row (top edge)
        # @param width [Integer] Width in grid boxes
        # @param height [Integer] Height in grid boxes
        # @param legend [String] Legend text (required)
        # @param position [Symbol] Legend position (default: :top_left)
        # @param legend_padding [Integer] Padding inside legend box (default: 5)
        # @param font_size [Integer] Legend font size (default: 12)
        # @param border_color [String, nil] Border color (default: theme border)
        # @param text_color [String, nil] Text color (default: theme text)
        # @param inset_boxes [Float] Border inset from edge in grid boxes (default: 0.5)
        # @param legend_offset_x [Integer] Fine-tuning X offset (default: 0)
        # @param legend_offset_y [Integer] Fine-tuning Y offset (default: 0)
        # @return [void]
        def fieldset(col, row, width, height, legend:, position: :top_left, **options)
          canvas = @canvas || Canvas.new(@pdf, @grid)
          Fieldset.new(
            canvas: canvas,
            col: col, row: row, width: width, height: height,
            legend: legend,
            position: position,
            **options
          ).render
        end
      end

      # Default configuration values
      DEFAULTS = {
        position: :top_left,          # :top_left, :top_center, :top_right, :bottom_left, :bottom_right
        legend_padding: 5,            # Padding inside legend box
        font_size: 12,                # Legend font size
        border_color: nil,            # Will use theme border color if nil
        text_color: nil,              # Will use theme text color if nil
        inset_boxes: 0.5,             # Border inset from outer edge (in grid boxes)
        legend_offset_x: 0,           # Fine-tuning offset
        legend_offset_y: 0            # Fine-tuning offset
      }.freeze

      # Position configuration: maps position to edge and rotation
      POSITION_CONFIG = {
        top_left:     { edge: :top,    align: :left,   rotation: 0 },
        top_center:   { edge: :top,    align: :center, rotation: 0 },
        top_right:    { edge: :right,  align: :top,    rotation: -90 },
        bottom_left:  { edge: :bottom, align: :left,   rotation: 0 },
        bottom_right: { edge: :left,   align: :bottom, rotation: 90 }
      }.freeze

      def initialize(canvas:, col:, row:, width:, height:, legend:,
                     position: DEFAULTS[:position],
                     legend_padding: DEFAULTS[:legend_padding],
                     font_size: DEFAULTS[:font_size],
                     border_color: DEFAULTS[:border_color],
                     text_color: DEFAULTS[:text_color],
                     inset_boxes: DEFAULTS[:inset_boxes],
                     legend_offset_x: DEFAULTS[:legend_offset_x],
                     legend_offset_y: DEFAULTS[:legend_offset_y])
        super(canvas: canvas)
        @col = col
        @row = row
        @width_boxes = width
        @height_boxes = height
        @legend = legend
        @position_name = position
        @legend_padding = legend_padding
        @font_size = font_size
        @border_color_option = border_color
        @text_color_option = text_color
        @inset_boxes = inset_boxes
        @legend_offset_x = legend_offset_x
        @legend_offset_y = legend_offset_y

        @config = POSITION_CONFIG[@position_name]
        raise ArgumentError, "Invalid position: #{@position_name}" unless @config
      end

      def render
        @box = grid.rect(@col, @row, @width_boxes, @height_boxes)

        # Calculate inset border
        inset = grid.width(@inset_boxes)
        @border = {
          x: @box[:x] + inset,
          y: @box[:y] - inset,
          width: @box[:width] - (inset * 2),
          height: @box[:height] - (inset * 2)
        }

        # Measure legend
        pdf.font "Helvetica-Bold", size: @font_size
        @legend_width = pdf.width_of(@legend)
        @legend_total_width = @legend_width + (@legend_padding * 2)

        draw_border
        draw_legend

        reset_colors
      end

      private

      def border_color
        @border_color ||= @border_color_option || Themes.current[:colors][:border]
      end

      def text_color
        @text_color ||= @text_color_option || Themes.current[:colors][:text_black]
      end

      def draw_border
        pdf.stroke_color border_color

        case @config[:edge]
        when :top
          draw_top_edge_border
        when :right
          draw_right_edge_border
        when :bottom
          draw_bottom_edge_border
        when :left
          draw_left_edge_border
        end
      end

      def draw_top_edge_border
        gap_start, gap_end = calculate_horizontal_gap(@config[:align])

        # Top edge with gap
        pdf.stroke_line [@border[:x], @border[:y]], [gap_start, @border[:y]]
        pdf.stroke_line [gap_end, @border[:y]], [@border[:x] + @border[:width], @border[:y]]
        # Remaining edges
        draw_right_edge
        draw_bottom_edge_full
        draw_left_edge
      end

      def draw_bottom_edge_border
        gap_start, gap_end = calculate_horizontal_gap(@config[:align])

        draw_top_edge_full
        draw_right_edge
        # Bottom edge with gap
        pdf.stroke_line [@border[:x] + @border[:width], @border[:y] - @border[:height]],
                         [gap_end, @border[:y] - @border[:height]]
        pdf.stroke_line [gap_start, @border[:y] - @border[:height]],
                         [@border[:x], @border[:y] - @border[:height]]
        draw_left_edge
      end

      def draw_right_edge_border
        gap_start, gap_end = calculate_vertical_gap(:top)

        draw_top_edge_full
        # Right edge with gap
        pdf.stroke_line [@border[:x] + @border[:width], @border[:y]],
                         [@border[:x] + @border[:width], gap_start]
        pdf.stroke_line [@border[:x] + @border[:width], gap_end],
                         [@border[:x] + @border[:width], @border[:y] - @border[:height]]
        draw_bottom_edge_full
        draw_left_edge
      end

      def draw_left_edge_border
        gap_start, gap_end = calculate_vertical_gap(:bottom)

        draw_top_edge_full
        draw_right_edge
        draw_bottom_edge_full
        # Left edge with gap
        pdf.stroke_line [@border[:x], @border[:y] - @border[:height]],
                         [@border[:x], gap_end]
        pdf.stroke_line [@border[:x], gap_start],
                         [@border[:x], @border[:y]]
      end

      # Full edge drawing helpers
      def draw_top_edge_full
        pdf.stroke_line [@border[:x], @border[:y]], [@border[:x] + @border[:width], @border[:y]]
      end

      def draw_right_edge
        pdf.stroke_line [@border[:x] + @border[:width], @border[:y]],
                         [@border[:x] + @border[:width], @border[:y] - @border[:height]]
      end

      def draw_bottom_edge_full
        pdf.stroke_line [@border[:x] + @border[:width], @border[:y] - @border[:height]],
                         [@border[:x], @border[:y] - @border[:height]]
      end

      def draw_left_edge
        pdf.stroke_line [@border[:x], @border[:y] - @border[:height]], [@border[:x], @border[:y]]
      end

      def calculate_horizontal_gap(align)
        case align
        when :left
          start = @box[:x] + grid.width(1) + @legend_offset_x
        when :center
          start = @box[:x] + (@box[:width] / 2) - (@legend_total_width / 2) + @legend_offset_x
        when :right
          start = @box[:x] + @box[:width] - grid.width(1) - @legend_total_width + @legend_offset_x
        end

        [start, start + @legend_total_width]
      end

      def calculate_vertical_gap(align)
        case align
        when :top
          start = @box[:y] - grid.height(1) + @legend_offset_y
          [start, start - @legend_total_width]
        when :bottom
          start = @box[:y] - @box[:height] + grid.height(1) + @legend_offset_y
          [start, start + @legend_total_width]
        end
      end

      def draw_legend
        case @config[:edge]
        when :top
          draw_horizontal_legend(@box[:y], @config[:align])
        when :bottom
          draw_horizontal_legend(@box[:y] - @box[:height], @config[:align])
        when :right
          draw_vertical_legend(:right)
        when :left
          draw_vertical_legend(:left)
        end
      end

      def draw_horizontal_legend(y_base, align)
        case align
        when :left
          x = @box[:x] + grid.width(1) + @legend_padding + @legend_offset_x
        when :center
          x = @box[:x] + (@box[:width] / 2) - (@legend_width / 2) + @legend_offset_x
        when :right
          x = @box[:x] + @box[:width] - grid.width(1) - @legend_total_width + @legend_padding + @legend_offset_x
        end

        pdf.fill_color text_color
        pdf.font "Helvetica-Bold", size: @font_size
        pdf.text_box @legend,
                      at: [x, y_base + (@font_size / 2)],
                      width: @legend_width,
                      height: @font_size + 4,
                      valign: :center
      end

      def draw_vertical_legend(edge)
        if edge == :right
          center_x = @box[:x] + @box[:width]
          center_y = @box[:y] - grid.height(1) - @legend_padding - (@legend_width / 2)
          rotation = -90
        else # :left
          center_x = @box[:x] + @legend_offset_x
          center_y = @box[:y] - @box[:height] + grid.height(1) + @legend_padding + (@legend_width / 2) + @legend_offset_y
          rotation = 90
        end

        pdf.fill_color text_color
        pdf.font "Helvetica-Bold", size: @font_size
        pdf.rotate(rotation, origin: [center_x, center_y]) do
          pdf.text_box @legend,
                        at: [center_x - (@legend_width / 2), center_y + (@font_size / 2)],
                        width: @legend_width,
                        height: @font_size + 4,
                        valign: :center
        end
      end

      def reset_colors
        pdf.stroke_color Styling::Colors.TEXT_BLACK
        pdf.fill_color Styling::Colors.TEXT_BLACK
      end
    end
  end
end
