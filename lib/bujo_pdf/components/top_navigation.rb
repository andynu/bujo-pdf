# frozen_string_literal: true

require_relative '../base/component'

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
    # Navigation links have rounded rectangle backgrounds (20% opacity)
    # matching the sidebar navigation style.
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

        draw_year_link(nav_box)
        draw_prev_week_link(nav_box) if show_prev?
        draw_next_week_link(nav_box) if show_next?
        draw_title(nav_box)
      end

      private

      def show_prev?
        @week_num > 1
      end

      def show_next?
        @week_num < @total_weeks
      end

      def draw_year_link(nav_box)
        require_relative '../themes/theme_registry'
        nav_color = BujoPdf::Themes.current[:colors][:text_gray]

        link_width = grid.width(2)
        link_height = grid.height(1)
        link_x = grid.x(0)  # Columns 0-1
        link_y = grid.y(0)  # Row 0 - top of page

        # Draw background
        draw_nav_background(link_x, link_y, link_width, link_height)

        # Draw text
        pdf.font "Helvetica", size: NAV_FONT_SIZE
        pdf.fill_color nav_color
        pdf.text_box @year.to_s,
                      at: [link_x, link_y],
                      width: link_width,
                      height: link_height,
                      align: :center,
                      valign: :center

        # Link annotation
        pdf.link_annotation([link_x, link_y - link_height, link_x + link_width, link_y],
                            Dest: "seasonal",
                            Border: [0, 0, 0])

        # Reset color
        pdf.fill_color BujoPdf::Themes.current[:colors][:text_black]
      end

      def draw_prev_week_link(nav_box)
        require_relative '../themes/theme_registry'
        nav_color = BujoPdf::Themes.current[:colors][:text_gray]

        link_width = grid.width(2)
        link_height = grid.height(1)
        link_x = grid.x(2)  # Columns 2-3
        link_y = grid.y(0)  # Row 0 - top of page

        # Draw background
        draw_nav_background(link_x, link_y, link_width, link_height)

        # Draw text
        pdf.font "Helvetica", size: NAV_FONT_SIZE
        pdf.fill_color nav_color
        pdf.text_box "w#{format('%02d', @week_num - 1)}",
                      at: [link_x, link_y],
                      width: link_width,
                      height: link_height,
                      align: :center,
                      valign: :center

        # Link annotation
        pdf.link_annotation([link_x, link_y - link_height, link_x + link_width, link_y],
                            Dest: "week_#{@week_num - 1}",
                            Border: [0, 0, 0])

        # Reset color
        pdf.fill_color BujoPdf::Themes.current[:colors][:text_black]
      end

      def draw_next_week_link(nav_box)
        require_relative '../themes/theme_registry'
        nav_color = BujoPdf::Themes.current[:colors][:text_gray]

        link_width = grid.width(2)
        link_height = grid.height(1)
        link_x = grid.x(40)  # Columns 40-41 (one box in from right edge)
        link_y = grid.y(0)  # Row 0 - top of page

        # Draw background
        draw_nav_background(link_x, link_y, link_width, link_height)

        # Draw text
        pdf.font "Helvetica", size: NAV_FONT_SIZE
        pdf.fill_color nav_color
        pdf.text_box "w#{format('%02d', @week_num + 1)}",
                      at: [link_x, link_y],
                      width: link_width,
                      height: link_height,
                      align: :center,
                      valign: :center

        # Link annotation
        pdf.link_annotation([link_x, link_y - link_height, link_x + link_width, link_y],
                            Dest: "week_#{@week_num + 1}",
                            Border: [0, 0, 0])

        # Reset color
        pdf.fill_color BujoPdf::Themes.current[:colors][:text_black]
      end

      def draw_nav_background(left, top, width, height)
        require_relative '../themes/theme_registry'
        border_color = BujoPdf::Themes.current[:colors][:borders]

        # Small inset for visual breathing room
        inset = 2
        rect_left = left + inset
        rect_width = width - (inset * 2)
        rect_top = top - inset
        rect_height = height - (inset * 2)

        # 20% opacity filled background (matching sidebar style)
        pdf.transparent(0.2) do
          pdf.fill_color border_color
          pdf.fill_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
        end

        # Reset color
        text_color = BujoPdf::Themes.current[:colors][:text_black]
        pdf.fill_color text_color
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
