# frozen_string_literal: true

require_relative '../component'

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
    # All navigation links use gray color (888888) for subtle appearance.
    #
    # Example usage:
    #   nav = TopNavigation.new(pdf, grid_system,
    #     year: 2025,
    #     week_num: 42,
    #     total_weeks: 52,
    #     week_start: Date.new(2025, 10, 13),
    #     week_end: Date.new(2025, 10, 19)
    #   )
    #   nav.render
    class TopNavigation < Component
      FOOTER_FONT_SIZE = 8
      TITLE_FONT_SIZE = 14
      NAV_COLOR = '888888'

      def initialize(pdf, grid_system, **options)
        super
        validate_options
      end

      def render
        content_start_col = context[:content_start_col] || 3
        content_width_boxes = context[:content_width_boxes] || 39

        nav_box = @grid_system.rect(content_start_col, 0, content_width_boxes, 2)

        draw_year_link(nav_box)
        draw_prev_week_link(nav_box) if show_prev?
        draw_next_week_link(nav_box) if show_next?
        draw_title(nav_box)
      end

      private

      def validate_options
        required_keys = [:year, :week_num, :total_weeks, :week_start, :week_end]
        missing_keys = required_keys - context.keys

        unless missing_keys.empty?
          raise ArgumentError, "TopNavigation requires: #{missing_keys.join(', ')}"
        end
      end

      def show_prev?
        context[:week_num] > 1
      end

      def show_next?
        context[:week_num] < context[:total_weeks]
      end

      def draw_year_link(nav_box)
        @pdf.font "Helvetica", size: FOOTER_FONT_SIZE
        @pdf.fill_color NAV_COLOR

        nav_year_width = @grid_system.width(4)
        @pdf.text_box "< #{context[:year]}",
                      at: [nav_box[:x], nav_box[:y]],
                      width: nav_year_width,
                      height: nav_box[:height],
                      valign: :center

        @pdf.fill_color '000000'
        @pdf.link_annotation([nav_box[:x], nav_box[:y] - nav_box[:height],
                              nav_box[:x] + nav_year_width, nav_box[:y]],
                            Dest: "seasonal",
                            Border: [0, 0, 0])
      end

      def draw_prev_week_link(nav_box)
        @pdf.fill_color NAV_COLOR

        nav_year_width = @grid_system.width(4)
        nav_prev_x = nav_box[:x] + nav_year_width + @grid_system.width(1)
        nav_prev_width = @grid_system.width(3)

        @pdf.text_box "< w#{context[:week_num] - 1}",
                      at: [nav_prev_x, nav_box[:y]],
                      width: nav_prev_width,
                      height: nav_box[:height],
                      valign: :center

        @pdf.fill_color '000000'
        @pdf.link_annotation([nav_prev_x, nav_box[:y] - nav_box[:height],
                              nav_prev_x + nav_prev_width, nav_box[:y]],
                            Dest: "week_#{context[:week_num] - 1}",
                            Border: [0, 0, 0])
      end

      def draw_next_week_link(nav_box)
        nav_next_width = @grid_system.width(3)
        nav_next_x = nav_box[:x] + nav_box[:width] - nav_next_width

        @pdf.fill_color NAV_COLOR
        @pdf.text_box "w#{context[:week_num] + 1} >",
                      at: [nav_next_x, nav_box[:y]],
                      width: nav_next_width,
                      height: nav_box[:height],
                      align: :right,
                      valign: :center

        @pdf.fill_color '000000'
        @pdf.link_annotation([nav_next_x, nav_box[:y] - nav_box[:height],
                              nav_next_x + nav_next_width, nav_box[:y]],
                            Dest: "week_#{context[:week_num] + 1}",
                            Border: [0, 0, 0])
      end

      def draw_title(nav_box)
        @pdf.font "Helvetica-Bold", size: TITLE_FONT_SIZE

        title_x = nav_box[:x] + @grid_system.width(8)
        title_width = nav_box[:width] - @grid_system.width(16)
        title_text = "Week #{context[:week_num]}: #{context[:week_start].strftime('%b %-d')} - #{context[:week_end].strftime('%b %-d, %Y')}"

        @pdf.text_box title_text,
                      at: [title_x, nav_box[:y]],
                      width: title_width,
                      height: nav_box[:height],
                      align: :center,
                      valign: :center
      end
    end
  end
end
