# frozen_string_literal: true

require 'prawn'
require 'date'
require_relative 'utilities/date_calculator'
require_relative 'utilities/dot_grid'
require_relative 'page_factory'

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
    end

    # Generate the complete planner PDF.
    #
    # @param filename [String] Output filename (default: planner_YEAR.pdf)
    # @return [void]
    def generate(filename = "planner_#{@year}.pdf")
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
    end

    def generate_weekly_pages
      @weekly_start_page = @pdf.page_number + 1  # Next page

      total_weeks = Utilities::DateCalculator.total_weeks(@year)
      total_weeks.times do |i|
        week_num = i + 1
        @pdf.start_new_page
        generate_weekly_page(week_num)
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
      context = { year: @year }
      page = PageFactory.create(page_key, @pdf, context)
      page.generate
    end

    def generate_weekly_page(week_num)
      context = { year: @year }
      page = PageFactory.create_weekly_page(week_num, @pdf, context)
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
