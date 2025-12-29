# frozen_string_literal: true

require_relative 'base_layout'
require_relative '../components/month_sidebar'
require_relative '../components/right_sidebar'

module BujoPdf
  module Layouts
    # Daily layout with left month sidebar and right navigation tabs.
    #
    # Similar to StandardWithSidebarsLayout but uses MonthSidebar instead
    # of WeekSidebar, making it appropriate for daily planners where
    # 365 pages would overwhelm a week-based navigation.
    #
    # Layout structure:
    #   - Left sidebar (columns 0-1): Month list (2 boxes)
    #   - Content area (columns 2-41): Page content (40 boxes wide)
    #   - Right sidebar (column 42): Year page tabs (1 box)
    #
    # Options:
    #   - :current_month [Integer, nil] - Month to highlight (1-12, nil for auto-detect)
    #   - :highlight_tab [Symbol, nil] - Tab to highlight
    #   - :year [Integer] - Year for sidebar rendering
    #
    # @example Daily page (auto-highlight current month)
    #   use_layout :daily_with_sidebars
    #
    # @example Specific month highlight
    #   use_layout :daily_with_sidebars, current_month: 3
    class DailyWithSidebarsLayout < BaseLayout
      # Content area excluding sidebars.
      #
      # Content spans columns 2-41 (40 boxes wide) and full page height,
      # leaving space for left month sidebar (2 boxes) and right navigation tabs (1 box).
      #
      # @return [Hash] Content area specification
      def content_area
        {
          col: 2,
          row: 0,
          width_boxes: 40,
          height_boxes: 55
        }
      end

      # Render sidebars before page content.
      #
      # Draws both the left month sidebar and right navigation tabs.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_before(page)
        render_month_sidebar(page)
        render_right_sidebar(page)
      end

      private

      def canvas
        @canvas ||= Canvas.new(@pdf, @grid_system)
      end

      # Render the left month sidebar.
      #
      # Shows a vertical list of all months in the year.
      # Highlights the current month based on the day being viewed.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_month_sidebar(page)
        year = options[:year] || page.context[:year]

        sidebar = Components::MonthSidebar.new(
          canvas: canvas,
          year: year,
          current_month: options[:current_month],
          page_context: page.context
        )
        sidebar.render
      end

      # Render the right navigation sidebar.
      #
      # Shows vertical tabs for year overview pages.
      # Uses same tab configuration as standard layout.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_right_sidebar(page)
        top_tabs = build_top_tabs

        sidebar = Components::RightSidebar.new(
          canvas: canvas,
          top_tabs: top_tabs,
          bottom_tabs: [],
          page_context: page.context
        )
        sidebar.render
      end

      # Build top navigation tabs.
      #
      # @return [Array<Hash>] Array of tab specifications
      def build_top_tabs
        tabs = [
          { label: "Year", dest: "seasonal" },
          { label: "Future", dest: [:future_log_1, :future_log_2] },
          { label: "Events", dest: "year_events" },
          { label: "Highlights", dest: "year_highlights" },
          { label: "Multi", dest: "multi_year" },
          { label: "Grids", dest: [:grid_showcase, :grids_overview, :grid_dot, :grid_graph, :grid_lined, :grid_isometric, :grid_perspective, :grid_hexagon] }
        ]

        tabs.map { |tab| resolve_tab_destination(tab) }
      end

      def resolve_tab_destination(tab)
        dest = tab[:dest]

        if dest.is_a?(String) || dest.is_a?(Symbol)
          return {
            label: tab[:label],
            dest: dest.to_s,
            current: current_page?(dest) || highlight_matches?(dest)
          }
        end

        if dest.is_a?(Array)
          return resolve_cyclic_destination(tab[:label], dest)
        end

        raise ArgumentError, "Tab destination must be String, Symbol, or Array, got #{dest.class}"
      end

      def resolve_cyclic_destination(label, dest_array)
        current_index = dest_array.index { |d| current_page?(d) }

        highlight_index = if options[:highlight_tab]
                            dest_array.index { |d| d.to_s == options[:highlight_tab].to_s }
                          end

        active_index = current_index || highlight_index

        if active_index
          next_index = (active_index + 1) % dest_array.size
          return {
            label: label,
            dest: dest_array[next_index].to_s,
            current: true
          }
        end

        {
          label: label,
          dest: dest_array.first.to_s,
          current: false
        }
      end

      def current_page?(dest)
        return false unless options[:page_context]
        options[:page_context].current_page?(dest)
      end

      def highlight_matches?(dest)
        return false unless options[:highlight_tab]
        options[:highlight_tab].to_s == dest.to_s
      end
    end
  end
end
