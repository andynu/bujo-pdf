# frozen_string_literal: true

require_relative 'component'
require_relative '../utilities/styling'

module BujoPdf
  # Base class for sidebar components.
  #
  # SidebarBase provides common functionality shared by different sidebar types
  # (week sidebars, month sidebars, etc.):
  #
  # - Standard positioning constants
  # - Background drawing with current/linked states
  # - Item rendering helpers
  # - Theme-aware color support
  #
  # Subclasses should:
  # 1. Override `render` to iterate through items
  # 2. Use `draw_item_background` for consistent visual treatment
  # 3. Use `draw_item_text` for text rendering with links
  # 4. Override `current_item?` to determine highlight state
  #
  # @example Subclass implementation
  #   class WeekSidebar < SidebarBase
  #     def render
  #       @total_weeks.times do |i|
  #         week = i + 1
  #         row = sidebar_start_row + i
  #         draw_week_entry(week, row)
  #       end
  #     end
  #
  #     private
  #
  #     def draw_week_entry(week, row)
  #       item_box = item_rect(row, 1)  # 1 row height
  #       is_current = current_item?(week)
  #       draw_item_background(item_box, is_current)
  #       # ... render text
  #     end
  #   end
  class SidebarBase < Component
    include Styling::Colors

    # Default sidebar positioning constants
    # Subclasses can override these via constructor options
    DEFAULT_START_COL = 0.25
    DEFAULT_WIDTH_BOXES = 2
    DEFAULT_START_ROW = 2
    DEFAULT_PADDING_BOXES = 0.3
    DEFAULT_FONT_SIZE = 6

    # @param canvas [Canvas] The canvas wrapping pdf and grid
    # @param page_context [Object, nil] Optional context for current page detection
    # @param start_col [Float] Starting column for sidebar (default: 0.25)
    # @param width_boxes [Float] Width in grid boxes (default: 2)
    # @param start_row [Integer] Starting row (default: 2)
    # @param padding_boxes [Float] Internal padding in boxes (default: 0.3)
    # @param font_size [Integer] Font size for sidebar text (default: 6)
    def initialize(canvas:, page_context: nil, start_col: nil, width_boxes: nil,
                   start_row: nil, padding_boxes: nil, font_size: nil)
      super(canvas: canvas)
      @page_context = page_context
      @start_col = start_col || DEFAULT_START_COL
      @width_boxes = width_boxes || DEFAULT_WIDTH_BOXES
      @start_row = start_row || DEFAULT_START_ROW
      @padding_boxes = padding_boxes || DEFAULT_PADDING_BOXES
      @font_size = font_size || DEFAULT_FONT_SIZE
    end

    protected

    # Accessors for positioning constants (can be overridden or configured)
    attr_reader :page_context

    def sidebar_start_col
      @start_col
    end

    def sidebar_width_boxes
      @width_boxes
    end

    def sidebar_start_row
      @start_row
    end

    def sidebar_padding_boxes
      @padding_boxes
    end

    def sidebar_font_size
      @font_size
    end

    # Get a rectangle for a sidebar item at the given row.
    #
    # @param row [Integer, Float] Grid row for the item
    # @param height_boxes [Integer, Float] Height in grid boxes (default: 1)
    # @return [Hash] Rectangle with :x, :y, :width, :height keys
    def item_rect(row, height_boxes = 1)
      grid.rect(sidebar_start_col, row, sidebar_width_boxes, height_boxes)
    end

    # Draw background for a sidebar item.
    #
    # Current items get a stroked border; non-current items get a filled
    # background at 20% opacity. Both use rounded rectangles with small gaps.
    #
    # @param item_box [Hash] Rectangle from item_rect()
    # @param is_current [Boolean] True if this is the current/active item
    # @param gap_vertical [Integer] Vertical gap in points (default: 2)
    # @param corner_radius [Integer] Corner radius in points (default: 2)
    def draw_item_background(item_box, is_current, gap_vertical: 2, corner_radius: 2)
      # Calculate gap on right side: 0.25 box overlap + 2px visual gap
      gap_right = grid.width(0.25) + 2

      left = item_box[:x]
      width = item_box[:width] - gap_right
      height = item_box[:height] - gap_vertical
      top = item_box[:y] - (gap_vertical / 2.0)

      if is_current
        # Current item: stroked rectangle with border color
        pdf.stroke_color color_borders
        pdf.stroke_rounded_rectangle([left, top], width, height, corner_radius)
      else
        # Other items: filled rectangle with 20% opacity
        pdf.transparent(0.2) do
          pdf.fill_color color_borders
          pdf.fill_rounded_rectangle([left, top], width, height, corner_radius)
        end
      end

      # Reset colors to theme defaults
      pdf.fill_color color_text_black
      pdf.stroke_color color_text_black
    end

    # Draw text for a sidebar item.
    #
    # Renders right-aligned text within the item box with proper padding.
    # Handles both current (bold, no link) and linked (gray, with link) states.
    #
    # @param item_box [Hash] Rectangle from item_rect()
    # @param text [String] Text to display
    # @param is_current [Boolean] True if this is the current/active item
    # @param dest [String, nil] Named destination for link (if not current)
    # @param bold [Boolean] Force bold for non-current items (default: false)
    def draw_item_text(item_box, text, is_current, dest: nil, bold: false)
      # Shift text box 5px left to keep text within beveled rectangle
      text_x = item_box[:x] + grid.width(sidebar_padding_boxes) - 5
      text_width = item_box[:width] - grid.width(sidebar_padding_boxes * 2)

      if is_current
        draw_current_item_text(item_box, text_x, text_width, text)
      else
        draw_linked_item_text(item_box, text_x, text_width, text, dest, bold: bold)
      end
    end

    # Draw formatted text with mixed styles for a sidebar item.
    #
    # Useful when an item has multiple text parts with different styles
    # (e.g., month abbreviation bold + week number regular).
    #
    # @param item_box [Hash] Rectangle from item_rect()
    # @param formatted_parts [Array<Hash>] Array of Prawn formatted text parts
    # @param is_current [Boolean] True if this is the current/active item
    # @param dest [String, nil] Named destination for link (if not current)
    def draw_item_formatted_text(item_box, formatted_parts, is_current, dest: nil)
      text_x = item_box[:x] + grid.width(sidebar_padding_boxes) - 5
      text_width = item_box[:width] - grid.width(sidebar_padding_boxes * 2)

      if is_current
        # Current: all parts use theme text color, bold
        current_parts = formatted_parts.map do |part|
          part.merge(color: color_text_black, styles: [:bold])
        end
        draw_formatted_text_box(item_box, text_x, text_width, current_parts)
      else
        # Linked: use specified colors (typically gray), add link
        with_fill_color(color_text_gray) do
          draw_formatted_text_box(item_box, text_x, text_width, formatted_parts)
          draw_link_annotation(item_box, dest) if dest
        end
      end
    end

    private

    def draw_current_item_text(item_box, text_x, text_width, text)
      with_font("Helvetica-Bold", sidebar_font_size) do
        with_fill_color(color_text_black) do
          pdf.text_box text,
                       at: [text_x, item_box[:y]],
                       width: text_width,
                       height: item_box[:height],
                       align: :right,
                       valign: :center,
                       overflow: :shrink_to_fit
        end
      end
    end

    def draw_linked_item_text(item_box, text_x, text_width, text, dest, bold: false)
      with_fill_color(color_text_gray) do
        font_family = bold ? "Helvetica-Bold" : "Helvetica"
        with_font(font_family, sidebar_font_size) do
          pdf.text_box text,
                       at: [text_x, item_box[:y]],
                       width: text_width,
                       height: item_box[:height],
                       align: :right,
                       valign: :center,
                       overflow: :shrink_to_fit
        end

        draw_link_annotation(item_box, dest) if dest
      end
    end

    def draw_formatted_text_box(item_box, text_x, text_width, parts)
      pdf.formatted_text_box parts,
                             at: [text_x, item_box[:y]],
                             width: text_width,
                             height: item_box[:height],
                             align: :right,
                             valign: :center,
                             overflow: :shrink_to_fit
    end

    def draw_link_annotation(item_box, dest)
      return unless dest

      link_left = item_box[:x]
      link_bottom = item_box[:y] - item_box[:height]
      link_right = item_box[:x] + item_box[:width]
      link_top = item_box[:y]

      pdf.link_annotation([link_left, link_bottom, link_right, link_top],
                          Dest: dest,
                          Border: [0, 0, 0])
    end
  end
end
