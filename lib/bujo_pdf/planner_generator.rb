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
      @current_page_number = 0
      @total_pages = nil
    end

    # Generate the complete planner PDF.
    #
    # @param filename [String] Output filename (default: planner_YEAR.pdf)
    # @return [void]
    def generate(filename = "planner_#{@year}.pdf")
      # Calculate total pages upfront
      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      @total_pages = 3 + total_weeks + 2  # 3 overview + weeks + 2 template pages

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
      @current_page_number = 1
      generate_page(:seasonal)
      @seasonal_page = @pdf.page_number

      @pdf.start_new_page
      @current_page_number = 2
      generate_page(:year_events)
      @events_page = @pdf.page_number

      @pdf.start_new_page
      @current_page_number = 3
      generate_page(:year_highlights)
      @highlights_page = @pdf.page_number
    end

    def generate_weekly_pages
      @weekly_start_page = @pdf.page_number + 1  # Next page

      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      total_weeks.times do |i|
        week_num = i + 1
        @pdf.start_new_page
        @current_page_number += 1
        generate_weekly_page(week_num)
      end
    end

    def generate_template_pages
      @pdf.start_new_page
      @current_page_number += 1
      generate_page(:reference)
      @reference_page = @pdf.page_number

      @pdf.start_new_page
      @current_page_number += 1
      generate_page(:dots)
      @dots_page = @pdf.page_number
    end

    def generate_page(page_key)
      context = RenderContext.new(
        page_key: page_key,
        page_number: @current_page_number,
        year: @year,
        total_pages: @total_pages
      )
      page = PageFactory.create(page_key, @pdf, context)
      page.generate
    end

    def generate_weekly_page(week_num)
      # Calculate week dates
      week_start = Utilities::DateCalculator.week_start(@year, week_num)
      week_end = Utilities::DateCalculator.week_end(@year, week_num)
      total_weeks = Utilities::DateCalculator.total_weeks(@year)

      context = RenderContext.new(
        page_key: "week_#{week_num}".to_sym,
        page_number: @current_page_number,
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
      @pdf.outline.define do
        section "#{@year} Overview", destination: @seasonal_page do
          page destination: @seasonal_page, title: 'Seasonal Calendar'
          page destination: @events_page, title: 'Year at a Glance - Events'
          page destination: @highlights_page, title: 'Year at a Glance - Highlights'
        end

        page destination: @weekly_start_page, title: 'Weekly Pages'

        section 'Templates', destination: @dots_page do
          page destination: @reference_page, title: 'Grid Reference & Calibration'
          page destination: @dots_page, title: 'Dot Grid'
        end
      end
    end
  end
end
