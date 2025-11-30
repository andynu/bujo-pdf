# frozen_string_literal: true

module BujoPdf
  module Pages
    # Aggregates all page mixins for inclusion in document builders.
    #
    # This module mirrors Components::All but for pages. Each page class
    # defines a Mixin module with verb methods, and this module includes
    # all of them, providing a single include point.
    #
    # Instance Variable Contract:
    # Classes including Pages::All must provide:
    # - @pdf [Prawn::Document] - The PDF document
    # - @year [Integer] - The year being generated
    # - @date_config [DateConfiguration, nil] - Date configuration
    # - @event_store [EventStore, nil] - Calendar events
    # - @total_pages [Integer, nil] - Total pages (estimate)
    #
    # Example:
    #   class MyBuilder
    #     include BujoPdf::Pages::All
    #
    #     def initialize(year)
    #       @year = year
    #       @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    #       @date_config = nil
    #       @event_store = nil
    #       @total_pages = 100
    #       BujoPdf::DotGrid.create_stamp(@pdf, "page_dots")
    #     end
    #
    #     def build
    #       seasonal_calendar
    #       index_pages(count: 2)
    #       weekly_pages
    #       grid_pages
    #     end
    #   end
    #
    # Adding a new page verb:
    #   1. Add a Mixin module to the page class
    #   2. Include MixinSupport in the Mixin
    #   3. Define the verb method(s)
    #   4. Add base.include PageClass::Mixin here
    module All
      # Composite verbs that combine multiple page verbs.
      #
      # These are defined directly in All rather than in individual page classes
      # because they aggregate multiple pages.
      module CompositeVerbs
        # Generate all grid pages in sequence.
        #
        # This is a convenience method that generates all 8 grid pages:
        # showcase, overview, dot, graph, lined, isometric, perspective, hexagon.
        #
        # @return [void]
        def grid_pages
          grid_showcase_page
          grids_overview_page
          dot_grid_page
          graph_grid_page
          lined_grid_page
          isometric_grid_page
          perspective_grid_page
          hexagon_grid_page
        end

        # Generate all template pages in sequence.
        #
        # Includes tracker example, reference/calibration, and wheel pages.
        #
        # @return [void]
        def template_pages
          tracker_example_page
          reference_page
          daily_wheel_page
          year_wheel_page
        end
      end

      def self.included(base)
        # Include shared helpers first
        base.include MixinSupport

        # Simple pages (no parameters)
        base.include SeasonalCalendar::Mixin
        base.include YearAtGlanceEvents::Mixin
        base.include YearAtGlanceHighlights::Mixin
        base.include MultiYearOverview::Mixin

        # Parameterized pages
        base.include IndexPage::Mixin
        base.include FutureLog::Mixin
        base.include WeeklyPage::Mixin
        base.include MonthlyReview::Mixin
        base.include QuarterlyPlanning::Mixin
        base.include CollectionPage::Mixin

        # Grid pages
        base.include GridShowcase::Mixin
        base.include GridsOverview::Mixin
        base.include Grids::DotGridPage::Mixin
        base.include Grids::GraphGridPage::Mixin
        base.include Grids::LinedGridPage::Mixin
        base.include Grids::IsometricGridPage::Mixin
        base.include Grids::PerspectiveGridPage::Mixin
        base.include Grids::HexagonGridPage::Mixin

        # Template pages
        base.include TrackerExample::Mixin
        base.include ReferenceCalibration::Mixin
        base.include DailyWheel::Mixin
        base.include YearWheel::Mixin

        # Composite verbs (must be included after individual page mixins)
        base.include CompositeVerbs
      end
    end
  end
end
