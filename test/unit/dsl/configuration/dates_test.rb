#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../../test_helper'
require 'yaml'
require 'tempfile'

module BujoPdf
  class DateConfigurationTest < Minitest::Test
    # ============================================
    # HighlightedDate Tests
    # ============================================

    def test_highlighted_date_initializes_with_required_params
      date = DateConfiguration::HighlightedDate.new(
        date: '2025-01-15',
        label: 'Test Event'
      )

      assert_equal Date.new(2025, 1, 15), date.date
      assert_equal 'Test Event', date.label
    end

    def test_highlighted_date_initializes_with_optional_params
      date = DateConfiguration::HighlightedDate.new(
        date: '2025-01-15',
        label: 'Test Event',
        category: 'holiday',
        priority: 'high',
        color: 'FF0000',
        text_color: '000000'
      )

      assert_equal 'holiday', date.category
      assert_equal 'high', date.priority
      assert_equal 'FF0000', date.color
      assert_equal '000000', date.text_color
    end

    def test_highlighted_date_defaults
      date = DateConfiguration::HighlightedDate.new(
        date: '2025-01-15',
        label: 'Test Event'
      )

      assert_equal 'other', date.category
      assert_equal 'normal', date.priority
      assert_nil date.color
      assert_nil date.text_color
    end

    def test_highlighted_date_accepts_date_object
      date_obj = Date.new(2025, 1, 15)
      date = DateConfiguration::HighlightedDate.new(
        date: date_obj,
        label: 'Test Event'
      )

      assert_equal Date.new(2025, 1, 15), date.date
    end

    def test_highlighted_date_week_number
      date = DateConfiguration::HighlightedDate.new(
        date: '2025-01-15',
        label: 'Test Event'
      )

      # Week 1 starts on Monday Dec 30, 2024 for 2025
      year_start_monday = Date.new(2024, 12, 30)
      week_num = date.week_number(year_start_monday)

      assert_kind_of Integer, week_num
      assert week_num > 0
    end

    def test_highlighted_date_day_of_week
      date = DateConfiguration::HighlightedDate.new(
        date: '2025-01-15',
        label: 'Test Event'
      )

      assert_equal 'Wednesday', date.day_of_week
    end

    # ============================================
    # DateConfiguration Initialization Tests
    # ============================================

    def test_initialize_without_config
      config = DateConfiguration.new('/nonexistent/path.yml')

      assert_equal [], config.dates
      assert config.categories.is_a?(Hash)
      assert config.priorities.is_a?(Hash)
    end

    def test_initialize_with_year
      config = DateConfiguration.new('/nonexistent/path.yml', year: 2025)

      assert_equal [], config.dates
    end

    def test_initialize_with_valid_config
      with_temp_config_file(valid_config_yaml) do |path|
        config = DateConfiguration.new(path)

        assert_equal 2, config.dates.length
        assert_equal 'New Year', config.dates[0].label
      end
    end

    # ============================================
    # Config Loading Tests
    # ============================================

    def test_load_config_with_valid_yaml
      with_temp_config_file(valid_config_yaml) do |path|
        config = DateConfiguration.new(path)

        assert_equal 2, config.dates.length
      end
    end

    def test_load_config_warns_on_year_mismatch
      yaml = <<~YAML
        year: 2024
        dates:
          - date: 2024-01-01
            label: Test
      YAML

      with_temp_config_file(yaml) do |path|
        assert_output(nil, /doesn't match/) do
          DateConfiguration.new(path, year: 2025)
        end
      end
    end

    def test_load_config_handles_syntax_error
      invalid_yaml = "dates: [invalid yaml here\n"

      with_temp_config_file(invalid_yaml) do |path|
        assert_output(nil, /YAML syntax error/) do
          DateConfiguration.new(path)
        end
      end
    end

    def test_load_config_handles_invalid_structure
      yaml = "just a string, not a hash"

      with_temp_config_file(yaml) do |path|
        assert_output(nil, /Invalid config format/) do
          DateConfiguration.new(path)
        end
      end
    end

    def test_load_config_skips_invalid_dates
      yaml = <<~YAML
        dates:
          - date: invalid-date
            label: Bad Date
          - date: 2025-01-15
            label: Good Date
      YAML

      with_temp_config_file(yaml) do |path|
        config = nil
        assert_output(nil, /Skipping invalid date/) do
          config = DateConfiguration.new(path)
        end
        assert_equal 1, config.dates.length
        assert_equal 'Good Date', config.dates[0].label
      end
    end

    def test_load_config_merges_custom_categories
      yaml = <<~YAML
        categories:
          custom:
            color: '00FF00'
            text_color: '000000'
            icon: 'x'
        dates: []
      YAML

      with_temp_config_file(yaml) do |path|
        config = DateConfiguration.new(path)

        assert config.categories.key?('custom')
        assert_equal '00FF00', config.categories['custom']['color']
      end
    end

    def test_load_config_merges_custom_priorities
      yaml = <<~YAML
        priorities:
          low:
            border_width: 0.25
            bold: false
        dates: []
      YAML

      with_temp_config_file(yaml) do |path|
        config = DateConfiguration.new(path)

        assert config.priorities.key?('low')
        assert_equal 0.25, config.priorities['low']['border_width']
      end
    end

    # ============================================
    # Date Lookup Tests
    # ============================================

    def test_dates_for_month
      with_temp_config_file(valid_config_yaml) do |path|
        config = DateConfiguration.new(path)

        january_dates = config.dates_for_month(1)
        assert_equal 1, january_dates.length
        assert_equal 'New Year', january_dates[0].label
      end
    end

    def test_dates_for_month_empty
      with_temp_config_file(valid_config_yaml) do |path|
        config = DateConfiguration.new(path)

        march_dates = config.dates_for_month(3)
        assert_equal [], march_dates
      end
    end

    def test_dates_for_week
      with_temp_config_file(valid_config_yaml) do |path|
        config = DateConfiguration.new(path)

        # Week 1 starts on Monday Dec 30, 2024 for 2025
        year_start_monday = Date.new(2024, 12, 30)
        week_dates = config.dates_for_week(1, year_start_monday)

        # Jan 1, 2025 falls in week 1
        assert week_dates.any? { |d| d.label == 'New Year' }
      end
    end

    def test_date_for_day
      with_temp_config_file(valid_config_yaml) do |path|
        config = DateConfiguration.new(path)

        result = config.date_for_day(Date.new(2025, 1, 1))
        assert_equal 'New Year', result.label
      end
    end

    def test_date_for_day_not_found
      with_temp_config_file(valid_config_yaml) do |path|
        config = DateConfiguration.new(path)

        result = config.date_for_day(Date.new(2025, 3, 15))
        assert_nil result
      end
    end

    # ============================================
    # Style Lookup Tests
    # ============================================

    def test_category_style_returns_style
      config = DateConfiguration.new('/nonexistent/path.yml')

      style = config.category_style('holiday')
      assert_equal 'FFE5E5', style['color']
      assert_equal 'CC0000', style['text_color']
      assert_equal '*', style['icon']
    end

    def test_category_style_returns_other_for_unknown
      config = DateConfiguration.new('/nonexistent/path.yml')

      style = config.category_style('unknown')
      assert_equal config.category_style('other'), style
    end

    def test_priority_style_returns_style
      config = DateConfiguration.new('/nonexistent/path.yml')

      style = config.priority_style('high')
      assert_equal 1.5, style['border_width']
      assert_equal true, style['bold']
    end

    def test_priority_style_returns_normal_for_unknown
      config = DateConfiguration.new('/nonexistent/path.yml')

      style = config.priority_style('unknown')
      assert_equal config.priority_style('normal'), style
    end

    # ============================================
    # Utility Method Tests
    # ============================================

    def test_any_returns_true_with_dates
      with_temp_config_file(valid_config_yaml) do |path|
        config = DateConfiguration.new(path)

        assert config.any?
      end
    end

    def test_any_returns_false_without_dates
      config = DateConfiguration.new('/nonexistent/path.yml')

      refute config.any?
    end

    # ============================================
    # Default Values Tests
    # ============================================

    def test_default_categories
      config = DateConfiguration.new('/nonexistent/path.yml')

      assert config.categories.key?('holiday')
      assert config.categories.key?('personal')
      assert config.categories.key?('work')
      assert config.categories.key?('other')
    end

    def test_default_priorities
      config = DateConfiguration.new('/nonexistent/path.yml')

      assert config.priorities.key?('high')
      assert config.priorities.key?('normal')
    end

    private

    def valid_config_yaml
      <<~YAML
        year: 2025
        dates:
          - date: 2025-01-01
            label: New Year
            category: holiday
            priority: high
          - date: 2025-02-14
            label: Valentine's Day
            category: personal
      YAML
    end

    def with_temp_config_file(content)
      file = Tempfile.new(['dates', '.yml'])
      file.write(content)
      file.close
      yield(file.path)
    ensure
      file.unlink
    end
  end
end
