# frozen_string_literal: true

require_relative 'standard_layout_page'
require_relative '../utilities/date_calculator'
require_relative '../utilities/styling'
require_relative '../components/top_navigation'
require_relative '../components/daily_section'
require_relative '../components/cornell_notes'

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
    class WeeklyPage < StandardLayoutPage
      include Styling::Colors
      include Styling::Grid

      # Mixin providing weekly_page and weekly_pages verbs for document builders.
      module Mixin
        include MixinSupport

        # Generate a single weekly page.
        #
        # @param week [Integer] Week number (1-53)
        # @return [void]
        def weekly_page(week:)
          start_new_page
          week_start = Utilities::DateCalculator.week_start(@year, week)
          week_end = Utilities::DateCalculator.week_end(@year, week)
          context = build_context(
            page_key: "week_#{week}".to_sym,
            week_num: week,
            week_start: week_start,
            week_end: week_end
          )
          WeeklyPage.new(@pdf, context).generate
        end

        # Generate all weekly pages for the year.
        #
        # @return [void]
        def weekly_pages
          total_weeks.times do |i|
            weekly_page(week: i + 1)
          end
        end
      end

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
        @total_weeks = context[:total_weeks] || Utilities::DateCalculator.total_weeks(@year)

        set_destination("week_#{@week_num}")

        # Use StandardLayoutPage setup
        super
      end

      def render
        draw_dot_grid
        # draw_diagnostic_grid(label_every: 5)
        # Sidebars rendered automatically by layout!
        draw_navigation
        draw_daily_section
        draw_cornell_notes
      end

      protected

      # Highlight this week in sidebar
      def current_week
        @week_num
      end

      # Weekly pages don't highlight tabs
      def highlight_tab
        nil
      end

      private

      def draw_navigation
        # Use TopNavigation component
        nav = Components::TopNavigation.new(@pdf, @grid_system,
          year: @year,
          week_num: @week_num,
          total_weeks: @total_weeks,
          week_start: @week_start,
          week_end: @week_end,
          content_start_col: 2,
          content_width_boxes: 40
        )
        nav.render
      end

      def draw_daily_section
        # Use DailySection component
        section = Components::DailySection.new(@pdf, @grid_system,
          week_start: @week_start,
          content_start_col: 2,
          content_start_row: 2,
          content_width_boxes: 40,
          daily_rows: 9,
          line_count: WEEKLY_DAY_LINES_COUNT.to_i,
          header_height: WEEKLY_DAY_HEADER_HEIGHT,
          header_padding: WEEKLY_DAY_HEADER_PADDING,
          lines_start: WEEKLY_DAY_LINES_START,
          lines_padding: WEEKLY_DAY_LINES_PADDING,
          line_margin: WEEKLY_DAY_LINE_MARGIN,
          day_header_font_size: WEEKLY_DAY_HEADER_FONT_SIZE,
          day_date_font_size: WEEKLY_DAY_DATE_FONT_SIZE,
          date_config: context.date_config
        )
        section.render
      end

      def draw_cornell_notes
        # Use CornellNotes component
        notes = Components::CornellNotes.new(@pdf, @grid_system,
          content_start_col: 2,
          notes_start_row: 11,  # After daily section (rows 2-10)
          cues_cols: 10,
          notes_cols: 30,
          notes_main_rows: 35,
          summary_rows: 9
        )
        notes.render
      end
    end
  end
end
