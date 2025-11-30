# frozen_string_literal: true

require 'prawn'
require_relative 'page_ref'
require_relative 'page_set'
require_relative 'utilities/dot_grid'
require_relative 'pages/all'

module BujoPdf
  # Orchestrates PDF document generation with page tracking.
  #
  # DocumentBuilder wraps the page generation process to collect PageRef
  # objects as pages are created, enabling automatic outline generation
  # and link validation.
  #
  # @example Basic usage
  #   DocumentBuilder.generate("planner.pdf", year: 2025) do
  #     seasonal_calendar
  #     index_pages(count: 2)
  #     year_events_page
  #   end
  #
  class DocumentBuilder
    include Pages::All

    attr_reader :year, :output_path, :pages

    # Generate a PDF document.
    #
    # @param output_path [String] Path for the generated PDF
    # @param year [Integer] Year for the planner
    # @yield Document definition block
    # @return [DocumentBuilder] The builder instance
    def self.generate(output_path, year: Date.today.year,
                      config_path: 'config/dates.yml',
                      calendars_config_path: 'config/calendars.yml',
                      collections_config_path: 'config/collections.yml',
                      &block)
      builder = new(
        output_path: output_path,
        year: year,
        config_path: config_path,
        calendars_config_path: calendars_config_path,
        collections_config_path: collections_config_path
      )
      builder.generate(&block)
      builder
    end

    def initialize(output_path:, year:, config_path:, calendars_config_path:, collections_config_path:)
      @output_path = output_path
      @year = year
      @config_path = config_path
      @calendars_config_path = calendars_config_path
      @collections_config_path = collections_config_path
      @pages = []

      # Required by Pages::All mixins
      @pdf = nil
      @date_config = nil
      @event_store = nil
      @total_pages = nil
    end

    # Generate the PDF.
    #
    # @yield Document definition block
    # @return [void]
    def generate(&block)
      @date_config = DateConfiguration.new(@config_path, year: @year)
      @event_store = load_calendar_events(@calendars_config_path)
      @collections_config = CollectionsConfiguration.new(@collections_config_path)

      Prawn::Document.generate(@output_path, page_size: 'LETTER', margin: 0) do |pdf|
        @pdf = pdf
        DotGrid.create_stamp(@pdf, "page_dots")

        instance_eval(&block)

        build_outline
        puts "Generated #{@output_path} with #{pdf.page_count} pages"
      end
    end

    # Track a page after it's generated.
    #
    # Call this after generating a page to record its PageRef.
    #
    # @param dest_name [String, Symbol] Named destination
    # @param title [String] Display title
    # @param page_type [Symbol] Page type
    # @return [PageRef]
    def track_page(dest_name:, title:, page_type:, **metadata)
      ref = PageRef.new(
        dest_name: dest_name,
        title: title,
        page_type: page_type,
        metadata: metadata
      )
      ref.pdf_page_number = @pdf.page_number
      @pages << ref
      ref
    end

    # Get total pages generated.
    def total_page_count
      @pages.size
    end

    # Find a page by destination.
    def page_by_dest(dest_name)
      @pages.find { |p| p.dest_name.to_s == dest_name.to_s }
    end

    # Get all weeks for a year.
    #
    # @param target_year [Integer] Year to get weeks for (default: @year)
    # @return [Array<Week>] All weeks in the year
    def weeks_in(target_year = nil)
      Week.all_in(target_year || @year)
    end

    # Get total weeks in the year.
    #
    # @return [Integer]
    def total_weeks
      Utilities::DateCalculator.total_weeks(@year)
    end

    private

    def build_outline
      @pdf.outline.define do
        # Outline built from @pages - implement as needed
      end
    end

    def load_calendar_events(config_path)
      return nil unless File.exist?(config_path)

      CalendarIntegration.load_events(config_path: config_path, year: @year)
    end
  end
end
