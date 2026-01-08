# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/styling'

module BujoPdf
  module Pages
    # Monthly overview page showing a single month at a glance with notes area.
    #
    # This page displays a month header, mini calendar, and ruled lines for
    # notes/planning. It uses full_page layout to avoid sidebar complexity.
    #
    # Features:
    # - Month name header
    # - Mini calendar for the month
    # - Ruled lines for notes/planning
    #
    # Example:
    #   page = MonthlyOverview.new(pdf, { month: 1, year: 2025 })
    #   page.generate
    class MonthlyOverview < Base
      include Styling::Colors
      include Styling::Grid

      register_page :monthly_overview,
        title: "%{month_name} Overview",
        dest: "month_%{month}"

      def setup
        @month = context[:month]
        @year = context[:year]
        @month_name = Date::MONTHNAMES[@month]

        set_destination("month_#{@month}")
        use_layout :full_page
      end

      def render
        draw_dot_grid
        draw_header
        draw_calendar
        draw_notes_area
      end

      private

      def draw_header
        # Header with month name centered
        h1(0, 2, "#{@month_name} #{@year}", width: COLS, align: :center)
      end

      def draw_calendar
        # Mini calendar positioned below header
        # Using 21 boxes width for the calendar, centered
        calendar_width = 21
        calendar_col = (COLS - calendar_width) / 2
        mini_month(calendar_col, 5, calendar_width, month: @month, year: @year, show_links: true)
      end

      def draw_notes_area
        # Notes section below the calendar
        # Calendar takes ~8 rows (see MiniMonth::HEIGHT_BOXES), starting at row 5
        # So notes start around row 14
        notes_start_row = 14
        notes_col = 2
        notes_width = COLS - 4  # 2-box margin on each side

        h2(notes_col, notes_start_row, "Notes & Plans", width: notes_width)
        ruled_lines(notes_col, notes_start_row + 2, notes_width, 38)
      end
    end
  end
end
