# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/date_calculator'
require_relative '../components/top_navigation'
require_relative '../components/daily_section'
require_relative '../components/cornell_notes'
require_relative '../components/week_sidebar'
require_relative '../components/right_sidebar'

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
        draw_week_sidebar
        draw_right_sidebar
        draw_navigation
        draw_daily_section
        draw_cornell_notes
      end

      private

      def draw_navigation
        # Use TopNavigation component
        nav = Components::TopNavigation.new(@pdf, @grid_system,
          year: @year,
          week_num: @week_num,
          total_weeks: @total_weeks,
          week_start: @week_start,
          week_end: @week_end
        )
        nav.render
      end

      def draw_daily_section
        # Use DailySection component
        section = Components::DailySection.new(@pdf, @grid_system,
          week_start: @week_start,
          content_start_col: 3,
          content_start_row: 2,
          content_width_boxes: 39,
          daily_rows: 9,
          line_count: WEEKLY_DAY_LINES_COUNT.to_i,
          header_height: WEEKLY_DAY_HEADER_HEIGHT,
          header_padding: WEEKLY_DAY_HEADER_PADDING,
          lines_start: WEEKLY_DAY_LINES_START,
          lines_padding: WEEKLY_DAY_LINES_PADDING,
          line_margin: WEEKLY_DAY_LINE_MARGIN,
          day_header_font_size: WEEKLY_DAY_HEADER_FONT_SIZE,
          day_date_font_size: WEEKLY_DAY_DATE_FONT_SIZE
        )
        section.render
      end

      def draw_cornell_notes
        # Use CornellNotes component
        notes = Components::CornellNotes.new(@pdf, @grid_system,
          content_start_col: 3,
          notes_start_row: 11,  # After daily section (rows 2-10)
          cues_cols: 10,
          notes_cols: 29,
          notes_main_rows: 35,
          summary_rows: 9
        )
        notes.render
      end

      def draw_week_sidebar
        # Use WeekSidebar component
        sidebar = Components::WeekSidebar.new(@pdf, @grid_system,
          year: @year,
          total_weeks: @total_weeks,
          current_week_num: @week_num
        )
        sidebar.render
      end

      def draw_right_sidebar
        # Use RightSidebar component
        sidebar = Components::RightSidebar.new(@pdf, @grid_system,
          top_tabs: [
            { label: "Year", dest: "seasonal" },
            { label: "Events", dest: "year_events" },
            { label: "Highlights", dest: "year_highlights" }
          ],
          bottom_tabs: [
            { label: "Dots", dest: "dots" }
          ]
        )
        sidebar.render
      end
    end
  end
end
