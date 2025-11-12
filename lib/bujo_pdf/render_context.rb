# frozen_string_literal: true

module BujoPdf
  # Structured rendering context passed to pages and components.
  #
  # Provides typed access to rendering state and helper methods
  # for context-aware rendering. This replaces the ad-hoc hash-based
  # context system with a formal class that supports features like
  # current page detection and dynamic component styling.
  #
  # @example Creating a context for a weekly page
  #   context = RenderContext.new(
  #     page_key: :week_42,
  #     page_number: 10,
  #     year: 2025,
  #     week_num: 42,
  #     week_start: Date.new(2025, 10, 13),
  #     week_end: Date.new(2025, 10, 19),
  #     total_weeks: 52
  #   )
  #
  # @example Checking if rendering a specific page
  #   context.current_page?(:week_42)  # => true
  #   context.current_page?(:seasonal) # => false
  #
  # @example Using in a component to highlight current page
  #   if context.current_page?(:year_events)
  #     @pdf.font "Helvetica-Bold"  # Bold for current page
  #   else
  #     @pdf.font "Helvetica"       # Normal for other pages
  #   end
  class RenderContext
    # @return [Symbol] Current page type (:seasonal, :week_1, :year_events, etc.)
    attr_reader :page_key

    # @return [Integer] Current page number (1-based index in PDF)
    attr_reader :page_number

    # @return [Integer, nil] Total page count in document
    attr_reader :total_pages

    # @return [Integer] Year being generated
    attr_reader :year

    # @return [Integer, nil] Week number (1-52/53) for weekly pages
    attr_reader :week_num

    # @return [Date, nil] Week start date for weekly pages
    attr_reader :week_start

    # @return [Date, nil] Week end date for weekly pages
    attr_reader :week_end

    # @return [Integer, nil] Total weeks in the year
    attr_reader :total_weeks

    # @return [Hash] Additional context data
    attr_reader :data

    # Initialize a new RenderContext.
    #
    # @param page_key [Symbol] Page identifier (:seasonal, :week_42, etc.)
    # @param page_number [Integer] Page number (1-based)
    # @param year [Integer] Year being generated
    # @param week_num [Integer, nil] Week number for weekly pages
    # @param week_start [Date, nil] Week start date for weekly pages
    # @param week_end [Date, nil] Week end date for weekly pages
    # @param total_weeks [Integer, nil] Total weeks in year
    # @param total_pages [Integer, nil] Total pages in document
    # @param data [Hash] Additional context data
    def initialize(page_key:, page_number:, year:,
                   week_num: nil, week_start: nil, week_end: nil,
                   total_weeks: nil, total_pages: nil, **data)
      @page_key = page_key
      @page_number = page_number
      @year = year
      @week_num = week_num
      @week_start = week_start
      @week_end = week_end
      @total_weeks = total_weeks
      @total_pages = total_pages
      @data = data
    end

    # Check if currently rendering a specific page.
    #
    # This is the primary method for context-aware component rendering.
    # Components can use this to adapt their appearance based on which
    # page they're rendering on.
    #
    # @param key [Symbol, String] Page key to check
    # @return [Boolean] True if current page matches key
    #
    # @example
    #   context.current_page?(:seasonal)       # => true/false
    #   context.current_page?("seasonal")      # => true/false (string works too)
    #   context.current_page?(:week_42)        # => true/false
    def current_page?(key)
      @page_key == key.to_sym
    end

    # Check if currently rendering a weekly page.
    #
    # Weekly pages have a week_num set, while overview pages don't.
    #
    # @return [Boolean] True if on a weekly page
    def weekly_page?
      !@week_num.nil?
    end

    # Get the destination key for this page.
    #
    # This is the named destination used in PDF links. The destination
    # string matches the page_key converted to string format.
    #
    # @return [String] Destination key
    #
    # @example
    #   context.destination  # => "seasonal"
    #   context.destination  # => "week_42"
    def destination
      @page_key.to_s
    end

    # Access additional context data.
    #
    # Allows hash-style access to all context attributes, including
    # both the primary attributes (page_key, year, etc.) and any
    # additional data passed via **data.
    #
    # This provides backward compatibility with the old hash-based
    # context system.
    #
    # @param key [Symbol] Data key
    # @return [Object, nil] Data value
    #
    # @example
    #   context[:year]       # => 2025
    #   context[:week_num]   # => 42
    #   context[:custom_key] # => (value from **data)
    def [](key)
      case key
      when :page_key then @page_key
      when :page_number then @page_number
      when :year then @year
      when :week_num then @week_num
      when :week_start then @week_start
      when :week_end then @week_end
      when :total_weeks then @total_weeks
      when :total_pages then @total_pages
      else @data[key]
      end
    end

    # Convert to hash for backward compatibility.
    #
    # Returns all context attributes as a hash. Useful when interfacing
    # with code that expects the old hash-based context format.
    #
    # @return [Hash] Context as hash
    #
    # @example
    #   context.to_h  # => { page_key: :week_42, year: 2025, ... }
    def to_h
      {
        page_key: @page_key,
        page_number: @page_number,
        year: @year,
        week_num: @week_num,
        week_start: @week_start,
        week_end: @week_end,
        total_weeks: @total_weeks,
        total_pages: @total_pages
      }.merge(@data)
    end
  end
end
