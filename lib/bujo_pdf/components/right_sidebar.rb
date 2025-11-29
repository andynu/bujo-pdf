# frozen_string_literal: true

require_relative '../component'

module BujoPdf
  module Components
    # RightSidebar component for right sidebar tabs navigation.
    #
    # Renders a vertical list of navigation tabs on the right edge with:
    #   - All tabs stack from top with uniform point-based gaps
    #   - Rotated text (-90°) for vertical reading
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
      DEFAULT_SIDEBAR_COL = 42
      FONT_SIZE = 8
      TAB_GAP_PT = 4           # Uniform gap between tabs in points
      TAB_PADDING_PT = 6       # Padding around text within each tab
      START_Y_OFFSET_PT = 14   # Start position from top of page in points

      def initialize(pdf, grid_system, **options)
        super
        @top_tabs = context.fetch(:top_tabs, [])
        @bottom_tabs = context.fetch(:bottom_tabs, [])
        @sidebar_col = context.fetch(:sidebar_col, DEFAULT_SIDEBAR_COL)
        @page_context = context[:page_context]  # RenderContext for current_page? detection
      end

      def render
        # Combine all tabs and render from top to bottom
        all_tabs = @top_tabs + @bottom_tabs
        render_tabs_from_top(all_tabs)
      end

      private

      # Override current_page? to use the page's RenderContext
      def current_page?(dest)
        return false unless @page_context
        @page_context.respond_to?(:current_page?) && @page_context.current_page?(dest)
      end

      def render_tabs_from_top(tabs)
        # Start from top of page with small offset
        page_top = @grid.y(0)
        current_y = page_top - START_Y_OFFSET_PT

        tabs.each do |tab|
          # Calculate tab height based on text width (since it will be rotated)
          tab_height = calculate_tab_height(tab[:label])

          # Render this tab at current_y position
          render_tab_at_y(current_y, tab_height, tab[:label], tab[:dest])

          # Move down for next tab (add gap)
          current_y -= (tab_height + TAB_GAP_PT)
        end
      end

      def calculate_tab_height(label)
        # Measure text width (which becomes height when rotated)
        # Save current font, set measurement font, then restore
        text_width = nil
        @pdf.font("Helvetica", size: FONT_SIZE) do
          text_width = @pdf.width_of(label)
        end
        text_width + (TAB_PADDING_PT * 2)
      end

      def render_tab_at_y(top_y, height, label, dest)
        # Check if this tab's destination matches current page
        is_current = current_page?(dest)

        # Calculate tab rectangle coordinates
        tab_width = @grid.width(1)
        tab_left = @grid.x(@sidebar_col)
        tab_right = tab_left + tab_width
        tab_top = top_y
        tab_bottom = top_y - height

        # Draw background rectangle first
        draw_tab_background(tab_left, tab_top, tab_width, height, is_current)

        # Draw the rotated text
        draw_tab_text(tab_left, tab_top, tab_width, height, label, is_current)

        # Add clickable link (skip for current page)
        unless is_current
          @pdf.link_annotation([tab_left, tab_bottom, tab_right, tab_top],
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
          @pdf.stroke_color border_color
          @pdf.stroke_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
        else
          # Other tabs: 20% opacity filled background
          @pdf.transparent(0.2) do
            @pdf.fill_color border_color
            @pdf.fill_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
          end
        end

        # Reset colors
        text_color = BujoPdf::Themes.current[:colors][:text_black]
        @pdf.fill_color text_color
        @pdf.stroke_color text_color
      end

      def draw_tab_text(left, top, width, height, label, is_current)
        require_relative '../themes/theme_registry'

        # Font and color based on current state
        font_style = is_current ? "Helvetica-Bold" : "Helvetica"
        color = is_current ? BujoPdf::Themes.current[:colors][:text_black] : BujoPdf::Themes.current[:colors][:text_gray]

        with_font(font_style, FONT_SIZE) do
          with_fill_color(color) do
            # Center point of the tab for rotation
            center_x = left + (width / 2.0)
            center_y = top - (height / 2.0)

            # Rotate -90 degrees (clockwise) for top-to-bottom reading
            @pdf.rotate(-90, origin: [center_x, center_y]) do
              # After rotation, the text box needs to be positioned relative to center
              # Text width becomes the height dimension, text height becomes width
              text_box_width = height - (TAB_PADDING_PT * 2)
              text_box_height = width

              # Position text box so it's centered on the rotation point
              text_x = center_x - (text_box_width / 2.0)
              text_y = center_y + (text_box_height / 2.0)

              @pdf.text_box label,
                            at: [text_x, text_y],
                            width: text_box_width,
                            height: text_box_height,
                            align: :center,
                            valign: :center
            end
          end
        end
      end
    end
  end
end
