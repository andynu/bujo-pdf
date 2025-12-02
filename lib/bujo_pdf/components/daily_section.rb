# frozen_string_literal: true

require_relative '../base/component'
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
    #   canvas = Canvas.new(pdf, grid)
    #   section = DailySection.new(
    #     canvas: canvas,
    #     week_start: Date.new(2025, 10, 13),
    #     content_start_col: 3,
    #     content_start_row: 2,
    #     content_width_boxes: 39,
    #     daily_rows: 9
    #   )
    #   section.render
    class DailySection < Component
      def initialize(canvas:, week_start:, content_start_col:, content_start_row:,
                     content_width_boxes:, daily_rows:, line_count: 4,
                     line_margin: 3, header_font_size: 9,
                     date_config: nil, event_store: nil)
        super(canvas: canvas)
        @week_start = week_start
        @content_start_col = content_start_col
        @content_start_row = content_start_row
        @content_width_boxes = content_width_boxes
        @daily_rows = daily_rows
        @line_count = line_count
        @line_margin = line_margin
        @header_font_size = header_font_size
        @date_config = date_config
        @event_store = event_store
      end

      def render
        # Use WeekGrid for consistent, quantized column widths (Plan #22)
        # Note: show_headers: false because WeekColumn handles the complex headers
        week_grid = grid.week_grid(
          @content_start_col,
          @content_start_row,
          @content_width_boxes,
          @daily_rows,
          quantize: true,
          show_headers: false
        )

        # Render each day column using the WeekColumn sub-component
        week_grid.each_cell do |day_index, cell_rect|
          render_day_column(day_index, cell_rect)
        end
      end

      private

      def render_day_column(day_index, cell_rect)
        date = @week_start + day_index
        day_name = date.strftime('%A')
        is_weekend = (day_index == 5 || day_index == 6)  # Saturday and Sunday

        # Convert cell_rect (points) back to grid coordinates for WeekColumn
        col = cell_rect[:x] / Styling::Grid::DOT_SPACING
        row = @content_start_row
        width_boxes = cell_rect[:width] / Styling::Grid::DOT_SPACING
        height_boxes = @daily_rows

        # Create WeekColumn component with canvas
        column = WeekColumn.new(
          canvas: canvas,
          col: col, row: row, width: width_boxes, height: height_boxes,
          date: date,
          day_name: day_name,
          weekend: is_weekend,
          show_time_labels: (day_index == 0),  # Show time labels on Monday only
          line_count: @line_count,
          line_margin: @line_margin,
          header_font_size: @header_font_size,
          date_config: @date_config,
          event_store: @event_store
        )

        column.render
      end
    end
  end
end
