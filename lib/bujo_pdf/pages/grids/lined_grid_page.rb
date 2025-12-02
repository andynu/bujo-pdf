# frozen_string_literal: true

require_relative '../base'

module BujoPdf
  module Pages
    module Grids
      # Full-page ruled lines template
      #
      # Horizontal ruled lines spaced every 2 grid boxes (~10mm) with
      # an optional left margin line (like traditional notebook paper).
      # Part of the grids navigation cycle accessed via the Grids tab.
      #
      # Example:
      #   page = Grids::LinedGridPage.new(pdf, context)
      #   page.generate
      class LinedGridPage < Base
        register_page :grid_lined,
          title: "Ruled Lines (10mm)",
          dest: "grid_lined"

        # Mixin providing lined_grid_page verb for document builders.
        module Mixin
          include MixinSupport

          # Generate the lined grid page.
          #
          # @return [PageRef, nil] PageRef during define phase, nil during render
          def lined_grid_page
            define_page(dest: 'grid_lined', title: 'Ruled Lines', type: :grid) do |ctx|
              Grids::LinedGridPage.new(@pdf, ctx).generate
            end
          end
        end

        # Use full page layout (no sidebars)
        def setup
          set_destination('grid_lined')
          use_layout :full_page
        end

        # Render full-page ruled lines
        def render
          # Draw ruled lines using pre-created stamp (efficient)
          draw_grid(:lined)

          # Draw title/label at top
          draw_title
        end

        private

        # Draw page title
        #
        # Small, subtle title so it doesn't interfere with grid usage
        #
        # @return [void]
        def draw_title
          title_box = @grid_system.rect(0, 0, 43, 2)

          @pdf.bounding_box([title_box[:x] + 10, title_box[:y] - 5],
                            width: title_box[:width] - 20,
                            height: title_box[:height] - 10) do
            @pdf.text 'Ruled Lines (10mm)', size: 8, color: 'AAAAAA'
          end
        end
      end
    end
  end
end
