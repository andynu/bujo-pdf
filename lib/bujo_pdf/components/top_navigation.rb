# frozen_string_literal: true

require_relative '../base/component'
require_relative 'link_box'

module BujoPdf
  module Components
    # TopNavigation component for weekly pages.
    #
    # Renders the top navigation bar with:
    #   - Year link on the left (links to seasonal calendar)
    #   - Previous week link (if not first week)
    #   - Centered week title with date range
    #   - Next week link (if not last week)
    #
    # Navigation links use LinkBox for consistent styling with
    # rounded rectangle backgrounds (20% opacity).
    #
    # Example usage:
    #   canvas = Canvas.new(pdf, grid)
    #   nav = TopNavigation.new(
    #     canvas: canvas,
    #     year: 2025,
    #     week_num: 42,
    #     total_weeks: 52,
    #     week_start: Date.new(2025, 10, 13),
    #     week_end: Date.new(2025, 10, 19)
    #   )
    #   nav.render
    class TopNavigation < Component
      include LinkBox::Mixin

      NAV_FONT_SIZE = 8
      TITLE_FONT_SIZE = 14

      def initialize(canvas:, year:, week_num:, total_weeks:, week_start:, week_end:,
                     content_start_col: 3, content_width_boxes: 39)
        super(canvas: canvas)
        @year = year
        @week_num = week_num
        @total_weeks = total_weeks
        @week_start = week_start
        @week_end = week_end
        @content_start_col = content_start_col
        @content_width_boxes = content_width_boxes
      end

      def render
        nav_box = grid.rect(@content_start_col, 0, @content_width_boxes, 2)

        draw_year_link
        draw_prev_week_link if show_prev?
        draw_next_week_link if show_next?
        draw_title(nav_box)
      end

      private

      def show_prev?
        @week_num > 1
      end

      def show_next?
        @week_num < @total_weeks
      end

      def draw_year_link
        link_box(0, 0, 2, 1, @year.to_s, dest: "seasonal", font_size: NAV_FONT_SIZE)
      end

      def draw_prev_week_link
        link_box(2, 0, 2, 1, "w#{format('%02d', @week_num - 1)}", dest: "week_#{@week_num - 1}", font_size: NAV_FONT_SIZE)
      end

      def draw_next_week_link
        link_box(40, 0, 2, 1, "w#{format('%02d', @week_num + 1)}", dest: "week_#{@week_num + 1}", font_size: NAV_FONT_SIZE)
      end

      def draw_title(nav_box)
        pdf.font "Helvetica-Bold", size: TITLE_FONT_SIZE

        title_x = nav_box[:x] + grid.width(8)
        title_width = nav_box[:width] - grid.width(16)
        title_text = "Week #{@week_num}: #{@week_start.strftime('%b %-d')} - #{@week_end.strftime('%b %-d, %Y')}"

        pdf.text_box title_text,
                      at: [title_x, nav_box[:y]],
                      width: title_width,
                      height: nav_box[:height],
                      align: :center,
                      valign: :center
      end
    end
  end
end
