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
      PADDING_BOXES = 0.5
      FONT_SIZE = 8
      NAV_COLOR = '888888'

      def initialize(pdf, grid_system, **options)
        super
        validate_options
      end

      def render
        # Build week-to-month letter mapping once
        @week_months = Utilities::DateCalculator.week_to_month_letter_map(context[:year])

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
        week_box = @grid_system.rect(0, row, SIDEBAR_WIDTH_BOXES, 1)

        # Build display text with optional month letter
        month_letter = @week_months[week]
        display_text = month_letter ? "#{month_letter} w#{week}" : "w#{week}"

        if current_week?(week)
          draw_current_week(week_box, display_text)
        else
          draw_linked_week(week_box, display_text, week)
        end
      end

      def current_week?(week)
        context[:current_week_num] && context[:current_week_num] == week
      end

      def draw_current_week(week_box, display_text)
        # Current week: bold, no link
        @pdf.font "Helvetica-Bold", size: FONT_SIZE
        @pdf.fill_color '000000'
        @pdf.text_box display_text,
                      at: [week_box[:x] + @grid_system.width(PADDING_BOXES), week_box[:y]],
                      width: week_box[:width] - @grid_system.width(PADDING_BOXES * 2),
                      height: week_box[:height],
                      align: :right,
                      valign: :center
        @pdf.font "Helvetica", size: FONT_SIZE
      end

      def draw_linked_week(week_box, display_text, week)
        # Other weeks: gray, with link
        @pdf.fill_color NAV_COLOR
        @pdf.text_box display_text,
                      at: [week_box[:x] + @grid_system.width(PADDING_BOXES), week_box[:y]],
                      width: week_box[:width] - @grid_system.width(PADDING_BOXES * 2),
                      height: week_box[:height],
                      align: :right,
                      valign: :center

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
