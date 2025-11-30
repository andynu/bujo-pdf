# frozen_string_literal: true

require_relative '../base'

module BujoPdf
  module Pages
    module Grids
      # Full-page hexagon grid template
      #
      # Tessellating hexagon grid covering the entire page.
      # Useful for game maps, organic patterns, and chemistry diagrams.
      #
      # Example:
      #   page = Grids::HexagonGridPage.new(pdf, context)
      #   page.generate
      class HexagonGridPage < Base
        # Mixin providing hexagon_grid_page verb for document builders.
        module Mixin
          include MixinSupport

          # Generate the hexagon grid page.
          #
          # @return [PageRef, nil] PageRef during define phase, nil during render
          def hexagon_grid_page
            define_page(dest: 'grid_hexagon', title: 'Hexagon Grid', type: :grid) do |ctx|
              Grids::HexagonGridPage.new(@pdf, ctx).generate
            end
          end
        end

        # Use full page layout (no sidebars)
        def setup
          use_layout :full_page
        end

        # Render full-page hexagon grid
        def render
          draw_title
          draw_hexagon_grid
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
            @pdf.text 'Hexagon Grid', size: 8, color: 'AAAAAA'
          end
        end

        # Draw hexagon grid across entire page
        #
        # @return [void]
        def draw_hexagon_grid
          renderer = Utilities::GridFactory.create(
            :hexagon,
            @pdf,
            Styling::Grid::PAGE_WIDTH,
            Styling::Grid::PAGE_HEIGHT,
            line_width: 0.35,
            orientation: :flat_top
          )
          renderer.render
        end
      end
    end
  end
end
