# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/grid_rect'
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
        # @param align [Symbol] Alignment within the grid box: :top, :center, :bottom (default: :top)
        # @return [void]
        def hline(col, row, width, color: 'CCCCCC', stroke: 0.5, align: :top)
          c = @canvas || Canvas.new(@pdf, @grid)
          HLine.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            color: color,
            stroke: stroke,
            align: align
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
      # @param align [Symbol] Alignment within the grid box: :top, :center, :bottom
      def initialize(canvas:, col:, row:, width:, color: 'CCCCCC', stroke: 0.5, align: :top)
        super(canvas: canvas)
        @rect = GridRect.new(col, row, width, 1)
        @color = color
        @stroke = stroke
        @align = align
      end

      # Render the horizontal line, erasing dots if on-grid
      #
      # @return [void]
      def render
        # Only erase dots if positioned exactly on grid intersections
        if on_grid?
          erase_dots(@rect.col.to_i, @rect.row.to_i, @rect.width.to_i)
        end

        # Draw the line at the aligned y position
        y = aligned_y
        pdf.stroke_color @color
        pdf.line_width @stroke
        pdf.stroke_line [@rect.x, y], [@rect.x + @rect.width_pt, y]

        # Restore defaults
        pdf.stroke_color '000000'
        pdf.line_width 0.5
      end

      private

      # Calculate y position based on alignment within the grid box
      #
      # @return [Float]
      def aligned_y
        case @align
        when :top then @rect.y
        when :center then @rect.y - (@rect.height_pt / 2)
        when :bottom then @rect.y - @rect.height_pt
        else raise ArgumentError, "Unknown align: #{@align.inspect}"
        end
      end

      # Check if all positions are on grid (integer values)
      #
      # @return [Boolean]
      def on_grid?
        [@rect.col, @rect.row, @rect.width].all? { |n| n == n.to_i }
      end
    end
  end
end
