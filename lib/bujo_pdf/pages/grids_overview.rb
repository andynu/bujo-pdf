# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Grids overview page - entry point for grid reference cycling
    #
    # This page serves as the overview/index for the grid reference section.
    # It displays samples of the three basic grid types (dots, graph, lined)
    # that can be accessed by cycling through the Grids tab.
    #
    # Navigation cycle: grids_overview → grid_dot → grid_graph → grid_lined → grids_overview
    #
    # Example:
    #   page = GridsOverview.new(pdf, context)
    #   page.generate
    class GridsOverview < Base
      GRID_SAMPLES = [
        { label: 'Dot Grid', dest: 'grid_dot', description: '5mm dot spacing for flexible layouts' },
        { label: 'Graph Grid', dest: 'grid_graph', description: '5mm square grid for precise drawings' },
        { label: 'Ruled Lines', dest: 'grid_lined', description: 'Standard ruled lines for writing' }
      ].freeze

      # Set up layout with Grids tab highlighted
      def setup
        use_layout :standard_with_sidebars,
          highlight_tab: :grids
      end

      # Render the grids overview with sample links
      def render
        # Draw title at top
        draw_title

        # Draw grid samples with clickable links
        draw_grid_samples
      end

      private

      # Draw page title
      #
      # @return [void]
      def draw_title
        title_box = content_area_rect(0, 0, content_area[:width_boxes], 3)

        @pdf.bounding_box([title_box[:x], title_box[:y]],
                          width: title_box[:width],
                          height: title_box[:height]) do
          @pdf.text 'Grid Reference', size: 16, style: :bold, align: :center, valign: :center
        end
      end

      # Draw grid sample boxes with links
      #
      # @return [void]
      def draw_grid_samples
        # 3 samples × 16 boxes + 2 gaps × 2 boxes = 52 boxes total
        sections = @grid.divide_rows(row: 5, height: 52, count: GRID_SAMPLES.count, gap: 2)

        GRID_SAMPLES.zip(sections).each do |sample, section|
          draw_sample_box(sample, section.row, section.height)
        end
      end

      # Draw an individual grid sample box
      #
      # @param sample [Hash] Sample specification with :label, :dest, :description
      # @param row [Integer] Starting row for this sample
      # @param height [Integer] Height in grid boxes
      # @return [void]
      def draw_sample_box(sample, row, height)
        # Use full content area width
        box = content_area_rect(0, row, content_area[:width_boxes], height)

        # Draw border
        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.5
        @pdf.stroke_rectangle [box[:x], box[:y]], box[:width], box[:height]
        @pdf.stroke_color '000000'

        # Draw label and description
        @pdf.bounding_box([box[:x] + 10, box[:y] - 10],
                          width: box[:width] - 20,
                          height: box[:height] - 20) do
          @pdf.text sample[:label], size: 12, style: :bold
          @pdf.move_down 5
          @pdf.text sample[:description], size: 9, color: '666666'

          # Add "Tap to view" hint
          @pdf.move_down 10
          @pdf.text 'Tap to view full page', size: 8, color: '999999', style: :italic
        end

        # Add clickable link over entire box
        @grid_system.link(
          content_area[:col],
          row,
          content_area[:width_boxes],
          height,
          sample[:dest]
        )
      end

      # Get a rect within the content area (relative to content area origin)
      #
      # @param col_offset [Numeric] Column offset from content area start
      # @param row_offset [Numeric] Row offset from content area start
      # @param width_boxes [Numeric] Width in boxes
      # @param height_boxes [Numeric] Height in boxes
      # @return [Hash] Rectangle with :x, :y, :width, :height
      def content_area_rect(col_offset, row_offset, width_boxes, height_boxes)
        @grid_system.rect(
          content_area[:col] + col_offset,
          content_area[:row] + row_offset,
          width_boxes,
          height_boxes
        )
      end
    end
  end
end
