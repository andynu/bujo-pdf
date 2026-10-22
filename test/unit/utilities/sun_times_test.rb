#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestSunTimes < Minitest::Test
  SunTimes = BujoPdf::Utilities::SunTimes

  # US Naval Observatory one-day tables for 42.36N 71.06W, local clock time.
  USNO_BOSTON_2026 = {
    Date.new(2026, 12, 21) => %w[06:38 07:10 16:15 16:47],
    Date.new(2026, 6, 21) => %w[04:33 05:08 20:25 20:59],
    Date.new(2026, 3, 7) => %w[05:42 06:10 17:41 18:09],   # last day of EST
    Date.new(2026, 3, 8) => %w[06:40 07:08 18:43 19:11],   # first day of EDT
    Date.new(2026, 11, 1) => %w[05:48 06:18 16:37 17:07]   # first day back on EST
  }.freeze

  def minutes(hhmm)
    h, m = hhmm.split(':').map(&:to_i)
    (h * 60) + m
  end

  def test_matches_usno_boston_within_a_minute
    USNO_BOSTON_2026.each do |date, expected|
      times = SunTimes.for(date)
      actual = [times.dawn, times.sunrise, times.sunset, times.dusk]

      expected.zip(actual, %i[dawn sunrise sunset dusk]).each do |want, got, name|
        assert_in_delta minutes(want), got, 1, "#{name} on #{date}"
      end
    end
  end

  def test_eastern_offset_follows_us_dst_rule
    assert_equal(-5, SunTimes.eastern_utc_offset(Date.new(2026, 3, 7)))
    assert_equal(-4, SunTimes.eastern_utc_offset(Date.new(2026, 3, 8)))
    assert_equal(-4, SunTimes.eastern_utc_offset(Date.new(2026, 10, 31)))
    assert_equal(-5, SunTimes.eastern_utc_offset(Date.new(2026, 11, 1)))
    assert_equal(-4, SunTimes.eastern_utc_offset(Date.new(2025, 3, 9)))
    assert_equal(-5, SunTimes.eastern_utc_offset(Date.new(2025, 11, 2)))
  end

  def test_phase_at_classifies_minutes_of_the_day
    times = SunTimes.for(Date.new(2026, 12, 21))

    assert_equal :night, times.phase_at(minutes('06:00'))
    assert_equal :twilight, times.phase_at(minutes('06:50'))
    assert_equal :day, times.phase_at(minutes('12:00'))
    assert_equal :twilight, times.phase_at(minutes('16:30'))
    assert_equal :night, times.phase_at(minutes('18:00'))
  end

  def test_shaded_spans_within_an_hour
    times = SunTimes.for(Date.new(2026, 12, 21))

    assert_empty times.shaded_spans(minutes('12:00'), minutes('13:00'))

    spans = times.shaded_spans(minutes('16:00'), minutes('17:00'))
    assert_equal %i[twilight night], spans.map(&:first)
    assert_in_delta minutes('16:15'), spans[0][1], 2
    assert_in_delta minutes('16:47'), spans[0][2], 2
    assert_equal minutes('17:00'), spans[1][2]
  end
end
