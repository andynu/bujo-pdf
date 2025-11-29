# frozen_string_literal: true

require_relative '../utilities/styling'

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
    class RuledLines
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
        # @return [void]
        def ruled_lines(col, row, width, height, color: 'E5E5E5', stroke: 0.5)
          RuledLines.new(
            pdf: @pdf,
            grid: @grid_system,
            col: col,
            row: row,
            width: width,
            height: height,
            color: color,
            stroke: stroke
          ).render
        end
      end

      # Initialize a new RuledLines component
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param grid [GridSystem] The grid system for coordinate conversion
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top edge)
      # @param width [Integer] Width in grid boxes
      # @param height [Integer] Number of lines/rows
      # @param color [String] Line color as hex string
      # @param stroke [Float] Line width in points
      def initialize(pdf:, grid:, col:, row:, width:, height:, color: 'E5E5E5', stroke: 0.5)
        @pdf = pdf
        @grid = grid
        @col = col
        @row = row
        @width = width
        @height = height
        @color = color
        @stroke = stroke
      end

      # Render ruled lines with dots on top
      #
      # @return [void]
      def render
        draw_lines
        redraw_dots
      end

      private

      def draw_lines
        @pdf.stroke_color @color
        @pdf.line_width @stroke

        # Draw one line per grid row, aligned exactly with grid positions
        @height.times do |i|
          row = @row + i
          line_y = @grid.y(row + 1)  # Bottom of the row, aligned to grid

          @pdf.stroke_line [@grid.x(@col), line_y], [@grid.x(@col + @width), line_y]
        end

        # Restore defaults
        @pdf.stroke_color '000000'
        @pdf.line_width 0.5
      end

      def redraw_dots
        GridDots.new(
          pdf: @pdf,
          grid: @grid,
          col: @col,
          row: @row,
          width: @width,
          height: @height
        ).render
      end
    end
  end
end
