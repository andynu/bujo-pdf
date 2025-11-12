# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Base class for pages that use the standard sidebar layout.
    #
    # Automatically sets up:
    # - Left week sidebar
    # - Right navigation tabs
    # - Content area for page content
    #
    # Subclasses must implement:
    # - current_week: Which week to highlight (or nil)
    # - highlight_tab: Which tab to highlight (or nil)
    #
    # @example Year overview page
    #   class YearAtGlanceEvents < StandardLayoutPage
    #     protected
    #
    #     def current_week
    #       nil  # Year overview doesn't highlight weeks
    #     end
    #
    #     def highlight_tab
    #       :year_events  # Highlight the Events tab
    #     end
    #
    #     def render_content
    #       # Render year-at-a-glance grid here
    #     end
    #   end
    #
    # @example Weekly page
    #   class WeeklyPage < StandardLayoutPage
    #     protected
    #
    #     def current_week
    #       context.week_num  # Highlight this week in sidebar
    #     end
    #
    #     def highlight_tab
    #       nil  # Weekly pages don't highlight tabs
    #     end
    #
    #     def render_content
    #       # Render daily section and Cornell notes here
    #     end
    #   end
    class StandardLayoutPage < Base
      def setup
        use_layout :standard_with_sidebars,
          current_week: current_week,
          highlight_tab: highlight_tab,
          year: year_for_layout,
          total_weeks: total_weeks_for_layout
      end

      protected

      # Which week to highlight in sidebar (override in subclass).
      #
      # @return [Integer, nil] Week number or nil for no highlight
      def current_week
        nil
      end

      # Which tab to highlight in right sidebar (override in subclass).
      #
      # @return [Symbol, nil] Tab key or nil for no highlight
      def highlight_tab
        nil
      end

      # Year value for layout (override in subclass if needed).
      #
      # Defaults to context[:year]. Subclasses can override if they compute
      # year differently (e.g., storing in @year instance variable).
      #
      # @return [Integer] Year value
      def year_for_layout
        @year || context[:year]
      end

      # Total weeks value for layout (override in subclass if needed).
      #
      # Defaults to context[:total_weeks]. Subclasses can override if they
      # compute total weeks differently (e.g., storing in @total_weeks).
      #
      # @return [Integer] Total weeks in year
      def total_weeks_for_layout
        @total_weeks || context[:total_weeks]
      end
    end
  end
end
