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
    # Supports both integer and float grid coordinates:
    # - Integer positions: Line on grid, dots erased behind it
    # - Float positions: Line between grid points, no dot erasure
    #
    # Example usage in a page:
    #   hline(2, 5, 20)                              # On-grid, dots erased
    #   hline(2, 5, 20, color: '333333', stroke: 1)  # Thick dark line
    #   hline(2.5, 5.5, 20)                          # Sub-grid, no dot erasure
    #
    class HLine < Component
      include EraseDots::Mixin

      # Mixin providing the hline verb for pages and components
      module Mixin
        # Render a horizontal line at a grid position
        #
        # @param col [Numeric] Starting column (left edge), supports floats
        # @param row [Numeric] Row position, supports floats
        # @param width [Numeric] Width in grid boxes, supports floats
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
      # @param col [Numeric] Starting column (left edge)
      # @param row [Numeric] Row position
      # @param width [Numeric] Width in grid boxes
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

      # Render the horizontal line, erasing dots if on-grid
      #
      # @return [void]
      def render
        # Only erase dots if positioned exactly on grid intersections
        if on_grid?
          erase_dots(@col.to_i, @row.to_i, @width.to_i)
        end

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

      private

      # Check if all positions are on grid (integer values)
      #
      # @return [Boolean]
      def on_grid?
        integer?(@col) && integer?(@row) && integer?(@width)
      end

      # Check if a number is effectively an integer
      #
      # @param num [Numeric] Number to check
      # @return [Boolean]
      def integer?(num)
        num == num.to_i
      end
    end
  end
end
