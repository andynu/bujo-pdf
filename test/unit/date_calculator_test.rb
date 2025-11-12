#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'

# Unit tests for DateCalculator - week numbering, date calculations, and edge cases
class TestDateCalculator < Minitest::Test
  include BujoPdf::Utilities

  # Test year_start_monday for various years with different January 1 weekdays
  def test_year_start_monday_when_jan_1_is_monday
    # 2024: January 1 is Monday
    start = DateCalculator.year_start_monday(2024)
    assert_equal Date.new(2024, 1, 1), start
    assert_equal 1, start.wday # Monday
  end

  def test_year_start_monday_when_jan_1_is_tuesday
    # 2019: January 1 is Tuesday
    start = DateCalculator.year_start_monday(2019)
    assert_equal Date.new(2018, 12, 31), start # Previous day is Monday
    assert_equal 1, start.wday # Monday
  end

  def test_year_start_monday_when_jan_1_is_wednesday
    # 2025: January 1 is Wednesday
    start = DateCalculator.year_start_monday(2025)
    assert_equal Date.new(2024, 12, 30), start # 2 days back is Monday
    assert_equal 1, start.wday # Monday
  end

  def test_year_start_monday_when_jan_1_is_thursday
    # 2026: January 1 is Thursday
    start = DateCalculator.year_start_monday(2026)
    assert_equal Date.new(2025, 12, 29), start # 3 days back is Monday
    assert_equal 1, start.wday # Monday
  end

  def test_year_start_monday_when_jan_1_is_friday
    # 2021: January 1 is Friday
    start = DateCalculator.year_start_monday(2021)
    assert_equal Date.new(2020, 12, 28), start # 4 days back is Monday
    assert_equal 1, start.wday # Monday
  end

  def test_year_start_monday_when_jan_1_is_saturday
    # 2022: January 1 is Saturday
    start = DateCalculator.year_start_monday(2022)
    assert_equal Date.new(2021, 12, 27), start # 5 days back is Monday
    assert_equal 1, start.wday # Monday
  end

  def test_year_start_monday_when_jan_1_is_sunday
    # 2023: January 1 is Sunday
    start = DateCalculator.year_start_monday(2023)
    assert_equal Date.new(2022, 12, 26), start # 6 days back is Monday
    assert_equal 1, start.wday # Monday
  end

  # Test total_weeks for various years
  def test_total_weeks_for_typical_year
    # 2024: 53 weeks (Jan 1 is Monday)
    assert_equal 53, DateCalculator.total_weeks(2024)
  end

  def test_total_weeks_for_year_starting_wednesday
    # 2025: 53 weeks (Jan 1 is Wednesday)
    assert_equal 53, DateCalculator.total_weeks(2025)
  end

  def test_total_weeks_for_year_starting_thursday
    # 2026: 53 weeks (Jan 1 is Thursday)
    assert_equal 53, DateCalculator.total_weeks(2026)
  end

  def test_total_weeks_for_various_years
    # Test multiple years to ensure consistency
    # Note: Week count depends on when Jan 1 falls and the week-numbering system
    # With this system (Monday on or before Jan 1), most years have 53 weeks
    years_and_weeks = {
      2020 => 53, # Leap year, Wednesday start
      2021 => 53, # Friday start
      2022 => 53, # Saturday start
      2023 => 53, # Sunday start
      2024 => 53, # Leap year, Monday start
      2025 => 53, # Wednesday start
      2026 => 53  # Thursday start
    }

    years_and_weeks.each do |year, expected_weeks|
      actual = DateCalculator.total_weeks(year)
      assert_equal expected_weeks, actual,
                   "Year #{year} should have #{expected_weeks} weeks, got #{actual}"
    end
  end

  # Test week_start for various weeks
  def test_week_start_for_week_1
    # 2024: Week 1 starts January 1 (Monday)
    assert_equal Date.new(2024, 1, 1), DateCalculator.week_start(2024, 1)

    # 2025: Week 1 starts December 30, 2024 (Monday)
    assert_equal Date.new(2024, 12, 30), DateCalculator.week_start(2025, 1)
  end

  def test_week_start_for_mid_year_week
    # 2025: Week 26 (mid-year)
    start = DateCalculator.week_start(2025, 26)
    assert_equal 1, start.wday # Must be Monday
    assert_equal 6, start.month # June
  end

  def test_week_start_for_last_week
    # 2024: Week 53 (last week)
    start = DateCalculator.week_start(2024, 53)
    assert_equal 1, start.wday # Must be Monday
    assert_equal 12, start.month # December
    assert_equal 2024, start.year
  end

  def test_week_start_returns_monday
    # Verify all week starts are Mondays
    [2024, 2025, 2026].each do |year|
      total = DateCalculator.total_weeks(year)
      (1..total).each do |week_num|
        start = DateCalculator.week_start(year, week_num)
        assert_equal 1, start.wday,
                     "Week #{week_num} of #{year} should start on Monday, got #{start} (#{Date::DAYNAMES[start.wday]})"
      end
    end
  end

  # Test week_end for various weeks
  def test_week_end_for_week_1
    # 2024: Week 1 ends January 7 (Sunday)
    assert_equal Date.new(2024, 1, 7), DateCalculator.week_end(2024, 1)

    # 2025: Week 1 ends January 5, 2025 (Sunday)
    assert_equal Date.new(2025, 1, 5), DateCalculator.week_end(2025, 1)
  end

  def test_week_end_returns_sunday
    # Verify all week ends are Sundays
    [2024, 2025, 2026].each do |year|
      total = DateCalculator.total_weeks(year)
      (1..total).each do |week_num|
        week_end = DateCalculator.week_end(year, week_num)
        assert_equal 0, week_end.wday,
                     "Week #{week_num} of #{year} should end on Sunday, got #{week_end} (#{Date::DAYNAMES[week_end.wday]})"
      end
    end
  end

  def test_week_spans_exactly_7_days
    # Verify each week is exactly 7 days
    [2024, 2025, 2026].each do |year|
      total = DateCalculator.total_weeks(year)
      (1..total).each do |week_num|
        start = DateCalculator.week_start(year, week_num)
        week_end = DateCalculator.week_end(year, week_num)
        days = (week_end - start).to_i + 1 # +1 because inclusive

        assert_equal 7, days,
                     "Week #{week_num} of #{year} should span 7 days, got #{days}"
      end
    end
  end

  # Test week_number_for_date
  def test_week_number_for_date_on_january_1
    # 2024: January 1 is Week 1 (Monday)
    assert_equal 1, DateCalculator.week_number_for_date(2024, Date.new(2024, 1, 1))

    # 2025: January 1 is Week 1 (Wednesday)
    assert_equal 1, DateCalculator.week_number_for_date(2025, Date.new(2025, 1, 1))
  end

  def test_week_number_for_date_on_december_31
    # 2024: December 31 is Week 53 (Tuesday)
    assert_equal 53, DateCalculator.week_number_for_date(2024, Date.new(2024, 12, 31))

    # 2025: December 31 is Week 53 (Wednesday)
    assert_equal 53, DateCalculator.week_number_for_date(2025, Date.new(2025, 12, 31))
  end

  def test_week_number_for_date_on_leap_day
    # 2024: February 29 (leap day)
    leap_day = Date.new(2024, 2, 29)
    week_num = DateCalculator.week_number_for_date(2024, leap_day)

    # Verify it's a valid week number
    assert week_num >= 1, "Week number must be >= 1"
    assert week_num <= 53, "Week number must be <= 53"

    # Verify it falls within the calculated week boundaries
    week_start = DateCalculator.week_start(2024, week_num)
    week_end = DateCalculator.week_end(2024, week_num)
    assert leap_day >= week_start && leap_day <= week_end,
           "Leap day should be within week #{week_num} boundaries"
  end

  def test_week_number_for_date_covers_all_days
    # Verify every day of the year gets assigned a week number
    [2024, 2025].each do |year|
      date = Date.new(year, 1, 1)
      end_date = Date.new(year, 12, 31)

      while date <= end_date
        week_num = DateCalculator.week_number_for_date(year, date)

        assert week_num >= 1, "Date #{date} should have week_num >= 1, got #{week_num}"
        assert week_num <= DateCalculator.total_weeks(year),
               "Date #{date} should have week_num <= total_weeks, got #{week_num}"

        date += 1
      end
    end
  end

  # Test season_for_month
  def test_season_for_winter_months
    assert_equal 'Winter', DateCalculator.season_for_month(12)
    assert_equal 'Winter', DateCalculator.season_for_month(1)
    assert_equal 'Winter', DateCalculator.season_for_month(2)
  end

  def test_season_for_spring_months
    assert_equal 'Spring', DateCalculator.season_for_month(3)
    assert_equal 'Spring', DateCalculator.season_for_month(4)
    assert_equal 'Spring', DateCalculator.season_for_month(5)
  end

  def test_season_for_summer_months
    assert_equal 'Summer', DateCalculator.season_for_month(6)
    assert_equal 'Summer', DateCalculator.season_for_month(7)
    assert_equal 'Summer', DateCalculator.season_for_month(8)
  end

  def test_season_for_fall_months
    assert_equal 'Fall', DateCalculator.season_for_month(9)
    assert_equal 'Fall', DateCalculator.season_for_month(10)
    assert_equal 'Fall', DateCalculator.season_for_month(11)
  end

  # Test season_start_date
  def test_season_start_date_for_winter
    # Winter starts December 1
    assert_equal Date.new(2024, 12, 1), DateCalculator.season_start_date(2024, 12)

    # January and February are in winter that started previous December
    assert_equal Date.new(2023, 12, 1), DateCalculator.season_start_date(2024, 1)
    assert_equal Date.new(2023, 12, 1), DateCalculator.season_start_date(2024, 2)
  end

  def test_season_start_date_for_spring
    # Spring starts March 1
    assert_equal Date.new(2024, 3, 1), DateCalculator.season_start_date(2024, 3)
    assert_equal Date.new(2024, 3, 1), DateCalculator.season_start_date(2024, 4)
    assert_equal Date.new(2024, 3, 1), DateCalculator.season_start_date(2024, 5)
  end

  def test_season_start_date_for_summer
    # Summer starts June 1
    assert_equal Date.new(2024, 6, 1), DateCalculator.season_start_date(2024, 6)
    assert_equal Date.new(2024, 6, 1), DateCalculator.season_start_date(2024, 7)
    assert_equal Date.new(2024, 6, 1), DateCalculator.season_start_date(2024, 8)
  end

  def test_season_start_date_for_fall
    # Fall starts September 1
    assert_equal Date.new(2024, 9, 1), DateCalculator.season_start_date(2024, 9)
    assert_equal Date.new(2024, 9, 1), DateCalculator.season_start_date(2024, 10)
    assert_equal Date.new(2024, 9, 1), DateCalculator.season_start_date(2024, 11)
  end

  # Test first_week_of_month
  def test_first_week_of_month_for_january
    # January 1 is always in week 1
    assert_equal 1, DateCalculator.first_week_of_month(2024, 1)
    assert_equal 1, DateCalculator.first_week_of_month(2025, 1)
  end

  def test_first_week_of_month_for_all_months
    # Verify all months get assigned a first week
    [2024, 2025].each do |year|
      (1..12).each do |month|
        week_num = DateCalculator.first_week_of_month(year, month)

        assert week_num >= 1, "Month #{month} of #{year} should have first_week >= 1"
        assert week_num <= DateCalculator.total_weeks(year),
               "Month #{month} of #{year} should have first_week <= total_weeks"
      end
    end
  end

  def test_first_week_of_month_increments_properly
    # Verify months have sequential or close week numbers
    [2024, 2025].each do |year|
      prev_week = 0
      (1..12).each do |month|
        week_num = DateCalculator.first_week_of_month(year, month)

        # Each month should start at or after previous month's first week
        assert week_num >= prev_week,
               "Month #{month} first week (#{week_num}) should be >= previous month (#{prev_week})"

        prev_week = week_num
      end
    end
  end

  # Test month_abbrev_for_week
  def test_month_abbrev_for_week_returns_abbrev_for_first_week
    # Week 1 should return "Jan" for January
    assert_equal 'Jan', DateCalculator.month_abbrev_for_week(2024, 1)
    assert_equal 'Jan', DateCalculator.month_abbrev_for_week(2025, 1)
  end

  def test_month_abbrev_for_week_returns_nil_for_non_first_weeks
    # Weeks that aren't the first week of any month should return nil
    # Week 2 is not the first week of any month
    assert_nil DateCalculator.month_abbrev_for_week(2024, 2)
  end

  def test_month_abbrev_for_week_custom_char_length
    # Test with custom character length (2 chars)
    result = DateCalculator.month_abbrev_for_week(2024, 1, char: 2)
    assert_equal 'Ja', result
  end

  def test_month_abbrev_for_week_covers_all_months
    # Verify all 12 months have a first week
    [2024, 2025].each do |year|
      month_abbrevs_found = []

      total = DateCalculator.total_weeks(year)
      (1..total).each do |week_num|
        abbrev = DateCalculator.month_abbrev_for_week(year, week_num)
        month_abbrevs_found << abbrev if abbrev
      end

      # Should find exactly 12 month abbreviations
      assert_equal 12, month_abbrevs_found.length,
                   "Year #{year} should have 12 months with first weeks, found #{month_abbrevs_found.length}"
    end
  end

  # Test week_to_month_abbrev_map
  def test_week_to_month_abbrev_map_returns_hash
    map = DateCalculator.week_to_month_abbrev_map(2024)

    assert_instance_of Hash, map
    assert_equal 12, map.size, "Map should contain 12 entries (one per month)"
  end

  def test_week_to_month_abbrev_map_contains_all_months
    map = DateCalculator.week_to_month_abbrev_map(2024)

    expected_abbrevs = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    actual_abbrevs = map.values

    # Should have all 12 month abbreviations (check as a set)
    assert_equal expected_abbrevs.sort, actual_abbrevs.sort,
                 "Map should contain all 12 month abbreviations"
  end

  def test_week_to_month_abbrev_map_matches_individual_calls
    year = 2024
    map = DateCalculator.week_to_month_abbrev_map(year)

    # Verify map matches individual month_abbrev_for_week calls
    map.each do |week_num, abbrev|
      individual_result = DateCalculator.month_abbrev_for_week(year, week_num)
      assert_equal abbrev, individual_result,
                   "Map entry for week #{week_num} should match individual call"
    end
  end

  def test_week_to_month_abbrev_map_custom_char_length
    map = DateCalculator.week_to_month_abbrev_map(2024, char: 2)

    # Verify all abbreviations are 2 characters
    map.values.each do |abbrev|
      assert_equal 2, abbrev.length, "Abbreviation should be 2 chars: #{abbrev}"
    end
  end

  # Edge case tests
  def test_handles_leap_year_correctly
    # 2024 is a leap year (366 days)
    assert Date.new(2024, 2, 29), "2024 should have February 29"

    # Verify leap day gets assigned to a week
    leap_day_week = DateCalculator.week_number_for_date(2024, Date.new(2024, 2, 29))
    assert leap_day_week >= 1 && leap_day_week <= 53,
           "Leap day should be in a valid week"
  end

  def test_handles_non_leap_year_correctly
    # 2025 is not a leap year (365 days)
    assert_raises(ArgumentError) do
      Date.new(2025, 2, 29) # Should raise error
    end
  end

  def test_weeks_have_no_gaps
    # Verify there are no date gaps between consecutive weeks
    [2024, 2025].each do |year|
      total = DateCalculator.total_weeks(year)
      (1..total - 1).each do |week_num|
        week1_end = DateCalculator.week_end(year, week_num)
        week2_start = DateCalculator.week_start(year, week_num + 1)

        # Next week should start exactly 1 day after previous week ends
        assert_equal week1_end + 1, week2_start,
                     "Week #{week_num + 1} should start immediately after week #{week_num}"
      end
    end
  end

  def test_year_coverage_complete
    # Verify week system covers all days from Jan 1 to Dec 31
    [2024, 2025].each do |year|
      # First week should start on or before January 1
      first_week_start = DateCalculator.week_start(year, 1)
      assert first_week_start <= Date.new(year, 1, 1),
             "First week should start on or before Jan 1"

      # Last week should end on or after December 31
      last_week_num = DateCalculator.total_weeks(year)
      last_week_end = DateCalculator.week_end(year, last_week_num)
      assert last_week_end >= Date.new(year, 12, 31),
             "Last week should end on or after Dec 31"
    end
  end
end
