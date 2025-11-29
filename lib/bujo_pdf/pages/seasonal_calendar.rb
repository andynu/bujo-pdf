# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/date_calculator'
require_relative '../utilities/styling'
require_relative '../sub_components/fieldset'

module BujoPdf
  module Pages
    # Seasonal calendar page showing the year at a glance organized by seasons.
    #
    # This page displays mini calendars for all 12 months grouped into seasons:
    #   - Left column: Winter (Jan, Feb) + Spring (Mar, Apr, May, Jun)
    #   - Right column: Summer (Jul, Aug) + Fall (Sep, Oct, Nov) + Winter (Dec)
    #
    # Features:
    #   - Grid-based layout with fieldset borders for each season
    #   - Mini calendars with clickable dates that link to weekly pages
    #   - Week sidebar with navigation
    #   - Right sidebar with links to year overview pages
    #
    # Example:
    #   page = SeasonalCalendar.new(pdf, { year: 2025 })
    #   page.generate
    class SeasonalCalendar < Base
      include Styling::Colors
      include Styling::Grid

      MONTH_NAMES = %w[
        January February March April May June
        July August September October November December
      ]

      def setup
        set_destination('seasonal')
        @year = context[:year]
        @total_weeks = Utilities::DateCalculator.total_weeks(@year)

        use_layout :standard_with_sidebars,
          current_week: nil,              # No week highlighting
          highlight_tab: :seasonal,       # Highlight "Year" tab
          year: @year,
          total_weeks: @total_weeks
      end

      def render
        draw_dot_grid
        # draw_diagnostic_grid(label_every: 5)
        # Sidebars rendered automatically by layout!
        draw_header
        draw_seasons
      end

      private

      def draw_header
        # Header: rows 0-1 (2 boxes), full width
        header = @grid_system.rect(0, 0, COLS, 2)
        @pdf.font "Helvetica-Bold", size: 18
        @pdf.fill_color Styling::Colors.TEXT_BLACK
        @pdf.text_box "Year #{@year}",
                      at: [header[:x], header[:y]],
                      width: header[:width],
                      height: header[:height],
                      align: :center,
                      valign: :center
      end

      def draw_seasons
        # Season layout: 2-column layout with label space on left
        label_offset = 2  # Reserve 2 boxes on left for seasonal labels
        half_width = (COLS - label_offset) / 2

        # Left column (6 months total)
        # Winter (Jan, Feb): top-left
        winter_left_row = 2
        draw_season_grid({ name: "Winter", months: [1, 2] }, label_offset, winter_left_row, half_width)

        # Spring (Mar, Apr, May, Jun): below Winter on left
        spring_left_row = winter_left_row + calculate_season_height(2)
        draw_season_grid({ name: "Spring", months: [3, 4, 5, 6] }, label_offset, spring_left_row, half_width)

        # Right column (6 months total)
        # Summer (Jul, Aug): top-right
        summer_row = 2
        draw_season_grid({ name: "Summer", months: [7, 8] }, label_offset + half_width, summer_row, half_width)

        # Fall (Sep, Oct, Nov): below Summer
        fall_row = summer_row + calculate_season_height(2)
        draw_season_grid({ name: "Fall", months: [9, 10, 11] }, label_offset + half_width, fall_row, half_width)

        # Winter (Dec): below Fall
        winter_right_row = fall_row + calculate_season_height(3)
        draw_season_grid({ name: "Winter", months: [12] }, label_offset + half_width, winter_right_row, half_width)
      end

      def calculate_season_height(num_months)
        # Each month needs: 1 box for title + 1 box for day headers + 6 boxes for calendar rows = 8
        # Plus 1 box spacing after each month
        (num_months * 8) + (num_months * 1)
      end

      def draw_season_grid(season, start_col, start_row, width_boxes)
        # Calculate season height
        height_boxes = calculate_season_height(season[:months].length)

        # Draw fieldset with legend on top edge
        draw_fieldset(start_col, start_row, width_boxes, height_boxes, season[:name])

        # Draw months in the content area
        current_row = start_row
        season[:months].each do |month|
          draw_month_grid(month, start_col, current_row, width_boxes)
          current_row += 8  # 1 title + 1 headers + 6 calendar rows
          current_row += 1  # 1 box gutter after each month
        end
      end

      def draw_fieldset(start_col, start_row, width_boxes, height_boxes, legend)
        # Draw box border
        box(start_col, start_row, width_boxes, height_boxes,
            stroke: Styling::Colors.BORDERS, fill: nil)

        # Draw season label with superscript positioning (centered on top border)
        h1(start_col + 1, start_row, legend,
           position: :superscript,
           color: Styling::Colors.BORDERS)
      end

      def draw_month_grid(month, start_col, start_row, width_boxes)
        # Month title (1 box high)
        title_box = @grid_system.rect(start_col, start_row, width_boxes, 1)
        @pdf.font "Helvetica-Bold", size: 10
        @pdf.fill_color Styling::Colors.TEXT_BLACK
        @pdf.text_box MONTH_NAMES[month - 1],
                      at: [title_box[:x], title_box[:y]],
                      width: title_box[:width],
                      height: title_box[:height],
                      align: :center,
                      valign: :center

        # Day headers (1 box high): M T W T F S S
        headers_row = start_row + 1
        day_names = ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        col_width_boxes = width_boxes / 7.0

        day_names.each_with_index do |day, i|
          col_x = @grid_system.x(start_col) + (i * @grid_system.width(col_width_boxes))
          @pdf.font "Helvetica", size: 7
          @pdf.fill_color Styling::Colors.TEXT_BLACK
          @pdf.text_box day,
                        at: [col_x, @grid_system.y(headers_row)],
                        width: @grid_system.width(col_width_boxes),
                        height: @grid_system.height(1),
                        align: :center,
                        valign: :center
        end

        # Calendar days (6 rows of 1 box each)
        first_day = Date.new(@year, month, 1)
        last_day = Date.new(@year, month, -1)
        days_in_month = last_day.day
        start_wday = first_day.wday
        start_col_offset = (start_wday + 6) % 7  # Convert to Monday-based

        @pdf.font "Helvetica", size: 7
        row = 0
        col = start_col_offset

        # First pass: Draw weekend backgrounds
        1.upto(days_in_month) do |day|
          date = Date.new(@year, month, day)

          # Calculate position
          temp_row = (start_col_offset + day - 1) / 7
          temp_col = (start_col_offset + day - 1) % 7

          # Only draw background for weekends (columns 5 and 6 = Saturday and Sunday)
          if date.saturday? || date.sunday?
            cal_row = headers_row + 1 + temp_row
            cell_x = @grid_system.x(start_col) + (temp_col * @grid_system.width(col_width_boxes))
            cell_y = @grid_system.y(cal_row)
            cell_width = @grid_system.width(col_width_boxes)
            cell_height = @grid_system.height(1)

            # Draw weekend background with 10% opacity (matching WeekColumn pattern)
            @pdf.fill_color Styling::Colors.WEEKEND_BG
            @pdf.transparent(0.1) do
              @pdf.fill_rectangle [cell_x, cell_y], cell_width, cell_height
            end
            @pdf.fill_color Styling::Colors.TEXT_BLACK
          end
        end

        # Second pass: Draw day numbers and links
        @pdf.fill_color Styling::Colors.TEXT_BLACK
        1.upto(days_in_month) do |day|
          date = Date.new(@year, month, day)
          week_num = Utilities::DateCalculator.week_number_for_date(@year, date)

          cal_row = headers_row + 1 + row
          cell_x = @grid_system.x(start_col) + (col * @grid_system.width(col_width_boxes))
          cell_y = @grid_system.y(cal_row)

          @pdf.text_box day.to_s,
                        at: [cell_x, cell_y],
                        width: @grid_system.width(col_width_boxes),
                        height: @grid_system.height(1),
                        align: :center,
                        valign: :center

          # Add clickable link
          link_bottom = cell_y - @grid_system.height(1)
          @pdf.link_annotation([cell_x, link_bottom, cell_x + @grid_system.width(col_width_boxes), cell_y],
                              Dest: "week_#{week_num}",
                              Border: [0, 0, 0])

          col += 1
          if col >= 7
            col = 0
            row += 1
          end
        end
      end

    end
  end
end
