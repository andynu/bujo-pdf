# frozen_string_literal: true

require_relative '../base'

module BujoPdf
  module Pages
    module Grids
      # Full-page isometric grid template
      #
      # 30-60-90 degree diamond grid covering the entire page.
      # Useful for technical drawing, 3D sketching, and game maps.
      #
      # Example:
      #   page = Grids::IsometricGridPage.new(pdf, context)
      #   page.generate
      class IsometricGridPage < Base
        # Use full page layout (no sidebars)
        def setup
          use_layout :full_page
        end

        # Render full-page isometric grid
        def render
          draw_title
          draw_isometric_grid
        end

        private

        # Draw page title
        #
        # @return [void]
        def draw_title
          title_box = @grid_system.rect(0, 0, 43, 2)

          @pdf.bounding_box([title_box[:x] + 10, title_box[:y] - 5],
                            width: title_box[:width] - 20,
                            height: title_box[:height] - 10) do
            @pdf.text 'Isometric Grid', size: 8, color: 'AAAAAA'
          end
        end

        # Draw isometric grid across entire page
        #
        # @return [void]
        def draw_isometric_grid
          renderer = Utilities::GridFactory.create(
            :isometric,
            @pdf,
            Styling::Grid::PAGE_WIDTH,
            Styling::Grid::PAGE_HEIGHT,
            line_width: 0.25
          )
          renderer.render
        end
      end
    end
  end
end
