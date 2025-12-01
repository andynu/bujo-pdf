# frozen_string_literal: true

require_relative '../../../../test_helper'
require 'webmock/minitest'

module BujoPdf
  module CalendarIntegration
    class IcalFetcherTest < Minitest::Test
      def setup
        @cache_dir = Dir.mktmpdir('ical_fetcher_test')
        @fetcher = IcalFetcher.new(
          cache_enabled: true,
          cache_directory: @cache_dir,
          cache_ttl_seconds: 3600,
          timeout_seconds: 5,
          max_retries: 2,
          retry_delay_seconds: 0 # No delay in tests
        )
      end

      def teardown
        FileUtils.rm_rf(@cache_dir) if @cache_dir && File.exist?(@cache_dir)
        WebMock.reset!
      end

      # ============================================
      # Initialization Tests
      # ============================================

      def test_initialize_with_defaults
        fetcher = IcalFetcher.new
        assert_equal true, fetcher.instance_variable_get(:@cache_enabled)
        assert_equal '.cache/ical', fetcher.instance_variable_get(:@cache_directory)
        assert_equal 86_400, fetcher.instance_variable_get(:@cache_ttl_seconds)
        assert_equal 10, fetcher.instance_variable_get(:@timeout_seconds)
        assert_equal 3, fetcher.instance_variable_get(:@max_retries)
        assert_equal 2, fetcher.instance_variable_get(:@retry_delay_seconds)
      end

      def test_initialize_with_custom_params
        fetcher = IcalFetcher.new(
          cache_enabled: false,
          cache_directory: '/custom/path',
          cache_ttl_seconds: 1800,
          timeout_seconds: 30,
          max_retries: 5,
          retry_delay_seconds: 1
        )

        assert_equal false, fetcher.instance_variable_get(:@cache_enabled)
        assert_equal '/custom/path', fetcher.instance_variable_get(:@cache_directory)
        assert_equal 1800, fetcher.instance_variable_get(:@cache_ttl_seconds)
        assert_equal 30, fetcher.instance_variable_get(:@timeout_seconds)
        assert_equal 5, fetcher.instance_variable_get(:@max_retries)
        assert_equal 1, fetcher.instance_variable_get(:@retry_delay_seconds)
      end

      def test_initialize_creates_cache_directory
        cache_dir = File.join(@cache_dir, 'nested', 'cache')
        refute File.exist?(cache_dir)

        IcalFetcher.new(cache_enabled: true, cache_directory: cache_dir)

        assert File.directory?(cache_dir)
      end

      def test_initialize_disables_cache_on_directory_creation_failure
        # Use a path that can't be created (under a file, not a directory)
        temp_file = File.join(@cache_dir, 'blockfile')
        File.write(temp_file, 'content')
        invalid_path = File.join(temp_file, 'nested', 'cache')

        fetcher = IcalFetcher.new(cache_enabled: true, cache_directory: invalid_path)

        assert_equal false, fetcher.instance_variable_get(:@cache_enabled)
      end

      # ============================================
      # URL Validation Tests
      # ============================================

      def test_fetch_invalid_url_returns_nil
        result = @fetcher.fetch('not-a-url')
        assert_nil result
      end

      def test_fetch_non_http_url_returns_nil
        result = @fetcher.fetch('ftp://example.com/calendar.ics')
        assert_nil result
      end

      def test_fetch_nil_url_returns_nil
        result = @fetcher.fetch(nil)
        assert_nil result
      end

      def test_fetch_url_with_invalid_uri_returns_nil
        # URL with null byte causes URI::InvalidURIError
        result = @fetcher.fetch("http://example\x00.com/cal.ics")
        assert_nil result
      end

      def test_fetch_empty_url_returns_nil
        result = @fetcher.fetch('')
        assert_nil result
      end

      # ============================================
      # Successful Fetch Tests
      # ============================================

      def test_fetch_success
        url = 'https://example.com/calendar.ics'
        ical_data = sample_ical_data

        stub_request(:get, url)
          .to_return(status: 200, body: ical_data)

        result = @fetcher.fetch(url, calendar_name: 'Test Calendar')

        assert_equal ical_data, result
      end

      def test_fetch_caches_successful_response
        url = 'https://example.com/calendar.ics'
        ical_data = sample_ical_data

        stub_request(:get, url)
          .to_return(status: 200, body: ical_data)

        @fetcher.fetch(url)

        # Second fetch should use cache (no network request)
        WebMock.reset!
        result = @fetcher.fetch(url)

        assert_equal ical_data, result
      end

      def test_fetch_uses_cached_data_when_valid
        url = 'https://example.com/calendar.ics'
        ical_data = sample_ical_data

        # Write to cache manually
        cache_path = @fetcher.send(:cache_file_path, url)
        File.write(cache_path, ical_data)

        # Should not make network request
        result = @fetcher.fetch(url)

        assert_equal ical_data, result
        assert_not_requested :get, url
      end

      def test_fetch_ignores_stale_cache
        url = 'https://example.com/calendar.ics'
        old_data = 'OLD DATA'
        new_data = sample_ical_data

        # Write old cache
        cache_path = @fetcher.send(:cache_file_path, url)
        File.write(cache_path, old_data)
        # Make cache file old
        old_time = Time.now - 7200 # 2 hours ago (TTL is 1 hour)
        File.utime(old_time, old_time, cache_path)

        stub_request(:get, url)
          .to_return(status: 200, body: new_data)

        result = @fetcher.fetch(url)

        assert_equal new_data, result
      end

      def test_fetch_without_caching
        url = 'https://example.com/calendar.ics'
        ical_data = sample_ical_data
        fetcher = IcalFetcher.new(cache_enabled: false)

        stub_request(:get, url)
          .to_return(status: 200, body: ical_data)

        result = fetcher.fetch(url)

        assert_equal ical_data, result
      end

      # ============================================
      # HTTP Error Handling Tests
      # ============================================

      def test_fetch_retries_on_network_error
        url = 'https://example.com/calendar.ics'
        ical_data = sample_ical_data

        stub_request(:get, url)
          .to_raise(StandardError.new('Network error'))
          .then.to_return(status: 200, body: ical_data)

        result = @fetcher.fetch(url)

        assert_equal ical_data, result
      end

      def test_fetch_returns_nil_after_max_retries
        url = 'https://example.com/calendar.ics'

        stub_request(:get, url)
          .to_raise(StandardError.new('Network error'))

        result = @fetcher.fetch(url)

        assert_nil result
      end

      def test_fetch_handles_http_error
        url = 'https://example.com/calendar.ics'

        stub_request(:get, url)
          .to_return(status: 500, body: 'Server Error')

        result = @fetcher.fetch(url)

        assert_nil result
      end

      def test_fetch_follows_redirects
        original_url = 'https://example.com/calendar.ics'
        redirect_url = 'https://other.example.com/calendar.ics'
        ical_data = sample_ical_data

        stub_request(:get, original_url)
          .to_return(status: 302, headers: { 'Location' => redirect_url })
        stub_request(:get, redirect_url)
          .to_return(status: 200, body: ical_data)

        result = @fetcher.fetch(original_url)

        assert_equal ical_data, result
      end

      def test_fetch_fails_after_too_many_redirects
        url = 'https://example.com/calendar.ics'

        # Create infinite redirect loop
        stub_request(:get, url)
          .to_return(status: 302, headers: { 'Location' => url })

        result = @fetcher.fetch(url)

        assert_nil result
      end

      # ============================================
      # Cache Management Tests
      # ============================================

      def test_clear_cache_for_specific_url
        url = 'https://example.com/calendar.ics'
        cache_path = @fetcher.send(:cache_file_path, url)
        File.write(cache_path, 'cached data')

        assert File.exist?(cache_path)

        @fetcher.clear_cache(url)

        refute File.exist?(cache_path)
      end

      def test_clear_cache_all
        url1 = 'https://example.com/calendar1.ics'
        url2 = 'https://example.com/calendar2.ics'

        # Create cache files
        File.write(@fetcher.send(:cache_file_path, url1), 'data1')
        File.write(@fetcher.send(:cache_file_path, url2), 'data2')

        @fetcher.clear_cache

        # Directory should be recreated but empty
        assert File.directory?(@cache_dir)
        assert_equal [], Dir.glob(File.join(@cache_dir, '*.ics'))
      end

      def test_clear_cache_noop_when_disabled
        fetcher = IcalFetcher.new(cache_enabled: false)

        # Should not raise
        fetcher.clear_cache
        fetcher.clear_cache('https://example.com/cal.ics')
      end

      def test_clear_cache_handles_nonexistent_file
        url = 'https://example.com/calendar.ics'
        cache_path = @fetcher.send(:cache_file_path, url)

        refute File.exist?(cache_path)

        # Should not raise
        @fetcher.clear_cache(url)
      end

      # ============================================
      # URL Sanitization Tests
      # ============================================

      def test_sanitize_url_redacts_query_params
        url = 'https://example.com/calendar.ics?secret=abc123&token=xyz'

        sanitized = @fetcher.send(:sanitize_url, url)

        assert_equal 'https://example.com/calendar.ics?[REDACTED]', sanitized
      end

      def test_sanitize_url_without_query_params
        url = 'https://example.com/calendar.ics'

        sanitized = @fetcher.send(:sanitize_url, url)

        assert_equal url, sanitized
      end

      def test_sanitize_url_handles_invalid_url
        sanitized = @fetcher.send(:sanitize_url, "not a \x00 valid url")

        assert_equal '[INVALID URL]', sanitized
      end

      # ============================================
      # Cache File Path Tests
      # ============================================

      def test_cache_file_path_uses_hash
        url = 'https://example.com/calendar.ics'
        expected_hash = Digest::SHA256.hexdigest(url)

        path = @fetcher.send(:cache_file_path, url)

        assert_equal File.join(@cache_dir, "#{expected_hash}.ics"), path
      end

      def test_cache_file_path_is_deterministic
        url = 'https://example.com/calendar.ics'

        path1 = @fetcher.send(:cache_file_path, url)
        path2 = @fetcher.send(:cache_file_path, url)

        assert_equal path1, path2
      end

      def test_different_urls_have_different_cache_paths
        url1 = 'https://example.com/calendar1.ics'
        url2 = 'https://example.com/calendar2.ics'

        path1 = @fetcher.send(:cache_file_path, url1)
        path2 = @fetcher.send(:cache_file_path, url2)

        refute_equal path1, path2
      end

      # ============================================
      # Write Cache Error Handling Tests
      # ============================================

      def test_write_to_cache_handles_write_error
        url = 'https://example.com/calendar.ics'

        # Make cache directory read-only
        FileUtils.chmod(0o444, @cache_dir)

        # Should not raise, just warn
        @fetcher.send(:write_to_cache, url, 'data')
      ensure
        FileUtils.chmod(0o755, @cache_dir)
      end

      # ============================================
      # Integration Tests
      # ============================================

      def test_full_fetch_workflow
        url = 'https://example.com/calendar.ics'
        ical_data = sample_ical_data

        # First fetch - from network
        stub_request(:get, url)
          .to_return(status: 200, body: ical_data)

        result1 = @fetcher.fetch(url, calendar_name: 'Test')
        assert_equal ical_data, result1

        # Second fetch - from cache
        WebMock.reset!
        result2 = @fetcher.fetch(url, calendar_name: 'Test')
        assert_equal ical_data, result2

        # Clear cache
        @fetcher.clear_cache(url)

        # Third fetch - from network again
        stub_request(:get, url)
          .to_return(status: 200, body: 'NEW DATA')

        result3 = @fetcher.fetch(url, calendar_name: 'Test')
        assert_equal 'NEW DATA', result3
      end

      private

      def sample_ical_data
        <<~ICAL
          BEGIN:VCALENDAR
          VERSION:2.0
          PRODID:-//Test//Test//EN
          BEGIN:VEVENT
          DTSTART:20250115
          DTEND:20250116
          SUMMARY:Test Event
          END:VEVENT
          END:VCALENDAR
        ICAL
      end
    end
  end
end
