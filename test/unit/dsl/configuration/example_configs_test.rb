# frozen_string_literal: true

require_relative '../../../test_helper'

module BujoPdf
  # Test that example YAML config files parse correctly through their loaders.
  # This catches drift between example files and what loaders expect.
  class ExampleConfigsTest < Minitest::Test
    def test_collections_example_parses
      example_path = 'config/collections.yml.example'
      skip 'No collections example' unless File.exist?(example_path)

      # Copy to temp file, load through CollectionsConfiguration
      Dir.mktmpdir do |dir|
        temp_path = File.join(dir, 'collections.yml')
        FileUtils.cp(example_path, temp_path)
        result = BujoPdf::CollectionsConfiguration.load(temp_path)
        assert_kind_of Array, result
        refute_empty result, 'Expected example to have at least one collection'
      end
    end

    def test_dates_example_parses
      example_path = 'config/dates.yml.example'
      skip 'No dates example' unless File.exist?(example_path)

      Dir.mktmpdir do |dir|
        temp_path = File.join(dir, 'dates.yml')
        FileUtils.cp(example_path, temp_path)
        config = BujoPdf::DateConfiguration.new(temp_path, year: 2025)
        # Should not raise, and should have dates
        assert config.any?, 'Expected example to have at least one date'
      end
    end

    def test_calendars_example_parses
      example_path = 'config/calendars.yml.example'
      skip 'No calendars example' unless File.exist?(example_path)

      Dir.mktmpdir do |dir|
        temp_path = File.join(dir, 'calendars.yml')
        FileUtils.cp(example_path, temp_path)
        loader = BujoPdf::CalendarIntegration::ConfigLoader.new(temp_path)
        # Should not raise, and should have calendars
        assert loader.any?, 'Expected example to have at least one calendar'
      end
    end
  end
end
