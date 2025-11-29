# frozen_string_literal: true

require 'prawn'
require 'date'
require_relative 'utilities/date_calculator'
require_relative 'utilities/dot_grid'
require_relative 'page_factory'
require_relative 'render_context'
require_relative 'date_configuration'
require_relative 'calendar_integration'
require_relative 'collections_configuration'

module BujoPdf
  # Main planner generator orchestrator.
  #
  # This class coordinates the generation of a complete year planner PDF.
  # It uses the PageFactory to create individual pages and manages the
  # overall PDF structure including named destinations and bookmarks.
  #
  # Example:
  #   generator = PlannerGenerator.new(2025)
  #   generator.generate("planner_2025.pdf")
  class PlannerGenerator
    # Page dimensions
    PAGE_WIDTH = 612    # 8.5 inches (letter size)
    PAGE_HEIGHT = 792   # 11 inches

    attr_reader :year, :pdf, :date_config, :event_store, :collections_config

    def initialize(year = Date.today.year, config_path: 'config/dates.yml',
                   calendars_config_path: 'config/calendars.yml',
                   collections_config_path: 'config/collections.yml')
      @year = year
      @pdf = nil
      @total_pages = nil
      @date_config = DateConfiguration.new(config_path, year: year)
      @event_store = load_calendar_events(calendars_config_path)
      @collections_config = CollectionsConfiguration.new(collections_config_path)
    end

    # Generate the complete planner PDF.
    #
    # @param filename [String] Output filename (default: planner_YEAR.pdf)
    # @return [void]
    # Number of index pages to generate (configurable)
    INDEX_PAGE_COUNT = 4

    # Number of future log pages (2 pages = 6 months)
    FUTURE_LOG_PAGE_COUNT = 2

    # Number of monthly review pages (one per month)
    MONTHLY_REVIEW_COUNT = 12

    # Number of quarterly planning pages (one per quarter)
    QUARTERLY_PLANNING_COUNT = 4

    def generate(filename = "planner_#{@year}.pdf")
      # Calculate total pages upfront
      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      collections_count = @collections_config.count
      # index + future log + collections + reviews + quarters + 4 overview + weeks + 7 grid + 4 template pages
      @total_pages = INDEX_PAGE_COUNT + FUTURE_LOG_PAGE_COUNT + collections_count + MONTHLY_REVIEW_COUNT + QUARTERLY_PLANNING_COUNT + 4 + total_weeks + 11

      Prawn::Document.generate(filename, page_size: 'LETTER', margin: 0) do |pdf|
        @pdf = pdf

        # Create reusable dot grid stamp for efficiency (reduces file size by ~90%)
        DotGrid.create_stamp(@pdf, "page_dots")

        # Generate all pages
        generate_index_pages
        generate_future_log_pages
        generate_collection_pages
        generate_monthly_review_pages
        generate_quarterly_planning_pages
        generate_overview_pages
        generate_weekly_pages
        generate_grid_pages
        generate_template_pages

        # Build PDF outline (table of contents / bookmarks)
        build_outline

        puts "Generated planner with #{pdf.page_count} pages"
      end
    end

    private

    def generate_index_pages
      @index_pages = {}

      INDEX_PAGE_COUNT.times do |i|
        page_num = i + 1

        # First page doesn't need start_new_page
        @pdf.start_new_page unless page_num == 1

        generate_index_page(page_num)
        @index_pages[page_num] = @pdf.page_number
      end
    end

    def generate_index_page(index_page_num)
      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      context = RenderContext.new(
        page_key: "index_#{index_page_num}".to_sym,
        page_number: @pdf.page_number,
        year: @year,
        total_weeks: total_weeks,
        total_pages: @total_pages,
        index_page_num: index_page_num,
        index_page_count: INDEX_PAGE_COUNT,
        date_config: @date_config,
        event_store: @event_store
      )

      page = PageFactory.create(:index, @pdf, context)
      page.generate
    end

    def generate_future_log_pages
      @future_log_pages = {}

      FUTURE_LOG_PAGE_COUNT.times do |i|
        page_num = i + 1
        @pdf.start_new_page
        generate_future_log_page(page_num)
        @future_log_pages[page_num] = @pdf.page_number
      end
    end

    def generate_future_log_page(future_log_page_num)
      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      start_month = (future_log_page_num - 1) * 3 + 1  # Page 1 = months 1-3, Page 2 = months 4-6

      context = RenderContext.new(
        page_key: "future_log_#{future_log_page_num}".to_sym,
        page_number: @pdf.page_number,
        year: @year,
        total_weeks: total_weeks,
        total_pages: @total_pages,
        future_log_page: future_log_page_num,
        future_log_start_month: start_month,
        date_config: @date_config,
        event_store: @event_store
      )

      page = PageFactory.create(:future_log, @pdf, context)
      page.generate
    end

    def generate_collection_pages
      @collection_pages = {}

      @collections_config.collections.each do |collection|
        @pdf.start_new_page
        generate_collection_page(collection)
        @collection_pages[collection[:id]] = @pdf.page_number
      end
    end

    def generate_collection_page(collection)
      total_weeks = Utilities::DateCalculator.total_weeks(@year)

      context = RenderContext.new(
        page_key: "collection_#{collection[:id]}".to_sym,
        page_number: @pdf.page_number,
        year: @year,
        total_weeks: total_weeks,
        total_pages: @total_pages,
        collection_id: collection[:id],
        collection_title: collection[:title],
        collection_subtitle: collection[:subtitle],
        date_config: @date_config,
        event_store: @event_store
      )

      page = PageFactory.create(:collection, @pdf, context)
      page.generate
    end

    def generate_monthly_review_pages
      @monthly_review_pages = {}

      MONTHLY_REVIEW_COUNT.times do |i|
        month_num = i + 1
        @pdf.start_new_page
        generate_monthly_review_page(month_num)
        @monthly_review_pages[month_num] = @pdf.page_number
      end
    end

    def generate_monthly_review_page(month_num)
      total_weeks = Utilities::DateCalculator.total_weeks(@year)

      context = RenderContext.new(
        page_key: "review_#{month_num}".to_sym,
        page_number: @pdf.page_number,
        year: @year,
        total_weeks: total_weeks,
        total_pages: @total_pages,
        review_month: month_num,
        date_config: @date_config,
        event_store: @event_store
      )

      page = PageFactory.create(:monthly_review, @pdf, context)
      page.generate
    end

    def generate_quarterly_planning_pages
      @quarterly_planning_pages = {}

      QUARTERLY_PLANNING_COUNT.times do |i|
        quarter_num = i + 1
        @pdf.start_new_page
        generate_quarterly_planning_page(quarter_num)
        @quarterly_planning_pages[quarter_num] = @pdf.page_number
      end
    end

    def generate_quarterly_planning_page(quarter_num)
      total_weeks = Utilities::DateCalculator.total_weeks(@year)

      context = RenderContext.new(
        page_key: "quarter_#{quarter_num}".to_sym,
        page_number: @pdf.page_number,
        year: @year,
        total_weeks: total_weeks,
        total_pages: @total_pages,
        quarter: quarter_num,
        date_config: @date_config,
        event_store: @event_store
      )

      page = PageFactory.create(:quarterly_planning, @pdf, context)
      page.generate
    end

    def generate_overview_pages
      @pdf.start_new_page
      generate_page(:seasonal)
      @seasonal_page = @pdf.page_number

      @pdf.start_new_page
      generate_page(:year_events)
      @events_page = @pdf.page_number

      @pdf.start_new_page
      generate_page(:year_highlights)
      @highlights_page = @pdf.page_number

      @pdf.start_new_page
      generate_multi_year_page
      @multi_year_page = @pdf.page_number
    end

    def generate_weekly_pages
      @weekly_start_page = @pdf.page_number + 1  # Next page
      @week_pages = {}

      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      total_weeks.times do |i|
        week_num = i + 1
        @pdf.start_new_page
        generate_weekly_page(week_num)
        @week_pages[week_num] = @pdf.page_number
      end
    end

    def generate_grid_pages
      # Grid showcase (entry point for Grids tab cycling)
      @pdf.start_new_page
      @pdf.add_dest('grid_showcase', @pdf.dest_xyz(0, @pdf.bounds.top))
      generate_page(:grid_showcase)
      @grid_showcase_page = @pdf.page_number

      # Grids overview
      @pdf.start_new_page
      @pdf.add_dest('grids_overview', @pdf.dest_xyz(0, @pdf.bounds.top))
      generate_page(:grids_overview)
      @grids_overview_page = @pdf.page_number

      # Dot grid full page
      @pdf.start_new_page
      @pdf.add_dest('grid_dot', @pdf.dest_xyz(0, @pdf.bounds.top))
      generate_page(:grid_dot)
      @grid_dot_page = @pdf.page_number

      # Graph grid full page
      @pdf.start_new_page
      @pdf.add_dest('grid_graph', @pdf.dest_xyz(0, @pdf.bounds.top))
      generate_page(:grid_graph)
      @grid_graph_page = @pdf.page_number

      # Ruled lines full page
      @pdf.start_new_page
      @pdf.add_dest('grid_lined', @pdf.dest_xyz(0, @pdf.bounds.top))
      generate_page(:grid_lined)
      @grid_lined_page = @pdf.page_number

      # Isometric grid full page
      @pdf.start_new_page
      @pdf.add_dest('grid_isometric', @pdf.dest_xyz(0, @pdf.bounds.top))
      generate_page(:grid_isometric)
      @grid_isometric_page = @pdf.page_number

      # Perspective grid full page
      @pdf.start_new_page
      @pdf.add_dest('grid_perspective', @pdf.dest_xyz(0, @pdf.bounds.top))
      generate_page(:grid_perspective)
      @grid_perspective_page = @pdf.page_number

      # Hexagon grid full page
      @pdf.start_new_page
      @pdf.add_dest('grid_hexagon', @pdf.dest_xyz(0, @pdf.bounds.top))
      generate_page(:grid_hexagon)
      @grid_hexagon_page = @pdf.page_number
    end

    def generate_template_pages
      @pdf.start_new_page
      generate_page(:reference)
      @reference_page = @pdf.page_number

      @pdf.start_new_page
      generate_page(:daily_wheel)
      @daily_wheel_page = @pdf.page_number

      @pdf.start_new_page
      generate_page(:year_wheel)
      @year_wheel_page = @pdf.page_number
    end

    def generate_page(page_key)
      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      context = RenderContext.new(
        page_key: page_key,
        page_number: @pdf.page_number,
        year: @year,
        total_weeks: total_weeks,
        total_pages: @total_pages,
        date_config: @date_config,
        event_store: @event_store
      )
      page = PageFactory.create(page_key, @pdf, context)
      page.generate
    end

    def generate_multi_year_page
      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      context = RenderContext.new(
        page_key: :multi_year,
        page_number: @pdf.page_number,
        year: @year,
        year_count: 4,  # Show 4 years
        total_weeks: total_weeks,
        total_pages: @total_pages,
        date_config: @date_config,
        event_store: @event_store
      )
      page = PageFactory.create(:multi_year, @pdf, context)
      page.generate
    end

    def generate_weekly_page(week_num)
      # Calculate week dates
      week_start = Utilities::DateCalculator.week_start(@year, week_num)
      week_end = Utilities::DateCalculator.week_end(@year, week_num)
      total_weeks = Utilities::DateCalculator.total_weeks(@year)

      context = RenderContext.new(
        page_key: "week_#{week_num}".to_sym,
        page_number: @pdf.page_number,
        year: @year,
        week_num: week_num,
        week_start: week_start,
        week_end: week_end,
        total_weeks: total_weeks,
        total_pages: @total_pages,
        date_config: @date_config,
        event_store: @event_store
      )

      # Note: PageFactory.create_weekly_page expects a hash with :year
      # and merges in week info, but since we're passing RenderContext,
      # we need to use the page class directly
      require_relative 'pages/weekly_page'
      page = Pages::WeeklyPage.new(@pdf, context)
      page.generate
    end

    def build_outline
      # Capture instance variables in local scope for use in outline block
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
      reference_page = @reference_page
      daily_wheel_page = @daily_wheel_page
      year_wheel_page = @year_wheel_page

      @pdf.outline.define do
        # Index pages (for custom table of contents)
        page destination: index_pages[1], title: 'Index'

        # Future log (6-month spread)
        page destination: future_log_pages[1], title: 'Future Log'

        # Collection pages (if any configured)
        collections.each do |collection|
          page destination: collection_pages[collection[:id]], title: collection[:title]
        end

        # Monthly reviews (12 pages)
        page destination: monthly_review_pages[1], title: 'Monthly Reviews'

        # Quarterly planning (4 pages)
        page destination: quarterly_planning_pages[1], title: 'Quarterly Planning'

        # Year overview pages (flat, no nesting)
        page destination: seasonal_page, title: 'Seasonal Calendar'
        page destination: events_page, title: 'Year at a Glance - Events'
        page destination: highlights_page, title: 'Year at a Glance - Highlights'
        page destination: multi_year_page, title: 'Multi-Year Overview'

        # Month pages (flat, linking to first week of each month)
        (1..12).each do |month|
          month_name = Date::MONTHNAMES[month]
          weeks_in_month = Utilities::DateCalculator.weeks_for_month(year, month)

          # Only create entry if there are weeks for this month
          if weeks_in_month.any?
            first_week = weeks_in_month.first
            page destination: week_pages[first_week], title: "#{month_name} #{year}"
          end
        end

        # Grid pages
        page destination: grid_showcase_page, title: 'Grid Types Showcase'
        page destination: grids_overview_page, title: '  - Basic Grids Overview'
        page destination: grid_dot_page, title: '  - Dot Grid (5mm)'
        page destination: grid_graph_page, title: '  - Graph Grid (5mm)'
        page destination: grid_lined_page, title: '  - Ruled Lines (10mm)'
        page destination: grid_isometric_page, title: '  - Isometric Grid'
        page destination: grid_perspective_page, title: '  - Perspective Grid'
        page destination: grid_hexagon_page, title: '  - Hexagon Grid'

        # Template pages
        page destination: reference_page, title: 'Calibration & Reference'
        page destination: daily_wheel_page, title: 'Daily Wheel'
        page destination: year_wheel_page, title: 'Year Wheel'
      end
    end

    def load_calendar_events(config_path)
      return nil unless File.exist?(config_path)

      CalendarIntegration.load_events(config_path: config_path, year: @year)
    end
  end
end
