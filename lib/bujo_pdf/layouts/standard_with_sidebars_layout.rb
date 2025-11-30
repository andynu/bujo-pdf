# frozen_string_literal: true

require_relative 'base_layout'
require_relative '../components/week_sidebar'
require_relative '../components/right_sidebar'

module BujoPdf
  module Layouts
    # Standard layout with left week sidebar and right navigation tabs.
    #
    # Layout structure:
    #   - Left sidebar (columns 0-1): Week list with month indicators (2 boxes)
    #   - Content area (columns 2-41): Page content (40 boxes wide)
    #   - Right sidebar (column 42): Year page tabs (1 box)
    #
    # This is the standard layout used by most planner pages including
    # weekly pages and year-at-a-glance pages.
    #
    # Options:
    #   - :current_week [Integer, nil] - Week number to highlight in week sidebar (nil for no highlight)
    #   - :highlight_tab [Symbol, nil] - Tab to highlight (:seasonal, :future_log_1, :future_log_2, :year_events, :year_highlights, :grids, nil)
    #   - :year [Integer] - Year for sidebar rendering (from page context if not provided)
    #   - :total_weeks [Integer] - Total weeks in year (from page context if not provided)
    #
    # Navigation Tab Multi-Tap Cycling:
    #   Tabs can cycle through multiple pages using destination arrays:
    #     { label: "Grids", dest: [:grids_overview, :grid_dot, :grid_graph, :grid_lined] }
    #
    #   When not on any page in the cycle, clicking goes to the first page.
    #   When on a page in the cycle, clicking advances to the next page.
    #   After the last page, clicking cycles back to the first.
    #   Tab is highlighted when on any page in the cycle.
    #
    # @example Weekly page (highlight current week, no tab highlight)
    #   use_layout :standard_with_sidebars,
    #     current_week: 42,
    #     highlight_tab: nil
    #
    # @example Year overview page (no week highlight, highlight specific tab)
    #   use_layout :standard_with_sidebars,
    #     current_week: nil,
    #     highlight_tab: :year_events
    class StandardWithSidebarsLayout < BaseLayout
      # Content area excluding sidebars.
      #
      # Content spans columns 2-41 (40 boxes wide) and full page height,
      # leaving space for left week sidebar (2 boxes) and right navigation tabs (1 box).
      #
      # @return [Hash] Content area specification
      def content_area
        {
          col: 2,              # Start after left sidebar (2 boxes)
          row: 0,              # Start at top
          width_boxes: 40,     # Columns 2-41 inclusive (40 boxes)
          height_boxes: 55     # Full page height
        }
      end

      # Render sidebars before page content.
      #
      # Draws both the left week sidebar and right navigation tabs with
      # appropriate highlighting based on layout options.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_before(page)
        render_week_sidebar(page)
        render_right_sidebar(page)
      end

      private

      def canvas
        @canvas ||= Canvas.new(@pdf, @grid_system)
      end

      # Render the left week sidebar.
      #
      # Shows a vertical list of all weeks in the year with month indicators.
      # Highlights the current week if specified in options.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_week_sidebar(page)
        # Extract year and total_weeks with fallbacks
        year = options[:year] || page.context[:year]
        total_weeks = options[:total_weeks] || page.context[:total_weeks]

        sidebar = Components::WeekSidebar.new(
          canvas: canvas,
          year: year,
          total_weeks: total_weeks,
          current_week_num: options[:current_week],
          page_context: page.context
        )
        sidebar.render
      end

      # Render the right navigation sidebar.
      #
      # Shows vertical tabs for year overview pages and dots page.
      # Highlights the specified tab if provided in options.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_right_sidebar(page)
        # Build tabs with highlighting
        top_tabs = build_top_tabs

        sidebar = Components::RightSidebar.new(
          canvas: canvas,
          top_tabs: top_tabs,
          bottom_tabs: [],
          page_context: page.context
        )
        sidebar.render
      end

      # Build top navigation tabs with optional highlighting.
      #
      # Creates tabs for seasonal calendar, events, highlights, multi-year, and grids pages.
      # Supports single destinations (strings/symbols) and multi-destination arrays for cycling.
      # Marks the appropriate tab as current if highlight_tab option is set.
      #
      # @return [Array<Hash>] Array of resolved tab specifications with :label, :dest, and :current
      def build_top_tabs
        tabs = [
          { label: "Year", dest: "seasonal" },
          { label: "Future", dest: [:future_log_1, :future_log_2] },
          { label: "Events", dest: "year_events" },
          { label: "Highlights", dest: "year_highlights" },
          { label: "Multi", dest: "multi_year" },
          { label: "Grids", dest: [:grid_showcase, :grids_overview, :grid_dot, :grid_graph, :grid_lined, :grid_isometric, :grid_perspective, :grid_hexagon] }
        ]

        # Resolve each tab (handles both single destinations and cycling arrays)
        tabs.map { |tab| resolve_tab_destination(tab) }
      end

      # Resolve tab destination based on current page and cycle position.
      #
      # For single destinations (string/symbol), returns tab with highlighting based on current page.
      # For destination arrays (multi-tap cycling), computes next destination in cycle.
      #
      # @param tab [Hash] Tab specification with :label and :dest
      # @return [Hash] Resolved tab with :label, :dest (string), and :current (boolean)
      #
      # @example Single destination
      #   resolve_tab_destination({ label: "Year", dest: "seasonal" })
      #   # => { label: "Year", dest: "seasonal", current: true/false }
      #
      # @example Multi-destination cycle (on first page in cycle)
      #   # When current page is :grids_overview
      #   resolve_tab_destination({ label: "Grids", dest: [:grids_overview, :grid_dot, :grid_graph] })
      #   # => { label: "Grids", dest: "grid_dot", current: true }
      #
      # @example Multi-destination cycle (not in cycle)
      #   # When current page is :week_1
      #   resolve_tab_destination({ label: "Grids", dest: [:grids_overview, :grid_dot, :grid_graph] })
      #   # => { label: "Grids", dest: "grids_overview", current: false }
      def resolve_tab_destination(tab)
        dest = tab[:dest]

        # Single destination: simple pass-through with highlighting
        if dest.is_a?(String) || dest.is_a?(Symbol)
          return {
            label: tab[:label],
            dest: dest.to_s,
            current: current_page?(dest) || highlight_matches?(dest)
          }
        end

        # Multi-destination array: compute cycle
        if dest.is_a?(Array)
          return resolve_cyclic_destination(tab[:label], dest)
        end

        # Unexpected type: raise error
        raise ArgumentError, "Tab destination must be String, Symbol, or Array, got #{dest.class}"
      end

      # Resolve cyclic destination for multi-tap navigation.
      #
      # Determines the next destination in the cycle based on the current page.
      # If not in cycle, goes to first page (entry point).
      # If in cycle, advances to next page (wraps to first after last).
      #
      # @param label [String] Tab label
      # @param dest_array [Array<Symbol>] Array of destination page keys
      # @return [Hash] Resolved tab with :label, :dest, and :current
      #
      # @example Not in cycle
      #   resolve_cyclic_destination("Grids", [:a, :b, :c])
      #   # => { label: "Grids", dest: "a", current: false }
      #
      # @example In cycle (first page)
      #   # When current page is :a
      #   resolve_cyclic_destination("Grids", [:a, :b, :c])
      #   # => { label: "Grids", dest: "b", current: true }
      #
      # @example In cycle (last page wraps to first)
      #   # When current page is :c
      #   resolve_cyclic_destination("Grids", [:a, :b, :c])
      #   # => { label: "Grids", dest: "a", current: true }
      def resolve_cyclic_destination(label, dest_array)
        # Find current page in cycle (nil if not in cycle)
        current_index = dest_array.index { |d| current_page?(d) }

        # Also check if highlight_tab matches any page in cycle
        highlight_index = if options[:highlight_tab]
                            dest_array.index { |d| d.to_s == options[:highlight_tab].to_s }
                          end

        # Determine which index to use (prefer current_index from actual page)
        active_index = current_index || highlight_index

        if active_index.nil?
          # Not in cycle: go to first page (entry point), not highlighted
          {
            label: label,
            dest: dest_array.first.to_s,
            current: false
          }
        else
          # In cycle: advance to next page (wrap around), highlighted
          next_index = (active_index + 1) % dest_array.size
          {
            label: label,
            dest: dest_array[next_index].to_s,
            current: true
          }
        end
      end

      # Check if currently rendering a specific page.
      #
      # Accesses the page context to determine current page key.
      # Must be called during render_before/render_after when page context is available.
      #
      # @param dest [Symbol, String] Destination to check
      # @return [Boolean] True if on specified page
      def current_page?(dest)
        # Access context through options (passed from page) or return false if unavailable
        return false unless options[:page_context]

        options[:page_context].current_page?(dest)
      end

      # Check if highlight_tab option matches destination.
      #
      # Used as fallback when page context isn't available yet.
      #
      # @param dest [Symbol, String] Destination to check
      # @return [Boolean] True if highlight_tab matches
      def highlight_matches?(dest)
        return false unless options[:highlight_tab]

        options[:highlight_tab].to_s == dest.to_s
      end
    end
  end
end
