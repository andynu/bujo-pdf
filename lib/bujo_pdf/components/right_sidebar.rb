# frozen_string_literal: true

require_relative '../base/sidebar_base'
require_relative '../sidebars/sidebar_registry'
require_relative '../utilities/tab_resolver'
require_relative 'link_box'

module BujoPdf
  module Components
    # TabSidebar component for right sidebar tabs navigation.
    # (Also aliased as RightSidebar for backward compatibility)
    #
    # Renders a vertical list of navigation tabs on the right edge with:
    #   - All tabs stack from top with uniform point-based gaps
    #   - Rotated text (-90deg) for vertical reading
    #   - Rounded rectangle backgrounds via LinkBox
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
    #   sidebar = TabSidebar.new(
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
    class TabSidebar < SidebarBase
      include Sidebars::SidebarRegistry
      include LinkBox::Mixin

      register_sidebar :tab_sidebar

      DEFAULT_SIDEBAR_COL = 42
      FONT_SIZE = 8
      TAB_GAP_PT = 4           # Uniform gap between tabs in points
      TAB_PADDING_PT = 6       # Padding around text within each tab
      START_Y_OFFSET_PT = 14   # Start position from top of page in points

      def initialize(canvas:, top_tabs: [], bottom_tabs: [], sidebar_col: DEFAULT_SIDEBAR_COL, page_context: nil)
        super(canvas: canvas, page_context: page_context)
        @top_tabs = top_tabs
        @bottom_tabs = bottom_tabs
        @sidebar_col = sidebar_col
      end

      def render
        # Combine all tabs and resolve destinations
        all_tabs = @top_tabs + @bottom_tabs
        resolved_tabs = resolve_tabs(all_tabs)
        render_tabs_from_top(resolved_tabs)
      end

      private

      # Resolve tab destinations using TabResolver.
      #
      # Tabs that already have :current set pass through unchanged.
      # Other tabs get resolved with page_context-aware highlighting.
      #
      # @param tabs [Array<Hash>] Tab configurations
      # @return [Array<Hash>] Resolved tabs with :label, :dest, :current
      def resolve_tabs(tabs)
        resolver = Utilities::TabResolver.new(page_context: page_context)
        resolver.resolve_all(tabs)
      end

      def render_tabs_from_top(tabs)
        # Start from top of page with small offset
        page_top = grid.y(0)
        current_y = page_top - START_Y_OFFSET_PT

        tabs.each do |tab|
          # Calculate tab height based on text width (since it will be rotated)
          is_current = tab[:current] || false
          tab_height = calculate_tab_height(tab[:label], bold: is_current)

          # Render this tab at current_y position
          render_tab_at_y(current_y, tab_height, tab)

          # Move down for next tab (add gap)
          current_y -= (tab_height + TAB_GAP_PT)
        end
      end

      def calculate_tab_height(label, bold: false)
        # Measure text width (which becomes height when rotated)
        # Bold text is wider, so use correct font for accurate measurement
        font_name = bold ? "Helvetica-Bold" : "Helvetica"
        text_width = nil
        pdf.font(font_name, size: FONT_SIZE) do
          text_width = pdf.width_of(label)
        end
        text_width + (TAB_PADDING_PT * 2)
      end

      def render_tab_at_y(top_y, height, tab)
        is_current = tab[:current] || false
        tab_width = grid.width(1)
        tab_left = grid.x(@sidebar_col)

        # Use LinkBox with pt_ overrides for dynamic positioning
        link_box(
          0, 0, 1, 1, tab[:label],
          dest: tab[:dest],
          current: is_current,
          rotation: -90,
          font_size: FONT_SIZE,
          inset: 2,
          pt_x: tab_left,
          pt_y: top_y,
          pt_width: tab_width,
          pt_height: height
        )
      end
    end

    # Backward compatibility alias
    RightSidebar = TabSidebar

    # Register :right_sidebar as alias for :tab_sidebar
    Sidebars::SidebarRegistry.register(:right_sidebar, TabSidebar)
  end
end
