# frozen_string_literal: true

require_relative 'standard_layout_page'
require_relative '../utilities/styling'

module BujoPdf
  module Pages
    # Multi-Year Overview page.
    #
    # Displays multiple years side-by-side with months as rows, enabling
    # year-over-year comparison. Each cell links to the corresponding week
    # in that year's planner.
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
        col_width = year_column_width

        @year_count.times do |year_idx|
          year = @start_year + year_idx
          col = content_area[:col] + MONTH_LABEL_WIDTH + (year_idx * col_width)

          @grid_system.text_box(
            year.to_s,
            col,
            content_area[:row] + HEADER_START_ROW,
            col_width,
            HEADER_HEIGHT,
            align: :center,
            valign: :center,
            size: 14,
            style: :bold
          )
        end
      end

      def draw_month_labels
        12.times do |month_idx|
          row = HEADER_HEIGHT + (month_idx * MONTH_HEIGHT_BOXES)

          # Draw month label with padding from cell borders
          label_box = @grid_system.rect(
            content_area[:col],
            content_area[:row] + row,
            MONTH_LABEL_WIDTH,
            MONTH_HEIGHT_BOXES
          )

          # Add padding (0.3 boxes on all sides)
          padding = @grid_system.width(0.3)

          @pdf.text_box MONTH_NAMES[month_idx],
            at: [label_box[:x] + padding, label_box[:y] - padding],
            width: label_box[:width] - (padding * 2),
            height: label_box[:height] - (padding * 2),
            align: :right,
            valign: :center,
            size: 10
        end
      end

      def draw_year_columns
        col_width = year_column_width

        @year_count.times do |year_idx|
          year = @start_year + year_idx
          base_col = content_area[:col] + MONTH_LABEL_WIDTH + (year_idx * col_width)

          12.times do |month_idx|
            month_num = month_idx + 1
            row = HEADER_HEIGHT + (month_idx * MONTH_HEIGHT_BOXES)

            draw_cell(
              year,
              month_num,
              base_col,
              content_area[:row] + row,
              col_width,
              MONTH_HEIGHT_BOXES
            )
          end
        end
      end

      def draw_cell(year, month_num, col, row, width_boxes, height_boxes)
        # Calculate first day of month and its week number
        first_day = Date.new(year, month_num, 1)
        week_num = calculate_week_number(year, first_day)

        # Cell is blank for data collection - no text displayed
        # Just add clickable link to corresponding week page
        @grid_system.link(
          col,
          row,
          width_boxes,
          height_boxes,
          "week_#{week_num}"
        )
      end

      def calculate_week_number(year, date)
        # Use the same Monday-based week calculation as DateCalculator
        year_start = Date.new(year, 1, 1)
        days_back = (year_start.wday + 6) % 7  # Convert to Monday-based
        year_start_monday = year_start - days_back

        days_from_start = (date - year_start_monday).to_i
        (days_from_start / 7) + 1
      end

      def draw_grid_lines
        @pdf.stroke_color BORDERS
        @pdf.line_width 0.5

        # Horizontal lines between months (including top and bottom)
        13.times do |i|
          row = HEADER_HEIGHT + (i * MONTH_HEIGHT_BOXES)
          y = @grid_system.y(content_area[:row] + row)

          @pdf.stroke_line(
            [@grid_system.x(content_area[:col]), y],
            [@grid_system.x(content_area[:col] + content_area[:width_boxes]), y]
          )
        end

        # Vertical lines between years (including left and right edges)
        col_width = year_column_width
        (@year_count + 1).times do |i|
          col = content_area[:col] + MONTH_LABEL_WIDTH + (i * col_width)
          x = @grid_system.x(col)

          top_y = @grid_system.y(content_area[:row] + HEADER_HEIGHT)
          bottom_y = @grid_system.y(content_area[:row] + HEADER_HEIGHT + (12 * MONTH_HEIGHT_BOXES))

          @pdf.stroke_line([x, top_y], [x, bottom_y])
        end

        # Vertical line separating month labels from data
        label_edge_x = @grid_system.x(content_area[:col] + MONTH_LABEL_WIDTH)
        top_y = @grid_system.y(content_area[:row] + HEADER_HEIGHT)
        bottom_y = @grid_system.y(content_area[:row] + HEADER_HEIGHT + (12 * MONTH_HEIGHT_BOXES))
        @pdf.stroke_line([label_edge_x, top_y], [label_edge_x, bottom_y])
      end

      def year_column_width
        # Available width after month labels, divided by number of years
        (content_area[:width_boxes] - MONTH_LABEL_WIDTH) / @year_count
      end
    end
  end
end
