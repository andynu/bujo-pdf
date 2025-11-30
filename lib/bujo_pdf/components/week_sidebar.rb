# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/date_calculator'

module BujoPdf
  module Components
    # WeekSidebar component for left sidebar with week list.
    #
    # Renders a vertical list of all weeks in the year with:
    #   - Month letters for weeks where a new month starts
    #   - Week numbers (w1, w2, etc.)
    #   - Current week highlighted in bold (if specified)
    #   - Clickable links to all other weeks
    #   - Gray color for non-current weeks
    #
    # Grid positioning:
    #   - Columns 0.25-2.25 (2 boxes wide, inset 0.25 from left edge)
    #   - Starts at row 2
    #   - One week per row
    #   - Internal padding: 0.3 boxes on each side
    #
    # Example usage:
    #   canvas = Canvas.new(pdf, grid)
    #   sidebar = WeekSidebar.new(
    #     canvas: canvas,
    #     year: 2025,
    #     total_weeks: 52,
    #     current_week_num: 42  # Optional: highlights this week
    #   )
    #   sidebar.render
    class WeekSidebar < Component
      SIDEBAR_START_COL = 0.25
      SIDEBAR_WIDTH_BOXES = 2
      SIDEBAR_START_ROW = 2
      PADDING_BOXES = 0.3
      FONT_SIZE = 6
      NAV_COLOR = '888888'

      def initialize(canvas:, year:, total_weeks:, current_week_num: nil, page_context: nil)
        super(canvas: canvas)
        @year = year
        @total_weeks = total_weeks
        @current_week_num = current_week_num
        @page_context = page_context
      end

      def render
        # Build week-to-month abbreviation mapping once
        @week_months = Utilities::DateCalculator.week_to_month_abbrev_map(@year, char: 1)

        pdf.font "Helvetica", size: FONT_SIZE

        @total_weeks.times do |i|
          week = i + 1
          row = SIDEBAR_START_ROW + i
          draw_week_entry(week, row)
        end
      end

      private

      def draw_week_entry(week, row)
        week_box = grid.rect(SIDEBAR_START_COL, row, SIDEBAR_WIDTH_BOXES, 1)

        # Get month abbreviation if this is the first week of a month
        month_abbrev = @week_months[week]
        # Zero-padded week number
        week_text = format("w%02d", week)

        # Draw background rectangle first (behind text)
        draw_week_background(week_box, current_week?(week))

        if current_week?(week)
          draw_current_week(week_box, month_abbrev, week_text)
        else
          draw_linked_week(week_box, month_abbrev, week_text, week)
        end
      end

      def current_week?(week)
        # Use page_context's current_page? method if available
        # Falls back to legacy current_week_num check for backward compatibility
        if @page_context&.respond_to?(:current_page?)
          @page_context.current_page?("week_#{week}".to_sym)
        else
          @current_week_num && @current_week_num == week
        end
      end

      def draw_week_background(week_box, is_current)
        # Get the border color from the theme
        require_relative '../themes/theme_registry'
        border_color = BujoPdf::Themes.current[:colors][:borders]

        # Calculate rectangle coordinates with 2px gaps (top/bottom and right)
        # Sidebar goes 0.25-2.25 boxes, content starts at 2.0 boxes
        # So we need to stop at 2.0 boxes minus 2px gap = 0.25 boxes overlap + 2px
        gap_vertical = 2
        gap_right = grid.width(0.25) + 2  # 0.25 box overlap + 2px visual gap

        left = week_box[:x]
        width = week_box[:width] - gap_right  # Reduce width to stop before content area
        height = week_box[:height] - gap_vertical  # Reduce height for vertical gap
        top = week_box[:y] - (gap_vertical / 2.0)  # Center the reduced height

        if is_current
          # Current week: stroked rectangle with border color
          pdf.stroke_color border_color
          pdf.stroke_rounded_rectangle([left, top], width, height, 2)
        else
          # Other weeks: filled rectangle with 20% opacity
          pdf.transparent(0.2) do
            pdf.fill_color border_color
            pdf.fill_rounded_rectangle([left, top], width, height, 2)
          end
        end

        # Reset colors to theme defaults (not hardcoded black)
        text_color = BujoPdf::Themes.current[:colors][:text_black]
        pdf.fill_color text_color
        pdf.stroke_color text_color
      end

      def draw_current_week(week_box, month_abbrev, week_text)
        # Current week: both parts bold, theme text color, no link
        # Shift text box 5px left to keep text within beveled rectangle
        # Use standard padding calculation but adjust starting position
        text_x = week_box[:x] + grid.width(PADDING_BOXES) - 5
        text_width = week_box[:width] - grid.width(PADDING_BOXES * 2)

        # Use theme text color for current week
        require_relative '../themes/theme_registry'
        text_color = BujoPdf::Themes.current[:colors][:text_black]

        with_font("Helvetica-Bold", FONT_SIZE) do
          with_fill_color(text_color) do
            if month_abbrev
              # Render as combined text, right-aligned, both parts bold
              display_text = "#{month_abbrev} #{week_text}"
              pdf.text_box display_text,
                            at: [text_x, week_box[:y]],
                            width: text_width,
                            height: week_box[:height],
                            align: :right,
                            valign: :center,
                            overflow: :shrink_to_fit
            else
              # Just week number, bold
              pdf.text_box week_text,
                            at: [text_x, week_box[:y]],
                            width: text_width,
                            height: week_box[:height],
                            align: :right,
                            valign: :center,
                            overflow: :shrink_to_fit
            end
          end
        end
      end

      def draw_linked_week(week_box, month_abbrev, week_text, week)
        # Other weeks: gray text with link
        # Shift text box 5px left to keep text within beveled rectangle
        # Use standard padding calculation but adjust starting position
        text_x = week_box[:x] + grid.width(PADDING_BOXES) - 5
        text_width = week_box[:width] - grid.width(PADDING_BOXES * 2)

        # Use theme gray color for non-current weeks
        require_relative '../themes/theme_registry'
        nav_color = BujoPdf::Themes.current[:colors][:text_gray]

        with_fill_color(nav_color) do
          if month_abbrev
            # Month abbreviation is bold, week number is regular weight
            # Use formatted_text_box for consistent right-alignment
            pdf.formatted_text_box [
              { text: "#{month_abbrev} ", styles: [:bold], size: FONT_SIZE, color: nav_color },
              { text: week_text, size: FONT_SIZE, color: nav_color }
            ],
                          at: [text_x, week_box[:y]],
                          width: text_width,
                          height: week_box[:height],
                          align: :right,
                          valign: :center,
                          overflow: :shrink_to_fit
          else
            # Just week number, regular weight
            pdf.text_box week_text,
                          at: [text_x, week_box[:y]],
                          width: text_width,
                          height: week_box[:height],
                          align: :right,
                          valign: :center,
                          overflow: :shrink_to_fit
          end

          # Link annotation rect: [left, bottom, right, top]
          link_left = week_box[:x]
          link_bottom = week_box[:y] - week_box[:height]
          link_right = week_box[:x] + week_box[:width]
          link_top = week_box[:y]

          pdf.link_annotation([link_left, link_bottom, link_right, link_top],
                              Dest: "week_#{week}",
                              Border: [0, 0, 0])
        end
      end
    end
  end
end
