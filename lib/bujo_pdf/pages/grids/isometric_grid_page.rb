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
        register_page :grid_isometric,
          title: "Isometric Grid",
          dest: "grid_isometric"

        # Mixin providing isometric_grid_page verb for document builders.
        module Mixin
          include MixinSupport

          # Generate the isometric grid page.
          #
          # @return [PageRef, nil] PageRef during define phase, nil during render
          def isometric_grid_page
            define_page(dest: 'grid_isometric', title: 'Isometric Grid', type: :grid) do |ctx|
              Grids::IsometricGridPage.new(@pdf, ctx).generate
            end
          end
        end

        # Use full page layout (no sidebars)
        def setup
          set_destination('grid_isometric')
          use_layout :full_page
        end

        # Render full-page isometric grid
        def render
          # Draw isometric grid using pre-created stamp (efficient)
          draw_grid(:isometric)

          # Draw title/label at top
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
            @pdf.text 'Isometric Grid', size: 8, color: 'AAAAAA'
          end
        end
      end
    end
  end
end
