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
    # Supports both integer and float grid coordinates:
    # - Integer positions: Line on grid, dots erased behind it
    # - Float positions: Line between grid points, no dot erasure
    #
    # Example usage in a page:
    #   vline(10, 2, 20)                              # On-grid, dots erased
    #   vline(10, 2, 20, color: '333333', stroke: 1)  # Thick dark line
    #   vline(10.5, 2.5, 20)                          # Sub-grid, no dot erasure
    #
    class VLine < Component
      include EraseDots::Mixin

      # Mixin providing the vline verb for pages and components
      module Mixin
        # Render a vertical line at a grid position
        #
        # @param col [Numeric] Column position, supports floats
        # @param row [Numeric] Starting row (top edge), supports floats
        # @param height [Numeric] Height in grid boxes, supports floats
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
      # @param col [Numeric] Column position
      # @param row [Numeric] Starting row (top edge)
      # @param height [Numeric] Height in grid boxes
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

      # Render the vertical line, erasing dots if on-grid
      #
      # @return [void]
      def render
        # Only erase dots if positioned exactly on grid intersections
        if on_grid?
          erase_dots(@col.to_i, @row.to_i, 0, @height.to_i)
        end

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

      private

      # Check if all positions are on grid (integer values)
      #
      # @return [Boolean]
      def on_grid?
        integer?(@col) && integer?(@row) && integer?(@height)
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
