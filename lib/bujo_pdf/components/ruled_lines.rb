# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative 'grid_dots'

module BujoPdf
  module Components
    # RuledLines renders horizontal ruled lines over a grid region.
    #
    # Lines are quantized to the dot grid - each line sits exactly on a grid row.
    # Dots are automatically redrawn over the lines so they appear on top,
    # creating a layered effect where lines are behind the dot pattern.
    #
    # Example usage in a page:
    #   ruled_lines(2, 5, 20, 10)
    #   ruled_lines(2, 5, 20, 10, color: 'CCCCCC', stroke: 1.0)
    #
    class RuledLines < Component
      include GridDots::Mixin

      # Mixin providing the ruled_lines verb for pages
      #
      # Include via Components::All in Pages::Base
      module Mixin
        # Render ruled lines over a grid region with dots on top
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Starting row (top edge)
        # @param width [Integer] Width in grid boxes
        # @param height [Integer] Number of lines/rows
        # @param color [String] Line color as hex string (default: 'E5E5E5')
        # @param stroke [Float] Line width in points (default: 0.5)
        # @param dash [Array, nil] Dash pattern [length, space] or nil for solid (default: nil)
        # @param redraw_dots [Boolean] Whether to redraw dots on top of lines (default: true)
        # @return [void]
        def ruled_lines(col, row, width, height, color: 'E5E5E5', stroke: 0.5, dash: nil, redraw_dots: true)
          c = @canvas || Canvas.new(@pdf, @grid)
          RuledLines.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            height: height,
            color: color,
            stroke: stroke,
            dash: dash,
            redraw_dots: redraw_dots
          ).render
        end
      end

      # Initialize a new RuledLines component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top edge)
      # @param width [Integer] Width in grid boxes
      # @param height [Integer] Number of lines/rows
      # @param color [String] Line color as hex string
      # @param stroke [Float] Line width in points
      # @param dash [Array, nil] Dash pattern [length, space] or nil for solid
      # @param redraw_dots [Boolean] Whether to redraw dots on top of lines
      def initialize(canvas:, col:, row:, width:, height:, color: 'E5E5E5', stroke: 0.5, dash: nil, redraw_dots: true)
        super(canvas: canvas)
        @col = col
        @row = row
        @width = width
        @height = height
        @color = color
        @stroke = stroke
        @dash = dash
        @redraw_dots = redraw_dots
      end

      # Render ruled lines with optional dots on top
      #
      # @return [void]
      def render
        draw_lines
        redraw_dots_if_enabled
      end

      private

      def draw_lines
        pdf.stroke_color @color
        pdf.line_width @stroke

        # Apply dash pattern if specified
        if @dash
          pdf.dash(@dash[0], space: @dash[1])
        end

        # Draw one line per grid row, aligned exactly with grid positions
        @height.times do |i|
          row = @row + i
          line_y = grid.y(row + 1)  # Bottom of the row, aligned to grid

          pdf.stroke_line [grid.x(@col), line_y], [grid.x(@col + @width), line_y]
        end

        # Restore defaults
        pdf.undash if @dash
        pdf.stroke_color '000000'
        pdf.line_width 0.5
      end

      def redraw_dots_if_enabled
        grid_dots(@col, @row, @width, @height) if @redraw_dots
      end
    end
  end
end
