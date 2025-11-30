# frozen_string_literal: true

require_relative '../base'

module BujoPdf
  module Pages
    module Grids
      # Full-page graph (square) grid template
      #
      # 5mm square grid created by drawing lines at dot positions.
      # Part of the grids navigation cycle accessed via the Grids tab.
      #
      # Example:
      #   page = Grids::GraphGridPage.new(pdf, context)
      #   page.generate
      class GraphGridPage < Base
        register_page :grid_graph,
          title: "Graph Grid (5mm)",
          dest: "grid_graph"

        # Mixin providing graph_grid_page verb for document builders.
        module Mixin
          include MixinSupport

          # Generate the graph grid page.
          #
          # @return [PageRef, nil] PageRef during define phase, nil during render
          def graph_grid_page
            define_page(dest: 'grid_graph', title: 'Graph Grid', type: :grid) do |ctx|
              Grids::GraphGridPage.new(@pdf, ctx).generate
            end
          end
        end

        # Use full page layout (no sidebars)
        def setup
          set_destination('grid_graph')
          use_layout :full_page
        end

        # Render full-page graph grid
        def render
          # Draw title/label at top
          draw_title

          # Draw graph grid (vertical and horizontal lines at every grid position)
          draw_graph_grid
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
            @pdf.text 'Graph Grid (5mm)', size: 8, color: 'AAAAAA'
          end
        end

        # Draw graph grid by rendering lines at every grid intersection
        #
        # @return [void]
        def draw_graph_grid
          @pdf.stroke_color 'CCCCCC'  # Light gray matching dot grid
          @pdf.line_width 0.25

          # Draw vertical lines at each column
          (0..43).each do |col|
            x = @grid_system.x(col)
            @pdf.line [x, 0], [x, @grid_system.page_height]
          end

          # Draw horizontal lines at each row
          (0..55).each do |row|
            y = @grid_system.y(row)
            @pdf.line [0, y], [@grid_system.page_width, y]
          end

          @pdf.stroke
          @pdf.stroke_color '000000'  # Reset to black
        end
      end
    end
  end
end
