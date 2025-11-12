# frozen_string_literal: true

require 'prawn'
require 'date'
require_relative 'utilities/date_calculator'
require_relative 'utilities/dot_grid'
require_relative 'page_factory'
require_relative 'render_context'

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

    attr_reader :year, :pdf

    def initialize(year = Date.today.year)
      @year = year
      @pdf = nil
      @total_pages = nil
    end

    # Generate the complete planner PDF.
    #
    # @param filename [String] Output filename (default: planner_YEAR.pdf)
    # @return [void]
    def generate(filename = "planner_#{@year}.pdf")
      # Calculate total pages upfront
      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      @total_pages = 4 + total_weeks + 2  # 4 overview + weeks + 2 template pages

      Prawn::Document.generate(filename, page_size: 'LETTER', margin: 0) do |pdf|
        @pdf = pdf

        # Create reusable dot grid stamp for efficiency (reduces file size by ~90%)
        DotGrid.create_stamp(@pdf, "page_dots")

        # Generate all pages
        generate_overview_pages
        generate_weekly_pages
        generate_template_pages

        # Build PDF outline (table of contents / bookmarks)
        build_outline

        puts "Generated planner with #{pdf.page_count} pages"
      end
    end

    private

    def generate_overview_pages
      # First page (no start_new_page needed)
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

    def generate_template_pages
      @pdf.start_new_page
      generate_page(:reference)
      @reference_page = @pdf.page_number

      @pdf.start_new_page
      generate_page(:dots)
      @dots_page = @pdf.page_number
    end

    def generate_page(page_key)
      context = RenderContext.new(
        page_key: page_key,
        page_number: @pdf.page_number,
        year: @year,
        total_pages: @total_pages
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
        total_pages: @total_pages
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
        total_pages: @total_pages
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
      seasonal_page = @seasonal_page
      events_page = @events_page
      highlights_page = @highlights_page
      multi_year_page = @multi_year_page
      weekly_start_page = @weekly_start_page
      week_pages = @week_pages
      reference_page = @reference_page
      dots_page = @dots_page

      @pdf.outline.define do
        section "#{year} Overview", destination: seasonal_page do
          page destination: seasonal_page, title: 'Seasonal Calendar'
          page destination: events_page, title: 'Year at a Glance - Events'
          page destination: highlights_page, title: 'Year at a Glance - Highlights'
          page destination: multi_year_page, title: 'Multi-Year Overview'
        end

        # Monthly groupings of weekly pages
        section 'Monthly Pages', destination: weekly_start_page do
          (1..12).each do |month|
            month_name = Date::MONTHNAMES[month]
            weeks_in_month = Utilities::DateCalculator.weeks_for_month(year, month)

            # Only create section if there are weeks for this month
            if weeks_in_month.any?
              first_week = weeks_in_month.first
              section "#{month_name} #{year}", destination: week_pages[first_week] do
                weeks_in_month.each do |week_num|
                  page_num = week_pages[week_num]
                  page destination: page_num, title: "Week #{week_num}" if page_num
                end
              end
            end
          end
        end

        section 'Templates', destination: reference_page do
          page destination: reference_page, title: 'Grid Reference & Calibration'
          page destination: dots_page, title: 'Dot Grid'
        end
      end
    end
  end
end
