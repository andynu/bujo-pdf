# frozen_string_literal: true

require_relative '../../../../test_helper'

module BujoPdf
  module CalendarIntegration
    class EventTest < Minitest::Test
      # ============================================
      # Initialization Tests
      # ============================================

      def test_initialize_with_required_params
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert_equal Date.new(2025, 1, 15), event.date
        assert_equal 'Meeting', event.summary
      end

      def test_initialize_with_all_params
        event = Event.new(
          date: Date.new(2025, 1, 15),
          summary: 'Meeting',
          calendar_name: 'Work',
          color: 'FF0000',
          icon: '*',
          all_day: false
        )

        assert_equal Date.new(2025, 1, 15), event.date
        assert_equal 'Meeting', event.summary
        assert_equal 'Work', event.calendar_name
        assert_equal 'FF0000', event.color
        assert_equal '*', event.icon
        assert_equal false, event.all_day
      end

      def test_initialize_converts_string_date_to_date_object
        event = Event.new(date: '2025-01-15', summary: 'Meeting')

        assert_kind_of Date, event.date
        assert_equal Date.new(2025, 1, 15), event.date
      end

      def test_initialize_preserves_date_object
        date = Date.new(2025, 1, 15)
        event = Event.new(date: date, summary: 'Meeting')

        assert_same date, event.date
      end

      def test_initialize_defaults_calendar_name_to_nil
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert_nil event.calendar_name
      end

      def test_initialize_defaults_color_to_nil
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert_nil event.color
      end

      def test_initialize_defaults_icon_to_nil
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert_nil event.icon
      end

      def test_initialize_defaults_all_day_to_true
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert_equal true, event.all_day
      end

      # ============================================
      # Attribute Reader Tests
      # ============================================

      def test_date_accessor
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert_equal Date.new(2025, 1, 15), event.date
      end

      def test_summary_accessor
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Team Standup')

        assert_equal 'Team Standup', event.summary
      end

      def test_calendar_name_accessor
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', calendar_name: 'Personal')

        assert_equal 'Personal', event.calendar_name
      end

      def test_color_accessor
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', color: '00FF00')

        assert_equal '00FF00', event.color
      end

      def test_icon_accessor
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', icon: '+')

        assert_equal '+', event.icon
      end

      def test_all_day_accessor
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', all_day: false)

        assert_equal false, event.all_day
      end

      # ============================================
      # week_number Tests
      # ============================================

      def test_week_number_returns_correct_week
        # Week 1 starts Monday Dec 30, 2024 for year 2025
        year_start_monday = Date.new(2024, 12, 30)
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        # Jan 15, 2025 is 16 days from Dec 30 -> week 3
        assert_equal 3, event.week_number(year_start_monday)
      end

      def test_week_number_for_first_week
        year_start_monday = Date.new(2024, 12, 30)
        event = Event.new(date: Date.new(2024, 12, 31), summary: 'New Years Eve')

        # Day 2 of week 1
        assert_equal 1, event.week_number(year_start_monday)
      end

      def test_week_number_for_week_boundary
        year_start_monday = Date.new(2024, 12, 30)
        # Sunday Jan 5 is last day of week 1
        event = Event.new(date: Date.new(2025, 1, 5), summary: 'Sunday')

        assert_equal 1, event.week_number(year_start_monday)

        # Monday Jan 6 is first day of week 2
        event2 = Event.new(date: Date.new(2025, 1, 6), summary: 'Monday')
        assert_equal 2, event2.week_number(year_start_monday)
      end

      # ============================================
      # day_of_week Tests
      # ============================================

      def test_day_of_week_returns_correct_day_name
        # Jan 15, 2025 is a Wednesday
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert_equal 'Wednesday', event.day_of_week
      end

      def test_day_of_week_for_monday
        # Jan 13, 2025 is a Monday
        event = Event.new(date: Date.new(2025, 1, 13), summary: 'Meeting')

        assert_equal 'Monday', event.day_of_week
      end

      def test_day_of_week_for_sunday
        # Jan 19, 2025 is a Sunday
        event = Event.new(date: Date.new(2025, 1, 19), summary: 'Meeting')

        assert_equal 'Sunday', event.day_of_week
      end

      # ============================================
      # display_label Tests
      # ============================================

      def test_display_label_without_icon
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert_equal 'Meeting', event.display_label
      end

      def test_display_label_with_icon
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', icon: '*')

        assert_equal '* Meeting', event.display_label
      end

      def test_display_label_excludes_icon_when_requested
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', icon: '*')

        assert_equal 'Meeting', event.display_label(include_icon: false)
      end

      def test_display_label_with_nil_icon_and_include_icon_true
        event = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', icon: nil)

        assert_equal 'Meeting', event.display_label(include_icon: true)
      end

      # ============================================
      # Comparison Tests (<=>)
      # ============================================

      def test_comparison_earlier_date_is_less
        event1 = Event.new(date: Date.new(2025, 1, 10), summary: 'Earlier')
        event2 = Event.new(date: Date.new(2025, 1, 15), summary: 'Later')

        assert_equal(-1, event1 <=> event2)
      end

      def test_comparison_later_date_is_greater
        event1 = Event.new(date: Date.new(2025, 1, 15), summary: 'Later')
        event2 = Event.new(date: Date.new(2025, 1, 10), summary: 'Earlier')

        assert_equal 1, event1 <=> event2
      end

      def test_comparison_same_date_is_equal
        event1 = Event.new(date: Date.new(2025, 1, 15), summary: 'Event 1')
        event2 = Event.new(date: Date.new(2025, 1, 15), summary: 'Event 2')

        assert_equal 0, event1 <=> event2
      end

      def test_events_are_sortable
        events = [
          Event.new(date: Date.new(2025, 1, 15), summary: 'Middle'),
          Event.new(date: Date.new(2025, 1, 10), summary: 'First'),
          Event.new(date: Date.new(2025, 1, 20), summary: 'Last')
        ]

        sorted = events.sort

        assert_equal 'First', sorted[0].summary
        assert_equal 'Middle', sorted[1].summary
        assert_equal 'Last', sorted[2].summary
      end

      # ============================================
      # matches? Tests
      # ============================================

      def test_matches_returns_true_for_same_date_and_summary
        event1 = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')
        event2 = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')

        assert event1.matches?(event2)
      end

      def test_matches_returns_false_for_different_date
        event1 = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')
        event2 = Event.new(date: Date.new(2025, 1, 16), summary: 'Meeting')

        refute event1.matches?(event2)
      end

      def test_matches_returns_false_for_different_summary
        event1 = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting')
        event2 = Event.new(date: Date.new(2025, 1, 15), summary: 'Call')

        refute event1.matches?(event2)
      end

      def test_matches_ignores_other_attributes
        event1 = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', color: 'FF0000')
        event2 = Event.new(date: Date.new(2025, 1, 15), summary: 'Meeting', color: '00FF00')

        # Different colors but same date/summary -> matches
        assert event1.matches?(event2)
      end
    end
  end
end
