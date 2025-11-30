# frozen_string_literal: true

require 'prawn'
require_relative 'page_ref'
require_relative 'page_set'
require_relative 'utilities/dot_grid'
require_relative 'pages/all'

module BujoPdf
  # Orchestrates PDF document generation with a three-phase architecture.
  #
  # DocumentBuilder provides a declarative DSL for defining document structure
  # with automatic page tracking, link validation, and outline generation.
  #
  # Three Phases:
  # 1. **Define**: Declare document structure without rendering
  # 2. **Validate**: Verify all internal links resolve to valid pages
  # 3. **Render**: Generate the actual PDF with correct page numbers
  #
  # @example Basic usage
  #   DocumentBuilder.generate("planner.pdf", year: 2025) do
  #     seasonal_calendar
  #     year_events_page
  #     52.times { |i| weekly_page(week: i + 1) }
  #   end
  #
  # @example Capturing page references
  #   DocumentBuilder.generate("planner.pdf", year: 2025) do
  #     @seasonal = seasonal_calendar  # Returns PageRef during define phase
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
      builder.define(&block)
      builder.validate!
      builder.render!
      builder
    end

    def initialize(output_path:, year:, config_path:, calendars_config_path:, collections_config_path:)
      @output_path = output_path
      @year = year
      @config_path = config_path
      @calendars_config_path = calendars_config_path
      @collections_config_path = collections_config_path
      @pages = []
      @links = []  # Registered links for validation

      # Phase tracking
      @defining = false
      @validated = false
      @rendered = false

      # Required by Pages::All mixins
      @pdf = nil
      @date_config = nil
      @event_store = nil
      @total_pages = nil
    end

    # Define phase: Declare document structure.
    #
    # Executes the block to collect PageRef objects. Pages are not
    # rendered yet - this phase just builds the document manifest.
    #
    # @yield Document structure definition
    # @return [void]
    def define(&block)
      raise "Document already defined" if @validated || @rendered

      @defining = true
      instance_eval(&block)
      @defining = false
    end

    # Validate phase: Check all links resolve.
    #
    # Verifies that all registered internal links point to valid
    # page destinations. Raises an error if any links are broken.
    #
    # @raise [LinkValidationError] if any links cannot be resolved
    # @return [void]
    def validate!
      return if @validated

      broken_links = @links.reject { |link| valid_destination?(link[:dest]) }
      if broken_links.any?
        messages = broken_links.map { |l| "  - #{l[:dest]} (from #{l[:source]})" }
        raise LinkValidationError, "Broken links found:\n#{messages.join("\n")}"
      end

      @validated = true
    end

    # Render phase: Generate the actual PDF.
    #
    # Creates the PDF document, rendering all declared pages in order.
    # After rendering, PageRef objects have their pdf_page_number set.
    #
    # @return [void]
    def render!
      return if @rendered

      # Load configuration
      @date_config = DateConfiguration.new(@config_path, year: @year)
      @event_store = load_calendar_events(@calendars_config_path)
      @collections_config = CollectionsConfiguration.new(@collections_config_path)
      @total_pages = @pages.size

      Prawn::Document.generate(@output_path, page_size: 'LETTER', margin: 0) do |pdf|
        @pdf = pdf
        DotGrid.create_stamp(@pdf, "page_dots")

        @pages.each do |page_ref|
          # Execute the stored render block
          page_ref.render

          # Record actual page number
          page_ref.pdf_page_number = @pdf.page_number
        end

        build_outline
        puts "Generated #{@output_path} with #{pdf.page_count} pages"
      end

      @rendered = true
    end

    # Register a link for validation.
    #
    # Called by pages when they create internal links.
    #
    # @param dest [String, Symbol] Destination name
    # @param source [String] Description of where the link is from
    # @return [void]
    def register_link(dest, source:)
      @links << { dest: dest.to_s, source: source }
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

    # Check if a destination exists in the pages list.
    def valid_destination?(dest_name)
      @pages.any? { |p| p.dest_name.to_s == dest_name.to_s }
    end

    def build_outline
      pages_by_dest = @pages.each_with_object({}) { |p, h| h[p.dest_name.to_s] = p }
      year = @year

      @pdf.outline.define do
        # Front matter
        if (p = pages_by_dest['seasonal'])
          page destination: p.pdf_page_number, title: 'Seasonal Calendar'
        end
        if (p = pages_by_dest['index_1'])
          page destination: p.pdf_page_number, title: 'Index'
        end
        if (p = pages_by_dest['future_log_1'])
          page destination: p.pdf_page_number, title: 'Future Log'
        end

        # Year overview
        if (p = pages_by_dest['year_events'])
          page destination: p.pdf_page_number, title: 'Year at a Glance - Events'
        end
        if (p = pages_by_dest['year_highlights'])
          page destination: p.pdf_page_number, title: 'Year at a Glance - Highlights'
        end
        if (p = pages_by_dest['multi_year'])
          page destination: p.pdf_page_number, title: 'Multi-Year Overview'
        end

        # Planning pages
        if (p = pages_by_dest['quarter_1'])
          page destination: p.pdf_page_number, title: 'Quarterly Planning'
        end
        if (p = pages_by_dest['review_1'])
          page destination: p.pdf_page_number, title: 'Monthly Reviews'
        end

        # Months (link to first week of each month)
        (1..12).each do |month|
          month_name = Date::MONTHNAMES[month]
          weeks = Utilities::DateCalculator.weeks_for_month(year, month)
          if weeks.any? && (p = pages_by_dest["week_#{weeks.first}"])
            page destination: p.pdf_page_number, title: "#{month_name} #{year}"
          end
        end

        # Grids
        if (p = pages_by_dest['grid_showcase'])
          page destination: p.pdf_page_number, title: 'Grid Types Showcase'
        end
        if (p = pages_by_dest['grids_overview'])
          page destination: p.pdf_page_number, title: '  - Basic Grids Overview'
        end
        if (p = pages_by_dest['grid_dot'])
          page destination: p.pdf_page_number, title: '  - Dot Grid (5mm)'
        end
        if (p = pages_by_dest['grid_graph'])
          page destination: p.pdf_page_number, title: '  - Graph Grid (5mm)'
        end
        if (p = pages_by_dest['grid_lined'])
          page destination: p.pdf_page_number, title: '  - Ruled Lines (10mm)'
        end
        if (p = pages_by_dest['grid_isometric'])
          page destination: p.pdf_page_number, title: '  - Isometric Grid'
        end
        if (p = pages_by_dest['grid_perspective'])
          page destination: p.pdf_page_number, title: '  - Perspective Grid'
        end
        if (p = pages_by_dest['grid_hexagon'])
          page destination: p.pdf_page_number, title: '  - Hexagon Grid'
        end

        # Templates
        if (p = pages_by_dest['tracker_example'])
          page destination: p.pdf_page_number, title: 'Tracker Ideas'
        end
        if (p = pages_by_dest['reference'])
          page destination: p.pdf_page_number, title: 'Calibration & Reference'
        end
        if (p = pages_by_dest['daily_wheel'])
          page destination: p.pdf_page_number, title: 'Daily Wheel'
        end
        if (p = pages_by_dest['year_wheel'])
          page destination: p.pdf_page_number, title: 'Year Wheel'
        end

        # Collections
        pages_by_dest.each do |dest, p|
          next unless dest.start_with?('collection_')

          page destination: p.pdf_page_number, title: p.title
        end
      end
    end

    def load_calendar_events(config_path)
      return nil unless File.exist?(config_path)

      CalendarIntegration.load_events(config_path: config_path, year: @year)
    end
  end

  # Error raised when link validation fails.
  class LinkValidationError < StandardError; end
end
