# frozen_string_literal: true

require_relative 'standard_layout_page'
require_relative '../utilities/styling'

module BujoPdf
  module Pages
    # Multi-Year Overview page.
    #
    # Displays multiple years side-by-side with months as rows, enabling
    # year-over-year comparison. Each cell is blank for manual data entry.
    #
    # Grid layout:
    # - Month labels: 3 columns on left
    # - Year data: Remaining columns divided by year count
    # - Each month: 4 rows tall
    # - Header: 2 rows for year labels
    #
    # Example:
    #   page = MultiYearOverview.new(pdf, {
    #     year: 2024,
    #     year_count: 4,
    #     total_weeks: 52
    #   })
    #   page.generate
    class MultiYearOverview < StandardLayoutPage
      include Styling::Colors

      MONTH_NAMES = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze
      MONTH_HEIGHT_BOXES = 4
      MONTH_LABEL_WIDTH = 3
      HEADER_HEIGHT = 2
      HEADER_START_ROW = 0

      def initialize(pdf, context)
        super
        @start_year = context[:year]
        @year_count = context[:year_count] || 4
      end

      def setup
        set_destination('multi_year')
        super
      end

      protected

      def highlight_tab
        :multi_year
      end

      def render
        draw_header
        draw_month_labels
        draw_year_columns
        draw_grid_lines
      end

      private

      def draw_header
        year_cols = @grid.divide_columns(
          col: content_area[:col] + MONTH_LABEL_WIDTH,
          width: content_area[:width_boxes] - MONTH_LABEL_WIDTH,
          count: @year_count
        )

        year_cols.each_with_index do |col, year_idx|
          @grid_system.text_box(
            (@start_year + year_idx).to_s,
            col.col,
            content_area[:row] + HEADER_START_ROW,
            col.width,
            HEADER_HEIGHT,
            align: :center,
            valign: :center,
            size: 14,
            style: :bold
          )
        end
      end

      def draw_month_labels
        month_rows = @grid.divide_rows(
          row: content_area[:row] + HEADER_HEIGHT,
          height: 12 * MONTH_HEIGHT_BOXES,
          count: 12
        )

        MONTH_NAMES.zip(month_rows).each do |month_name, section|
          label_box = @grid_system.rect(
            content_area[:col],
            section.row,
            MONTH_LABEL_WIDTH,
            section.height
          )

          # Add padding (0.3 boxes on all sides)
          padding = @grid_system.width(0.3)

          @pdf.text_box month_name,
            at: [label_box[:x] + padding, label_box[:y] - padding],
            width: label_box[:width] - (padding * 2),
            height: label_box[:height] - (padding * 2),
            align: :right,
            valign: :center,
            size: 10
        end
      end

      def draw_year_columns
        # Grid of year columns × month rows (order: :right = row-major)
        cells = @grid.divide_grid(
          col: content_area[:col] + MONTH_LABEL_WIDTH,
          row: content_area[:row] + HEADER_HEIGHT,
          width: content_area[:width_boxes] - MONTH_LABEL_WIDTH,
          height: 12 * MONTH_HEIGHT_BOXES,
          cols: @year_count,
          rows: 12,
          order: :right
        )

        cells.each_with_index do |cell, idx|
          year_idx = idx % @year_count
          month_idx = idx / @year_count

          draw_cell(
            @start_year + year_idx,
            month_idx + 1,
            cell.col,
            cell.row,
            cell.width,
            cell.height
          )
        end
      end

      def draw_cell(year, month_num, col, row, width_boxes, height_boxes)
        # Cell is intentionally blank for manual data entry
        # No links or text - just an empty cell within the grid
      end

      def draw_grid_lines
        @pdf.stroke_color Styling::Colors.BORDERS
        @pdf.line_width 0.5

        grid_top = content_area[:row] + HEADER_HEIGHT
        grid_height = 12 * MONTH_HEIGHT_BOXES
        grid_left = content_area[:col] + MONTH_LABEL_WIDTH
        grid_width = content_area[:width_boxes] - MONTH_LABEL_WIDTH

        month_rows = @grid.divide_rows(row: grid_top, height: grid_height, count: 12)
        year_cols = @grid.divide_columns(col: grid_left, width: grid_width, count: @year_count)

        # Horizontal lines between months (including top and bottom)
        month_rows.each do |section|
          y = @grid_system.y(section.row)
          @pdf.stroke_line(
            [@grid_system.x(content_area[:col]), y],
            [@grid_system.x(content_area[:col] + content_area[:width_boxes]), y]
          )
        end
        # Bottom line
        bottom_y = @grid_system.y(grid_top + grid_height)
        @pdf.stroke_line(
          [@grid_system.x(content_area[:col]), bottom_y],
          [@grid_system.x(content_area[:col] + content_area[:width_boxes]), bottom_y]
        )

        # Vertical lines between years (including left and right edges)
        top_y = @grid_system.y(grid_top)
        year_cols.each do |col|
          x = @grid_system.x(col.col)
          @pdf.stroke_line([x, top_y], [x, bottom_y])
        end
        # Right edge
        right_x = @grid_system.x(grid_left + grid_width)
        @pdf.stroke_line([right_x, top_y], [right_x, bottom_y])

        # Vertical line separating month labels from data
        label_edge_x = @grid_system.x(grid_left)
        @pdf.stroke_line([label_edge_x, top_y], [label_edge_x, bottom_y])
      end
    end
  end
end
