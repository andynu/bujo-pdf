# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative 'erase_dots'

module BujoPdf
  module Components
    # HLine renders a horizontal line at a grid row, erasing dots behind it.
    #
    # Draws a horizontal rule and covers the dots underneath so the line
    # appears cleanly without dots showing through. Useful for section
    # dividers and as a building block for fieldset-style components.
    #
    # Example usage in a page:
    #   hline(2, 5, 20)                              # Default gray line
    #   hline(2, 5, 20, color: '333333', stroke: 1)  # Thick dark line
    #
    class HLine < Component
      include EraseDots::Mixin

      # Mixin providing the hline verb for pages and components
      module Mixin
        # Render a horizontal line at a grid row
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Row position (line sits on this grid row)
        # @param width [Integer] Width in grid boxes
        # @param color [String] Line color as hex string (default: 'CCCCCC')
        # @param stroke [Float] Line width in points (default: 0.5)
        # @return [void]
        def hline(col, row, width, color: 'CCCCCC', stroke: 0.5)
          c = @canvas || Canvas.new(@pdf, @grid)
          HLine.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            color: color,
            stroke: stroke
          ).render
        end
      end

      # Initialize a new HLine component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Row position
      # @param width [Integer] Width in grid boxes
      # @param color [String] Line color as hex string
      # @param stroke [Float] Line width in points
      def initialize(canvas:, col:, row:, width:, color: 'CCCCCC', stroke: 0.5)
        super(canvas: canvas)
        @col = col
        @row = row
        @width = width
        @color = color
        @stroke = stroke
      end

      # Render the horizontal line with dots erased behind it
      #
      # @return [void]
      def render
        # Erase dots along the line first
        erase_dots(@col, @row, @width)

        # Draw the line
        y = grid.y(@row)
        x_start = grid.x(@col)
        x_end = grid.x(@col + @width)

        pdf.stroke_color @color
        pdf.line_width @stroke
        pdf.stroke_line [x_start, y], [x_end, y]

        # Restore defaults
        pdf.stroke_color '000000'
        pdf.line_width 0.5
      end
    end
  end
end
