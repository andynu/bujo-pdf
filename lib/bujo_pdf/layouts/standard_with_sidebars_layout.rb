# frozen_string_literal: true

require_relative 'base_layout'
require_relative '../components/week_sidebar'
require_relative '../components/right_sidebar'

module BujoPdf
  module Layouts
    # Standard layout with left week sidebar and right navigation tabs.
    #
    # Layout structure:
    #   - Left sidebar (columns 0-2): Week list with month indicators
    #   - Content area (columns 3-41): Page content (39 boxes wide)
    #   - Right sidebar (column 42): Year page tabs
    #
    # This is the standard layout used by most planner pages including
    # weekly pages and year-at-a-glance pages.
    #
    # Options:
    #   - :current_week [Integer, nil] - Week number to highlight in week sidebar (nil for no highlight)
    #   - :highlight_tab [Symbol, nil] - Tab to highlight (:seasonal, :year_events, :year_highlights, nil)
    #   - :year [Integer] - Year for sidebar rendering (from page context if not provided)
    #   - :total_weeks [Integer] - Total weeks in year (from page context if not provided)
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
      # Content spans columns 3-41 (39 boxes wide) and full page height,
      # leaving space for left week sidebar and right navigation tabs.
      #
      # @return [Hash] Content area specification
      def content_area
        {
          col: 3,              # Start after left sidebar (3 boxes)
          row: 0,              # Start at top
          width_boxes: 39,     # Columns 3-41 inclusive (39 boxes)
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
          @pdf,
          @grid_system,
          year: year,
          total_weeks: total_weeks,
          current_week_num: options[:current_week]
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
          @pdf,
          @grid_system,
          top_tabs: top_tabs,
          bottom_tabs: [
            { label: "Dots", dest: "dots" }
          ]
        )
        sidebar.render
      end

      # Build top navigation tabs with optional highlighting.
      #
      # Creates tabs for seasonal calendar, events, and highlights pages.
      # Marks the appropriate tab as current if highlight_tab option is set.
      #
      # @return [Array<Hash>] Array of tab specifications
      def build_top_tabs
        tabs = [
          { label: "Year", dest: "seasonal" },
          { label: "Events", dest: "year_events" },
          { label: "Highlights", dest: "year_highlights" }
        ]

        # Apply highlighting if specified
        if options[:highlight_tab]
          highlight_dest = options[:highlight_tab].to_s
          tabs.each do |tab|
            tab[:current] = (tab[:dest] == highlight_dest)
          end
        end

        tabs
      end
    end
  end
end
