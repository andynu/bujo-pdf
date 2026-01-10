# frozen_string_literal: true

require_relative '../base/sidebar_base'
require_relative '../sidebars/sidebar_registry'

module BujoPdf
  module Components
    # MonthSidebar component for left sidebar with month list.
    #
    # Renders a vertical list of all months in the year with:
    #   - Month abbreviations (Jan, Feb, etc.)
    #   - Current month highlighted when viewing a day in that month
    #   - Clickable links to first day of each month
    #   - Gray color for non-current months
    #
    # Designed for daily planners where week navigation doesn't make sense.
    #
    # Grid positioning:
    #   - Columns 0.25-2.25 (2 boxes wide, inset 0.25 from left edge)
    #   - Starts at row 2
    #   - 12 months total, ~4 rows per month for visual spacing
    #
    # Example usage:
    #   canvas = Canvas.new(pdf, grid)
    #   sidebar = MonthSidebar.new(
    #     canvas: canvas,
    #     year: 2025,
    #     current_month: 3  # Optional: highlights March
    #   )
    #   sidebar.render
    class MonthSidebar < SidebarBase
      include Sidebars::SidebarRegistry
      register_sidebar :month_sidebar

      # Constants preserved for backward compatibility with tests
      SIDEBAR_START_COL = 0.25
      SIDEBAR_WIDTH_BOXES = 2
      SIDEBAR_START_ROW = 2
      PADDING_BOXES = 0.3
      FONT_SIZE = 7
      MONTH_ABBREVS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

      # Height per month entry in rows (52 rows available / 12 months ≈ 4.3)
      ROWS_PER_MONTH = 4.0

      def initialize(canvas:, year:, current_month: nil, page_context: nil)
        super(canvas: canvas, page_context: page_context, font_size: FONT_SIZE)
        @year = year
        @current_month = current_month
      end

      def render
        pdf.font "Helvetica", size: sidebar_font_size

        12.times do |i|
          month = i + 1
          row = sidebar_start_row + (i * ROWS_PER_MONTH)
          draw_month_entry(month, row)
        end
      end

      private

      def draw_month_entry(month, row)
        month_box = item_rect(row, ROWS_PER_MONTH)
        month_abbrev = MONTH_ABBREVS[month - 1]
        is_current = current_month?(month)

        # Use base class helper for background drawing
        draw_item_background(month_box, is_current)

        # Build destination for linked months
        first_day = Date.new(@year, month, 1)
        dest = "day_#{first_day.strftime('%Y%m%d')}"

        # Use base class helper for text + link
        draw_item_text(month_box, month_abbrev, is_current, dest: dest)
      end

      def current_month?(month)
        # Check if current page is a day in this month
        if page_context&.respond_to?(:page_key)
          page_key = page_context.page_key.to_s
          if page_key.start_with?('day_')
            # Extract date from day_YYYYMMDD format
            date_str = page_key.sub('day_', '')
            page_month = date_str[4, 2].to_i
            return page_month == month
          end
        end

        # Fallback to explicit current_month
        @current_month == month
      end
    end
  end
end
