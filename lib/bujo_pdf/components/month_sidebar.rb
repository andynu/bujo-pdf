# frozen_string_literal: true

require_relative '../base/component'

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
    class MonthSidebar < Component
      SIDEBAR_START_COL = 0.25
      SIDEBAR_WIDTH_BOXES = 2
      SIDEBAR_START_ROW = 2
      PADDING_BOXES = 0.3
      FONT_SIZE = 7
      MONTH_ABBREVS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

      # Height per month entry in rows (52 rows available / 12 months ≈ 4.3)
      ROWS_PER_MONTH = 4.0

      def initialize(canvas:, year:, current_month: nil, page_context: nil)
        super(canvas: canvas)
        @year = year
        @current_month = current_month
        @page_context = page_context
      end

      def render
        pdf.font "Helvetica", size: FONT_SIZE

        12.times do |i|
          month = i + 1
          row = SIDEBAR_START_ROW + (i * ROWS_PER_MONTH)
          draw_month_entry(month, row)
        end
      end

      private

      def draw_month_entry(month, row)
        month_box = grid.rect(SIDEBAR_START_COL, row, SIDEBAR_WIDTH_BOXES, ROWS_PER_MONTH)

        month_abbrev = MONTH_ABBREVS[month - 1]
        is_current = current_month?(month)

        draw_month_background(month_box, is_current)

        if is_current
          draw_current_month(month_box, month_abbrev)
        else
          draw_linked_month(month_box, month_abbrev, month)
        end
      end

      def current_month?(month)
        # Check if current page is a day in this month
        if @page_context&.respond_to?(:page_key)
          page_key = @page_context.page_key.to_s
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

      def draw_month_background(month_box, is_current)
        require_relative '../themes/theme_registry'
        border_color = BujoPdf::Themes.current[:colors][:borders]

        gap_vertical = 2
        gap_right = grid.width(0.25) + 2

        left = month_box[:x]
        width = month_box[:width] - gap_right
        height = month_box[:height] - gap_vertical
        top = month_box[:y] - (gap_vertical / 2.0)

        if is_current
          pdf.stroke_color border_color
          pdf.stroke_rounded_rectangle([left, top], width, height, 2)
        else
          pdf.transparent(0.2) do
            pdf.fill_color border_color
            pdf.fill_rounded_rectangle([left, top], width, height, 2)
          end
        end

        text_color = BujoPdf::Themes.current[:colors][:text_black]
        pdf.fill_color text_color
        pdf.stroke_color text_color
      end

      def draw_current_month(month_box, month_abbrev)
        text_x = month_box[:x] + grid.width(PADDING_BOXES) - 5
        text_width = month_box[:width] - grid.width(PADDING_BOXES * 2)

        require_relative '../themes/theme_registry'
        text_color = BujoPdf::Themes.current[:colors][:text_black]

        with_font("Helvetica-Bold", FONT_SIZE) do
          with_fill_color(text_color) do
            pdf.text_box month_abbrev,
                         at: [text_x, month_box[:y]],
                         width: text_width,
                         height: month_box[:height],
                         align: :right,
                         valign: :center,
                         overflow: :shrink_to_fit
          end
        end
      end

      def draw_linked_month(month_box, month_abbrev, month)
        text_x = month_box[:x] + grid.width(PADDING_BOXES) - 5
        text_width = month_box[:width] - grid.width(PADDING_BOXES * 2)

        require_relative '../themes/theme_registry'
        nav_color = BujoPdf::Themes.current[:colors][:text_gray]

        with_fill_color(nav_color) do
          pdf.text_box month_abbrev,
                       at: [text_x, month_box[:y]],
                       width: text_width,
                       height: month_box[:height],
                       align: :right,
                       valign: :center,
                       overflow: :shrink_to_fit

          # Link to first day of month
          first_day = Date.new(@year, month, 1)
          dest = "day_#{first_day.strftime('%Y%m%d')}"

          link_left = month_box[:x]
          link_bottom = month_box[:y] - month_box[:height]
          link_right = month_box[:x] + month_box[:width]
          link_top = month_box[:y]

          pdf.link_annotation([link_left, link_bottom, link_right, link_top],
                              Dest: dest,
                              Border: [0, 0, 0])
        end
      end
    end
  end
end
