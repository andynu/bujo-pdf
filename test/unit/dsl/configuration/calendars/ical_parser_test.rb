# frozen_string_literal: true

require_relative '../../../../test_helper'

module BujoPdf
  module CalendarIntegration
    class IcalParserTest < Minitest::Test
      def setup
        @parser = IcalParser.new(calendar_name: 'Test Calendar')
      end

      # ============================================
      # Initialization Tests
      # ============================================

      def test_initializes_with_calendar_name
        parser = IcalParser.new(calendar_name: 'Work')
        assert_equal 'Work', parser.instance_variable_get(:@calendar_name)
      end

      def test_initializes_with_optional_color
        parser = IcalParser.new(calendar_name: 'Work', color: 'FF0000')
        assert_equal 'FF0000', parser.instance_variable_get(:@color)
      end

      def test_initializes_with_optional_icon
        parser = IcalParser.new(calendar_name: 'Work', icon: '*')
        assert_equal '*', parser.instance_variable_get(:@icon)
      end

      def test_initializes_with_optional_year_filter
        parser = IcalParser.new(calendar_name: 'Work', year: 2025)
        assert_equal 2025, parser.instance_variable_get(:@year)
      end

      # ============================================
      # Basic Parsing Tests
      # ============================================

      def test_parse_returns_empty_array_for_nil_data
        result = @parser.parse(nil)
        assert_equal [], result
      end

      def test_parse_returns_empty_array_for_empty_string
        result = @parser.parse('')
        assert_equal [], result
      end

      def test_parse_single_event
        ical_data = build_ical_with_events([
          { summary: 'Meeting', dtstart: '20250115', dtend: '20250116', all_day: true }
        ])

        events = @parser.parse(ical_data)

        assert_equal 1, events.size
        assert_kind_of Event, events.first
        assert_equal 'Meeting', events.first.summary
        assert_equal Date.new(2025, 1, 15), events.first.date
      end

      def test_parse_multiple_events
        ical_data = build_ical_with_events([
          { summary: 'Meeting 1', dtstart: '20250115', dtend: '20250116', all_day: true },
          { summary: 'Meeting 2', dtstart: '20250120', dtend: '20250121', all_day: true }
        ])

        events = @parser.parse(ical_data)

        assert_equal 2, events.size
        assert_equal 'Meeting 1', events[0].summary
        assert_equal 'Meeting 2', events[1].summary
      end

      def test_parse_assigns_calendar_name_to_events
        ical_data = build_ical_with_events([
          { summary: 'Test Event', dtstart: '20250115', dtend: '20250116', all_day: true }
        ])

        events = @parser.parse(ical_data)

        assert_equal 'Test Calendar', events.first.calendar_name
      end

      def test_parse_assigns_color_to_events
        parser = IcalParser.new(calendar_name: 'Work', color: 'FF0000')
        ical_data = build_ical_with_events([
          { summary: 'Test Event', dtstart: '20250115', dtend: '20250116', all_day: true }
        ])

        events = parser.parse(ical_data)

        assert_equal 'FF0000', events.first.color
      end

      def test_parse_assigns_icon_to_events
        parser = IcalParser.new(calendar_name: 'Work', icon: '*')
        ical_data = build_ical_with_events([
          { summary: 'Test Event', dtstart: '20250115', dtend: '20250116', all_day: true }
        ])

        events = parser.parse(ical_data)

        assert_equal '*', events.first.icon
      end

      # ============================================
      # All-Day Event Tests
      # ============================================

      def test_all_day_event_detection
        ical_data = build_ical_with_events([
          { summary: 'All Day Event', dtstart: '20250115', dtend: '20250116', all_day: true }
        ])

        events = @parser.parse(ical_data)

        assert events.first.all_day
      end

      def test_timed_event_not_all_day
        ical_data = build_ical_with_events([
          { summary: 'Timed Event', dtstart: '20250115T100000', dtend: '20250115T110000' }
        ])

        events = @parser.parse(ical_data)

        refute events.first.all_day
      end

      def test_skip_all_day_events_when_flag_set
        ical_data = build_ical_with_events([
          { summary: 'All Day Event', dtstart: '20250115', dtend: '20250116', all_day: true },
          { summary: 'Timed Event', dtstart: '20250116T100000', dtend: '20250116T110000' }
        ])

        events = @parser.parse(ical_data, skip_all_day: true)

        assert_equal 1, events.size
        assert_equal 'Timed Event', events.first.summary
      end

      # ============================================
      # Multi-Day Event Tests
      # ============================================

      def test_multi_day_event_creates_multiple_events
        ical_data = build_ical_with_events([
          { summary: 'Conference', dtstart: '20250115', dtend: '20250118', all_day: true }
        ])

        events = @parser.parse(ical_data)

        assert_equal 3, events.size
        assert_equal [Date.new(2025, 1, 15), Date.new(2025, 1, 16), Date.new(2025, 1, 17)],
                     events.map(&:date)
        events.each { |e| assert_equal 'Conference', e.summary }
      end

      # ============================================
      # Year Filtering Tests
      # ============================================

      def test_year_filter_includes_matching_events
        parser = IcalParser.new(calendar_name: 'Work', year: 2025)
        ical_data = build_ical_with_events([
          { summary: 'Event 2025', dtstart: '20250115', dtend: '20250116', all_day: true }
        ])

        events = parser.parse(ical_data)

        assert_equal 1, events.size
      end

      def test_year_filter_excludes_non_matching_events
        parser = IcalParser.new(calendar_name: 'Work', year: 2025)
        ical_data = build_ical_with_events([
          { summary: 'Event 2024', dtstart: '20240115', dtend: '20240116', all_day: true }
        ])

        events = parser.parse(ical_data)

        assert_equal [], events
      end

      def test_year_filter_on_multi_day_event_spanning_years
        parser = IcalParser.new(calendar_name: 'Work', year: 2025)
        ical_data = build_ical_with_events([
          { summary: 'New Year Event', dtstart: '20241231', dtend: '20250103', all_day: true }
        ])

        events = parser.parse(ical_data)

        # Only 2025 dates should be included
        assert_equal 2, events.size
        assert_equal [Date.new(2025, 1, 1), Date.new(2025, 1, 2)], events.map(&:date)
      end

      # ============================================
      # Exclude Pattern Tests
      # ============================================

      def test_exclude_patterns_filter_events
        ical_data = build_ical_with_events([
          { summary: 'Team Meeting', dtstart: '20250115', dtend: '20250116', all_day: true },
          { summary: 'Personal Appointment', dtstart: '20250116', dtend: '20250117', all_day: true }
        ])

        events = @parser.parse(ical_data, exclude_patterns: ['Personal'])

        assert_equal 1, events.size
        assert_equal 'Team Meeting', events.first.summary
      end

      def test_exclude_patterns_use_regex
        ical_data = build_ical_with_events([
          { summary: 'Team Meeting', dtstart: '20250115', dtend: '20250116', all_day: true },
          { summary: 'Team Standup', dtstart: '20250116', dtend: '20250117', all_day: true },
          { summary: 'Lunch', dtstart: '20250117', dtend: '20250118', all_day: true }
        ])

        events = @parser.parse(ical_data, exclude_patterns: ['^Team'])

        assert_equal 1, events.size
        assert_equal 'Lunch', events.first.summary
      end

      def test_multiple_exclude_patterns
        ical_data = build_ical_with_events([
          { summary: 'Team Meeting', dtstart: '20250115', dtend: '20250116', all_day: true },
          { summary: 'Personal Task', dtstart: '20250116', dtend: '20250117', all_day: true },
          { summary: 'Important Event', dtstart: '20250117', dtend: '20250118', all_day: true }
        ])

        events = @parser.parse(ical_data, exclude_patterns: ['Team', 'Personal'])

        assert_equal 1, events.size
        assert_equal 'Important Event', events.first.summary
      end

      # ============================================
      # Events Without Summary Tests
      # ============================================

      def test_skips_events_without_summary
        # Build manually to create event without summary
        cal = Icalendar::Calendar.new
        event = Icalendar::Event.new
        event.dtstart = Icalendar::Values::Date.new('20250115')
        event.dtend = Icalendar::Values::Date.new('20250116')
        # Deliberately no summary
        cal.add_event(event)

        events = @parser.parse(cal.to_ical)

        assert_equal [], events
      end

      # ============================================
      # Recurring Events Tests
      # ============================================

      def test_recurring_event_returns_hash_with_ical_event
        ical_data = build_recurring_event(
          summary: 'Weekly Meeting',
          dtstart: '20250115T100000',
          rrule: 'FREQ=WEEKLY;COUNT=4'
        )

        events = @parser.parse(ical_data)

        assert_equal 1, events.size
        assert_kind_of Hash, events.first
        assert events.first[:recurring]
        assert_equal 'Test Calendar', events.first[:calendar_name]
      end

      def test_recurring_event_includes_color_and_icon
        parser = IcalParser.new(calendar_name: 'Work', color: '00FF00', icon: '+')
        ical_data = build_recurring_event(
          summary: 'Weekly Meeting',
          dtstart: '20250115T100000',
          rrule: 'FREQ=WEEKLY;COUNT=4'
        )

        events = parser.parse(ical_data)

        assert_equal '00FF00', events.first[:color]
        assert_equal '+', events.first[:icon]
      end

      # ============================================
      # Error Handling Tests
      # ============================================

      def test_handles_invalid_ical_data_gracefully
        invalid_data = 'This is not valid iCal data'

        # Should return empty array, not raise
        events = @parser.parse(invalid_data)

        assert_equal [], events
      end

      def test_handles_malformed_events_gracefully
        # Build iCal with incomplete structure
        malformed_data = <<~ICAL
          BEGIN:VCALENDAR
          VERSION:2.0
          BEGIN:VEVENT
          DTSTART:invalid-date
          SUMMARY:Bad Event
          END:VEVENT
          END:VCALENDAR
        ICAL

        # Should not raise, may return empty or partial results
        events = @parser.parse(malformed_data)

        assert_kind_of Array, events
      end

      # ============================================
      # Date Conversion Tests
      # ============================================

      def test_handles_datetime_with_timezone
        ical_data = build_ical_with_events([
          { summary: 'TZ Event', dtstart: '20250115T100000Z', dtend: '20250115T110000Z' }
        ])

        events = @parser.parse(ical_data)

        assert_equal Date.new(2025, 1, 15), events.first.date
      end

      # ============================================
      # Helper Methods
      # ============================================

      private

      # Build iCal data string with given events
      def build_ical_with_events(event_specs)
        cal = Icalendar::Calendar.new

        event_specs.each do |spec|
          event = Icalendar::Event.new
          event.summary = spec[:summary]

          if spec[:all_day]
            event.dtstart = Icalendar::Values::Date.new(spec[:dtstart])
            event.dtend = Icalendar::Values::Date.new(spec[:dtend]) if spec[:dtend]
          else
            event.dtstart = Icalendar::Values::DateTime.new(spec[:dtstart])
            event.dtend = Icalendar::Values::DateTime.new(spec[:dtend]) if spec[:dtend]
          end

          cal.add_event(event)
        end

        cal.to_ical
      end

      # Build iCal data with a recurring event
      def build_recurring_event(summary:, dtstart:, rrule:)
        cal = Icalendar::Calendar.new
        event = Icalendar::Event.new
        event.summary = summary
        event.dtstart = Icalendar::Values::DateTime.new(dtstart)
        event.rrule = rrule
        cal.add_event(event)
        cal.to_ical
      end
    end
  end
end
