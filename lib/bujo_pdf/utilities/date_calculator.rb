# frozen_string_literal: true

require 'date'

module BujoPdf
  module Utilities
    # Date calculation utilities for week-based planner generation.
    #
    # This class handles all date-related calculations for the planner,
    # including week numbering, week boundaries, and date-to-week conversions.
    #
    # Week Numbering System:
    #   - Week 1 starts on the Monday on or before January 1
    #   - Weeks increment sequentially through the year
    #   - Total weeks: typically 52-53 depending on year
    #
    # Example:
    #   DateCalculator.year_start_monday(2025)  # => 2024-12-30 (Monday)
    #   DateCalculator.total_weeks(2025)         # => 53
    #   DateCalculator.week_start(2025, 1)       # => 2024-12-30
    #   DateCalculator.week_end(2025, 1)         # => 2025-01-05
    class DateCalculator
      # Calculate the Monday on or before January 1 of the given year.
      #
      # This is the starting point for the week numbering system. Week 1
      # always starts on this Monday, which may be in the previous year.
      #
      # @param year [Integer] The year to calculate for
      # @return [Date] The Monday starting the year's week numbering
      def self.year_start_monday(year)
        first_day = Date.new(year, 1, 1)
        # Convert Sunday=0 system to Monday=0 system: (wday + 6) % 7
        # If first_day is Monday (wday=1), days_back = 0
        # If first_day is Sunday (wday=0), days_back = 6
        days_back = (first_day.wday + 6) % 7
        first_day - days_back
      end

      # Calculate the total number of weeks in the given year.
      #
      # A year has 52 or 53 weeks depending on where January 1 falls and
      # whether it's a leap year.
      #
      # @param year [Integer] The year to calculate for
      # @return [Integer] Total weeks in the year (52 or 53)
      def self.total_weeks(year)
        start_monday = year_start_monday(year)
        end_date = Date.new(year, 12, 31)

        weeks = 0
        current_monday = start_monday

        # Count weeks until we pass December 31 of the target year
        while current_monday.year == year || current_monday <= end_date
          weeks += 1
          current_monday += 7
        end

        weeks
      end

      # Calculate the start date (Monday) for a given week number.
      #
      # @param year [Integer] The year
      # @param week_num [Integer] The week number (1-based)
      # @return [Date] The Monday starting the week
      def self.week_start(year, week_num)
        year_start_monday(year) + ((week_num - 1) * 7)
      end

      # Calculate the end date (Sunday) for a given week number.
      #
      # @param year [Integer] The year
      # @param week_num [Integer] The week number (1-based)
      # @return [Date] The Sunday ending the week
      def self.week_end(year, week_num)
        week_start(year, week_num) + 6
      end

      # Calculate the week number for a given date.
      #
      # @param year [Integer] The year (for week numbering context)
      # @param date [Date] The date to find the week number for
      # @return [Integer] The week number (1-based)
      def self.week_number_for_date(year, date)
        start_monday = year_start_monday(year)
        days_from_start = (date - start_monday).to_i
        (days_from_start / 7) + 1
      end

      # Get the season name for a given month.
      #
      # @param month [Integer] The month number (1-12)
      # @return [String] The season name ('Winter', 'Spring', 'Summer', 'Fall')
      def self.season_for_month(month)
        case month
        when 12, 1, 2
          'Winter'
        when 3, 4, 5
          'Spring'
        when 6, 7, 8
          'Summer'
        when 9, 10, 11
          'Fall'
        end
      end

      # Get the first date of the season containing the given month.
      #
      # Seasons are defined as:
      #   - Winter: December 1
      #   - Spring: March 1
      #   - Summer: June 1
      #   - Fall: September 1
      #
      # @param year [Integer] The year
      # @param month [Integer] The month number (1-12)
      # @return [Date] The first date of the season
      def self.season_start_date(year, month)
        case month
        when 12, 1, 2
          # Winter starts December 1
          # If current month is Jan or Feb, winter started previous December
          Date.new(month == 12 ? year : year - 1, 12, 1)
        when 3, 4, 5
          Date.new(year, 3, 1)
        when 6, 7, 8
          Date.new(year, 6, 1)
        when 9, 10, 11
          Date.new(year, 9, 1)
        end
      end

      # Get the week number for the first week of a given month.
      #
      # @param year [Integer] The year
      # @param month [Integer] The month number (1-12)
      # @return [Integer] The week number containing the 1st of the month
      def self.first_week_of_month(year, month)
        first_of_month = Date.new(year, month, 1)
        week_number_for_date(year, first_of_month)
      end

      # Get month letter for a given week.
      # Returns the first letter of the month if this week is the first week of that month.
      #
      # @param year [Integer] The year
      # @param week_num [Integer] The week number (1-based)
      # @return [String, nil] The month letter (e.g., "J" for January) or nil
      def self.month_letter_for_week(year, week_num)
        (1..12).each do |month|
          return Date::MONTHNAMES[month][0] if first_week_of_month(year, month) == week_num
        end
        nil
      end

      # Build a hash mapping week numbers to month letters.
      # Used for efficient lookup when rendering week sidebars.
      #
      # @param year [Integer] The year
      # @return [Hash<Integer, String>] Mapping of week_num => month_letter
      def self.week_to_month_letter_map(year)
        map = {}
        (1..12).each do |month|
          week_num = first_week_of_month(year, month)
          month_letter = Date::MONTHNAMES[month][0]
          map[week_num] = month_letter
        end
        map
      end
    end
  end
end
