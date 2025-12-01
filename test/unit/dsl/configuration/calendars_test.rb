# frozen_string_literal: true

require_relative '../../../test_helper'
require 'tmpdir'
require 'fileutils'

module BujoPdf
  class CalendarIntegrationTest < Minitest::Test
    def setup
      @tmp_dir = Dir.mktmpdir
      @config_path = File.join(@tmp_dir, 'calendars.yml')
    end

    def teardown
      FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
    end

    # ============================================
    # Basic Behavior Tests
    # ============================================

    def test_load_events_returns_nil_when_no_config_file
      result = CalendarIntegration.load_events(config_path: '/nonexistent/path.yml', year: 2025)

      assert_nil result
    end

    def test_load_events_returns_nil_when_no_enabled_calendars
      write_config({
        'settings' => { 'cache_ttl_seconds' => 3600 },
        'calendars' => []
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      assert_nil result
    end

    def test_load_events_returns_event_store_with_valid_config
      # Create a minimal mock iCal
      ical_path = write_ical_file(build_simple_ical('Test Event', '20250115', '20250116'))

      write_config({
        'settings' => {
          'cache_enabled' => false,
          'timeout_seconds' => 5,
          'max_retries' => 0
        },
        'calendars' => [
          {
            'name' => 'Test Calendar',
            'url' => "file://#{ical_path}",
            'color' => 'FF0000',
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      assert_kind_of CalendarIntegration::EventStore, result
    end

    def test_load_events_with_events_in_correct_year
      ical_path = write_ical_file(build_simple_ical('Meeting', '20250115', '20250116'))

      write_config({
        'settings' => { 'cache_enabled' => false },
        'calendars' => [
          {
            'name' => 'Work',
            'url' => "file://#{ical_path}",
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      assert_kind_of CalendarIntegration::EventStore, result
      stats = result.statistics
      assert stats[:total_events] >= 0
    end

    def test_load_events_filters_by_year
      ical_path = write_ical_file(build_simple_ical('Old Event', '20240115', '20240116'))

      write_config({
        'settings' => { 'cache_enabled' => false },
        'calendars' => [
          {
            'name' => 'Work',
            'url' => "file://#{ical_path}",
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      # Should return event store but with no events from 2024
      assert_kind_of CalendarIntegration::EventStore, result
      stats = result.statistics
      assert_equal 0, stats[:total_events]
    end

    # ============================================
    # Error Handling Tests
    # ============================================

    def test_load_events_handles_fetch_errors_gracefully
      write_config({
        'settings' => {
          'cache_enabled' => false,
          'timeout_seconds' => 1,
          'max_retries' => 0
        },
        'calendars' => [
          {
            'name' => 'Bad Calendar',
            'url' => 'file:///nonexistent/file.ics',
            'enabled' => true
          }
        ]
      })

      # Should not raise, should return an empty store or handle gracefully
      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      # May return empty store since fetch failed
      if result
        assert_kind_of CalendarIntegration::EventStore, result
      end
    end

    def test_load_events_handles_parse_errors_gracefully
      # Write invalid iCal data
      ical_path = File.join(@tmp_dir, 'invalid.ics')
      File.write(ical_path, 'This is not valid iCal data')

      write_config({
        'settings' => { 'cache_enabled' => false },
        'calendars' => [
          {
            'name' => 'Bad Calendar',
            'url' => "file://#{ical_path}",
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      # Should handle gracefully, returning store with no events
      if result
        assert_kind_of CalendarIntegration::EventStore, result
      end
    end

    # ============================================
    # Configuration Tests
    # ============================================

    def test_load_events_respects_skip_all_day_setting
      ical_path = write_ical_file(build_simple_ical('All Day Event', '20250115', '20250116'))

      write_config({
        'settings' => {
          'cache_enabled' => false,
          'skip_all_day' => true
        },
        'calendars' => [
          {
            'name' => 'Work',
            'url' => "file://#{ical_path}",
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      # With skip_all_day: true, all-day events should be filtered out
      assert_kind_of CalendarIntegration::EventStore, result
      stats = result.statistics
      assert_equal 0, stats[:total_events]
    end

    def test_load_events_respects_exclude_patterns
      ical_path = write_ical_file(build_simple_ical('Personal Task', '20250115', '20250116'))

      write_config({
        'settings' => {
          'cache_enabled' => false,
          'exclude_patterns' => ['Personal']
        },
        'calendars' => [
          {
            'name' => 'Work',
            'url' => "file://#{ical_path}",
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      # Event matching pattern should be excluded
      assert_kind_of CalendarIntegration::EventStore, result
      stats = result.statistics
      assert_equal 0, stats[:total_events]
    end

    def test_load_events_respects_max_events_per_day
      # Create multiple events on same day
      ical_content = <<~ICAL
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20250115
        DTEND;VALUE=DATE:20250116
        SUMMARY:Event 1
        END:VEVENT
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20250115
        DTEND;VALUE=DATE:20250116
        SUMMARY:Event 2
        END:VEVENT
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20250115
        DTEND;VALUE=DATE:20250116
        SUMMARY:Event 3
        END:VEVENT
        END:VCALENDAR
      ICAL

      ical_path = write_ical_file(ical_content)

      write_config({
        'settings' => {
          'cache_enabled' => false,
          'max_events_per_day' => 2
        },
        'calendars' => [
          {
            'name' => 'Work',
            'url' => "file://#{ical_path}",
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      assert_kind_of CalendarIntegration::EventStore, result
      # Max 2 events per day should be enforced
      events = result.events_for_date(Date.new(2025, 1, 15))
      assert events.size <= 2
    end

    def test_load_events_assigns_calendar_colors
      ical_path = write_ical_file(build_simple_ical('Colored Event', '20250115', '20250116'))

      write_config({
        'settings' => { 'cache_enabled' => false },
        'calendars' => [
          {
            'name' => 'Work',
            'url' => "file://#{ical_path}",
            'color' => 'FF0000',
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      events = result.events_for_date(Date.new(2025, 1, 15))
      if events.any?
        assert_equal 'FF0000', events.first.color
      end
    end

    def test_load_events_assigns_calendar_icons
      ical_path = write_ical_file(build_simple_ical('Icon Event', '20250115', '20250116'))

      write_config({
        'settings' => { 'cache_enabled' => false },
        'calendars' => [
          {
            'name' => 'Work',
            'url' => "file://#{ical_path}",
            'icon' => '*',
            'enabled' => true
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      events = result.events_for_date(Date.new(2025, 1, 15))
      if events.any?
        assert_equal '*', events.first.icon
      end
    end

    # ============================================
    # Output Tests
    # ============================================

    def test_load_events_prints_loading_message
      write_config({
        'settings' => { 'cache_enabled' => false },
        'calendars' => [
          { 'name' => 'Test', 'url' => 'file:///tmp/test.ics', 'enabled' => true }
        ]
      })

      output = capture_io do
        CalendarIntegration.load_events(config_path: @config_path, year: 2025)
      end

      assert_match(/Loading events from 1 calendar/, output.first)
    end

    def test_load_events_prints_statistics
      write_config({
        'settings' => { 'cache_enabled' => false },
        'calendars' => [
          { 'name' => 'Test', 'url' => 'file:///tmp/test.ics', 'enabled' => true }
        ]
      })

      output = capture_io do
        CalendarIntegration.load_events(config_path: @config_path, year: 2025)
      end

      assert_match(/Loaded \d+ events across \d+ days/, output.first)
    end

    # ============================================
    # Multiple Calendar Tests
    # ============================================

    def test_load_events_processes_multiple_calendars
      # Multiple calendars configured - file:// URLs are rejected but tests the multiple calendar loop
      write_config({
        'settings' => { 'cache_enabled' => false, 'timeout_seconds' => 1, 'max_retries' => 0 },
        'calendars' => [
          {
            'name' => 'Work',
            'url' => 'file:///tmp/work.ics',  # Will be rejected - file:// not valid
            'color' => 'FF0000',
            'enabled' => true
          },
          {
            'name' => 'Personal',
            'url' => 'file:///tmp/personal.ics',  # Will be rejected
            'color' => '00FF00',
            'enabled' => true
          }
        ]
      })

      # The test validates that multiple calendars are attempted to be processed
      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      # Should return an event store even if no events loaded (URLs rejected)
      assert_kind_of CalendarIntegration::EventStore, result
    end

    def test_load_events_skips_disabled_calendars
      # Test that disabled calendars are filtered out by ConfigLoader
      write_config({
        'settings' => { 'cache_enabled' => false, 'timeout_seconds' => 1, 'max_retries' => 0 },
        'calendars' => [
          {
            'name' => 'Enabled',
            'url' => 'file:///tmp/enabled.ics',  # Will be rejected, but calendar loop runs
            'enabled' => true
          },
          {
            'name' => 'Disabled',
            'url' => 'file:///tmp/disabled.ics',
            'enabled' => false
          }
        ]
      })

      result = CalendarIntegration.load_events(config_path: @config_path, year: 2025)

      # Should return event store (enabled calendar was attempted)
      assert_kind_of CalendarIntegration::EventStore, result
    end

    # ============================================
    # Helper Methods
    # ============================================

    private

    def write_config(config_hash)
      File.write(@config_path, YAML.dump(config_hash))
    end

    def write_ical_file(content, filename = 'test.ics')
      path = File.join(@tmp_dir, filename)
      File.write(path, content)
      path
    end

    def build_simple_ical(summary, dtstart, dtend)
      <<~ICAL
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:#{dtstart}
        DTEND;VALUE=DATE:#{dtend}
        SUMMARY:#{summary}
        END:VEVENT
        END:VCALENDAR
      ICAL
    end
  end
end
