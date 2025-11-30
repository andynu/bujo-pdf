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
    # Uses DocumentBuilder with the new `page` and `page_set` DSL for
    # declarative document definition. Page classes auto-register their
    # type, title, and destination patterns via `register_page`.
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
        @seasonal = page :seasonal

        page_set :index, label: "Index %page of %total" do
          INDEX_PAGE_COUNT.times { page :index }
        end

        page_set :future_log, label: "Future Log %page of %total" do
          FUTURE_LOG_PAGE_COUNT.times { page :future_log }
        end

        # 2. Year overview pages
        @year_events = page :year_events
        @year_highlights = page :year_highlights
        @multi_year = page :multi_year

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
              @quarterly_plans[quarter] = page :quarterly_planning, quarter: quarter
              generated_quarters.add(quarter)
            end

            # Monthly review at month boundaries
            unless generated_months.include?(month)
              @monthly_reviews[month] = page :monthly_review, month: month
              generated_months.add(month)
            end
          end

          @week_pages << page(:weekly, week_num: week.number)
        end

        # 4. Grid pages (with cycling navigation)
        page_set :grids, cycle: true do
          page :grid_showcase
          page :grids_overview
          page :grid_dot
          page :grid_graph
          page :grid_lined
          page :grid_isometric
          page :grid_perspective
          page :grid_hexagon
        end

        # 5. Template pages
        @tracker_example = page :tracker_example
        @reference = page :reference
        @daily_wheel = page :daily_wheel
        @year_wheel = page :year_wheel

        # 6. Collections
        @collection_pages = {}
        collections.each do |collection|
          @collection_pages[collection[:id]] = page :collection,
            collection_id: collection[:id],
            collection_title: collection[:title],
            collection_subtitle: collection[:subtitle]
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
