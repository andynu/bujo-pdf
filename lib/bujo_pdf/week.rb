# frozen_string_literal: true

require 'date'
require_relative 'utilities/date_calculator'

module BujoPdf
  # Value object representing a week in the planner.
  #
  # Provides clean iteration over weeks with boundary detection for
  # interleaving monthly reviews and quarterly planning pages.
  #
  # @example Basic usage
  #   week = Week.new(year: 2025, number: 1)
  #   week.start_date  # => 2024-12-30 (Monday)
  #   week.end_date    # => 2025-01-05 (Sunday)
  #   week.month       # => 1 (January - based on start_date in target year)
  #   week.quarter     # => 1
  #
  # @example Iteration with boundary detection
  #   generated_months = Set.new
  #   weeks_in(2025).each do |week|
  #     if week.in_year? && !generated_months.include?(week.month)
  #       monthly_review_page(month: week.month)
  #       generated_months << week.month
  #     end
  #     weekly_page(week: week.number)
  #   end
  #
  class Week
    attr_reader :year, :number, :start_date, :end_date

    # Create a new Week.
    #
    # @param year [Integer] The planner year
    # @param number [Integer] Week number (1-based)
    def initialize(year:, number:)
      @year = year
      @number = number
      @start_date = Utilities::DateCalculator.week_start(year, number)
      @end_date = Utilities::DateCalculator.week_end(year, number)
    end

    # Month number of the week's start date.
    #
    # Note: For weeks spanning year boundary, this may be December
    # of the previous year. Use `primary_month` for the month to
    # associate with this week for interleaving purposes.
    #
    # @return [Integer] Month number (1-12)
    def month
      start_date.month
    end

    # Month name of the week's start date.
    #
    # @return [String] Full month name (e.g., "January")
    def month_name
      Date::MONTHNAMES[month]
    end

    # Primary month for interleaving purposes.
    #
    # Returns the month of the start date, but only if the start date
    # is in the target year. Otherwise returns nil (week belongs to
    # previous year).
    #
    # @return [Integer, nil] Month number or nil if week starts in previous year
    def primary_month
      start_date.year == year ? start_date.month : nil
    end

    # Quarter number (1-4).
    #
    # @return [Integer]
    def quarter
      ((month - 1) / 3) + 1
    end

    # Check if this week's start date is in the target year.
    #
    # Week 1 may start in December of the previous year.
    #
    # @return [Boolean]
    def in_year?
      start_date.year == year
    end

    # Check if any days of this week fall in the target year.
    #
    # @return [Boolean]
    def overlaps_year?
      start_date.year == year || end_date.year == year
    end

    # Convert to hash for page context.
    #
    # @return [Hash]
    def to_context
      {
        week_num: number,
        week_start: start_date,
        week_end: end_date
      }
    end

    # Equality based on year and number.
    def ==(other)
      other.is_a?(Week) && year == other.year && number == other.number
    end

    def eql?(other)
      self == other
    end

    def hash
      [year, number].hash
    end

    def to_s
      "Week #{number} (#{start_date} - #{end_date})"
    end

    def inspect
      "#<Week year=#{year} number=#{number} #{start_date}..#{end_date}>"
    end

    # Generate all weeks for a year.
    #
    # @param year [Integer] The year
    # @return [Array<Week>] All weeks in the year
    def self.all_in(year)
      total = Utilities::DateCalculator.total_weeks(year)
      (1..total).map { |n| new(year: year, number: n) }
    end
  end
end
