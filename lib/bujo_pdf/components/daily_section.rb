# frozen_string_literal: true

require_relative '../component'
require_relative 'week_column'
require_relative '../utilities/styling'

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
    # Uses WeekGrid (Plan #22) for consistent, quantized column widths
    # and WeekColumn sub-component for rendering each day.
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
        # Use WeekGrid for consistent, quantized column widths (Plan #22)
        # Note: show_headers: false because WeekColumn handles the complex headers
        week_grid = @grid.week_grid(
          context[:content_start_col],
          context[:content_start_row],
          context[:content_width_boxes],
          context[:daily_rows],
          quantize: true,
          show_headers: false
        )

        # Render each day column using the WeekColumn sub-component
        week_grid.each_cell do |day_index, cell_rect|
          render_day_column(day_index, cell_rect)
        end
      end

      private

      def validate_configuration
        require_options(:week_start, :content_start_col, :content_start_row,
                       :content_width_boxes, :daily_rows)
      end

      def render_day_column(day_index, cell_rect)
        date = context[:week_start] + day_index
        day_name = date.strftime('%A')
        is_weekend = (day_index == 5 || day_index == 6)  # Saturday and Sunday

        # Convert cell_rect (points) back to grid coordinates for WeekColumn
        col = cell_rect[:x] / Styling::Grid::DOT_SPACING
        row = context[:content_start_row]
        width_boxes = cell_rect[:width] / Styling::Grid::DOT_SPACING
        height_boxes = context[:daily_rows]

        # Create WeekColumn component
        column = WeekColumn.new(@pdf, @grid,
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
          day_date_font_size: context.fetch(:day_date_font_size, 8),
          date_config: context[:date_config],
          event_store: context[:event_store]
        )

        # Render at column position
        column.render_at(col, row, width_boxes, height_boxes)
      end
    end
  end
end
