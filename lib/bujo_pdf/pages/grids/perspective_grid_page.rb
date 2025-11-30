# frozen_string_literal: true

require_relative '../base'

module BujoPdf
  module Pages
    module Grids
      # Full-page one-point perspective grid template
      #
      # Converging lines toward a central vanishing point.
      # Useful for architectural sketching, scene design, and spatial planning.
      #
      # Example:
      #   page = Grids::PerspectiveGridPage.new(pdf, context)
      #   page.generate
      class PerspectiveGridPage < Base
        register_page :grid_perspective,
          title: "Perspective Grid",
          dest: "grid_perspective"

        # Mixin providing perspective_grid_page verb for document builders.
        module Mixin
          include MixinSupport

          # Generate the perspective grid page.
          #
          # @return [PageRef, nil] PageRef during define phase, nil during render
          def perspective_grid_page
            define_page(dest: 'grid_perspective', title: 'Perspective Grid', type: :grid) do |ctx|
              Grids::PerspectiveGridPage.new(@pdf, ctx).generate
            end
          end
        end

        # Use full page layout (no sidebars)
        def setup
          use_layout :full_page
        end

        # Render full-page perspective grid
        def render
          draw_title
          draw_perspective_grid
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
            @pdf.text 'Perspective Grid (1-point)', size: 8, color: 'AAAAAA'
          end
        end

        # Draw perspective grid across entire page
        #
        # @return [void]
        def draw_perspective_grid
          renderer = Utilities::GridFactory.create(
            :perspective,
            @pdf,
            Styling::Grid::PAGE_WIDTH,
            Styling::Grid::PAGE_HEIGHT,
            num_points: 1,
            draw_guide_rectangles: true,
            num_converging: 24,
            line_width: 0.35
          )
          renderer.render
        end
      end
    end
  end
end
