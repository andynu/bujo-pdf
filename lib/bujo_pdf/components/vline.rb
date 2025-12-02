# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/grid_rect'
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
        # @param align [Symbol] Alignment within the grid box: :left, :center, :right (default: :left)
        # @return [void]
        def vline(col, row, height, color: 'CCCCCC', stroke: 0.5, align: :left)
          c = @canvas || Canvas.new(@pdf, @grid)
          VLine.new(
            canvas: c,
            col: col,
            row: row,
            height: height,
            color: color,
            stroke: stroke,
            align: align
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
      # @param align [Symbol] Alignment within the grid box: :left, :center, :right
      def initialize(canvas:, col:, row:, height:, color: 'CCCCCC', stroke: 0.5, align: :left)
        super(canvas: canvas)
        @rect = GridRect.new(col, row, 1, height)
        @color = color
        @stroke = stroke
        @align = align
      end

      # Render the vertical line, erasing dots if on-grid
      #
      # @return [void]
      def render
        # Only erase dots if positioned exactly on grid intersections
        if on_grid?
          erase_dots(@rect.col.to_i, @rect.row.to_i, 0, @rect.height.to_i)
        end

        # Draw the line at the aligned x position
        x = aligned_x
        pdf.stroke_color @color
        pdf.line_width @stroke
        pdf.stroke_line [x, @rect.y], [x, @rect.y - @rect.height_pt]

        # Restore defaults
        pdf.stroke_color '000000'
        pdf.line_width 0.5
      end

      private

      # Calculate x position based on alignment within the grid box
      #
      # @return [Float]
      def aligned_x
        case @align
        when :left then @rect.x
        when :center then @rect.x + (@rect.width_pt / 2)
        when :right then @rect.x + @rect.width_pt
        else raise ArgumentError, "Unknown align: #{@align.inspect}"
        end
      end

      # Check if all positions are on grid (integer values)
      #
      # @return [Boolean]
      def on_grid?
        [@rect.col, @rect.row, @rect.height].all? { |n| n == n.to_i }
      end
    end
  end
end
