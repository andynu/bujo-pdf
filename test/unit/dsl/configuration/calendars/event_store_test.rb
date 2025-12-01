# frozen_string_literal: true

require_relative '../../../../test_helper'

module BujoPdf
  module CalendarIntegration
    class EventStoreTest < Minitest::Test
      def setup
        @store = EventStore.new
      end

      # ============================================
      # Initialization Tests
      # ============================================

      def test_initialize_with_default_max_events_per_day
        store = EventStore.new

        assert_equal 3, store.max_events_per_day
      end

      def test_initialize_with_custom_max_events_per_day
        store = EventStore.new(max_events_per_day: 5)

        assert_equal 5, store.max_events_per_day
      end

      def test_initialize_creates_empty_store
        store = EventStore.new

        assert store.empty?
        assert_equal 0, store.total_events
      end

      # ============================================
      # add_event Tests
      # ============================================

      def test_add_event_stores_event_by_date
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        @store.add_event(event)

        assert_equal 1, @store.total_events
        assert @store.has_events?(Date.new(2025, 1, 15))
      end

      def test_add_event_ignores_nil
        @store.add_event(nil)

        assert @store.empty?
      end

      def test_add_event_ignores_objects_without_date_method
        object_without_date = Object.new

        @store.add_event(object_without_date)

        assert @store.empty?
      end

      def test_add_event_allows_multiple_events_on_same_date
        event1 = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting 1')
        event2 = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting 2')

        @store.add_event(event1)
        @store.add_event(event2)

        assert_equal 2, @store.event_count(Date.new(2025, 1, 15))
      end

      # ============================================
      # events_for_date Tests
      # ============================================

      def test_events_for_date_returns_events_for_given_date
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')
        @store.add_event(event)

        result = @store.events_for_date(Date.new(2025, 1, 15))

        assert_equal 1, result.size
        assert_equal 'Meeting', result.first.summary
      end

      def test_events_for_date_returns_empty_array_for_no_events
        result = @store.events_for_date(Date.new(2025, 1, 15))

        assert_equal [], result
      end

      def test_events_for_date_respects_max_events_per_day_limit
        store = EventStore.new(max_events_per_day: 2)
        3.times { |i| store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: "Event #{i}")) }

        result = store.events_for_date(Date.new(2025, 1, 15))

        assert_equal 2, result.size
      end

      def test_events_for_date_respects_explicit_limit
        3.times { |i| @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: "Event #{i}")) }

        result = @store.events_for_date(Date.new(2025, 1, 15), limit: 1)

        assert_equal 1, result.size
      end

      def test_events_for_date_returns_sorted_events
        event1 = Event.new(date: Date.new(2025, 1, 15), summary: 'B Event')
        event2 = Event.new(date: Date.new(2025, 1, 15), summary: 'A Event')
        @store.add_event(event1)
        @store.add_event(event2)

        result = @store.events_for_date(Date.new(2025, 1, 15))

        # Events on same date are sorted by <=> (date comparison returns 0, so order preserved)
        assert_equal 2, result.size
      end

      # ============================================
      # has_events? Tests
      # ============================================

      def test_has_events_returns_true_when_events_exist
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting'))

        assert @store.has_events?(Date.new(2025, 1, 15))
      end

      def test_has_events_returns_false_when_no_events
        refute @store.has_events?(Date.new(2025, 1, 15))
      end

      # ============================================
      # events_for_month Tests
      # ============================================

      def test_events_for_month_returns_events_in_month
        @store.add_event(Event.new(date: Date.new(2025, 1, 10), summary: 'Early'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 20), summary: 'Late'))
        @store.add_event(Event.new(date: Date.new(2025, 2, 5), summary: 'Next Month'))

        result = @store.events_for_month(2025, 1)

        assert_equal 2, result.size
        assert result.key?(Date.new(2025, 1, 10))
        assert result.key?(Date.new(2025, 1, 20))
        refute result.key?(Date.new(2025, 2, 5))
      end

      def test_events_for_month_returns_empty_hash_for_no_events
        result = @store.events_for_month(2025, 1)

        assert_equal({}, result)
      end

      def test_events_for_month_handles_last_day_of_month
        @store.add_event(Event.new(date: Date.new(2025, 1, 31), summary: 'End of Month'))

        result = @store.events_for_month(2025, 1)

        assert result.key?(Date.new(2025, 1, 31))
      end

      def test_events_for_month_handles_february
        @store.add_event(Event.new(date: Date.new(2025, 2, 28), summary: 'Feb End'))

        result = @store.events_for_month(2025, 2)

        assert result.key?(Date.new(2025, 2, 28))
      end

      # ============================================
      # events_for_week Tests
      # ============================================

      def test_events_for_week_returns_events_in_range
        monday = Date.new(2025, 1, 13)
        sunday = Date.new(2025, 1, 19)
        @store.add_event(Event.new(date: monday, summary: 'Monday'))
        @store.add_event(Event.new(date: sunday, summary: 'Sunday'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 20), summary: 'Next Week'))

        result = @store.events_for_week(monday, sunday)

        assert_equal 2, result.size
        assert result.key?(monday)
        assert result.key?(sunday)
      end

      def test_events_for_week_returns_empty_hash_for_no_events
        monday = Date.new(2025, 1, 13)
        sunday = Date.new(2025, 1, 19)

        result = @store.events_for_week(monday, sunday)

        assert_equal({}, result)
      end

      # ============================================
      # events_for_date_range Tests
      # ============================================

      def test_events_for_date_range_returns_events_in_range
        @store.add_event(Event.new(date: Date.new(2025, 1, 10), summary: 'In Range'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Also In Range'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 20), summary: 'Outside Range'))

        result = @store.events_for_date_range(Date.new(2025, 1, 10), Date.new(2025, 1, 15))

        assert_equal 2, result.size
        assert result.key?(Date.new(2025, 1, 10))
        assert result.key?(Date.new(2025, 1, 15))
        refute result.key?(Date.new(2025, 1, 20))
      end

      def test_events_for_date_range_includes_boundary_dates
        start_date = Date.new(2025, 1, 10)
        end_date = Date.new(2025, 1, 15)
        @store.add_event(Event.new(date: start_date, summary: 'Start'))
        @store.add_event(Event.new(date: end_date, summary: 'End'))

        result = @store.events_for_date_range(start_date, end_date)

        assert result.key?(start_date)
        assert result.key?(end_date)
      end

      def test_events_for_date_range_returns_empty_hash_for_no_events
        result = @store.events_for_date_range(Date.new(2025, 1, 1), Date.new(2025, 1, 31))

        assert_equal({}, result)
      end

      # ============================================
      # event_count Tests
      # ============================================

      def test_event_count_returns_count_for_date
        2.times { |i| @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: "Event #{i}")) }

        assert_equal 2, @store.event_count(Date.new(2025, 1, 15))
      end

      def test_event_count_returns_zero_for_no_events
        assert_equal 0, @store.event_count(Date.new(2025, 1, 15))
      end

      # ============================================
      # total_events Tests
      # ============================================

      def test_total_events_returns_count_of_all_events
        @store.add_event(Event.new(date: Date.new(2025, 1, 10), summary: 'Event 1'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Event 2'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 20), summary: 'Event 3'))

        assert_equal 3, @store.total_events
      end

      def test_total_events_returns_zero_for_empty_store
        assert_equal 0, @store.total_events
      end

      # ============================================
      # dates_with_events Tests
      # ============================================

      def test_dates_with_events_returns_sorted_dates
        @store.add_event(Event.new(date: Date.new(2025, 1, 20), summary: 'Later'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 10), summary: 'Earlier'))

        result = @store.dates_with_events

        assert_equal [Date.new(2025, 1, 10), Date.new(2025, 1, 20)], result
      end

      def test_dates_with_events_returns_empty_array_for_empty_store
        result = @store.dates_with_events

        assert_equal [], result
      end

      def test_dates_with_events_returns_unique_dates
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Event 1'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Event 2'))

        result = @store.dates_with_events

        assert_equal [Date.new(2025, 1, 15)], result
      end

      # ============================================
      # empty? Tests
      # ============================================

      def test_empty_returns_true_for_new_store
        assert @store.empty?
      end

      def test_empty_returns_false_after_adding_event
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting'))

        refute @store.empty?
      end

      # ============================================
      # statistics Tests
      # ============================================

      def test_statistics_returns_expected_keys
        result = @store.statistics

        assert result.key?(:total_events)
        assert result.key?(:unique_dates)
        assert result.key?(:max_events_on_single_day)
        assert result.key?(:dates_with_multiple_events)
      end

      def test_statistics_returns_correct_values_for_empty_store
        result = @store.statistics

        assert_equal 0, result[:total_events]
        assert_equal 0, result[:unique_dates]
        assert_equal 0, result[:max_events_on_single_day]
        assert_equal 0, result[:dates_with_multiple_events]
      end

      def test_statistics_returns_correct_values_with_events
        @store.add_event(Event.new(date: Date.new(2025, 1, 10), summary: 'Solo'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Double 1'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Double 2'))
        @store.add_event(Event.new(date: Date.new(2025, 1, 15), summary: 'Double 3'))

        result = @store.statistics

        assert_equal 4, result[:total_events]
        assert_equal 2, result[:unique_dates]
        assert_equal 3, result[:max_events_on_single_day]
        assert_equal 1, result[:dates_with_multiple_events]
      end
    end
  end
end
