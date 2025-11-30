# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'fileutils'
require 'digest'

module BujoPdf
  module CalendarIntegration
    # IcalFetcher handles fetching iCal data from URLs with caching and retry logic
    class IcalFetcher
      # @param cache_enabled [Boolean] Whether to use caching
      # @param cache_directory [String] Directory for cache files
      # @param cache_ttl_seconds [Integer] Cache time-to-live in seconds
      # @param timeout_seconds [Integer] Network timeout
      # @param max_retries [Integer] Maximum retry attempts
      # @param retry_delay_seconds [Integer] Delay between retries
      def initialize(
        cache_enabled: true,
        cache_directory: '.cache/ical',
        cache_ttl_seconds: 86_400,
        timeout_seconds: 10,
        max_retries: 3,
        retry_delay_seconds: 2
      )
        @cache_enabled = cache_enabled
        @cache_directory = cache_directory
        @cache_ttl_seconds = cache_ttl_seconds
        @timeout_seconds = timeout_seconds
        @max_retries = max_retries
        @retry_delay_seconds = retry_delay_seconds

        setup_cache_directory if @cache_enabled
      end

      # Fetch iCal data from URL
      # @param url [String] iCal URL to fetch
      # @param calendar_name [String] Optional calendar name for logging
      # @return [String, nil] iCal data or nil on failure
      def fetch(url, calendar_name: nil)
        # Validate URL
        unless valid_url?(url)
          warn "Invalid URL for calendar #{calendar_name}: #{sanitize_url(url)}"
          return nil
        end

        # Try cache first
        if @cache_enabled
          cached_data = read_from_cache(url)
          if cached_data
            puts "Using cached data for #{calendar_name || 'calendar'}"
            return cached_data
          end
        end

        # Fetch from network with retries
        data = fetch_with_retries(url, calendar_name)

        # Cache successful fetch
        write_to_cache(url, data) if data && @cache_enabled

        data
      end

      # Clear cache for a specific URL or all URLs
      # @param url [String, nil] URL to clear cache for, or nil for all
      def clear_cache(url = nil)
        return unless @cache_enabled

        if url
          cache_path = cache_file_path(url)
          File.delete(cache_path) if File.exist?(cache_path)
        else
          FileUtils.rm_rf(@cache_directory)
          setup_cache_directory
        end
      end

      private

      # Validate URL format
      # @param url [String] URL to validate
      # @return [Boolean] True if valid
      def valid_url?(url)
        return false unless url.is_a?(String)

        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        false
      end

      # Sanitize URL for error messages (hide sensitive parts)
      # @param url [String] URL to sanitize
      # @return [String] Sanitized URL
      def sanitize_url(url)
        uri = URI.parse(url)
        uri.query = '[REDACTED]' if uri.query
        uri.to_s
      rescue StandardError
        '[INVALID URL]'
      end

      # Fetch from network with retry logic
      # @param url [String] URL to fetch
      # @param calendar_name [String] Optional calendar name
      # @return [String, nil] Data or nil
      def fetch_with_retries(url, calendar_name)
        attempts = 0

        loop do
          attempts += 1

          begin
            return fetch_from_network(url, calendar_name)
          rescue StandardError => e
            if attempts < @max_retries
              warn "Fetch attempt #{attempts} failed for #{calendar_name || 'calendar'}: #{e.message}"
              sleep(@retry_delay_seconds)
            else
              warn "Failed to fetch #{calendar_name || 'calendar'} after #{attempts} attempts: #{e.message}"
              return nil
            end
          end
        end
      end

      # Fetch from network (single attempt)
      # @param url [String] URL to fetch
      # @param calendar_name [String] Optional calendar name
      # @return [String] iCal data
      def fetch_from_network(url, calendar_name)
        uri = URI.parse(url)

        # Follow up to 5 redirects
        redirect_limit = 5
        response = nil

        redirect_limit.times do
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = @timeout_seconds
          http.open_timeout = @timeout_seconds

          request = Net::HTTP::Get.new(uri.request_uri)
          request['User-Agent'] = 'BujoPdf Calendar Integration'

          response = http.request(request)

          case response
          when Net::HTTPSuccess
            puts "Fetched #{calendar_name || 'calendar'} from network"
            return response.body
          when Net::HTTPRedirection
            uri = URI.parse(response['location'])
          else
            raise "HTTP error: #{response.code} #{response.message}"
          end
        end

        raise "Too many redirects for #{sanitize_url(url)}"
      end

      # Get cache file path for URL
      # @param url [String] URL
      # @return [String] Cache file path
      def cache_file_path(url)
        # Use hash of URL as filename to avoid filesystem issues
        hash = Digest::SHA256.hexdigest(url)
        File.join(@cache_directory, "#{hash}.ics")
      end

      # Read from cache if valid
      # @param url [String] URL
      # @return [String, nil] Cached data or nil
      def read_from_cache(url)
        cache_path = cache_file_path(url)
        return nil unless File.exist?(cache_path)

        # Check if cache is stale
        age_seconds = Time.now - File.mtime(cache_path)
        return nil if age_seconds > @cache_ttl_seconds

        File.read(cache_path)
      end

      # Write to cache
      # @param url [String] URL
      # @param data [String] Data to cache
      def write_to_cache(url, data)
        cache_path = cache_file_path(url)
        File.write(cache_path, data)
      rescue StandardError => e
        warn "Failed to write cache: #{e.message}"
      end

      # Setup cache directory
      def setup_cache_directory
        FileUtils.mkdir_p(@cache_directory)
      rescue StandardError => e
        warn "Failed to create cache directory: #{e.message}"
        @cache_enabled = false
      end
    end
  end
end
