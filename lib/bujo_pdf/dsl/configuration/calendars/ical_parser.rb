# frozen_string_literal: true

require 'icalendar'
require 'date'
require_relative 'event'

module BujoPdf
  module CalendarIntegration
    # IcalParser parses iCal data and extracts events
    class IcalParser
      # @param calendar_name [String] Name of the source calendar
      # @param color [String] Hex color code for events
      # @param icon [String] Icon for events
      # @param year [Integer] Target year for filtering
      def initialize(calendar_name:, color: nil, icon: nil, year: nil)
        @calendar_name = calendar_name
        @color = color
        @icon = icon
        @year = year
      end

      # Parse iCal data into events
      # @param ical_data [String] iCal data string
      # @param skip_all_day [Boolean] Whether to skip all-day events
      # @param exclude_patterns [Array<String>] Regex patterns to exclude
      # @return [Array<Event>] Array of events
      def parse(ical_data, skip_all_day: false, exclude_patterns: [])
        return [] unless ical_data

        calendars = Icalendar::Calendar.parse(ical_data)
        events = []

        calendars.each do |calendar|
          calendar.events.each do |ical_event|
            # Skip if event should be excluded
            next if should_exclude?(ical_event, skip_all_day, exclude_patterns)

            # Handle both one-time and recurring events
            if ical_event.rrule.empty?
              # One-time event
              event_dates = extract_event_dates(ical_event)
              event_dates.each do |event_date|
                events << create_event(event_date, ical_event)
              end
            else
              # Recurring event - return with rrule for expansion
              events << create_recurring_event(ical_event)
            end
          end
        end

        events
      rescue Icalendar::Parser::ParseError => e
        warn "Failed to parse iCal data for #{@calendar_name}: #{e.message}"
        []
      rescue StandardError => e
        warn "Error parsing iCal data for #{@calendar_name}: #{e.message}"
        []
      end

      private

      # Check if event should be excluded
      # @param ical_event [Icalendar::Event] iCal event
      # @param skip_all_day [Boolean] Whether to skip all-day events
      # @param exclude_patterns [Array<String>] Patterns to exclude
      # @return [Boolean] True if should exclude
      def should_exclude?(ical_event, skip_all_day, exclude_patterns)
        # Skip if no summary
        return true unless ical_event.summary

        # Skip all-day events if requested
        if skip_all_day && all_day_event?(ical_event)
          return true
        end

        # Check exclude patterns
        summary = ical_event.summary.to_s
        exclude_patterns.any? do |pattern|
          Regexp.new(pattern).match?(summary)
        end
      rescue StandardError => e
        warn "Error checking exclusion for event: #{e.message}"
        false
      end

      # Check if event is all-day
      # @param ical_event [Icalendar::Event] iCal event
      # @return [Boolean] True if all-day
      def all_day_event?(ical_event)
        dtstart = ical_event.dtstart
        return false unless dtstart

        # Check if dtstart is a Date value (Icalendar::Values::Date)
        # or a plain Date (not DateTime)
        dtstart.class.name.include?('Date') && !dtstart.class.name.include?('DateTime')
      end

      # Extract event dates from iCal event
      # @param ical_event [Icalendar::Event] iCal event
      # @return [Array<Date>] Array of dates
      def extract_event_dates(ical_event)
        dates = []
        dtstart = ical_event.dtstart
        dtend = ical_event.dtend

        return dates unless dtstart

        # Convert to Date
        start_date = convert_to_date(dtstart)
        return dates unless start_date

        # Handle multi-day events
        if dtend
          end_date = convert_to_date(dtend)
          if end_date && end_date > start_date
            # Multi-day event - create entries for each day
            (start_date...end_date).each do |date|
              dates << date if !@year || date.year == @year
            end
            return dates
          end
        end

        # Single-day event - filter by year if specified
        return dates if @year && start_date.year != @year
        dates << start_date
      end

      # Convert various date/time types to Date
      # @param dt [Date, DateTime, Time, Icalendar::Values::Date] Date/time value
      # @return [Date, nil] Date or nil
      def convert_to_date(dt)
        return nil unless dt

        # Handle Icalendar value types
        if dt.respond_to?(:to_date)
          return dt.to_date
        end

        # Handle standard Ruby types
        case dt
        when Date
          dt
        when DateTime, Time
          dt.to_date
        when String
          Date.parse(dt)
        else
          nil
        end
      rescue StandardError
        nil
      end

      # Create an event from iCal event
      # @param date [Date] Event date
      # @param ical_event [Icalendar::Event] iCal event
      # @return [Event] Event instance
      def create_event(date, ical_event)
        Event.new(
          date: date,
          summary: ical_event.summary.to_s,
          calendar_name: @calendar_name,
          color: @color,
          icon: @icon,
          all_day: all_day_event?(ical_event)
        )
      end

      # Create a recurring event marker (to be expanded later)
      # @param ical_event [Icalendar::Event] iCal event
      # @return [Hash] Recurring event data
      def create_recurring_event(ical_event)
        {
          ical_event: ical_event,
          calendar_name: @calendar_name,
          color: @color,
          icon: @icon,
          recurring: true
        }
      end
    end
  end
end
