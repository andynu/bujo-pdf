# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'

module BujoPdf
  module Components
    # EraseDots covers dots with background-colored circles.
    #
    # Use this to "erase" dots behind text or other elements for better
    # readability. Works by drawing slightly larger background-colored
    # circles over existing dots.
    #
    # Example usage in a page:
    #   erase_dots(2, 5, 10)      # Erase single row of dots
    #   erase_dots(2, 5, 10, 3)   # Erase multiple rows
    #
    class EraseDots < Component
      # Mixin providing the erase_dots verb for pages and components
      #
      # Include via Components::All in Pages::Base, or directly in components.
      module Mixin
        # Erase dots over a grid region by covering with background color
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Starting row (top edge)
        # @param width [Integer] Width in grid boxes
        # @param height [Integer] Height in grid boxes (default: 0 for single row)
        # @return [void]
        def erase_dots(col, row, width, height = 0)
          c = @canvas || Canvas.new(@pdf, @grid)
          EraseDots.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            height: height
          ).render
        end
      end

      # Initialize a new EraseDots component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top edge)
      # @param width [Integer] Width in grid boxes
      # @param height [Integer] Height in grid boxes (default: 0 for single row)
      def initialize(canvas:, col:, row:, width:, height: 0)
        super(canvas: canvas)
        @col = col
        @row = row
        @width = width
        @height = height
      end

      # Render background-colored circles to cover existing dots
      #
      # @return [void]
      def render
        require_relative '../themes/theme_registry'

        bg_color = BujoPdf::Themes.current[:colors][:background]
        radius = Styling::Grid::DOT_RADIUS + 0.5 # Slightly larger to fully cover

        pdf.fill_color bg_color

        (@row..(@row + @height)).each do |r|
          dot_y = grid.y(r)
          (@col..(@col + @width)).each do |c|
            dot_x = grid.x(c)
            pdf.fill_circle [dot_x, dot_y], radius
          end
        end

        # Restore default fill color
        pdf.fill_color '000000'
      end
    end
  end
end
