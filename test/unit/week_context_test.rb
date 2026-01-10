# frozen_string_literal: true

require_relative '../test_helper'

class TestWeekContext < Minitest::Test
  def test_basic_construction
    ctx = BujoPdf::WeekContext.new(year: 2025, number: 42)

    assert_equal 2025, ctx.year
    assert_equal 42, ctx.number
    assert_equal 53, ctx.total_weeks  # 2025 has 53 weeks
    assert_kind_of Date, ctx.start_date
    assert_kind_of Date, ctx.end_date
  end

  def test_explicit_total_weeks
    ctx = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 52)

    assert_equal 52, ctx.total_weeks
  end

  def test_explicit_dates
    start_date = Date.new(2025, 10, 13)
    end_date = Date.new(2025, 10, 19)

    ctx = BujoPdf::WeekContext.new(
      year: 2025,
      number: 42,
      start_date: start_date,
      end_date: end_date
    )

    assert_equal start_date, ctx.start_date
    assert_equal end_date, ctx.end_date
  end

  def test_from_week
    week = BujoPdf::Week.new(year: 2025, number: 10)
    ctx = BujoPdf::WeekContext.from_week(week)

    assert_equal 2025, ctx.year
    assert_equal 10, ctx.number
    assert_equal 53, ctx.total_weeks
    assert_equal week.start_date, ctx.start_date
    assert_equal week.end_date, ctx.end_date
  end

  def test_from_week_with_explicit_total_weeks
    week = BujoPdf::Week.new(year: 2025, number: 10)
    ctx = BujoPdf::WeekContext.from_week(week, total_weeks: 52)

    assert_equal 52, ctx.total_weeks
  end

  def test_aliases_match_context_hash_keys
    ctx = BujoPdf::WeekContext.new(year: 2025, number: 42)

    # Aliases for backward compatibility with hash-based code
    assert_equal ctx.number, ctx.week_num
    assert_equal ctx.start_date, ctx.week_start
    assert_equal ctx.end_date, ctx.week_end
  end

  def test_first_week
    first = BujoPdf::WeekContext.new(year: 2025, number: 1)
    middle = BujoPdf::WeekContext.new(year: 2025, number: 26)

    assert first.first?
    refute middle.first?
  end

  def test_last_week
    # 2025 has 53 weeks
    last = BujoPdf::WeekContext.new(year: 2025, number: 53)
    middle = BujoPdf::WeekContext.new(year: 2025, number: 26)

    assert last.last?
    refute middle.last?
  end

  def test_prev_week_num
    first = BujoPdf::WeekContext.new(year: 2025, number: 1)
    middle = BujoPdf::WeekContext.new(year: 2025, number: 26)

    assert_nil first.prev_week_num
    assert_equal 25, middle.prev_week_num
  end

  def test_next_week_num
    # 2025 has 53 weeks
    last = BujoPdf::WeekContext.new(year: 2025, number: 53)
    middle = BujoPdf::WeekContext.new(year: 2025, number: 26)

    assert_nil last.next_week_num
    assert_equal 27, middle.next_week_num
  end

  def test_to_h
    ctx = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 52)
    hash = ctx.to_h

    assert_equal 2025, hash[:year]
    assert_equal 42, hash[:week_num]
    assert_equal 52, hash[:total_weeks]
    assert_kind_of Date, hash[:week_start]
    assert_kind_of Date, hash[:week_end]
  end

  def test_equality
    ctx1 = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 52)
    ctx2 = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 52)
    ctx3 = BujoPdf::WeekContext.new(year: 2025, number: 43, total_weeks: 52)
    ctx4 = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 53)

    assert_equal ctx1, ctx2
    refute_equal ctx1, ctx3  # Different week number
    refute_equal ctx1, ctx4  # Different total_weeks
  end

  def test_hash_for_collections
    ctx1 = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 52)
    ctx2 = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 52)

    set = Set.new([ctx1])
    assert set.include?(ctx2)
  end

  def test_frozen
    ctx = BujoPdf::WeekContext.new(year: 2025, number: 42)

    assert ctx.frozen?
  end

  def test_to_s
    ctx = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 53)

    assert_match(/Week 42\/53/, ctx.to_s)
  end

  def test_inspect
    ctx = BujoPdf::WeekContext.new(year: 2025, number: 42, total_weeks: 53)

    assert_match(/WeekContext/, ctx.inspect)
    assert_match(/year=2025/, ctx.inspect)
    assert_match(/number=42\/53/, ctx.inspect)
  end
end
