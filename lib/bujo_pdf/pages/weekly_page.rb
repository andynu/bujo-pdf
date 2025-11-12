# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/date_calculator'
require_relative '../sub_components/week_column'

module BujoPdf
  module Pages
    # Weekly page with daily section and Cornell notes.
    #
    # This page shows a full week (Monday-Sunday) with:
    #   - Top navigation: Year link, previous/next week links, week title
    #   - Daily section: 7 columns with headers and ruled lines
    #   - Cornell notes section: Cues column (25%), Notes column (75%), Summary (20%)
    #
    # Layout (grid-based):
    #   - Rows 0-1: Navigation and title (2 boxes)
    #   - Rows 2-10: Daily section (9 boxes, ~17% of content)
    #   - Rows 11-45: Cornell cues/notes (35 boxes)
    #   - Rows 46-54: Summary (9 boxes)
    #
    # Example:
    #   context = {
    #     year: 2025,
    #     week_num: 42,
    #     week_start: Date.new(2025, 10, 13),
    #     week_end: Date.new(2025, 10, 19)
    #   }
    #   page = WeeklyPage.new(pdf, context)
    #   page.generate
    class WeeklyPage < Base
      # Constants
      GRID_COLS = 43
      DOT_SPACING = 14.17
      COLOR_BORDERS = 'E5E5E5'
      COLOR_SECTION_HEADERS = 'AAAAAA'
      COLOR_WEEKEND_BG = 'FAFAFA'

      # Weekly page layout constants
      WEEKLY_TITLE_FONT_SIZE = 14
      WEEKLY_DAY_HEADER_FONT_SIZE = 9
      WEEKLY_DAY_DATE_FONT_SIZE = 8
      WEEKLY_DAY_HEADER_HEIGHT = 30
      WEEKLY_DAY_HEADER_PADDING = 2
      WEEKLY_DAY_LINES_START = 35
      WEEKLY_DAY_LINES_PADDING = 40
      WEEKLY_DAY_LINES_COUNT = 4.0
      WEEKLY_DAY_LINE_MARGIN = 3
      WEEKLY_NOTES_HEADER_FONT_SIZE = 10
      WEEKLY_NOTES_LABEL_FONT_SIZE = 8
      WEEKLY_NOTES_HEADER_PADDING = 5
      FOOTER_FONT_SIZE = 8

      def setup
        @week_num = context[:week_num]
        @week_start = context[:week_start]
        @week_end = context[:week_end]
        @year = context[:year]
        @total_weeks = Utilities::DateCalculator.total_weeks(@year)

        set_destination("week_#{@week_num}")
      end

      def render
        draw_dot_grid
        draw_diagnostic_grid(label_every: 5)
        draw_navigation
        draw_daily_section
        draw_cornell_notes
      end

      private

      def draw_navigation
        # Content area dimensions
        content_start_col = 3
        content_width_boxes = 39

        nav_box = @grid_system.rect(content_start_col, 0, content_width_boxes, 2)

        # Year link on the left
        @pdf.font "Helvetica", size: FOOTER_FONT_SIZE
        @pdf.fill_color '888888'
        nav_year_width = @grid_system.width(4)
        @pdf.text_box "< #{@year}",
                      at: [nav_box[:x], nav_box[:y]],
                      width: nav_year_width,
                      height: nav_box[:height],
                      valign: :center
        @pdf.fill_color '000000'
        @pdf.link_annotation([nav_box[:x], nav_box[:y] - nav_box[:height],
                              nav_box[:x] + nav_year_width, nav_box[:y]],
                            Dest: "seasonal",
                            Border: [0, 0, 0])

        # Previous week link (if not first week)
        if @week_num > 1
          @pdf.fill_color '888888'
          nav_prev_x = nav_box[:x] + nav_year_width + @grid_system.width(1)
          nav_prev_width = @grid_system.width(3)
          @pdf.text_box "< w#{@week_num - 1}",
                        at: [nav_prev_x, nav_box[:y]],
                        width: nav_prev_width,
                        height: nav_box[:height],
                        valign: :center
          @pdf.fill_color '000000'
          @pdf.link_annotation([nav_prev_x, nav_box[:y] - nav_box[:height],
                                nav_prev_x + nav_prev_width, nav_box[:y]],
                              Dest: "week_#{@week_num - 1}",
                              Border: [0, 0, 0])
        end

        # Next week link (if not last week)
        if @week_num < @total_weeks
          nav_next_width = @grid_system.width(3)
          nav_next_x = nav_box[:x] + nav_box[:width] - nav_next_width
          @pdf.fill_color '888888'
          @pdf.text_box "w#{@week_num + 1} >",
                        at: [nav_next_x, nav_box[:y]],
                        width: nav_next_width,
                        height: nav_box[:height],
                        align: :right,
                        valign: :center
          @pdf.fill_color '000000'
          @pdf.link_annotation([nav_next_x, nav_box[:y] - nav_box[:height],
                                nav_next_x + nav_next_width, nav_box[:y]],
                              Dest: "week_#{@week_num + 1}",
                              Border: [0, 0, 0])
        end

        # Title (centered)
        @pdf.font "Helvetica-Bold", size: WEEKLY_TITLE_FONT_SIZE
        title_x = nav_box[:x] + @grid_system.width(8)
        title_width = nav_box[:width] - @grid_system.width(16)
        @pdf.text_box "Week #{@week_num}: #{@week_start.strftime('%b %-d')} - #{@week_end.strftime('%b %-d, %Y')}",
                      at: [title_x, nav_box[:y]],
                      width: title_width,
                      height: nav_box[:height],
                      align: :center,
                      valign: :center
      end

      def draw_daily_section
        content_start_col = 3
        content_start_row = 2
        content_width_boxes = 39
        daily_rows = 9
        day_col_width_boxes = content_width_boxes / 7.0  # ~5.57 boxes per day

        7.times do |i|
          date = @week_start + i
          day_name = date.strftime('%A')
          is_weekend = (i == 5 || i == 6)  # Saturday and Sunday

          # Create and render week column component
          column = SubComponent::WeekColumn.new(@pdf, @grid_system,
            date: date,
            day_name: day_name,
            weekend: is_weekend,
            show_time_labels: (i == 0),  # Show time labels on Monday only
            line_count: WEEKLY_DAY_LINES_COUNT.to_i,
            header_height: WEEKLY_DAY_HEADER_HEIGHT,
            header_padding: WEEKLY_DAY_HEADER_PADDING,
            lines_start: WEEKLY_DAY_LINES_START,
            lines_padding: WEEKLY_DAY_LINES_PADDING,
            line_margin: WEEKLY_DAY_LINE_MARGIN,
            day_header_font_size: WEEKLY_DAY_HEADER_FONT_SIZE,
            day_date_font_size: WEEKLY_DAY_DATE_FONT_SIZE
          )

          # Render at column position
          col = content_start_col + (i * day_col_width_boxes)
          column.render_at(col, content_start_row, day_col_width_boxes, daily_rows)
        end
      end

      def draw_cornell_notes
        content_start_col = 3
        content_start_row = 2
        content_width_boxes = 39
        daily_rows = 9
        notes_main_rows = 35
        summary_rows = 9
        cues_cols = 10
        notes_cols = 29

        notes_start_row = content_start_row + daily_rows
        cues_box = @grid_system.rect(content_start_col, notes_start_row, cues_cols, notes_main_rows)
        notes_box = @grid_system.rect(content_start_col + cues_cols, notes_start_row, notes_cols, notes_main_rows)
        summary_box = @grid_system.rect(content_start_col, notes_start_row + notes_main_rows, content_width_boxes, summary_rows)

        @pdf.font "Helvetica-Bold", size: WEEKLY_NOTES_HEADER_FONT_SIZE

        # Cues column
        @pdf.bounding_box([cues_box[:x], cues_box[:y]],
                         width: cues_box[:width],
                         height: cues_box[:height]) do
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'
          @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
          @pdf.fill_color COLOR_SECTION_HEADERS
          @pdf.text "Cues/Questions", align: :center, size: WEEKLY_NOTES_LABEL_FONT_SIZE
          @pdf.fill_color '000000'
        end

        # Notes column
        @pdf.bounding_box([notes_box[:x], notes_box[:y]],
                         width: notes_box[:width],
                         height: notes_box[:height]) do
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'
          @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
          @pdf.fill_color COLOR_SECTION_HEADERS
          @pdf.text "Notes", align: :center, size: WEEKLY_NOTES_LABEL_FONT_SIZE
          @pdf.fill_color '000000'
        end

        # Summary section
        @pdf.bounding_box([summary_box[:x], summary_box[:y]],
                         width: summary_box[:width],
                         height: summary_box[:height]) do
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'
          @pdf.font "Helvetica-Bold", size: WEEKLY_NOTES_LABEL_FONT_SIZE
          @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
          @pdf.fill_color COLOR_SECTION_HEADERS
          @pdf.text "Summary", align: :center
          @pdf.fill_color '000000'
        end
      end
    end
  end
end
