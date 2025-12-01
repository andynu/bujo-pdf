# frozen_string_literal: true

require_relative '../base/component'
require_relative 'text'

module BujoPdf
  module Components
    # RightSidebar component for right sidebar tabs navigation.
    #
    # Renders a vertical list of navigation tabs on the right edge with:
    #   - All tabs stack from top with uniform point-based gaps
    #   - Rotated text (-90deg) for vertical reading
    #   - Rounded rectangle backgrounds (matching week sidebar style)
    #   - Current page: stroked border only
    #   - Other pages: 20% opacity filled background
    #   - Clickable links to destinations
    #
    # Grid positioning:
    #   - Column 42 (rightmost column, 1 box wide)
    #   - Tab heights calculated from text with uniform gaps
    #   - All tabs stack downward from top
    #
    # Example usage:
    #   canvas = Canvas.new(pdf, grid)
    #   sidebar = RightSidebar.new(
    #     canvas: canvas,
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
      include Text::Mixin
      DEFAULT_SIDEBAR_COL = 42
      FONT_SIZE = 8
      TAB_GAP_PT = 4           # Uniform gap between tabs in points
      TAB_PADDING_PT = 6       # Padding around text within each tab
      START_Y_OFFSET_PT = 14   # Start position from top of page in points

      def initialize(canvas:, top_tabs: [], bottom_tabs: [], sidebar_col: DEFAULT_SIDEBAR_COL, page_context: nil)
        super(canvas: canvas)
        @top_tabs = top_tabs
        @bottom_tabs = bottom_tabs
        @sidebar_col = sidebar_col
        @page_context = page_context
      end

      def render
        # Combine all tabs and render from top to bottom
        all_tabs = @top_tabs + @bottom_tabs
        render_tabs_from_top(all_tabs)
      end

      private

      def render_tabs_from_top(tabs)
        # Start from top of page with small offset
        page_top = grid.y(0)
        current_y = page_top - START_Y_OFFSET_PT

        tabs.each do |tab|
          # Calculate tab height based on text width (since it will be rotated)
          tab_height = calculate_tab_height(tab[:label])

          # Render this tab at current_y position
          render_tab_at_y(current_y, tab_height, tab)

          # Move down for next tab (add gap)
          current_y -= (tab_height + TAB_GAP_PT)
        end
      end

      def calculate_tab_height(label)
        # Measure text width (which becomes height when rotated)
        # Save current font, set measurement font, then restore
        text_width = nil
        pdf.font("Helvetica", size: FONT_SIZE) do
          text_width = pdf.width_of(label)
        end
        text_width + (TAB_PADDING_PT * 2)
      end

      def render_tab_at_y(top_y, height, tab)
        label = tab[:label]
        dest = tab[:dest]
        # Use current flag from layout (handles cycling tabs correctly)
        is_current = tab[:current] || false

        # Calculate tab rectangle coordinates
        tab_width = grid.width(1)
        tab_left = grid.x(@sidebar_col)
        tab_right = tab_left + tab_width
        tab_top = top_y
        tab_bottom = top_y - height

        # Draw background rectangle first
        draw_tab_background(tab_left, tab_top, tab_width, height, is_current)

        # Draw the rotated text
        draw_tab_text(tab_left, tab_top, tab_width, height, label, is_current)

        # Add clickable link (skip for current page)
        unless is_current
          pdf.link_annotation([tab_left, tab_bottom, tab_right, tab_top],
                               Dest: dest,
                               Border: [0, 0, 0])
        end
      end

      def draw_tab_background(left, top, width, height, is_current)
        require_relative '../themes/theme_registry'
        border_color = BujoPdf::Themes.current[:colors][:borders]

        # Small inset from edges for visual breathing room
        inset = 2
        rect_left = left + inset
        rect_width = width - (inset * 2)
        rect_top = top - inset
        rect_height = height - (inset * 2)

        if is_current
          # Current tab: stroked border only (no fill)
          pdf.stroke_color border_color
          pdf.stroke_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
        else
          # Other tabs: 20% opacity filled background
          pdf.transparent(0.2) do
            pdf.fill_color border_color
            pdf.fill_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
          end
        end

        # Reset colors
        text_color = BujoPdf::Themes.current[:colors][:text_black]
        pdf.fill_color text_color
        pdf.stroke_color text_color
      end

      def draw_tab_text(left, top, width, height, label, is_current)
        require_relative '../themes/theme_registry'

        # Font style and color based on current state
        font_style = is_current ? :bold : :normal
        color = is_current ? BujoPdf::Themes.current[:colors][:text_black] : BujoPdf::Themes.current[:colors][:text_gray]

        # Use Text component with centered rotation mode
        # - Center point is the middle of the tab rectangle
        # - Text box dimensions are (height-padding, width) which after -90 rotation
        #   becomes vertical extent = height-padding, horizontal extent = width
        text(
          0, 0, label,
          rotation: -90,
          size: FONT_SIZE,
          style: font_style,
          color: color,
          align: :center,
          pt_x: left + (width / 2.0),
          pt_y: top - (height / 2.0),
          pt_width: height - (TAB_PADDING_PT * 2),
          pt_height: width,
          centered: true
        )
      end
    end
  end
end
