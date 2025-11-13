# frozen_string_literal: true

require 'icalendar'
require 'date'
require_relative 'event'

module BujoPdf
  module CalendarIntegration
    # RecurringEventExpander expands recurring events (RRULE) into individual occurrences
    class RecurringEventExpander
      # Expand recurring events into individual occurrences
      # @param recurring_event_data [Hash] Recurring event data from parser
      # @param start_date [Date] Start of date range
      # @param end_date [Date] End of date range
      # @return [Array<Event>] Array of event occurrences
      def self.expand(recurring_event_data, start_date, end_date)
        return [] unless recurring_event_data[:recurring]

        ical_event = recurring_event_data[:ical_event]
        calendar_name = recurring_event_data[:calendar_name]
        color = recurring_event_data[:color]
        icon = recurring_event_data[:icon]

        events = []

        begin
          # Get all occurrences within the date range
          occurrences = ical_event.occurrences_between(
            start_date.to_time,
            (end_date + 1).to_time # Add 1 day to include end_date
          )

          occurrences.each do |occurrence|
            date = occurrence.start_time.to_date

            events << Event.new(
              date: date,
              summary: ical_event.summary.to_s,
              calendar_name: calendar_name,
              color: color,
              icon: icon,
              all_day: all_day_event?(ical_event)
            )
          end

        rescue StandardError => e
          warn "Error expanding recurring event '#{ical_event.summary}': #{e.message}"
        end

        events
      end

      # Check if event is all-day
      # @param ical_event [Icalendar::Event] iCal event
      # @return [Boolean] True if all-day
      def self.all_day_event?(ical_event)
        dtstart = ical_event.dtstart
        return false unless dtstart

        # Check if dtstart is a Date (not DateTime)
        dtstart.is_a?(Date) && !dtstart.is_a?(DateTime)
      end
    end
  end
end
