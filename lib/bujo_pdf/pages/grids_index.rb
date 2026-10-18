# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/grid_factory'

module BujoPdf
  module Pages
    # Landing page for the grids section: a captioned sample of every grid,
    # two per row, each tile linking to that grid's full page.
    #
    # Example:
    #   page = GridsIndex.new(pdf, context)
    #   page.generate
    class GridsIndex < Base
      register_page :grids_index,
        title: "Grids",
        dest: "grids_index"

      # Caption, destination, grid type and renderer options per tile, in nav order
      TILES = [
        ['Dot', 'grid_dot', :dots, {}],
        ['Isometric', 'grid_isometric', :isometric, {}],
        ['1-point perspective', 'grid_perspective', :perspective,
         { num_points: 1, draw_guide_rectangles: true, num_converging: 8, line_width: 0.5 }],
        ['2-point perspective', 'grid_perspective_2', :perspective_2, { line_width: 0.35 }],
        ['Graph', 'grid_graph', :graph, {}],
        ['Ruled', 'grid_lined', :lined, {}],
        ['Hexagon', 'grid_hexagon', :hexagon, { line_width: 0.5 }]
      ].freeze

      COLUMN_GAP = 2
      ROW_GAP = 1
      CAPTION_ROWS = 2
      TILE_TOP_ROW = 4

      # Mixin providing grids_index_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the grids index page.
        #
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def grids_index_page
          define_page(dest: 'grids_index', title: 'Grids', type: :grids_index) do |ctx|
            GridsIndex.new(@pdf, ctx).generate
          end
        end
      end

      def self.background_type
        :blank
      end

      def setup
        set_destination('grids_index')
      end

      def render
        col, width = inner_columns
        h2(col, 1, 'Grids', width: width)

        column(col, TILE_TOP_ROW, width, Layouts::BaseLayout::PAGE_HEIGHT_BOXES - TILE_TOP_ROW - 1, gap: ROW_GAP) do |c|
          TILES.each_slice(2) do |pair|
            c.slot(:fill) { |band| draw_band(band, pair) }
          end
        end
      end

      private

      # Content-area columns, one box in from each side, trimmed so two tiles
      # and the gap between them split evenly.
      #
      # @return [Array(Integer, Integer)] Starting column and width in boxes
      def inner_columns
        col = @content_area[:col] + 1
        width = @content_area[:width_boxes] - 2
        width -= 1 if (width - COLUMN_GAP).odd?
        [col, width]
      end

      def draw_band(band, pair)
        row(band, gap: COLUMN_GAP) do |r|
          pair.each { |tile| r.slot(:fill) { |cell| draw_tile(cell, *tile) } }
          r.slot(:fill) { |_empty| nil } if pair.size == 1
        end
      end

      def draw_tile(cell, caption, dest, type, options)
        column(cell) do |t|
          t.slot(CAPTION_ROWS) { |cap| h1(cap.col, cap.row, caption, width: cap.width) }
          t.slot(:fill) { |sample| draw_sample(sample, type, options) }
        end
        @grid_system.link(cell.col, cell.row, cell.width, cell.height, dest)
      end

      # Draw a grid sample clipped to its cell, framed by a light border.
      def draw_sample(cell, type, options)
        box = @grid_system.rect(cell.col, cell.row, cell.width, cell.height)
        @pdf.save_graphics_state do
          @pdf.rectangle [box[:x], box[:y]], box[:width], box[:height]
          @pdf.add_content 'W n'
          @pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
            Utilities::GridFactory.create(type, @pdf, box[:width], box[:height], **options).render
          end
        end
        @pdf.save_graphics_state do
          @pdf.stroke_color 'CCCCCC'
          @pdf.line_width 0.5
          @pdf.stroke_rectangle [box[:x], box[:y]], box[:width], box[:height]
        end
      end
    end
  end
end
