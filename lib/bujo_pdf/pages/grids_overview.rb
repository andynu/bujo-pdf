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
      register_page :grids_overview,
        title: "Grids Overview",
        dest: "grids_overview"

      # Mixin providing grids_overview_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the grids overview page.
        #
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def grids_overview_page
          define_page(dest: 'grids_overview', title: 'Grids Overview', type: :grid) do |ctx|
            GridsOverview.new(@pdf, ctx).generate
          end
        end
      end

      GRID_SAMPLES = [
        { label: 'Dot Grid', dest: 'grid_dot', description: '5mm dot spacing for flexible layouts' },
        { label: 'Graph Grid', dest: 'grid_graph', description: '5mm square grid for precise drawings' },
        { label: 'Ruled Lines', dest: 'grid_lined', description: 'Standard ruled lines for writing' }
      ].freeze

      # Set up layout with Grids tab highlighted
      def setup
        set_destination('grids_overview')
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

        # Draw grid pattern preview in the box
        draw_grid_preview(sample[:dest], box)

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

      # Draw a preview of the grid pattern inside the sample box
      #
      # @param dest [String] Grid destination identifier
      # @param box [Hash] Bounding box coordinates
      # @return [void]
      def draw_grid_preview(dest, box)
        # Calculate preview area (inside the box with padding)
        padding = 5
        preview_x = box[:x] + padding
        preview_y = box[:y] - padding
        preview_width = box[:width] - (padding * 2)
        preview_height = box[:height] - (padding * 2)

        case dest
        when 'grid_dot'
          draw_dot_preview(preview_x, preview_y, preview_width, preview_height)
        when 'grid_graph'
          draw_graph_preview(preview_x, preview_y, preview_width, preview_height)
        when 'grid_lined'
          draw_lined_preview(preview_x, preview_y, preview_width, preview_height)
        end
      end

      # Draw dot grid preview
      #
      # @param x [Float] Left x coordinate
      # @param y [Float] Top y coordinate
      # @param width [Float] Preview width
      # @param height [Float] Preview height
      # @return [void]
      def draw_dot_preview(x, y, width, height)
        spacing = Styling::Grid::DOT_SPACING
        radius = Styling::Grid::DOT_RADIUS

        @pdf.fill_color 'CCCCCC'

        # Draw dots at grid spacing
        cols = (width / spacing).to_i
        rows = (height / spacing).to_i

        (0..rows).each do |row_idx|
          (0..cols).each do |col_idx|
            dot_x = x + (col_idx * spacing)
            dot_y = y - (row_idx * spacing)
            next if dot_y < (y - height) || dot_x > (x + width)

            @pdf.fill_circle [dot_x, dot_y], radius
          end
        end

        @pdf.fill_color '000000'
      end

      # Draw graph grid preview
      #
      # @param x [Float] Left x coordinate
      # @param y [Float] Top y coordinate
      # @param width [Float] Preview width
      # @param height [Float] Preview height
      # @return [void]
      def draw_graph_preview(x, y, width, height)
        spacing = Styling::Grid::DOT_SPACING

        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.25

        # Draw vertical lines
        cols = (width / spacing).to_i
        (0..cols).each do |col_idx|
          line_x = x + (col_idx * spacing)
          next if line_x > (x + width)

          @pdf.line [line_x, y], [line_x, y - height]
        end

        # Draw horizontal lines
        rows = (height / spacing).to_i
        (0..rows).each do |row_idx|
          line_y = y - (row_idx * spacing)
          next if line_y < (y - height)

          @pdf.line [x, line_y], [x + width, line_y]
        end

        @pdf.stroke
        @pdf.stroke_color '000000'
      end

      # Draw ruled lines preview
      #
      # @param x [Float] Left x coordinate
      # @param y [Float] Top y coordinate
      # @param width [Float] Preview width
      # @param height [Float] Preview height
      # @return [void]
      def draw_lined_preview(x, y, width, height)
        line_spacing = Styling::Grid::DOT_SPACING * 2  # 10mm like the full page

        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.25

        # Draw horizontal lines
        rows = (height / line_spacing).to_i
        (0..rows).each do |row_idx|
          line_y = y - (row_idx * line_spacing)
          next if line_y < (y - height)

          @pdf.line [x, line_y], [x + width, line_y]
        end

        @pdf.stroke
        @pdf.stroke_color '000000'
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
