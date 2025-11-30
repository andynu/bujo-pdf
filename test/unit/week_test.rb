# frozen_string_literal: true

require_relative '../test_helper'

class TestWeek < Minitest::Test
  def test_week_1_may_start_in_previous_year
    week = BujoPdf::Week.new(year: 2025, number: 1)

    # Week 1 of 2025 starts on 2024-12-30 (Monday before Jan 1)
    assert_equal Date.new(2024, 12, 30), week.start_date
    assert_equal Date.new(2025, 1, 5), week.end_date
  end

  def test_month_returns_start_date_month
    week = BujoPdf::Week.new(year: 2025, number: 1)

    # Start date is in December
    assert_equal 12, week.month
  end

  def test_primary_month_nil_when_week_starts_in_previous_year
    week = BujoPdf::Week.new(year: 2025, number: 1)

    # Week starts in 2024, so primary_month is nil
    assert_nil week.primary_month
  end

  def test_primary_month_returns_month_when_in_year
    week = BujoPdf::Week.new(year: 2025, number: 2)

    # Week 2 starts in January 2025
    assert_equal 1, week.primary_month
  end

  def test_in_year_false_when_start_in_previous_year
    week = BujoPdf::Week.new(year: 2025, number: 1)

    refute week.in_year?
  end

  def test_in_year_true_when_start_in_target_year
    week = BujoPdf::Week.new(year: 2025, number: 2)

    assert week.in_year?
  end

  def test_overlaps_year_true_when_any_day_in_year
    week = BujoPdf::Week.new(year: 2025, number: 1)

    # Week 1 ends in 2025, so it overlaps
    assert week.overlaps_year?
  end

  def test_quarter_calculation
    # Q1: Jan-Mar
    assert_equal 1, BujoPdf::Week.new(year: 2025, number: 2).quarter  # January
    assert_equal 1, BujoPdf::Week.new(year: 2025, number: 10).quarter # March

    # Q2: Apr-Jun
    assert_equal 2, BujoPdf::Week.new(year: 2025, number: 14).quarter # April

    # Q3: Jul-Sep
    assert_equal 3, BujoPdf::Week.new(year: 2025, number: 27).quarter # July

    # Q4: Oct-Dec
    assert_equal 4, BujoPdf::Week.new(year: 2025, number: 40).quarter # October
  end

  def test_month_name
    week = BujoPdf::Week.new(year: 2025, number: 2)

    assert_equal "January", week.month_name
  end

  def test_to_context
    week = BujoPdf::Week.new(year: 2025, number: 5)
    ctx = week.to_context

    assert_equal 5, ctx[:week_num]
    assert_kind_of Date, ctx[:week_start]
    assert_kind_of Date, ctx[:week_end]
  end

  def test_all_in_returns_all_weeks
    weeks = BujoPdf::Week.all_in(2025)

    assert_equal 53, weeks.size
    assert_equal 1, weeks.first.number
    assert_equal 53, weeks.last.number
  end

  def test_equality
    week1 = BujoPdf::Week.new(year: 2025, number: 5)
    week2 = BujoPdf::Week.new(year: 2025, number: 5)
    week3 = BujoPdf::Week.new(year: 2025, number: 6)

    assert_equal week1, week2
    refute_equal week1, week3
  end

  def test_to_s
    week = BujoPdf::Week.new(year: 2025, number: 1)

    assert_match(/Week 1/, week.to_s)
    assert_match(/2024-12-30/, week.to_s)
  end
end
