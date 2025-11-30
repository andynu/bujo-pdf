# frozen_string_literal: true

require_relative '../base'

module BujoPdf
  module Pages
    module Grids
      # Full-page dot grid template
      #
      # Standard 5mm (14.17pt) dot grid covering the entire page.
      # Part of the grids navigation cycle accessed via the Grids tab.
      #
      # Example:
      #   page = Grids::DotGridPage.new(pdf, context)
      #   page.generate
      class DotGridPage < Base
        # Mixin providing dot_grid_page verb for document builders.
        module Mixin
          include MixinSupport

          # Generate the dot grid page.
          #
          # @return [void]
          def dot_grid_page
            start_new_page
            context = build_context(page_key: :grid_dot)
            Grids::DotGridPage.new(@pdf, context).generate
          end
        end

        # Use full page layout (no sidebars)
        def setup
          use_layout :full_page
        end

        # Render full-page dot grid
        def render
          # Draw title/label at top
          draw_title

          # Draw dot grid across entire page using the stamp
          draw_dot_grid
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
            @pdf.text 'Dot Grid (5mm)', size: 8, color: 'AAAAAA'
          end
        end
      end
    end
  end
end
