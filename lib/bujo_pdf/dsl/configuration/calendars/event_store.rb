# frozen_string_literal: true

require 'date'

module BujoPdf
  module CalendarIntegration
    # EventStore manages events organized by date with filtering and lookup
    class EventStore
      attr_reader :events_by_date, :max_events_per_day

      # @param max_events_per_day [Integer] Maximum events to show per day
      def initialize(max_events_per_day: 3)
        @events_by_date = Hash.new { |h, k| h[k] = [] }
        @max_events_per_day = max_events_per_day
      end

      # Add an event to the store
      # @param event [Event] Event to add
      def add_event(event)
        return unless event.respond_to?(:date)

        date_key = event.date.to_s
        @events_by_date[date_key] << event
      end

      # Get events for a specific date
      # @param date [Date] Date to look up
      # @param limit [Integer, nil] Optional limit (defaults to max_events_per_day)
      # @return [Array<Event>] Events for that date
      def events_for_date(date, limit: nil)
        limit ||= @max_events_per_day
        date_key = date.to_s
        events = @events_by_date[date_key] || []
        events.sort.take(limit)
      end

      # Check if a date has any events
      # @param date [Date] Date to check
      # @return [Boolean] True if date has events
      def has_events?(date)
        date_key = date.to_s
        !@events_by_date[date_key].empty?
      end

      # Get events for a specific month
      # @param year [Integer] Year
      # @param month [Integer] Month (1-12)
      # @return [Hash<Date, Array<Event>>] Events by date for that month
      def events_for_month(year, month)
        start_date = Date.new(year, month, 1)
        end_date = Date.new(year, month, -1) # Last day of month

        events_for_date_range(start_date, end_date)
      end

      # Get events for a specific week
      # @param week_start [Date] Start of week (Monday)
      # @param week_end [Date] End of week (Sunday)
      # @return [Hash<Date, Array<Event>>] Events by date for that week
      def events_for_week(week_start, week_end)
        events_for_date_range(week_start, week_end)
      end

      # Get events for a date range
      # @param start_date [Date] Start date
      # @param end_date [Date] End date
      # @return [Hash<Date, Array<Event>>] Events by date
      def events_for_date_range(start_date, end_date)
        result = {}

        (start_date..end_date).each do |date|
          events = events_for_date(date)
          result[date] = events unless events.empty?
        end

        result
      end

      # Get count of events for a date
      # @param date [Date] Date to check
      # @return [Integer] Number of events
      def event_count(date)
        date_key = date.to_s
        @events_by_date[date_key].size
      end

      # Get total number of events in store
      # @return [Integer] Total events
      def total_events
        @events_by_date.values.sum(&:size)
      end

      # Get all unique dates with events
      # @return [Array<Date>] Array of dates
      def dates_with_events
        @events_by_date.keys.map { |k| Date.parse(k) }.sort
      end

      # Check if store is empty
      # @return [Boolean] True if no events
      def empty?
        @events_by_date.empty?
      end

      # Get statistics about the store
      # @return [Hash] Statistics hash
      def statistics
        {
          total_events: total_events,
          unique_dates: @events_by_date.size,
          max_events_on_single_day: @events_by_date.values.map(&:size).max || 0,
          dates_with_multiple_events: @events_by_date.count { |_, events| events.size > 1 }
        }
      end
    end
  end
end
