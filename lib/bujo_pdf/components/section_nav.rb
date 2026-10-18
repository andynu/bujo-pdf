# frozen_string_literal: true

require_relative '../base/sidebar_base'
require_relative '../sidebars/sidebar_registry'
require_relative 'right_sidebar'
require_relative 'link_box'

module BujoPdf
  module Components
    # Right-edge navigation by section.
    #
    # Draws one rotated tab per declared nav section (see
    # DeclarationContext#nav_section). The section holding the current page
    # expands in place: its items follow its tab, inset toward the page edge
    # and bracketed, so every page of the section is one tap away. Other
    # sections stay collapsed to a tab that links to their landing page.
    #
    # Geometry matches TabSidebar, so a recipe can swap one for the other.
    class SectionNav < SidebarBase
      include Sidebars::SidebarRegistry
      include LinkBox::Mixin

      register_sidebar :section_nav

      ITEM_INSET_PT = 3
      ITEM_FONT_SIZE = TabSidebar::FONT_SIZE - 1
      BRACKET_X_PT = 1.5
      BRACKET_WIDTH_PT = 0.75
      BRACKET_COLOR = '888888'
      SECTION_GAP_PT = 6

      def render
        @y = grid.y(0) - TabSidebar::START_Y_OFFSET_PT
        sections.each do |section|
          draw_tab(section)
          draw_items(section) if in_section?(section)
        end
      end

      private

      def sections
        page_context&.[](:nav_sections) || []
      end

      def current_key
        page_context&.[](:page_key)
      end

      # The landing page counts even when it is not an item (the grids index).
      def in_section?(section)
        section.landing == current_key || section.items.any? { |item| item.id == current_key }
      end

      def draw_tab(section)
        current = section.landing == current_key
        draw_box(section, section.label, section.landing, current: current, inset: 0, font_size: TabSidebar::FONT_SIZE)
      end

      def draw_items(section)
        top = @y
        section.items.each do |item|
          draw_box(section, item.label, item.id, current: item.id == current_key,
                                                 inset: ITEM_INSET_PT, font_size: ITEM_FONT_SIZE)
        end
        draw_bracket(top, @y + TabSidebar::TAB_GAP_PT)
        @y -= SECTION_GAP_PT
      end

      def draw_box(section, label, dest, current:, inset:, font_size:)
        height = box_height(label, bold: current, font_size: font_size)
        if @y - height < grid.y(Layouts::BaseLayout::PAGE_HEIGHT_BOXES)
          raise ArgumentError, "section nav for :#{section.key} overflows the page"
        end

        link_box_pt(column_x + inset, @y, grid.width(1) - inset, height, label,
                    dest: dest.to_s, current: current, rotation: -90, font_size: font_size, inset: 2)
        @y -= height + TabSidebar::TAB_GAP_PT
      end

      def box_height(label, bold:, font_size:)
        width = nil
        pdf.font(bold ? 'Helvetica-Bold' : 'Helvetica', size: font_size) { width = pdf.width_of(label) }
        width + (TabSidebar::TAB_PADDING_PT * 2)
      end

      def draw_bracket(top, bottom)
        x = column_x + BRACKET_X_PT
        pdf.save_graphics_state do
          pdf.stroke_color BRACKET_COLOR
          pdf.line_width BRACKET_WIDTH_PT
          pdf.stroke_line [x, top], [x, bottom]
        end
      end

      def column_x
        grid.x(TabSidebar::DEFAULT_SIDEBAR_COL)
      end
    end
  end
end
