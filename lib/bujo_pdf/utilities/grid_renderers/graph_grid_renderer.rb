# frozen_string_literal: true

require_relative 'base_grid_renderer'

module BujoPdf
  module Utilities
    module GridRenderers
      # Renderer for graph (square) grid pattern
      #
      # Draws a grid of horizontal and vertical lines at regular intervals,
      # creating a square grid pattern commonly used for technical drawing,
      # math, and structured note-taking.
      #
      # @example Basic usage
      #   renderer = GraphGridRenderer.new(pdf, 612, 792)
      #   renderer.render
      #
      # @example Custom spacing and color
      #   renderer = GraphGridRenderer.new(pdf, 612, 792,
      #     spacing: 15,
      #     line_color: 'DDDDDD'
      #   )
      #   renderer.render
      class GraphGridRenderer < BaseGridRenderer
        # Render the graph grid pattern
        #
        # Draws vertical and horizontal lines aligned with the grid coordinate
        # system, starting at (0, 0) which corresponds to the top-left corner
        # in grid coordinates.
        #
        # @return [void]
        def render
          @pdf.stroke_color line_color
          @pdf.line_width line_width

          # Draw vertical lines at each column
          (0..cols).each do |col|
            x = col * @spacing
            @pdf.line [x, 0], [x, @height]
          end

          # Draw horizontal lines at each row
          (0..rows).each do |row|
            y = @height - (row * @spacing)
            @pdf.line [0, y], [@width, y]
          end

          @pdf.stroke
          restore_colors
        end
      end
    end
  end
end
