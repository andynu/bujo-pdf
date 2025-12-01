# frozen_string_literal: true

require_relative '../base/component'
require_relative 'text'
require_relative 'box'
require_relative '../utilities/styling'

module BujoPdf
  module Components
    # Fieldset draws HTML-like fieldset borders with legend labels
    #
    # This component creates a bordered box with a legend label that "breaks" the border.
    # The legend can be positioned on any of the four edges (top, right, bottom, left)
    # and can be rotated for vertical orientations.
    #
    # Uses box() verb for border drawing with a background-filled gap for the legend.
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
      include Box::Mixin

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
        # Calculate inset border in grid coordinates (float for sub-grid positioning)
        @border_col = @col + @inset_boxes
        @border_row = @row + @inset_boxes
        @border_width = @width_boxes - (@inset_boxes * 2)
        @border_height = @height_boxes - (@inset_boxes * 2)

        # Measure legend in grid boxes
        pdf.font "Helvetica-Bold", size: @font_size
        @legend_width_pt = pdf.width_of(@legend)
        @legend_width_boxes = @legend_width_pt / grid.dot_spacing
        @legend_padding_boxes = @legend_padding / grid.dot_spacing
        @legend_total_boxes = @legend_width_boxes + (@legend_padding_boxes * 2)

        # Get background color for gap erasing
        @background_color = BujoPdf::Themes.current[:colors][:background]

        draw_border
        draw_legend

        reset_colors
      end

      private

      def border_color
        @border_color ||= @border_color_option || Themes.current[:colors][:borders]
      end

      def text_color
        @text_color ||= @text_color_option || Themes.current[:colors][:text_black]
      end

      def draw_border
        # Draw the full border box
        box(@border_col, @border_row, @border_width, @border_height,
            stroke: border_color, fill: nil)

        # Erase the gap where the legend will go
        erase_legend_gap
      end

      # Erase the border segment where the legend will be placed
      def erase_legend_gap
        gap_col, gap_row, gap_width, gap_height = calculate_gap_rect

        # Draw a background-colored box to erase the border segment
        box(gap_col, gap_row, gap_width, gap_height,
            stroke: nil, fill: @background_color)
      end

      # Calculate the gap rectangle in grid coordinates
      # @return [Array<Float, Float, Float, Float>] [col, row, width, height]
      def calculate_gap_rect
        # Convert legend offset to grid boxes
        offset_x_boxes = @legend_offset_x / grid.dot_spacing
        offset_y_boxes = @legend_offset_y / grid.dot_spacing

        # Small height/width for the eraser box (just enough to cover the border line)
        stroke_boxes = 0.15  # ~2pt in grid boxes

        case @config[:edge]
        when :top
          gap_col = calculate_horizontal_gap_col(@config[:align], offset_x_boxes)
          gap_row = @border_row - stroke_boxes
          [gap_col, gap_row, @legend_total_boxes, stroke_boxes * 2]

        when :bottom
          gap_col = calculate_horizontal_gap_col(@config[:align], offset_x_boxes)
          gap_row = @border_row + @border_height - stroke_boxes
          [gap_col, gap_row, @legend_total_boxes, stroke_boxes * 2]

        when :right
          gap_col = @border_col + @border_width - stroke_boxes
          gap_row = @row + 1 + offset_y_boxes
          [gap_col, gap_row, stroke_boxes * 2, @legend_total_boxes]

        when :left
          gap_col = @border_col - stroke_boxes
          gap_row = @row + @height_boxes - 1 - @legend_total_boxes + offset_y_boxes
          [gap_col, gap_row, stroke_boxes * 2, @legend_total_boxes]
        end
      end

      # Calculate horizontal gap column based on alignment
      def calculate_horizontal_gap_col(align, offset_boxes)
        case align
        when :left
          @col + 1 + offset_boxes
        when :center
          @col + (@width_boxes / 2.0) - (@legend_total_boxes / 2.0) + offset_boxes
        when :right
          @col + @width_boxes - 1 - @legend_total_boxes + offset_boxes
        end
      end

      def draw_legend
        case @config[:edge]
        when :top
          draw_horizontal_legend(@border_row, @config[:align])
        when :bottom
          draw_horizontal_legend(@border_row + @border_height, @config[:align])
        when :right
          draw_vertical_legend(:right)
        when :left
          draw_vertical_legend(:left)
        end
      end

      def draw_horizontal_legend(row, align)
        # Convert legend offset to grid boxes
        offset_boxes = @legend_offset_x / grid.dot_spacing

        case align
        when :left
          col = @col + 1 + @legend_padding_boxes + offset_boxes
        when :center
          col = @col + (@width_boxes / 2.0) - (@legend_width_boxes / 2.0) + offset_boxes
        when :right
          col = @col + @width_boxes - 1 - @legend_total_boxes + @legend_padding_boxes + offset_boxes
        end

        # Position text box so its CENTER aligns with the border row
        # text() uses a 1-box height with valign: :center, so offset by 0.5 boxes
        text_row = row - 0.5

        text(col, text_row, @legend,
             size: @font_size, style: :bold, color: text_color,
             width: @legend_width_boxes.ceil, height: 1)
      end

      def draw_vertical_legend(edge)
        # Convert legend offset to grid boxes
        offset_x_boxes = @legend_offset_x / grid.dot_spacing
        offset_y_boxes = @legend_offset_y / grid.dot_spacing

        if edge == :right
          # Right edge: text rotated -90 (reads top-to-bottom)
          # Center on the right border line
          center_col = @border_col + @border_width
          center_row = @row + 1 + @legend_padding_boxes + (@legend_width_boxes / 2.0) + offset_y_boxes
          rotation = -90
        else # :left
          # Left edge: text rotated +90 (reads bottom-to-top)
          # Center on the left border line
          center_col = @border_col + offset_x_boxes
          center_row = @row + @height_boxes - 1 - @legend_padding_boxes - (@legend_width_boxes / 2.0) + offset_y_boxes
          rotation = 90
        end

        # Calculate center point in points for rotation
        center_x = grid.x(center_col)
        center_y = grid.y(center_row)

        # Height in boxes for the font size
        height_boxes = (@font_size + 4) / grid.dot_spacing

        text(0, 0, @legend,
             size: @font_size, style: :bold, color: text_color,
             width: @legend_width_boxes.ceil, height: height_boxes.ceil,
             rotation: rotation, pt_x: center_x, pt_y: center_y, centered: true)
      end

      def reset_colors
        pdf.stroke_color Styling::Colors.TEXT_BLACK
        pdf.fill_color Styling::Colors.TEXT_BLACK
      end
    end
  end
end
