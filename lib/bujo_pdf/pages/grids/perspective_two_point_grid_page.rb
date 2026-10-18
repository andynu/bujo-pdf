# frozen_string_literal: true

require_relative '../base'

module BujoPdf
  module Pages
    module Grids
      # Full-page two-point perspective grid template
      #
      # A horizon with a vanishing point on each side edge, rays fanning from
      # both, and vertical guides. Useful for drawing boxes, buildings and
      # rooms seen from a corner.
      #
      # Example:
      #   page = Grids::PerspectiveTwoPointGridPage.new(pdf, context)
      #   page.generate
      class PerspectiveTwoPointGridPage < Base
        register_page :grid_perspective_2,
          title: "2-Point Perspective Grid",
          dest: "grid_perspective_2"

        # Mixin providing perspective_two_point_grid_page verb for document builders.
        module Mixin
          include MixinSupport

          # Generate the 2-point perspective grid page.
          #
          # @return [PageRef, nil] PageRef during define phase, nil during render
          def perspective_two_point_grid_page
            define_page(dest: 'grid_perspective_2', title: '2-Point Perspective Grid', type: :grid) do |ctx|
              Grids::PerspectiveTwoPointGridPage.new(@pdf, ctx).generate
            end
          end
        end

        def setup
          set_destination('grid_perspective_2')
        end

        # The grid is the page's background, drawn before chrome so sidebars sit on top.
        def setup_page
          draw_grid(:perspective_2)
        end

        def render
          draw_title
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
            @pdf.text 'Perspective Grid (2-point)', size: 8, color: 'AAAAAA'
          end
        end
      end
    end
  end
end
