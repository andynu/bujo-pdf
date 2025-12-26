# frozen_string_literal: true

require 'date'

module BujoPdf
  module PdfDSL
    # Week represents a week in a planner year.
    #
    # This value object encapsulates week number and date calculations,
    # making it easy to iterate over weeks and access their properties
    # in the PDF DSL.
    #
    # @example Iterating over weeks
    #   weeks = Week.weeks_in(2025)
    #   weeks.first.number      # => 1
    #   weeks.first.start_date  # => 2024-12-30
    #   weeks.first.days        # => [Date array of 7 days]
    #
    class Week
      attr_reader :year, :number

      # Initialize a new week.
      #
      # @param year [Integer] The planner year
      # @param number [Integer] The week number (1-based)
      def initialize(year, number)
        @year = year
        @number = number
      end

      # Get the start date (Monday) of this week.
      #
      # @return [Date] The Monday starting this week
      def start_date
        @start_date ||= BujoPdf::Utilities::DateCalculator.week_start(@year, @number)
      end

      # Month number of the week's start date.
      #
      # Note: For weeks spanning year boundary, this may be December
      # of the previous year. Use `primary_month` for interleaving.
      #
      # @return [Integer] Month number (1-12)
      def month
        start_date.month
      end

      # Check if this week's start date is in the target year.
      #
      # Week 1 may start in December of the previous year.
      #
      # @return [Boolean]
      def in_year?
        start_date.year == @year
      end

      # Check if this week starts a new quarter.
      #
      # @return [Boolean] true if this is the first week with start date in months 1, 4, 7, or 10
      def starts_quarter?
        in_year? && [1, 4, 7, 10].include?(month)
      end

      # Get the quarter number (1-4).
      #
      # @return [Integer]
      def quarter
        ((month - 1) / 3) + 1
      end

      # Get the end date (Sunday) of this week.
      #
      # @return [Date] The Sunday ending this week
      def end_date
        BujoPdf::Utilities::DateCalculator.week_end(@year, @number)
      end

      # Get all days in this week.
      #
      # @return [Array<Date>] Array of 7 dates from Monday to Sunday
      def days
        (0..6).map { start_date + it }
      end

      # Get the date range as a formatted string.
      #
      # @param format [String] strftime format (default: "%b %-d")
      # @return [String] Formatted date range (e.g., "Dec 30 - Jan 5")
      def date_range(format: '%b %-d')
        start_str = start_date.strftime(format)
        end_str = end_date.strftime(format)
        "#{start_str} - #{end_str}"
      end

      # Check if this week contains the given date.
      #
      # @param date [Date] The date to check
      # @return [Boolean] true if the date is in this week
      def include?(date)
        date >= start_date && date <= end_date
      end

      # Get the previous week.
      #
      # @return [Week] The previous week
      def prev
        if @number > 1
          Week.new(@year, @number - 1)
        else
          # Go to last week of previous year
          prev_year = @year - 1
          total = BujoPdf::Utilities::DateCalculator.total_weeks(prev_year)
          Week.new(prev_year, total)
        end
      end

      # Get the next week.
      #
      # @return [Week] The next week
      def succ
        total = BujoPdf::Utilities::DateCalculator.total_weeks(@year)
        if @number < total
          Week.new(@year, @number + 1)
        else
          Week.new(@year + 1, 1)
        end
      end

      alias next succ

      # Subtract weeks.
      #
      # @param count [Integer] Number of weeks to subtract
      # @return [Week] The week that many weeks ago
      def -(count)
        result = self
        count.times { result = result.prev }
        result
      end

      # Add weeks.
      #
      # @param count [Integer] Number of weeks to add
      # @return [Week] The week that many weeks forward
      def +(count)
        result = self
        count.times { result = result.succ }
        result
      end

      # Get all weeks for a given year.
      #
      # @param year [Integer] The year
      # @return [Array<Week>] All weeks in the year
      def self.weeks_in(year)
        total = BujoPdf::Utilities::DateCalculator.total_weeks(year)
        (1..total).map { |n| new(year, n) }
      end

      # Enable comparison.
      #
      # @param other [Week] Another week
      # @return [Integer] -1, 0, or 1
      def <=>(other)
        return nil unless other.is_a?(Week)
        [year, number] <=> [other.year, other.number]
      end

      include Comparable

      # String representation.
      #
      # @return [String] "Week N of YYYY"
      def to_s
        "Week #{@number} of #{@year}"
      end

      # Hash equality.
      def eql?(other)
        other.is_a?(Week) && year == other.year && number == other.number
      end

      def hash
        [year, number].hash
      end
    end

    # Month represents a month for iteration purposes.
    #
    # @example Basic usage
    #   months = Month.months_in(2025)
    #   months.first.name  # => "January"
    #
    Month = Data.define(:year, :number) do
      # Get the month name.
      #
      # @return [String] Full month name (e.g., "January")
      def name
        Date::MONTHNAMES[number]
      end

      # Get the abbreviated month name.
      #
      # @return [String] Abbreviated name (e.g., "Jan")
      def abbrev
        Date::ABBR_MONTHNAMES[number]
      end

      # Get the first date of this month.
      #
      # @return [Date] First day of the month
      def start_date
        Date.new(year, number, 1)
      end

      # Get the last date of this month.
      #
      # @return [Date] Last day of the month
      def end_date
        Date.new(year, number, -1)
      end

      # Get all days in this month.
      #
      # @return [Array<Date>] All days in the month
      def days
        (start_date..end_date).to_a
      end

      # Get all weeks that include any days of this month.
      #
      # @return [Array<Week>] Weeks overlapping this month
      def weeks
        week_nums = BujoPdf::Utilities::DateCalculator.weeks_for_month(year, number)
        week_nums.map { |n| Week.new(year, n) }
      end

      # Get the season this month is in.
      #
      # @return [String] Season name
      def season
        BujoPdf::Utilities::DateCalculator.season_for_month(number)
      end

      # Get all months for a given year.
      #
      # @param year [Integer] The year
      # @return [Array<Month>] All 12 months
      def self.months_in(year)
        (1..12).map { |n| new(year, n) }
      end

      # String representation.
      #
      # @return [String] "Month YYYY"
      def to_s
        "#{name} #{year}"
      end
    end
  end
end
