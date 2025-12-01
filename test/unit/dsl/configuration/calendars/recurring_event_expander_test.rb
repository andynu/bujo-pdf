#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../../../test_helper'
require 'icalendar'
require 'date'

module BujoPdf
  module CalendarIntegration
    class RecurringEventExpanderTest < Minitest::Test
      # ============================================
      # expand Tests - Basic Cases
      # ============================================

      def test_expand_returns_empty_for_non_recurring_event
        event_data = { recurring: false }
        result = RecurringEventExpander.expand(event_data, Date.new(2025, 1, 1), Date.new(2025, 12, 31))
        assert_equal [], result
      end

      def test_expand_returns_empty_for_nil_recurring
        event_data = { recurring: nil }
        result = RecurringEventExpander.expand(event_data, Date.new(2025, 1, 1), Date.new(2025, 12, 31))
        assert_equal [], result
      end

      def test_expand_returns_empty_for_missing_recurring_key
        event_data = { ical_event: Object.new }
        result = RecurringEventExpander.expand(event_data, Date.new(2025, 1, 1), Date.new(2025, 12, 31))
        assert_equal [], result
      end

      # ============================================
      # expand Tests - With Mock Event
      # ============================================

      def test_expand_with_mock_event_returns_occurrences
        mock_event = MockRecurringEvent.new(
          summary: 'Weekly Meeting',
          occurrences: [
            MockOccurrence.new(Date.new(2025, 1, 6)),
            MockOccurrence.new(Date.new(2025, 1, 13)),
            MockOccurrence.new(Date.new(2025, 1, 20))
          ],
          dtstart: MockDateTime.new
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: 'FF0000',
          icon: '*'
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert_equal 3, result.size
        assert_equal Date.new(2025, 1, 6), result[0].date
        assert_equal Date.new(2025, 1, 13), result[1].date
        assert_equal Date.new(2025, 1, 20), result[2].date
      end

      def test_expand_sets_summary_on_events
        mock_event = MockRecurringEvent.new(
          summary: 'Team Sync',
          occurrences: [MockOccurrence.new(Date.new(2025, 1, 15))],
          dtstart: MockDateTime.new
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: nil,
          icon: nil
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert_equal 1, result.size
        assert_equal 'Team Sync', result.first.summary
      end

      def test_expand_sets_calendar_name_on_events
        mock_event = MockRecurringEvent.new(
          summary: 'Meeting',
          occurrences: [MockOccurrence.new(Date.new(2025, 1, 15))],
          dtstart: MockDateTime.new
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Personal Calendar',
          color: nil,
          icon: nil
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert_equal 'Personal Calendar', result.first.calendar_name
      end

      def test_expand_sets_color_on_events
        mock_event = MockRecurringEvent.new(
          summary: 'Meeting',
          occurrences: [MockOccurrence.new(Date.new(2025, 1, 15))],
          dtstart: MockDateTime.new
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: 'AABBCC',
          icon: nil
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert_equal 'AABBCC', result.first.color
      end

      def test_expand_sets_icon_on_events
        mock_event = MockRecurringEvent.new(
          summary: 'Meeting',
          occurrences: [MockOccurrence.new(Date.new(2025, 1, 15))],
          dtstart: MockDateTime.new
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: nil,
          icon: '!'
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert_equal '!', result.first.icon
      end

      # ============================================
      # expand Tests - Empty Results
      # ============================================

      def test_expand_with_no_occurrences_in_range
        mock_event = MockRecurringEvent.new(
          summary: 'Future Event',
          occurrences: [],
          dtstart: MockDateTime.new
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: nil,
          icon: nil
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert_equal [], result
      end

      # ============================================
      # expand Tests - All-Day Detection
      # ============================================

      def test_expand_all_day_event
        mock_event = MockRecurringEvent.new(
          summary: 'All Day Event',
          occurrences: [MockOccurrence.new(Date.new(2025, 1, 15))],
          dtstart: MockDate.new # Date (not DateTime) = all day
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: nil,
          icon: nil
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert result.first.all_day
      end

      def test_expand_timed_event_not_all_day
        mock_event = MockRecurringEvent.new(
          summary: 'Timed Event',
          occurrences: [MockOccurrence.new(Date.new(2025, 1, 15))],
          dtstart: MockDateTime.new # DateTime = not all day
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: nil,
          icon: nil
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        refute result.first.all_day
      end

      # ============================================
      # all_day_event? Tests
      # ============================================

      def test_all_day_event_returns_true_for_date_dtstart
        event = MockEventForAllDay.new(dtstart: MockDate.new)
        assert RecurringEventExpander.all_day_event?(event)
      end

      def test_all_day_event_returns_false_for_datetime_dtstart
        event = MockEventForAllDay.new(dtstart: MockDateTime.new)
        refute RecurringEventExpander.all_day_event?(event)
      end

      def test_all_day_event_returns_false_for_nil_dtstart
        event = MockEventForAllDay.new(dtstart: nil)
        refute RecurringEventExpander.all_day_event?(event)
      end

      # ============================================
      # Error Handling Tests
      # ============================================

      def test_expand_handles_error_gracefully
        bad_event = MockErrorEvent.new

        event_data = {
          recurring: true,
          ical_event: bad_event,
          calendar_name: 'Work',
          color: nil,
          icon: nil
        }

        # Should not raise, should return empty array
        result = nil
        assert_output(nil, /Error expanding recurring event/) do
          result = RecurringEventExpander.expand(
            event_data,
            Date.new(2025, 1, 1),
            Date.new(2025, 12, 31)
          )
        end

        assert_equal [], result
      end

      # ============================================
      # Edge Cases
      # ============================================

      def test_expand_returns_event_objects
        mock_event = MockRecurringEvent.new(
          summary: 'Meeting',
          occurrences: [MockOccurrence.new(Date.new(2025, 1, 15))],
          dtstart: MockDateTime.new
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: nil,
          icon: nil
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert_kind_of Event, result.first
      end

      def test_expand_with_multiple_occurrences
        mock_event = MockRecurringEvent.new(
          summary: 'Daily Standup',
          occurrences: (15..19).map { |day| MockOccurrence.new(Date.new(2025, 1, day)) },
          dtstart: MockDateTime.new
        )

        event_data = {
          recurring: true,
          ical_event: mock_event,
          calendar_name: 'Work',
          color: nil,
          icon: nil
        }

        result = RecurringEventExpander.expand(
          event_data,
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 31)
        )

        assert_equal 5, result.size
        result.each { |e| assert_equal 'Daily Standup', e.summary }
      end
    end

    # ============================================
    # Mock Classes
    # ============================================

    # Mock occurrence that behaves like icalendar occurrence
    class MockOccurrence
      attr_reader :start_time

      def initialize(date)
        @start_time = date.to_time
      end
    end

    # Mock Date class for all-day detection (Date but not DateTime)
    class MockDate < Date
      def initialize
        # Use a specific date
        super(2025, 1, 15)
      end
    end

    # Mock DateTime class for timed events
    class MockDateTime < DateTime
      def initialize
        super(2025, 1, 15, 10, 0, 0)
      end
    end

    # Mock recurring event with occurrences_between method
    class MockRecurringEvent
      attr_reader :summary, :dtstart

      def initialize(summary:, occurrences:, dtstart:)
        @summary = summary
        @occurrences = occurrences
        @dtstart = dtstart
      end

      def occurrences_between(_start_time, _end_time)
        @occurrences
      end
    end

    # Mock event for testing all_day_event? only
    class MockEventForAllDay
      attr_reader :dtstart

      def initialize(dtstart:)
        @dtstart = dtstart
      end
    end

    # Mock event that raises errors
    class MockErrorEvent
      def summary
        "Bad Event"
      end

      def occurrences_between(*_args)
        raise StandardError, "Simulated error"
      end
    end
  end
end
