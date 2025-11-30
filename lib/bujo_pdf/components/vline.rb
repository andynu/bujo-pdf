# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative 'erase_dots'

module BujoPdf
  module Components
    # VLine renders a vertical line at a grid column, erasing dots behind it.
    #
    # Draws a vertical rule and covers the dots underneath so the line
    # appears cleanly without dots showing through. Useful for column
    # dividers and as a building block for table-style components.
    #
    # Example usage in a page:
    #   vline(10, 2, 20)                              # Default gray line
    #   vline(10, 2, 20, color: '333333', stroke: 1)  # Thick dark line
    #
    class VLine < Component
      include EraseDots::Mixin

      # Mixin providing the vline verb for pages and components
      module Mixin
        # Render a vertical line at a grid column
        #
        # @param col [Integer] Column position (line sits on this grid column)
        # @param row [Integer] Starting row (top edge)
        # @param height [Integer] Height in grid boxes
        # @param color [String] Line color as hex string (default: 'CCCCCC')
        # @param stroke [Float] Line width in points (default: 0.5)
        # @return [void]
        def vline(col, row, height, color: 'CCCCCC', stroke: 0.5)
          c = @canvas || Canvas.new(@pdf, @grid)
          VLine.new(
            canvas: c,
            col: col,
            row: row,
            height: height,
            color: color,
            stroke: stroke
          ).render
        end
      end

      # Initialize a new VLine component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Column position
      # @param row [Integer] Starting row (top edge)
      # @param height [Integer] Height in grid boxes
      # @param color [String] Line color as hex string
      # @param stroke [Float] Line width in points
      def initialize(canvas:, col:, row:, height:, color: 'CCCCCC', stroke: 0.5)
        super(canvas: canvas)
        @col = col
        @row = row
        @height = height
        @color = color
        @stroke = stroke
      end

      # Render the vertical line with dots erased behind it
      #
      # @return [void]
      def render
        # Erase dots along the line first (single column, multiple rows)
        erase_dots(@col, @row, 0, @height)

        # Draw the line
        x = grid.x(@col)
        y_start = grid.y(@row)
        y_end = grid.y(@row + @height)

        pdf.stroke_color @color
        pdf.line_width @stroke
        pdf.stroke_line [x, y_start], [x, y_end]

        # Restore defaults
        pdf.stroke_color '000000'
        pdf.line_width 0.5
      end
    end
  end
end
