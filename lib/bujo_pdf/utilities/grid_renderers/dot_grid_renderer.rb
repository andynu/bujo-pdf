# frozen_string_literal: true

require_relative 'base_grid_renderer'

module BujoPdf
  module Utilities
    module GridRenderers
      # Renderer for dot grid pattern
      #
      # Draws a grid of small dots at regular intervals, commonly used in
      # bullet journals and planners. Dots serve as visual guides for
      # handwriting and drawing while remaining unobtrusive.
      #
      # @example Basic usage
      #   renderer = DotGridRenderer.new(pdf, 612, 792)
      #   renderer.render
      #
      # @example Custom dot size and color
      #   renderer = DotGridRenderer.new(pdf, 612, 792,
      #     spacing: 15,
      #     radius: 0.75,
      #     fill_color: 'DDDDDD'
      #   )
      #   renderer.render
      class DotGridRenderer < BaseGridRenderer
        # Initialize a new dot grid renderer
        #
        # @param pdf [Prawn::Document] The Prawn PDF document instance
        # @param width [Float] Width of area to fill with dots (in points)
        # @param height [Float] Height of area to fill with dots (in points)
        # @param options [Hash] Additional rendering options
        # @option options [Float] :spacing Distance between dots (default: 14.17pt = 5mm)
        # @option options [Float] :radius Radius of each dot (default: 0.5)
        # @option options [String] :fill_color 6-digit hex color for dots (default: 'CCCCCC')
        def initialize(pdf, width, height, options = {})
          super
          @radius = options.fetch(:radius, Styling::Grid::DOT_RADIUS)
        end

        # Render the dot grid pattern
        #
        # Dots are aligned with the grid coordinate system, starting at (0, 0)
        # which corresponds to the top-left corner in grid coordinates.
        #
        # @return [void]
        def render
          # Set fill color for dots
          @pdf.fill_color fill_color

          # Align with grid coordinate system: start at (0, height) which
          # corresponds to grid position (0, 0) - top-left corner
          start_x = 0
          start_y = @height

          # Draw dots at exact grid positions
          (0..rows).each do |row|
            y = start_y - (row * @spacing)
            (0..cols).each do |col|
              x = start_x + (col * @spacing)
              @pdf.fill_circle [x, y], @radius
            end
          end

          # Restore fill color to black
          restore_colors
        end
      end
    end
  end
end
