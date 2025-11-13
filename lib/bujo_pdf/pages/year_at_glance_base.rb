# frozen_string_literal: true

require_relative 'standard_layout_page'
require_relative '../utilities/date_calculator'
require_relative '../utilities/styling'

module BujoPdf
  module Pages
    # Base class for Year At Glance pages (Events and Highlights).
    #
    # These pages show a 12×31 grid (months × days) where each cell represents
    # one day of the year. Each cell is clickable and links to the corresponding
    # weekly page.
    #
    # Layout:
    #   - Header (rows 0-1): Page title
    #   - Month headers (row 2): 12 month names
    #   - Days grid (rows 3-52): 31 days × 12 months
    #
    # Subclasses must override:
    #   - page_title: The title to display in the header
    #   - destination_name: The named destination for this page
    class YearAtGlanceBase < StandardLayoutPage
      include Styling::Colors
      include Styling::Grid

      # Layout constants
      YEAR_TITLE_FONT_SIZE = 16
      YEAR_MONTH_HEADER_SIZE = 8
      YEAR_DAY_SIZE = 6
      YEAR_DAY_ABBREV_SIZE = 5
      YEAR_DAY_NUMBER_OFFSET = 2
      YEAR_DAY_ABBREV_HEIGHT = 8

      MONTH_NAMES = %w[
        January February March April May June
        July August September October November December
      ]

      def setup
        set_destination(destination_name)
        @year = context[:year]
        @total_weeks = Utilities::DateCalculator.total_weeks(@year)

        # Use StandardLayoutPage setup but with dynamic highlight_tab
        super
      end

      def render
        draw_weekend_backgrounds
        draw_dot_grid
        # draw_diagnostic_grid(label_every: 5)
        # Sidebars rendered automatically by layout!
        draw_header
        draw_month_headers
        draw_days_grid
        draw_legend if context.date_config&.any?
      end

      protected

      # Year overview pages don't highlight weeks
      def current_week
        nil
      end

      # Highlight the current tab (overridden by subclasses)
      def highlight_tab
        destination_name
      end

      # Subclasses must override these methods
      def page_title
        raise NotImplementedError, "#{self.class} must implement #page_title"
      end

      def destination_name
        raise NotImplementedError, "#{self.class} must implement #destination_name"
      end

      private

      def draw_header
        # Content area dimensions
        content_start_col = 2
        content_width_boxes = 40  # Columns 2-41 inclusive

        # Header - rows 0-1 (2 boxes)
        header_box = @grid_system.rect(content_start_col, 0, content_width_boxes, 2)
        @pdf.font "Helvetica-Bold", size: YEAR_TITLE_FONT_SIZE
        @pdf.text_box page_title,
                      at: [header_box[:x], header_box[:y]],
                      width: header_box[:width],
                      height: header_box[:height],
                      align: :center,
                      valign: :center
      end

      def draw_month_headers
        content_start_col = 2
        content_width_boxes = 40
        col_width_boxes = content_width_boxes / 12.0  # ≈ 3.33 boxes per month

        @pdf.font "Helvetica-Bold", size: YEAR_MONTH_HEADER_SIZE

        12.times do |month_index|
          month_name = MONTH_NAMES[month_index]

          # Calculate column position
          col_start = content_start_col + (month_index * col_width_boxes)
          cell_x = @grid_system.x(0) + (col_start * DOT_SPACING)
          cell_y = @grid_system.y(2)
          cell_width = col_width_boxes * DOT_SPACING
          cell_height = @grid_system.height(1)

          # Calculate which week contains the 1st of this month
          first_of_month = Date.new(@year, month_index + 1, 1)
          week_num = Utilities::DateCalculator.week_number_for_date(@year, first_of_month)

          # Draw month header cell
          @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
            @pdf.stroke_color BORDERS
            @pdf.stroke_bounds
            @pdf.stroke_color '000000'
            @pdf.text_box month_name[0..2],
                          at: [0, cell_height],
                          width: cell_width,
                          height: cell_height,
                          align: :center,
                          valign: :center
          end

          # Add clickable link
          link_bottom = cell_y - cell_height
          @pdf.link_annotation([cell_x, link_bottom, cell_x + cell_width, cell_y],
                              Dest: "week_#{week_num}",
                              Border: [0, 0, 0])
        end
      end

      def draw_days_grid
        content_start_col = 2
        content_width_boxes = 40
        col_width_boxes = content_width_boxes / 12.0

        # Days grid - rows 3-49.5 (46.5 rows for 31 days)
        day_height_rows = 1.5

        @pdf.font "Helvetica", size: YEAR_DAY_SIZE

        31.times do |day_index|
          day_num = day_index + 1
          day_row_start = 3 + (day_index * day_height_rows)

          12.times do |month_index|
            month = month_index + 1
            days_in_month = Date.new(@year, month, -1).day

            # Calculate cell position
            col_start = content_start_col + (month_index * col_width_boxes)
            cell_x = @grid_system.x(0) + (col_start * DOT_SPACING)
            cell_y = @grid_system.y(0) - (day_row_start * DOT_SPACING)
            cell_width = col_width_boxes * DOT_SPACING
            cell_height = day_height_rows * DOT_SPACING

            if day_num <= days_in_month
              draw_day_cell(cell_x, cell_y, cell_width, cell_height, month, day_num)
            else
              draw_empty_cell(cell_x, cell_y, cell_width, cell_height)
            end
          end
        end
      end

      def draw_day_cell(cell_x, cell_y, cell_width, cell_height, month, day_num)
        date = Date.new(@year, month, day_num)
        highlighted_date = context.date_config&.date_for_day(date)

        @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
          # Draw background highlight if date is highlighted
          if highlighted_date
            category_style = context.date_config.category_style(highlighted_date.category)
            bg_color = highlighted_date.color || category_style['color']

            @pdf.fill_color bg_color
            @pdf.fill_rectangle [0, cell_height], cell_width, cell_height
            @pdf.fill_color '000000'
          end

          # Draw border (highlighted dates with high priority get thicker border)
          @pdf.stroke_color BORDERS
          if highlighted_date
            priority_style = context.date_config.priority_style(highlighted_date.priority)
            if priority_style['border_width'] > 0.5
              category_style = context.date_config.category_style(highlighted_date.category)
              @pdf.stroke_color category_style['text_color']
              @pdf.line_width = priority_style['border_width']
            end
          end
          @pdf.stroke_bounds
          @pdf.line_width = 0.5  # Reset
          @pdf.stroke_color '000000'  # Reset

          # Add day number and abbreviation
          day_abbrev = date.strftime('%a')  # Mon, Tue, Wed, etc.

          @pdf.formatted_text_box [
            { text: "#{day_num} ", size: YEAR_DAY_SIZE },
            { text: day_abbrev, size: YEAR_DAY_ABBREV_SIZE, color: 'AAAAAA' }
          ],
                       at: [YEAR_DAY_NUMBER_OFFSET, cell_height - YEAR_DAY_NUMBER_OFFSET],
                       width: cell_width - (YEAR_DAY_NUMBER_OFFSET * 2),
                       height: cell_height - (YEAR_DAY_NUMBER_OFFSET * 2),
                       overflow: :shrink_to_fit

          # Add category icon if highlighted (top-right corner)
          if highlighted_date
            category_style = context.date_config.category_style(highlighted_date.category)
            icon = category_style['icon']

            @pdf.fill_color category_style['text_color']
            @pdf.text_box icon,
                          at: [cell_width - 10, cell_height - 2],
                          width: 8,
                          height: 8,
                          size: 6,
                          align: :right,
                          valign: :top
            @pdf.fill_color '000000'  # Reset
          end

          # Add clickable link to the week containing this date
          week_num = Utilities::DateCalculator.week_number_for_date(@year, date)

          @pdf.link_annotation([0, 0, cell_width, cell_height],
                              Dest: "week_#{week_num}",
                              Border: [0, 0, 0])
        end
      end

      def draw_empty_cell(cell_x, cell_y, cell_width, cell_height)
        @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
          @pdf.stroke_color BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'
          @pdf.fill_color 'EEEEEE'
          @pdf.fill_rectangle [0, cell_height], cell_width, cell_height
          @pdf.fill_color '000000'
        end
      end

      # Draw subtle weekend background shading for Saturday and Sunday cells
      # Uses the same pattern as WeekColumn: WEEKEND_BG color at 10% opacity
      # Must be called BEFORE draw_dot_grid to ensure dots appear on top
      def draw_weekend_backgrounds
        content_start_col = 2
        content_width_boxes = 40
        col_width_boxes = content_width_boxes / 12.0

        # Days grid - rows 3-49.5 (46.5 rows for 31 days)
        day_height_rows = 1.5

        # Iterate through all days (31) and months (12)
        31.times do |day_index|
          day_num = day_index + 1
          day_row_start = 3 + (day_index * day_height_rows)

          12.times do |month_index|
            month = month_index + 1
            days_in_month = Date.new(@year, month, -1).day

            # Skip if this day doesn't exist in this month
            next unless day_num <= days_in_month

            # Check if this date is a weekend
            date = Date.new(@year, month, day_num)
            next unless date.saturday? || date.sunday?

            # Calculate cell position (same logic as draw_days_grid)
            col_start = content_start_col + (month_index * col_width_boxes)
            cell_x = @grid_system.x(0) + (col_start * DOT_SPACING)
            cell_y = @grid_system.y(0) - (day_row_start * DOT_SPACING)
            cell_width = col_width_boxes * DOT_SPACING
            cell_height = day_height_rows * DOT_SPACING

            # Draw weekend background with 10% opacity
            @pdf.fill_color WEEKEND_BG
            @pdf.transparent(0.1) do
              @pdf.fill_rectangle [cell_x, cell_y], cell_width, cell_height
            end
            @pdf.fill_color '000000'
          end
        end
      end

      # Draw legend showing highlighted date labels
      # Uses bottom 5 rows (rows 50-54) for the legend area
      def draw_legend
        content_start_col = 2
        content_width_boxes = 40

        # Legend area - rows 50-54 (5 boxes)
        legend_box = @grid_system.rect(content_start_col, 50, content_width_boxes, 5)

        # Get all dates for this year, sorted by date
        all_dates = context.date_config.dates.sort_by(&:date)
        return if all_dates.empty?

        # Build legend text with icon, date, and label
        @pdf.font "Helvetica", size: 7
        legend_text = all_dates.map do |highlighted_date|
          category_style = context.date_config.category_style(highlighted_date.category)
          icon = category_style['icon']
          date_str = highlighted_date.date.strftime('%b %-d')
          "#{icon} #{date_str}: #{highlighted_date.label}"
        end.join('   ')

        # Draw legend text box
        @pdf.text_box legend_text,
                      at: [legend_box[:x] + 4, legend_box[:y] - 4],
                      width: legend_box[:width] - 8,
                      height: legend_box[:height] - 8,
                      align: :left,
                      valign: :top,
                      overflow: :shrink_to_fit,
                      leading: 2
      end

    end
  end
end
