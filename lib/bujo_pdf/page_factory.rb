# frozen_string_literal: true

require_relative 'pages/base'
require_relative 'pages/daily_wheel'
require_relative 'pages/grid_showcase'
require_relative 'pages/grids_overview'
require_relative 'pages/grids/dot_grid_page'
require_relative 'pages/grids/graph_grid_page'
require_relative 'pages/grids/hexagon_grid_page'
require_relative 'pages/grids/isometric_grid_page'
require_relative 'pages/grids/lined_grid_page'
require_relative 'pages/grids/perspective_grid_page'
require_relative 'pages/index_pages'
require_relative 'pages/future_log'
require_relative 'pages/collection_page'
require_relative 'pages/reference_calibration'
require_relative 'pages/seasonal_calendar'
require_relative 'pages/year_at_glance_events'
require_relative 'pages/year_at_glance_highlights'
require_relative 'pages/year_wheel'
require_relative 'pages/multi_year_overview'

module BujoPdf
  # Factory for creating page instances.
  #
  # The PageFactory manages the registry of available page types and
  # provides methods for instantiating pages with the correct dependencies.
  #
  # Example:
  #   page = PageFactory.create(:dots, pdf, { year: 2025 })
  #   page.generate
  #
  #   # Register a custom page type
  #   PageFactory.register(:custom, MyCustomPage)
  class PageFactory
    # Registry mapping page keys to page classes
    @registry = {
      daily_wheel: Pages::DailyWheel,
      grid_showcase: Pages::GridShowcase,
      grids_overview: Pages::GridsOverview,
      grid_dot: Pages::Grids::DotGridPage,
      grid_graph: Pages::Grids::GraphGridPage,
      grid_hexagon: Pages::Grids::HexagonGridPage,
      grid_isometric: Pages::Grids::IsometricGridPage,
      grid_lined: Pages::Grids::LinedGridPage,
      grid_perspective: Pages::Grids::PerspectiveGridPage,
      index: Pages::IndexPage,
      future_log: Pages::FutureLog,
      collection: Pages::CollectionPage,
      reference: Pages::ReferenceCalibration,
      seasonal: Pages::SeasonalCalendar,
      year_events: Pages::YearAtGlanceEvents,
      year_highlights: Pages::YearAtGlanceHighlights,
      year_wheel: Pages::YearWheel,
      multi_year: Pages::MultiYearOverview
    }

    class << self
      attr_reader :registry

      # Create a page instance.
      #
      # @param page_key [Symbol] The page type key (e.g., :dots, :seasonal)
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [Hash] Rendering context (year, week_num, etc.)
      # @raise [ArgumentError] if the page type is not registered
      # @return [Pages::Base] A page instance ready to generate
      def create(page_key, pdf, context)
        page_class = registry[page_key]
        raise ArgumentError, "Unknown page type: #{page_key}" unless page_class

        page_class.new(pdf, context)
      end

      # Register a custom page type.
      #
      # @param page_key [Symbol] The page type key to register
      # @param page_class [Class] The page class (must inherit from Pages::Base)
      # @raise [ArgumentError] if the page class doesn't inherit from Pages::Base
      # @return [void]
      def register(page_key, page_class)
        unless page_class < Pages::Base
          raise ArgumentError, "Page class must inherit from Pages::Base"
        end

        @registry = registry.merge(page_key => page_class)
      end

      # Create a weekly page instance.
      #
      # This is a specialized factory method for creating weekly pages with
      # the appropriate context (week number, start/end dates).
      #
      # @param week_num [Integer] The week number (1-52 or 1-53)
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [Hash] Base rendering context (must include :year)
      # @return [Pages::Base] A weekly page instance ready to generate
      def create_weekly_page(week_num, pdf, context)
        require_relative 'utilities/date_calculator'
        require_relative 'pages/weekly_page'

        year = context[:year]
        context_with_week = context.merge(
          week_num: week_num,
          week_start: Utilities::DateCalculator.week_start(year, week_num),
          week_end: Utilities::DateCalculator.week_end(year, week_num)
        )

        Pages::WeeklyPage.new(pdf, context_with_week)
      end

      # Create an index page instance.
      #
      # This is a specialized factory method for creating index pages with
      # the appropriate context (index page number, total count).
      #
      # @param index_page_num [Integer] The index page number (1, 2, 3...)
      # @param index_page_count [Integer] Total number of index pages
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [Hash] Base rendering context
      # @return [Pages::Base] An index page instance ready to generate
      def create_index_page(index_page_num, index_page_count, pdf, context)
        require_relative 'pages/index_pages'
        require_relative 'render_context'

        context_with_index = context.is_a?(RenderContext) ? context.to_h : context
        context_with_index = context_with_index.merge(
          page_key: "index_#{index_page_num}".to_sym,
          index_page_num: index_page_num,
          index_page_count: index_page_count
        )

        Pages::IndexPage.new(pdf, context_with_index)
      end
    end
  end
end
