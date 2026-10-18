# frozen_string_literal: true

require_relative '../base/sidebar_base'
require_relative '../sidebars/sidebar_registry'
require_relative 'link_box'

module BujoPdf
  module Components
    # Left-edge navigation by month.
    #
    # Draws the twelve declared nav months (see DeclarationContext#nav_month)
    # one row each from the top, each linking to its first week. On a page
    # that belongs to a month, that month expands in place to list its items
    # (quarterly plan, weeks, review) in PDF order, bracketed like the
    # expanded section on the right edge; later months shift down.
    class CalendarNav < SidebarBase
      include Sidebars::SidebarRegistry
      include LinkBox::Mixin

      register_sidebar :calendar_nav

      MONTH_COL = 0
      MONTH_WIDTH = 2
      ITEM_COL = 0.3
      ITEM_WIDTH = 1.7
      ITEM_FONT_SIZE = 7
      BRACKET_COL = 0.15
      BRACKET_WIDTH_PT = 0.75
      BRACKET_COLOR = '888888'

      def render
        row = sidebar_start_row
        months.each do |month|
          link_box(MONTH_COL, row, MONTH_WIDTH, 1, month.label,
                   dest: month.first_week.to_s, current: month.first_week == current_key)
          row += 1
          row = draw_items(month, row) if month.items.any? { |item| item.id == current_key }
        end
      end

      private

      def months
        page_context&.[](:nav_months) || []
      end

      def current_key
        page_context&.[](:page_key)
      end

      def draw_items(month, row)
        top = row
        month.items.each do |item|
          link_box(ITEM_COL, row, ITEM_WIDTH, 1, item.label,
                   dest: item.id.to_s, current: item.id == current_key, font_size: ITEM_FONT_SIZE)
          row += 1
        end
        draw_bracket(top, row)
        row
      end

      def draw_bracket(top_row, bottom_row)
        x = grid.x(BRACKET_COL)
        pdf.save_graphics_state do
          pdf.stroke_color BRACKET_COLOR
          pdf.line_width BRACKET_WIDTH_PT
          pdf.stroke_line [x, grid.y(top_row)], [x, grid.y(bottom_row)]
        end
      end
    end
  end
end
