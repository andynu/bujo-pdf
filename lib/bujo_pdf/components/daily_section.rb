# frozen_string_literal: true

require_relative '../component'
require_relative '../sub_components/week_column'

module BujoPdf
  module Components
    # DailySection component for weekly pages.
    #
    # Renders a 7-column daily section showing Monday-Sunday with:
    #   - Day headers (day name + date)
    #   - Ruled lines for notes
    #   - Time labels on Monday column (AM/PM/EVE)
    #   - Weekend background shading
    #
    # Uses the WeekColumn sub-component (from Plan 04) for rendering each day.
    #
    # Example usage:
    #   section = DailySection.new(pdf, grid_system,
    #     week_start: Date.new(2025, 10, 13),
    #     content_start_col: 3,
    #     content_start_row: 2,
    #     content_width_boxes: 39,
    #     daily_rows: 9,
    #     line_count: 4,
    #     header_height: 30,
    #     header_padding: 2,
    #     lines_start: 35,
    #     lines_padding: 40,
    #     line_margin: 3,
    #     day_header_font_size: 9,
    #     day_date_font_size: 8
    #   )
    #   section.render
    class DailySection < Component
      def render
        day_col_width_boxes = context[:content_width_boxes] / 7.0  # ~5.57 boxes per day

        7.times do |i|
          render_day_column(i, day_col_width_boxes)
        end
      end

      private

      def validate_configuration
        require_options(:week_start, :content_start_col, :content_start_row,
                       :content_width_boxes, :daily_rows)
      end

      def render_day_column(day_index, day_col_width_boxes)
        date = context[:week_start] + day_index
        day_name = date.strftime('%A')
        is_weekend = (day_index == 5 || day_index == 6)  # Saturday and Sunday

        # Create WeekColumn sub-component (from Plan 04)
        column = SubComponent::WeekColumn.new(@pdf, @grid,
          date: date,
          day_name: day_name,
          weekend: is_weekend,
          show_time_labels: (day_index == 0),  # Show time labels on Monday only
          line_count: context.fetch(:line_count, 4),
          header_height: context.fetch(:header_height, 30),
          header_padding: context.fetch(:header_padding, 2),
          lines_start: context.fetch(:lines_start, 35),
          lines_padding: context.fetch(:lines_padding, 40),
          line_margin: context.fetch(:line_margin, 3),
          day_header_font_size: context.fetch(:day_header_font_size, 9),
          day_date_font_size: context.fetch(:day_date_font_size, 8)
        )

        # Render at column position
        col = context[:content_start_col] + (day_index * day_col_width_boxes)
        column.render_at(col, context[:content_start_row], day_col_width_boxes, context[:daily_rows])
      end
    end
  end
end
