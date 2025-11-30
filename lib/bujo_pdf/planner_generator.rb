# frozen_string_literal: true

require 'prawn'
require 'date'
require 'set'
require_relative 'utilities/date_calculator'
require_relative 'document_builder'
require_relative 'date_configuration'
require_relative 'calendar_integration'
require_relative 'collections_configuration'
require_relative 'week'

module BujoPdf
  # Main planner generator orchestrator.
  #
  # This class coordinates the generation of a complete year planner PDF
  # using DocumentBuilder for automatic page tracking and outline generation.
  #
  # Example:
  #   generator = PlannerGenerator.new(2025)
  #   generator.generate("planner_2025.pdf")
  class PlannerGenerator
    # Page count constants
    INDEX_PAGE_COUNT = 2
    FUTURE_LOG_PAGE_COUNT = 2

    attr_reader :year, :date_config, :event_store, :collections_config

    def initialize(year = Date.today.year, config_path: 'config/dates.yml',
                   calendars_config_path: 'config/calendars.yml',
                   collections_config_path: 'config/collections.yml')
      @year = year
      @config_path = config_path
      @calendars_config_path = calendars_config_path
      @collections_config_path = collections_config_path
      @date_config = DateConfiguration.new(config_path, year: year)
      @event_store = load_calendar_events(calendars_config_path)
      @collections_config = CollectionsConfiguration.new(collections_config_path)
    end

    # Generate the complete planner PDF.
    #
    # Uses DocumentBuilder for automatic page tracking. All page verbs
    # return PageRef objects during the define phase, which are then
    # rendered in order with their page numbers captured automatically.
    #
    # @param filename [String] Output filename (default: planner_YEAR.pdf)
    # @return [DocumentBuilder] The builder instance with all page refs
    def generate(filename = "planner_#{@year}.pdf")
      year = @year
      collections = @collections_config.collections

      DocumentBuilder.generate(
        filename,
        year: year,
        config_path: @config_path,
        calendars_config_path: @calendars_config_path,
        collections_config_path: @collections_config_path
      ) do
        # 1. Front matter: Seasonal calendar, Index, Future log
        @seasonal = seasonal_calendar

        @index_pages = []
        INDEX_PAGE_COUNT.times do |i|
          @index_pages << index_page(num: i + 1, total: INDEX_PAGE_COUNT)
        end

        @future_log_pages = []
        FUTURE_LOG_PAGE_COUNT.times do |i|
          @future_log_pages << future_log_page(num: i + 1, total: FUTURE_LOG_PAGE_COUNT)
        end

        # 2. Year overview pages
        @year_events = year_events_page
        @year_highlights = year_highlights_page
        @multi_year = multi_year_page

        # 3. Weekly pages with interleaved monthly reviews and quarterly planning
        @week_pages = []
        @monthly_reviews = {}
        @quarterly_plans = {}

        generated_months = Set.new
        generated_quarters = Set.new

        weeks_in(year).each do |week|
          # Insert interleaved pages for weeks that start in the target year
          if week.in_year?
            month = week.month
            quarter = week.quarter

            # Quarterly planning at quarter boundaries
            unless generated_quarters.include?(quarter)
              @quarterly_plans[quarter] = quarterly_planning_page(quarter: quarter)
              generated_quarters.add(quarter)
            end

            # Monthly review at month boundaries
            unless generated_months.include?(month)
              @monthly_reviews[month] = monthly_review_page(month: month)
              generated_months.add(month)
            end
          end

          @week_pages << weekly_page(week: week.number)
        end

        # 4. Grid pages
        @grid_showcase = grid_showcase_page
        @grids_overview = grids_overview_page
        @grid_dot = dot_grid_page
        @grid_graph = graph_grid_page
        @grid_lined = lined_grid_page
        @grid_isometric = isometric_grid_page
        @grid_perspective = perspective_grid_page
        @grid_hexagon = hexagon_grid_page

        # 5. Template pages
        @tracker_example = tracker_example_page
        @reference = reference_page
        @daily_wheel = daily_wheel_page
        @year_wheel = year_wheel_page

        # 6. Collections
        @collection_pages = {}
        collections.each do |collection|
          @collection_pages[collection[:id]] = collection_page(
            id: collection[:id],
            title: collection[:title],
            subtitle: collection[:subtitle]
          )
        end
      end
    end

    private

    def load_calendar_events(config_path)
      return nil unless File.exist?(config_path)

      CalendarIntegration.load_events(config_path: config_path, year: @year)
    end
  end
end
