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

        LINE_SPACING_BOXES = 2  # Lines every 2 boxes (~10mm)
        MARGIN_COL = 3          # Left margin at column 3 (matching sidebar width)

        # Use full page layout (no sidebars)
        def setup
          use_layout :full_page
        end

        # Render full-page ruled lines
        def render
          # Draw title/label at top
          draw_title

          # Draw ruled lines
          draw_ruled_lines

          # Draw left margin line
          draw_margin_line
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

        # Draw horizontal ruled lines
        #
        # Lines are drawn every LINE_SPACING_BOXES rows, starting after the title
        #
        # @return [void]
        def draw_ruled_lines
          @pdf.stroke_color 'CCCCCC'  # Light gray matching other grids
          @pdf.line_width 0.25

          # Start after title area (row 2), draw lines every LINE_SPACING_BOXES
          start_row = 2
          (start_row..55).step(LINE_SPACING_BOXES).each do |row|
            y = @grid_system.y(row)
            @pdf.line [0, y], [@grid_system.page_width, y]
          end

          @pdf.stroke
          @pdf.stroke_color '000000'  # Reset to black
        end

        # Draw left margin line
        #
        # Vertical line at MARGIN_COL matching traditional notebook paper
        #
        # @return [void]
        def draw_margin_line
          @pdf.stroke_color 'FFCCCC'  # Light red/pink for margin (traditional style)
          @pdf.line_width 0.5

          x = @grid_system.x(MARGIN_COL)
          @pdf.line [x, 0], [x, @grid_system.page_height]

          @pdf.stroke
          @pdf.stroke_color '000000'  # Reset to black
        end
      end
    end
  end
end
