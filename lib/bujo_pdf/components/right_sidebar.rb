# frozen_string_literal: true

require_relative '../component'

module BujoPdf
  module Components
    # RightSidebar component for right sidebar tabs navigation.
    #
    # Renders a vertical list of navigation tabs on the right edge with:
    #   - Top-aligned tabs (stack downward from start_row)
    #   - Bottom-aligned tabs (stack upward from bottom)
    #   - Rotated text (-90°) for vertical reading
    #   - Clickable links to destinations
    #   - Gray color (888888)
    #
    # Grid positioning:
    #   - Column 42 (rightmost column, 1 box wide)
    #   - Each tab: customizable height (default 3 boxes)
    #   - Top tabs: start at row 1, stack downward
    #   - Bottom tabs: start at bottom, stack upward
    #
    # Example usage:
    #   sidebar = RightSidebar.new(pdf, grid_system,
    #     top_tabs: [
    #       { label: "Year", dest: "seasonal" },
    #       { label: "Events", dest: "year_events" }
    #     ],
    #     bottom_tabs: [
    #       { label: "Dots", dest: "dots" }
    #     ]
    #   )
    #   sidebar.render
    class RightSidebar < Component
      GRID_ROWS = 55
      DEFAULT_TAB_HEIGHT = 3
      DEFAULT_SIDEBAR_COL = 42
      DEFAULT_START_ROW = 1
      FONT_SIZE = 8
      NAV_COLOR = '888888'
      PADDING_BOXES = 0.5

      def initialize(pdf, grid_system, **options)
        super
        @top_tabs = context.fetch(:top_tabs, [])
        @bottom_tabs = context.fetch(:bottom_tabs, [])
        @start_row = context.fetch(:start_row, DEFAULT_START_ROW)
        @tab_height = context.fetch(:tab_height, DEFAULT_TAB_HEIGHT)
        @sidebar_col = context.fetch(:sidebar_col, DEFAULT_SIDEBAR_COL)
      end

      def render
        render_top_tabs
        render_bottom_tabs
      end

      private

      def render_top_tabs
        @top_tabs.each_with_index do |tab, idx|
          row = @start_row + (idx * @tab_height)
          render_tab(row, tab[:label], tab[:dest], align: :left)
        end
      end

      def render_bottom_tabs
        @bottom_tabs.each_with_index do |tab, idx|
          # Start from bottommost position and work upward
          row = GRID_ROWS - @tab_height - (idx * @tab_height)
          render_tab(row, tab[:label], tab[:dest], align: :right)
        end
      end

      def render_tab(row, label, dest, align:)
        # Check if this tab's destination matches current page
        is_current = current_page?(dest)

        # Use bold font and black color for current page, normal gray for others
        font_style = is_current ? "Helvetica-Bold" : "Helvetica"
        color = is_current ? '000000' : NAV_COLOR  # Black for current, gray for others

        @pdf.fill_color color
        @pdf.font font_style, size: FONT_SIZE

        # Calculate text area with padding
        # Top padding (becomes left after rotation): PADDING_BOXES at top
        # Right padding (to keep text within box): PADDING_BOXES at right
        text_height_pt = @grid_system.height(@tab_height - PADDING_BOXES)
        padding_pt = @grid_system.height(PADDING_BOXES)

        # Position for rotated text - rotate around center of tab region
        # Inset from right edge and adjust Y to push text down into box
        tab_x = @grid_system.x(@sidebar_col + 1) - padding_pt
        # Adjust Y center down by full padding to push text into the box with proper top margin
        tab_y_center = @grid_system.y(row) - @grid_system.height(@tab_height / 2.0) - padding_pt

        # Draw rotated text centered in the tab
        @pdf.rotate(-90, origin: [tab_x, tab_y_center]) do
          # Calculate text box position in rotated space
          text_x = tab_x - (text_height_pt / 2.0) - padding_pt
          text_y = tab_y_center + (@grid_system.width(1) / 2.0)

          @pdf.text_box label,
                        at: [text_x, text_y],
                        width: text_height_pt,
                        height: @grid_system.width(1),
                        align: align,
                        valign: :center
        end

        # Add clickable link for the entire tab region (skip link for current page)
        unless is_current
          @grid_system.link(@sidebar_col, row, 1, @tab_height, dest)
        end

        # Reset fill color
        @pdf.fill_color '000000'
      end
    end
  end
end
