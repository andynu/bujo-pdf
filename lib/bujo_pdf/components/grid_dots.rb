# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'

module BujoPdf
  module Components
    # GridDots renders dot grid pattern over a specific region.
    #
    # Use this component to redraw dots after drawing background elements
    # (lines, fills) that should appear behind the dot grid. This enables
    # a layered z-index effect without restructuring all rendering.
    #
    # Example usage:
    #   # Draw background lines first
    #   @pdf.stroke_line [x1, y1], [x2, y2]
    #
    #   # Then render dots on top
    #   grid_dots(2, 5, 20, 10)
    #
    class GridDots < Component
      # Mixin providing the grid_dots verb for pages
      #
      # Include via Components::All in Pages::Base
      module Mixin
        # Render dots over a grid region
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Starting row (top edge)
        # @param width [Integer] Width in grid boxes
        # @param height [Integer] Height in grid boxes
        # @param color [String, nil] Optional hex color override
        # @return [void]
        def grid_dots(col, row, width, height, color: nil)
          c = @canvas || Canvas.new(@pdf, @grid)
          GridDots.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            height: height,
            color: color
          ).render
        end
      end

      # Initialize a new GridDots component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top edge)
      # @param width [Integer] Width in grid boxes
      # @param height [Integer] Height in grid boxes
      # @param color [String, nil] Optional hex color override (default: theme dot color)
      def initialize(canvas:, col:, row:, width:, height:, color: nil)
        super(canvas: canvas)
        @col = col
        @row = row
        @width = width
        @height = height
        @color = color || Styling::Colors.DOT_GRID
        @radius = Styling::Grid::DOT_RADIUS
      end

      # Render dots at each grid intersection within the region
      #
      # @return [void]
      def render
        pdf.fill_color @color

        # Draw dots at each grid intersection
        (@row..(@row + @height)).each do |r|
          dot_y = grid.y(r)
          (@col..(@col + @width)).each do |c|
            dot_x = grid.x(c)
            pdf.fill_circle [dot_x, dot_y], @radius
          end
        end

        # Restore default fill color
        pdf.fill_color '000000'
      end
    end
  end
end
