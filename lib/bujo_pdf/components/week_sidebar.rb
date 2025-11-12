# frozen_string_literal: true

require_relative '../component'
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
    #   - Columns 0-1 (2 boxes wide)
    #   - Starts at row 2
    #   - One week per row
    #   - Internal padding: 0.5 boxes on each side
    #
    # Example usage:
    #   sidebar = WeekSidebar.new(pdf, grid_system,
    #     year: 2025,
    #     total_weeks: 52,
    #     current_week_num: 42  # Optional: highlights this week
    #   )
    #   sidebar.render
    class WeekSidebar < Component
      SIDEBAR_WIDTH_BOXES = 2
      SIDEBAR_START_ROW = 2
      PADDING_BOXES = 0.3
      FONT_SIZE = 8
      NAV_COLOR = '888888'

      def initialize(pdf, grid_system, **options)
        super
        validate_options
      end

      def render
        # Build week-to-month abbreviation mapping once
        @week_months = Utilities::DateCalculator.week_to_month_abbrev_map(context[:year], char: 1)

        @pdf.font "Helvetica", size: FONT_SIZE

        context[:total_weeks].times do |i|
          week = i + 1
          row = SIDEBAR_START_ROW + i
          draw_week_entry(week, row)
        end
      end

      private

      def validate_options
        required_keys = [:year, :total_weeks]
        missing_keys = required_keys - context.keys

        unless missing_keys.empty?
          raise ArgumentError, "WeekSidebar requires: #{missing_keys.join(', ')}"
        end
      end

      def draw_week_entry(week, row)
        week_box = @grid.rect(0, row, SIDEBAR_WIDTH_BOXES, 1)

        # Get month abbreviation if this is the first week of a month
        month_abbrev = @week_months[week]
        # Zero-padded week number
        week_text = format("w%02d", week)

        if current_week?(week)
          draw_current_week(week_box, month_abbrev, week_text)
        else
          draw_linked_week(week_box, month_abbrev, week_text, week)
        end
      end

      def current_week?(week)
        # Use RenderContext's current_page? method if available
        # Falls back to legacy current_week_num check for backward compatibility
        if context.respond_to?(:current_page?)
          context.current_page?("week_#{week}".to_sym)
        else
          context[:current_week_num] && context[:current_week_num] == week
        end
      end

      def draw_current_week(week_box, month_abbrev, week_text)
        # Current week: both parts bold and black, no link
        @pdf.fill_color '000000'
        @pdf.font "Helvetica-Bold", size: FONT_SIZE

        if month_abbrev
          # Render as combined text, right-aligned, both parts bold
          display_text = "#{month_abbrev} #{week_text}"
          @pdf.text_box display_text,
                        at: [week_box[:x] + @grid.width(PADDING_BOXES), week_box[:y]],
                        width: week_box[:width] - @grid.width(PADDING_BOXES * 2),
                        height: week_box[:height],
                        align: :right,
                        valign: :center
        else
          # Just week number, bold and black
          @pdf.text_box week_text,
                        at: [week_box[:x] + @grid.width(PADDING_BOXES), week_box[:y]],
                        width: week_box[:width] - @grid.width(PADDING_BOXES * 2),
                        height: week_box[:height],
                        align: :right,
                        valign: :center
        end

        @pdf.font "Helvetica", size: FONT_SIZE
      end

      def draw_linked_week(week_box, month_abbrev, week_text, week)
        # Other weeks: gray, with link
        @pdf.fill_color NAV_COLOR

        if month_abbrev
          # Month abbreviation is bold, week number is regular weight
          # Render as two overlapping text boxes with careful width management

          # Calculate widths with proper font context
          @pdf.font "Helvetica", size: FONT_SIZE
          week_width = @pdf.width_of(week_text, size: FONT_SIZE) + 2  # Add small buffer

          @pdf.font "Helvetica-Bold", size: FONT_SIZE
          month_width = @pdf.width_of("#{month_abbrev} ", size: FONT_SIZE) + 2  # Add small buffer

          # Calculate total width needed
          total_width = month_width + week_width
          available_width = week_box[:width] - @grid.width(PADDING_BOXES * 2)

          # Right-align the entire text block
          text_start_x = week_box[:x] + week_box[:width] - @grid.width(PADDING_BOXES) - total_width

          # Render month abbreviation (bold)
          @pdf.font "Helvetica-Bold", size: FONT_SIZE
          @pdf.text_box "#{month_abbrev} ",
                        at: [text_start_x, week_box[:y]],
                        width: month_width,
                        height: week_box[:height],
                        align: :left,
                        valign: :center,
                        overflow: :shrink_to_fit

          # Render week number (regular weight)
          @pdf.font "Helvetica", size: FONT_SIZE
          @pdf.text_box week_text,
                        at: [text_start_x + month_width, week_box[:y]],
                        width: week_width,
                        height: week_box[:height],
                        align: :left,
                        valign: :center,
                        overflow: :shrink_to_fit
        else
          # Just week number, regular weight
          @pdf.text_box week_text,
                        at: [week_box[:x] + @grid.width(PADDING_BOXES), week_box[:y]],
                        width: week_box[:width] - @grid.width(PADDING_BOXES * 2),
                        height: week_box[:height],
                        align: :right,
                        valign: :center
        end

        # Link annotation rect: [left, bottom, right, top]
        link_left = week_box[:x]
        link_bottom = week_box[:y] - week_box[:height]
        link_right = week_box[:x] + week_box[:width]
        link_top = week_box[:y]

        @pdf.link_annotation([link_left, link_bottom, link_right, link_top],
                            Dest: "week_#{week}",
                            Border: [0, 0, 0])

        @pdf.fill_color '000000'
      end
    end
  end
end
