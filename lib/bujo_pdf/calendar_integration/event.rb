# frozen_string_literal: true

require 'date'

module BujoPdf
  module CalendarIntegration
    # Event represents a calendar event with date, summary, and styling information
    class Event
      attr_reader :date, :summary, :calendar_name, :color, :icon, :all_day

      # @param date [Date] The date of the event
      # @param summary [String] Event title/summary
      # @param calendar_name [String] Name of the source calendar
      # @param color [String] Hex color code (6 digits, no #)
      # @param icon [String] Display icon for this event
      # @param all_day [Boolean] Whether this is an all-day event
      def initialize(date:, summary:, calendar_name: nil, color: nil, icon: nil, all_day: true)
        @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
        @summary = summary
        @calendar_name = calendar_name
        @color = color
        @icon = icon
        @all_day = all_day
      end

      # Calculate which week this date falls in (1-indexed)
      # @param year_start_monday [Date] The Monday of week 1
      # @return [Integer] The week number (1-53)
      def week_number(year_start_monday)
        days_from_start = (@date - year_start_monday).to_i
        (days_from_start / 7) + 1
      end

      # Get the day of week as a string
      # @return [String] Day name (e.g., "Monday", "Tuesday")
      def day_of_week
        @date.strftime('%A')
      end

      # Get a short display label for this event
      # @param include_icon [Boolean] Whether to include the icon
      # @return [String] Display label
      def display_label(include_icon: true)
        parts = []
        parts << @icon if include_icon && @icon
        parts << @summary
        parts.join(' ')
      end

      # Compare events by date for sorting
      # @param other [Event] Another event
      # @return [Integer] Comparison result (-1, 0, 1)
      def <=>(other)
        @date <=> other.date
      end

      # Check if this event matches another by date and summary
      # @param other [Event] Another event
      # @return [Boolean] True if events match
      def matches?(other)
        @date == other.date && @summary == other.summary
      end
    end
  end
end
