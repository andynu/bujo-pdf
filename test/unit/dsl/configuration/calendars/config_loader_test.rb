#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../../../test_helper'

module BujoPdf
  module CalendarIntegration
    class ConfigLoaderTest < Minitest::Test
      def setup
        @temp_dir = Dir.mktmpdir
        @config_path = File.join(@temp_dir, 'calendars.yml')
      end

      def teardown
        FileUtils.remove_entry(@temp_dir)
      end

      # ============================================
      # Initialization Tests
      # ============================================

      def test_initialize_with_nonexistent_file
        loader = ConfigLoader.new('/nonexistent/path.yml')
        assert_empty loader.calendars
      end

      def test_initialize_with_default_path
        loader = ConfigLoader.new
        assert_kind_of ConfigLoader, loader
      end

      def test_default_cache_config
        loader = ConfigLoader.new('/nonexistent.yml')
        assert loader.cache_enabled?
        assert_equal '.cache/ical', loader.cache_directory
        assert_equal 24 * 3600, loader.cache_ttl_seconds
      end

      def test_default_network_config
        loader = ConfigLoader.new('/nonexistent.yml')
        assert_equal 10, loader.timeout_seconds
        assert_equal 3, loader.max_retries
        assert_equal 2, loader.retry_delay_seconds
      end

      def test_default_filter_config
        loader = ConfigLoader.new('/nonexistent.yml')
        assert_equal 3, loader.max_events_per_day
        refute loader.skip_all_day?
        assert_empty loader.exclude_patterns
      end

      # ============================================
      # Loading Valid Config Tests
      # ============================================

      def test_load_calendars_from_yaml
        write_config(<<~YAML)
          calendars:
            - name: Work
              url: https://example.com/work.ics
            - name: Personal
              url: https://example.com/personal.ics
        YAML

        loader = ConfigLoader.new(@config_path)
        assert_equal 2, loader.calendars.length
        assert_equal 'Work', loader.calendars[0].name
        assert_equal 'Personal', loader.calendars[1].name
      end

      def test_load_calendar_with_all_options
        write_config(<<~YAML)
          calendars:
            - name: Work
              url: https://example.com/work.ics
              enabled: false
              color: FF0000
              icon: '*'
        YAML

        loader = ConfigLoader.new(@config_path)
        cal = loader.calendars[0]
        assert_equal 'Work', cal.name
        assert_equal 'https://example.com/work.ics', cal.url
        refute cal.enabled
        assert_equal 'FF0000', cal.color
        assert_equal '*', cal.icon
      end

      def test_load_calendar_with_defaults
        write_config(<<~YAML)
          calendars:
            - name: Work
              url: https://example.com/work.ics
        YAML

        loader = ConfigLoader.new(@config_path)
        cal = loader.calendars[0]
        assert cal.enabled
        assert_equal 'CCCCCC', cal.color
      end

      def test_load_cache_config
        write_config(<<~YAML)
          cache:
            enabled: false
            directory: /tmp/ical
            ttl_hours: 48
        YAML

        loader = ConfigLoader.new(@config_path)
        refute loader.cache_enabled?
        assert_equal '/tmp/ical', loader.cache_directory
        assert_equal 48 * 3600, loader.cache_ttl_seconds
      end

      def test_load_network_config
        write_config(<<~YAML)
          network:
            timeout_seconds: 30
            max_retries: 5
            retry_delay_seconds: 5
        YAML

        loader = ConfigLoader.new(@config_path)
        assert_equal 30, loader.timeout_seconds
        assert_equal 5, loader.max_retries
        assert_equal 5, loader.retry_delay_seconds
      end

      def test_load_filter_config
        write_config(<<~YAML)
          filters:
            skip_all_day: true
            max_events_per_day: 5
            exclude_patterns:
              - "Holiday"
              - "Vacation"
        YAML

        loader = ConfigLoader.new(@config_path)
        assert loader.skip_all_day?
        assert_equal 5, loader.max_events_per_day
        assert_equal ['Holiday', 'Vacation'], loader.exclude_patterns
      end

      # ============================================
      # Error Handling Tests
      # ============================================

      def test_handles_invalid_yaml_syntax
        File.write(@config_path, "calendars:\n  - name: [broken yaml")

        _output, err = capture_io do
          loader = ConfigLoader.new(@config_path)
          assert_empty loader.calendars
        end
        assert_match(/YAML syntax error/, err)
      end

      def test_handles_non_hash_config
        File.write(@config_path, "- just\n- an\n- array")

        _output, err = capture_io do
          loader = ConfigLoader.new(@config_path)
          assert_empty loader.calendars
        end
        assert_match(/Invalid config format/, err)
      end

      def test_handles_standard_error_during_load
        # Stub YAML.safe_load_file to raise StandardError
        write_config("calendars: []")

        YAML.stub :safe_load_file, ->(_) { raise StandardError, "simulated error" } do
          _output, err = capture_io do
            loader = ConfigLoader.new(@config_path)
            assert_empty loader.calendars
          end
          assert_match(/Error loading calendar configuration/, err)
        end
      end

      def test_handles_non_array_calendars
        write_config(<<~YAML)
          calendars:
            name: NotAnArray
            url: https://example.com
        YAML

        loader = ConfigLoader.new(@config_path)
        assert_empty loader.calendars
      end

      def test_skips_calendar_without_name
        write_config(<<~YAML)
          calendars:
            - url: https://example.com/work.ics
        YAML

        loader = ConfigLoader.new(@config_path)
        assert_empty loader.calendars
      end

      def test_skips_calendar_without_url
        write_config(<<~YAML)
          calendars:
            - name: Work
        YAML

        loader = ConfigLoader.new(@config_path)
        assert_empty loader.calendars
      end

      def test_skips_non_hash_calendar_entry
        write_config(<<~YAML)
          calendars:
            - name: Work
              url: https://example.com/work.ics
            - "just a string"
            - name: Personal
              url: https://example.com/personal.ics
        YAML

        loader = ConfigLoader.new(@config_path)
        assert_equal 2, loader.calendars.length
      end

      # ============================================
      # Query Method Tests
      # ============================================

      def test_enabled_calendars
        write_config(<<~YAML)
          calendars:
            - name: Work
              url: https://example.com/work.ics
              enabled: true
            - name: Personal
              url: https://example.com/personal.ics
              enabled: false
        YAML

        loader = ConfigLoader.new(@config_path)
        enabled = loader.enabled_calendars
        assert_equal 1, enabled.length
        assert_equal 'Work', enabled[0].name
      end

      def test_any_returns_false_when_empty
        loader = ConfigLoader.new('/nonexistent.yml')
        refute loader.any?
      end

      def test_any_returns_true_when_calendars_exist
        write_config(<<~YAML)
          calendars:
            - name: Work
              url: https://example.com/work.ics
        YAML

        loader = ConfigLoader.new(@config_path)
        assert loader.any?
      end

      # ============================================
      # CalendarConfig Tests
      # ============================================

      def test_calendar_config_initialization
        config = ConfigLoader::CalendarConfig.new(
          name: 'Test',
          url: 'https://example.com',
          enabled: false,
          color: 'FF0000',
          icon: '*'
        )

        assert_equal 'Test', config.name
        assert_equal 'https://example.com', config.url
        refute config.enabled
        assert_equal 'FF0000', config.color
        assert_equal '*', config.icon
      end

      def test_calendar_config_defaults
        config = ConfigLoader::CalendarConfig.new(
          name: 'Test',
          url: 'https://example.com'
        )

        assert config.enabled
        assert_equal 'CCCCCC', config.color
      end

      def test_handles_argument_error_in_calendar_config
        write_config(<<~YAML)
          calendars:
            - name: Valid
              url: https://example.com/valid.ics
            - name: WillFail
              url: https://example.com/fail.ics
        YAML

        # Stub CalendarConfig.new to raise ArgumentError on second call
        call_count = 0
        original_new = ConfigLoader::CalendarConfig.method(:new)

        ConfigLoader::CalendarConfig.stub :new, ->(**args) {
          call_count += 1
          raise ArgumentError, "simulated argument error" if call_count == 2
          original_new.call(**args)
        } do
          _output, err = capture_io do
            loader = ConfigLoader.new(@config_path)
            assert_equal 1, loader.calendars.length
            assert_equal 'Valid', loader.calendars[0].name
          end
          assert_match(/Skipping invalid calendar/, err)
        end
      end

      private

      def write_config(yaml_content)
        File.write(@config_path, yaml_content)
      end
    end
  end
end
