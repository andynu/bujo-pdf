# frozen_string_literal: true

require_relative 'calendars/event'
require_relative 'calendars/config_loader'
require_relative 'calendars/ical_fetcher'
require_relative 'calendars/ical_parser'
require_relative 'calendars/recurring_event_expander'
require_relative 'calendars/event_store'

module BujoPdf
  # CalendarIntegration provides iCal URL integration for event highlighting
  module CalendarIntegration
    # Load events from iCal calendars configured in calendars.yml
    # @param config_path [String] Path to calendars.yml
    # @param year [Integer] Target year for filtering events
    # @return [EventStore, nil] Event store with loaded events, or nil if no config
    def self.load_events(config_path: 'config/calendars.yml', year:)
      return nil unless File.exist?(config_path)

      # Load configuration
      config = ConfigLoader.new(config_path)
      return nil if config.enabled_calendars.empty?

      puts "Loading events from #{config.enabled_calendars.size} calendar(s)..."

      # Initialize event store
      store = EventStore.new(max_events_per_day: config.max_events_per_day)

      # Initialize fetcher
      fetcher = IcalFetcher.new(
        cache_enabled: config.cache_enabled?,
        cache_directory: config.cache_directory,
        cache_ttl_seconds: config.cache_ttl_seconds,
        timeout_seconds: config.timeout_seconds,
        max_retries: config.max_retries,
        retry_delay_seconds: config.retry_delay_seconds
      )

      # Calculate date range for the year
      year_start = Date.new(year, 1, 1)
      year_end = Date.new(year, 12, 31)

      # Process each enabled calendar
      recurring_events = []

      config.enabled_calendars.each do |calendar|
        # Fetch iCal data
        ical_data = fetcher.fetch(calendar.url, calendar_name: calendar.name)
        next unless ical_data

        # Parse events
        parser = IcalParser.new(
          calendar_name: calendar.name,
          color: calendar.color,
          icon: calendar.icon,
          year: year
        )

        events = parser.parse(
          ical_data,
          skip_all_day: config.skip_all_day?,
          exclude_patterns: config.exclude_patterns
        )

        # Separate one-time and recurring events
        events.each do |event|
          if event.is_a?(Hash) && event[:recurring]
            recurring_events << event
          else
            store.add_event(event)
          end
        end
      end

      # Expand recurring events
      unless recurring_events.empty?
        puts "Expanding #{recurring_events.size} recurring event(s)..."
        recurring_events.each do |recurring_data|
          expanded = RecurringEventExpander.expand(recurring_data, year_start, year_end)
          expanded.each { |event| store.add_event(event) }
        end
      end

      # Print statistics
      stats = store.statistics
      puts "Loaded #{stats[:total_events]} events across #{stats[:unique_dates]} days"

      store
    rescue StandardError => e
      warn "Failed to load calendar events: #{e.message}"
      warn e.backtrace.take(5).join("\n")
      nil
    end
  end
end
