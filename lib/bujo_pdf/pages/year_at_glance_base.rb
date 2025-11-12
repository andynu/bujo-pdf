# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/date_calculator'
require_relative '../components/week_sidebar'
require_relative '../components/right_sidebar'

module BujoPdf
  module Pages
    # Base class for Year At Glance pages (Events and Highlights).
    #
    # These pages show a 12×31 grid (months × days) where each cell represents
    # one day of the year. Each cell is clickable and links to the corresponding
    # weekly page.
    #
    # Layout:
    #   - Header (rows 0-1): Page title
    #   - Month headers (row 2): 12 month names
    #   - Days grid (rows 3-52): 31 days × 12 months
    #
    # Subclasses must override:
    #   - page_title: The title to display in the header
    #   - destination_name: The named destination for this page
    class YearAtGlanceBase < Base
      # Constants
      GRID_COLS = 43
      DOT_SPACING = 14.17
      COLOR_BORDERS = 'E5E5E5'

      # Layout constants
      YEAR_TITLE_FONT_SIZE = 16
      YEAR_MONTH_HEADER_SIZE = 8
      YEAR_DAY_SIZE = 6
      YEAR_DAY_ABBREV_SIZE = 5
      YEAR_DAY_NUMBER_OFFSET = 2
      YEAR_DAY_ABBREV_HEIGHT = 8

      MONTH_NAMES = %w[
        January February March April May June
        July August September October November December
      ]

      def setup
        set_destination(destination_name)
        @year = context[:year]
        @total_weeks = Utilities::DateCalculator.total_weeks(@year)
      end

      def render
        draw_dot_grid
        draw_diagnostic_grid(label_every: 5)
        draw_week_sidebar
        draw_right_sidebar
        draw_header
        draw_month_headers
        draw_days_grid
      end

      protected

      # Subclasses must override these methods
      def page_title
        raise NotImplementedError, "#{self.class} must implement #page_title"
      end

      def destination_name
        raise NotImplementedError, "#{self.class} must implement #destination_name"
      end

      private

      def draw_header
        # Content area dimensions
        content_start_col = 3
        content_width_boxes = 39  # Columns 3-41 inclusive

        # Header - rows 0-1 (2 boxes)
        header_box = @grid_system.rect(content_start_col, 0, content_width_boxes, 2)
        @pdf.font "Helvetica-Bold", size: YEAR_TITLE_FONT_SIZE
        @pdf.text_box page_title,
                      at: [header_box[:x], header_box[:y]],
                      width: header_box[:width],
                      height: header_box[:height],
                      align: :center,
                      valign: :center
      end

      def draw_month_headers
        content_start_col = 3
        content_width_boxes = 39
        col_width_boxes = content_width_boxes / 12.0  # ≈ 3.25 boxes per month

        @pdf.font "Helvetica-Bold", size: YEAR_MONTH_HEADER_SIZE

        12.times do |month_index|
          month_name = MONTH_NAMES[month_index]

          # Calculate column position
          col_start = content_start_col + (month_index * col_width_boxes)
          cell_x = @grid_system.x(0) + (col_start * DOT_SPACING)
          cell_y = @grid_system.y(2)
          cell_width = col_width_boxes * DOT_SPACING
          cell_height = @grid_system.height(1)

          # Calculate which week contains the 1st of this month
          first_of_month = Date.new(@year, month_index + 1, 1)
          week_num = Utilities::DateCalculator.week_number_for_date(@year, first_of_month)

          # Draw month header cell
          @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
            @pdf.stroke_color COLOR_BORDERS
            @pdf.stroke_bounds
            @pdf.stroke_color '000000'
            @pdf.text_box month_name[0..2],
                          at: [0, cell_height],
                          width: cell_width,
                          height: cell_height,
                          align: :center,
                          valign: :center
          end

          # Add clickable link
          link_bottom = cell_y - cell_height
          @pdf.link_annotation([cell_x, link_bottom, cell_x + cell_width, cell_y],
                              Dest: "week_#{week_num}",
                              Border: [0, 0, 0])
        end
      end

      def draw_days_grid
        content_start_col = 3
        content_width_boxes = 39
        col_width_boxes = content_width_boxes / 12.0

        # Days grid - rows 3-52 (50 rows for 31 days)
        day_height_rows = 50.0 / 31.0

        @pdf.font "Helvetica", size: YEAR_DAY_SIZE

        31.times do |day_index|
          day_num = day_index + 1
          day_row_start = 3 + (day_index * day_height_rows)

          12.times do |month_index|
            month = month_index + 1
            days_in_month = Date.new(@year, month, -1).day

            # Calculate cell position
            col_start = content_start_col + (month_index * col_width_boxes)
            cell_x = @grid_system.x(0) + (col_start * DOT_SPACING)
            cell_y = @grid_system.y(0) - (day_row_start * DOT_SPACING)
            cell_width = col_width_boxes * DOT_SPACING
            cell_height = day_height_rows * DOT_SPACING

            if day_num <= days_in_month
              draw_day_cell(cell_x, cell_y, cell_width, cell_height, month, day_num)
            else
              draw_empty_cell(cell_x, cell_y, cell_width, cell_height)
            end
          end
        end
      end

      def draw_day_cell(cell_x, cell_y, cell_width, cell_height, month, day_num)
        @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'

          # Add day number and abbreviation
          date = Date.new(@year, month, day_num)
          day_abbrev = date.strftime('%a')[0..1]  # Mo, Tu, We, etc.

          @pdf.text_box day_num.to_s,
                       at: [YEAR_DAY_NUMBER_OFFSET, cell_height - YEAR_DAY_NUMBER_OFFSET],
                       width: cell_width - (YEAR_DAY_NUMBER_OFFSET * 2),
                       height: cell_height - (YEAR_DAY_NUMBER_OFFSET * 2),
                       size: YEAR_DAY_SIZE,
                       overflow: :shrink_to_fit

          # Add day of week abbreviation
          @pdf.text_box day_abbrev,
                       at: [YEAR_DAY_NUMBER_OFFSET, YEAR_DAY_ABBREV_HEIGHT],
                       width: cell_width - (YEAR_DAY_NUMBER_OFFSET * 2),
                       height: YEAR_DAY_ABBREV_HEIGHT,
                       size: YEAR_DAY_ABBREV_SIZE,
                       style: :italic,
                       overflow: :shrink_to_fit

          # Add clickable link to the week containing this date
          week_num = Utilities::DateCalculator.week_number_for_date(@year, date)

          @pdf.link_annotation([0, 0, cell_width, cell_height],
                              Dest: "week_#{week_num}",
                              Border: [0, 0, 0])
        end
      end

      def draw_empty_cell(cell_x, cell_y, cell_width, cell_height)
        @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'
          @pdf.fill_color 'EEEEEE'
          @pdf.fill_rectangle [0, cell_height], cell_width, cell_height
          @pdf.fill_color '000000'
        end
      end

      def draw_week_sidebar
        # Use WeekSidebar component
        # No current week for year-at-glance pages
        sidebar = Components::WeekSidebar.new(@pdf, @grid_system,
          year: @year,
          total_weeks: @total_weeks
        )
        sidebar.render
      end

      def draw_right_sidebar
        # Use RightSidebar component
        # Determine which tab is current based on destination_name
        current = destination_name

        top_tabs = []
        top_tabs << { label: "Year", dest: "seasonal", current: (current == "seasonal") }
        top_tabs << { label: "Events", dest: "year_events", current: (current == "year_events") }
        top_tabs << { label: "Highlights", dest: "year_highlights", current: (current == "year_highlights") }

        sidebar = Components::RightSidebar.new(@pdf, @grid_system,
          top_tabs: top_tabs,
          bottom_tabs: [
            { label: "Dots", dest: "dots" }
          ]
        )
        sidebar.render
      end
    end
  end
end
