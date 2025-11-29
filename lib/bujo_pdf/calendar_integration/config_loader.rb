# frozen_string_literal: true

require 'yaml'

module BujoPdf
  module CalendarIntegration
    # ConfigLoader loads and validates calendar configuration from YAML
    class ConfigLoader
      attr_reader :calendars, :cache_config, :network_config, :filter_config

      # Calendar configuration with defaults
      class CalendarConfig
        attr_reader :name, :url, :enabled, :color, :icon

        def initialize(name:, url:, enabled: true, color: 'CCCCCC', icon: '•')
          @name = name
          @url = url
          @enabled = enabled
          @color = color
          @icon = icon
        end
      end

      # Initialize with config file path
      # @param config_path [String] Path to calendars.yml
      def initialize(config_path = 'config/calendars.yml')
        @config_path = config_path
        @calendars = []
        @cache_config = default_cache_config
        @network_config = default_network_config
        @filter_config = default_filter_config
        load_config if File.exist?(@config_path)
      end

      # Load configuration from YAML file
      def load_config
        return unless File.exist?(@config_path)

        begin
          config = YAML.safe_load_file(@config_path)

          unless config.is_a?(Hash)
            warn "Invalid config format in #{@config_path}"
            return
          end

          # Load calendar definitions
          load_calendars(config['calendars']) if config['calendars']

          # Load cache configuration
          @cache_config.merge!(config['cache']) if config['cache']

          # Load network configuration
          @network_config.merge!(config['network']) if config['network']

          # Load filter configuration
          @filter_config.merge!(config['filters']) if config['filters']

        rescue Psych::SyntaxError => e
          warn "YAML syntax error in #{@config_path}: #{e.message}"
        rescue StandardError => e
          warn "Error loading calendar configuration: #{e.message}"
        end
      end

      # Get only enabled calendars
      # @return [Array<CalendarConfig>] Enabled calendars
      def enabled_calendars
        @calendars.select(&:enabled)
      end

      # Check if any calendars are configured
      # @return [Boolean] True if calendars exist
      def any?
        !@calendars.empty?
      end

      # Check if caching is enabled
      # @return [Boolean] True if caching is enabled
      def cache_enabled?
        @cache_config['enabled']
      end

      # Get cache directory path
      # @return [String] Cache directory
      def cache_directory
        @cache_config['directory']
      end

      # Get cache TTL in seconds
      # @return [Integer] Cache TTL in seconds
      def cache_ttl_seconds
        @cache_config['ttl_hours'] * 3600
      end

      # Get network timeout in seconds
      # @return [Integer] Timeout in seconds
      def timeout_seconds
        @network_config['timeout_seconds']
      end

      # Get maximum retries
      # @return [Integer] Max retries
      def max_retries
        @network_config['max_retries']
      end

      # Get retry delay in seconds
      # @return [Integer] Retry delay
      def retry_delay_seconds
        @network_config['retry_delay_seconds']
      end

      # Get max events per day
      # @return [Integer] Max events per day
      def max_events_per_day
        @filter_config['max_events_per_day']
      end

      # Check if should skip all-day events
      # @return [Boolean] True to skip all-day events
      def skip_all_day?
        @filter_config['skip_all_day']
      end

      # Get exclude patterns
      # @return [Array<String>] Regex patterns to exclude
      def exclude_patterns
        @filter_config['exclude_patterns'] || []
      end

      private

      # Load calendar definitions from config
      # @param calendars_config [Array<Hash>] Calendar configurations
      def load_calendars(calendars_config)
        return unless calendars_config.is_a?(Array)

        calendars_config.each do |cal_config|
          next unless cal_config.is_a?(Hash)
          next unless cal_config['name'] && cal_config['url']

          @calendars << CalendarConfig.new(
            name: cal_config['name'],
            url: cal_config['url'],
            enabled: cal_config.fetch('enabled', true),
            color: cal_config.fetch('color', 'CCCCCC'),
            icon: cal_config.fetch('icon', '•')
          )
        rescue ArgumentError => e
          warn "Skipping invalid calendar: #{cal_config.inspect} - #{e.message}"
        end
      end

      # Default cache configuration
      # @return [Hash] Default cache config
      def default_cache_config
        {
          'enabled' => true,
          'directory' => '.cache/ical',
          'ttl_hours' => 24
        }
      end

      # Default network configuration
      # @return [Hash] Default network config
      def default_network_config
        {
          'timeout_seconds' => 10,
          'max_retries' => 3,
          'retry_delay_seconds' => 2
        }
      end

      # Default filter configuration
      # @return [Hash] Default filter config
      def default_filter_config
        {
          'date_range_only' => true,
          'skip_all_day' => false,
          'max_events_per_day' => 3,
          'exclude_patterns' => []
        }
      end
    end
  end
end
