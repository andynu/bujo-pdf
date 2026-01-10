# frozen_string_literal: true

require 'date'
require_relative 'utilities/date_calculator'

module BujoPdf
  # Value object bundling week data for component rendering.
  #
  # Eliminates the data clump of (year, week_num, total_weeks, week_start, week_end)
  # that is passed to many components like TopNavigation, WeekSidebar, etc.
  #
  # @example From a Week object
  #   week = Week.new(year: 2025, number: 42)
  #   ctx = WeekContext.from_week(week)
  #
  # @example Direct construction
  #   ctx = WeekContext.new(
  #     year: 2025,
  #     number: 42,
  #     total_weeks: 52,
  #     start_date: Date.new(2025, 10, 13),
  #     end_date: Date.new(2025, 10, 19)
  #   )
  #
  # @example Usage in components
  #   nav = TopNavigation.new(canvas: canvas, week_context: ctx)
  #
  class WeekContext
    attr_reader :year, :number, :total_weeks, :start_date, :end_date

    # Create a new WeekContext.
    #
    # @param year [Integer] The planner year
    # @param number [Integer] Week number (1-based)
    # @param total_weeks [Integer, nil] Total weeks in the year (calculated if nil)
    # @param start_date [Date, nil] Monday of the week (calculated if nil)
    # @param end_date [Date, nil] Sunday of the week (calculated if nil)
    def initialize(year:, number:, total_weeks: nil, start_date: nil, end_date: nil)
      @year = year
      @number = number
      @total_weeks = total_weeks || Utilities::DateCalculator.total_weeks(year)
      @start_date = start_date || Utilities::DateCalculator.week_start(year, number)
      @end_date = end_date || Utilities::DateCalculator.week_end(year, number)
      freeze
    end

    # Create a WeekContext from a Week object.
    #
    # @param week [Week] The week to convert
    # @param total_weeks [Integer, nil] Total weeks (calculated from year if nil)
    # @return [WeekContext]
    def self.from_week(week, total_weeks: nil)
      new(
        year: week.year,
        number: week.number,
        total_weeks: total_weeks,
        start_date: week.start_date,
        end_date: week.end_date
      )
    end

    # Alias for number, matching context hash key convention.
    #
    # @return [Integer]
    def week_num
      number
    end

    # Alias for start_date, matching context hash key convention.
    #
    # @return [Date]
    def week_start
      start_date
    end

    # Alias for end_date, matching context hash key convention.
    #
    # @return [Date]
    def week_end
      end_date
    end

    # Check if this is the first week.
    #
    # @return [Boolean]
    def first?
      number == 1
    end

    # Check if this is the last week.
    #
    # @return [Boolean]
    def last?
      number == total_weeks
    end

    # Get the previous week's number.
    #
    # @return [Integer, nil] Previous week number, or nil if first week
    def prev_week_num
      first? ? nil : number - 1
    end

    # Get the next week's number.
    #
    # @return [Integer, nil] Next week number, or nil if last week
    def next_week_num
      last? ? nil : number + 1
    end

    # Convert to a hash for backward compatibility with context-based code.
    #
    # @return [Hash] Hash with symbol keys
    def to_h
      {
        year: year,
        week_num: number,
        total_weeks: total_weeks,
        week_start: start_date,
        week_end: end_date
      }
    end

    # Equality based on year, number, and total_weeks.
    def ==(other)
      other.is_a?(WeekContext) &&
        year == other.year &&
        number == other.number &&
        total_weeks == other.total_weeks
    end

    def eql?(other)
      self == other
    end

    def hash
      [year, number, total_weeks].hash
    end

    def to_s
      "Week #{number}/#{total_weeks} (#{start_date} - #{end_date})"
    end

    def inspect
      "#<WeekContext year=#{year} number=#{number}/#{total_weeks} #{start_date}..#{end_date}>"
    end
  end
end
