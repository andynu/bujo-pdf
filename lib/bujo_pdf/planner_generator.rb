# frozen_string_literal: true

require 'prawn'
require 'date'
require 'set'
require_relative 'utilities/date_calculator'
require_relative 'utilities/dot_grid'
require_relative 'page_factory'
require_relative 'render_context'
require_relative 'date_configuration'
require_relative 'calendar_integration'
require_relative 'collections_configuration'
require_relative 'pages/all'
require_relative 'week'

module BujoPdf
  # Main planner generator orchestrator.
  #
  # This class coordinates the generation of a complete year planner PDF.
  # It uses page verb mixins from Pages::All to generate individual pages
  # with proper context and footer labels.
  #
  # Example:
  #   generator = PlannerGenerator.new(2025)
  #   generator.generate("planner_2025.pdf")
  class PlannerGenerator
    include Pages::All

    # Page dimensions
    PAGE_WIDTH = 612    # 8.5 inches (letter size)
    PAGE_HEIGHT = 792   # 11 inches

    # Page count constants
    INDEX_PAGE_COUNT = 2
    FUTURE_LOG_PAGE_COUNT = 2
    MONTHLY_REVIEW_COUNT = 12
    QUARTERLY_PLANNING_COUNT = 4
    GRID_PAGE_COUNT = 8
    TEMPLATE_PAGE_COUNT = 4

    attr_reader :year, :pdf, :date_config, :event_store, :collections_config

    def initialize(year = Date.today.year, config_path: 'config/dates.yml',
                   calendars_config_path: 'config/calendars.yml',
                   collections_config_path: 'config/collections.yml')
      @year = year
      @pdf = nil
      @total_pages = nil
      @config_path = config_path
      @calendars_config_path = calendars_config_path
      @collections_config_path = collections_config_path
      @date_config = DateConfiguration.new(config_path, year: year)
      @event_store = load_calendar_events(calendars_config_path)
      @collections_config = CollectionsConfiguration.new(collections_config_path)
    end

    # Generate the complete planner PDF.
    #
    # @param filename [String] Output filename (default: planner_YEAR.pdf)
    # @return [void]
    def generate(filename = "planner_#{@year}.pdf")
      calculate_total_pages

      Prawn::Document.generate(filename, page_size: 'LETTER', margin: 0) do |pdf|
        @pdf = pdf

        # Create reusable dot grid stamp for efficiency (reduces file size by ~90%)
        DotGrid.create_stamp(@pdf, "page_dots")

        # Generate all pages using verb methods from Pages::All.
        # Each verb handles context creation and page generation internally.

        # 1. Front matter: Seasonal calendar, Index, Future log
        generate_front_matter

        # 2. Year overview pages (events, highlights, multi-year)
        generate_year_overview

        # 3. Weekly pages with interleaved monthly reviews and quarterly planning
        generate_weekly_section

        # 4. Grid pages (8 types)
        generate_grid_pages

        # 5. Template pages (tracker, reference, wheels)
        generate_template_pages

        # 6. Collections (at the end)
        generate_collections

        # Build PDF outline (table of contents / bookmarks)
        build_outline
        puts "Generated planner with #{pdf.page_count} pages"
      end
    end

    private

    def calculate_total_pages
      collections_count = @collections_config.count
      @total_pages = 1 + INDEX_PAGE_COUNT + FUTURE_LOG_PAGE_COUNT + 3 +
                     total_weeks + MONTHLY_REVIEW_COUNT + QUARTERLY_PLANNING_COUNT +
                     GRID_PAGE_COUNT + TEMPLATE_PAGE_COUNT + collections_count
    end

    # Generate front matter: seasonal calendar, index, future log
    def generate_front_matter
      seasonal_calendar
      @seasonal_page = @pdf.page_number

      @index_pages = {}
      INDEX_PAGE_COUNT.times do |i|
        index_page(num: i + 1, total: INDEX_PAGE_COUNT)
        @index_pages[i + 1] = @pdf.page_number
      end

      @future_log_pages = {}
      FUTURE_LOG_PAGE_COUNT.times do |i|
        future_log_page(num: i + 1, total: FUTURE_LOG_PAGE_COUNT)
        @future_log_pages[i + 1] = @pdf.page_number
      end
    end

    # Generate year overview pages
    def generate_year_overview
      year_events_page
      @events_page = @pdf.page_number

      year_highlights_page
      @highlights_page = @pdf.page_number

      multi_year_page
      @multi_year_page = @pdf.page_number
    end

    # Generate weekly pages with interleaved monthly reviews and quarterly planning.
    #
    # Uses Week value objects for clean boundary detection.
    def generate_weekly_section
      @weekly_start_page = @pdf.page_number + 1
      @week_pages = {}
      @monthly_review_pages = {}
      @quarterly_planning_pages = {}

      generated_months = Set.new
      generated_quarters = Set.new

      Week.all_in(@year).each do |week|
        # Skip interleaving for weeks that start in previous year
        if week.in_year?
          month = week.month
          quarter = week.quarter

          # Insert quarterly planning at quarter boundaries
          unless generated_quarters.include?(quarter)
            quarterly_planning_page(quarter: quarter)
            @quarterly_planning_pages[quarter] = @pdf.page_number
            generated_quarters.add(quarter)
          end

          # Insert monthly review at month boundaries
          unless generated_months.include?(month)
            monthly_review_page(month: month)
            @monthly_review_pages[month] = @pdf.page_number
            generated_months.add(month)
          end
        end

        weekly_page(week: week.number)
        @week_pages[week.number] = @pdf.page_number
      end
    end

    # Generate all grid pages
    def generate_grid_pages
      grid_showcase_page
      @grid_showcase_page = @pdf.page_number

      grids_overview_page
      @grids_overview_page = @pdf.page_number

      dot_grid_page
      @grid_dot_page = @pdf.page_number

      graph_grid_page
      @grid_graph_page = @pdf.page_number

      lined_grid_page
      @grid_lined_page = @pdf.page_number

      isometric_grid_page
      @grid_isometric_page = @pdf.page_number

      perspective_grid_page
      @grid_perspective_page = @pdf.page_number

      hexagon_grid_page
      @grid_hexagon_page = @pdf.page_number
    end

    # Generate template pages
    def generate_template_pages
      tracker_example_page
      @tracker_example_page = @pdf.page_number

      reference_page
      @reference_page = @pdf.page_number

      daily_wheel_page
      @daily_wheel_page = @pdf.page_number

      year_wheel_page
      @year_wheel_page = @pdf.page_number
    end

    # Generate collection pages
    def generate_collections
      @collection_pages = {}
      @collections_config.collections.each do |collection|
        collection_page(id: collection[:id], title: collection[:title], subtitle: collection[:subtitle])
        @collection_pages[collection[:id]] = @pdf.page_number
      end
    end

    def build_outline
      # Capture instance variables for use in outline block
      year = @year
      index_pages = @index_pages
      future_log_pages = @future_log_pages
      collection_pages = @collection_pages
      collections = @collections_config.collections
      monthly_review_pages = @monthly_review_pages
      quarterly_planning_pages = @quarterly_planning_pages
      seasonal_page = @seasonal_page
      events_page = @events_page
      highlights_page = @highlights_page
      multi_year_page = @multi_year_page
      week_pages = @week_pages
      grids_overview_page = @grids_overview_page
      grid_dot_page = @grid_dot_page
      grid_graph_page = @grid_graph_page
      grid_lined_page = @grid_lined_page
      grid_isometric_page = @grid_isometric_page
      grid_perspective_page = @grid_perspective_page
      grid_hexagon_page = @grid_hexagon_page
      grid_showcase_page = @grid_showcase_page
      tracker_example_page = @tracker_example_page
      reference_page = @reference_page
      daily_wheel_page = @daily_wheel_page
      year_wheel_page = @year_wheel_page

      @pdf.outline.define do
        page destination: seasonal_page, title: 'Seasonal Calendar'
        page destination: index_pages[1], title: 'Index'
        page destination: future_log_pages[1], title: 'Future Log'

        page destination: events_page, title: 'Year at a Glance - Events'
        page destination: highlights_page, title: 'Year at a Glance - Highlights'
        page destination: multi_year_page, title: 'Multi-Year Overview'

        page destination: quarterly_planning_pages[1], title: 'Quarterly Planning'
        page destination: monthly_review_pages[1], title: 'Monthly Reviews'

        (1..12).each do |month|
          month_name = Date::MONTHNAMES[month]
          weeks_in_month = Utilities::DateCalculator.weeks_for_month(year, month)
          if weeks_in_month.any?
            first_week = weeks_in_month.first
            page destination: week_pages[first_week], title: "#{month_name} #{year}"
          end
        end

        page destination: grid_showcase_page, title: 'Grid Types Showcase'
        page destination: grids_overview_page, title: '  - Basic Grids Overview'
        page destination: grid_dot_page, title: '  - Dot Grid (5mm)'
        page destination: grid_graph_page, title: '  - Graph Grid (5mm)'
        page destination: grid_lined_page, title: '  - Ruled Lines (10mm)'
        page destination: grid_isometric_page, title: '  - Isometric Grid'
        page destination: grid_perspective_page, title: '  - Perspective Grid'
        page destination: grid_hexagon_page, title: '  - Hexagon Grid'

        page destination: tracker_example_page, title: 'Tracker Ideas'
        page destination: reference_page, title: 'Calibration & Reference'
        page destination: daily_wheel_page, title: 'Daily Wheel'
        page destination: year_wheel_page, title: 'Year Wheel'

        collections.each do |collection|
          page destination: collection_pages[collection[:id]], title: collection[:title]
        end
      end
    end

    def load_calendar_events(config_path)
      return nil unless File.exist?(config_path)

      CalendarIntegration.load_events(config_path: config_path, year: @year)
    end
  end
end
