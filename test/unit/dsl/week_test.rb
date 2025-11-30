#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestWeek < Minitest::Test
  def test_basic_creation
    week = BujoPdf::PdfDSL::Week.new(2025, 1)

    assert_equal 2025, week.year
    assert_equal 1, week.number
  end

  def test_start_date
    week = BujoPdf::PdfDSL::Week.new(2025, 1)
    start = week.start_date

    assert_equal 1, start.wday  # Monday
    # 2025 Week 1 starts 2024-12-30
    assert_equal Date.new(2024, 12, 30), start
  end

  def test_end_date
    week = BujoPdf::PdfDSL::Week.new(2025, 1)
    end_date = week.end_date

    assert_equal 0, end_date.wday  # Sunday
    assert_equal Date.new(2025, 1, 5), end_date
  end

  def test_days
    week = BujoPdf::PdfDSL::Week.new(2025, 1)
    days = week.days

    assert_equal 7, days.length
    assert_equal Date.new(2024, 12, 30), days.first
    assert_equal Date.new(2025, 1, 5), days.last
  end

  def test_date_range
    week = BujoPdf::PdfDSL::Week.new(2025, 1)
    range = week.date_range

    assert_includes range, 'Dec'
    assert_includes range, 'Jan'
    assert_includes range, '-'
  end

  def test_include_date
    week = BujoPdf::PdfDSL::Week.new(2025, 1)

    assert week.include?(Date.new(2025, 1, 1))
    assert week.include?(Date.new(2024, 12, 30))
    refute week.include?(Date.new(2024, 12, 29))
    refute week.include?(Date.new(2025, 1, 6))
  end

  def test_prev_week
    week = BujoPdf::PdfDSL::Week.new(2025, 10)
    prev = week.prev

    assert_equal 2025, prev.year
    assert_equal 9, prev.number
  end

  def test_prev_week_year_boundary
    week = BujoPdf::PdfDSL::Week.new(2025, 1)
    prev = week.prev

    assert_equal 2024, prev.year
    # Last week of 2024
    assert prev.number >= 52
  end

  def test_next_week
    week = BujoPdf::PdfDSL::Week.new(2025, 10)
    next_week = week.next

    assert_equal 2025, next_week.year
    assert_equal 11, next_week.number
  end

  def test_next_week_year_boundary
    total = BujoPdf::Utilities::DateCalculator.total_weeks(2025)
    week = BujoPdf::PdfDSL::Week.new(2025, total)
    next_week = week.next

    assert_equal 2026, next_week.year
    assert_equal 1, next_week.number
  end

  def test_arithmetic
    week = BujoPdf::PdfDSL::Week.new(2025, 10)

    plus_two = week + 2
    assert_equal 12, plus_two.number

    minus_three = week - 3
    assert_equal 7, minus_three.number
  end

  def test_weeks_in_year
    weeks = BujoPdf::PdfDSL::Week.weeks_in(2025)
    total = BujoPdf::Utilities::DateCalculator.total_weeks(2025)

    assert_equal total, weeks.length
    assert_equal 1, weeks.first.number
    assert_equal total, weeks.last.number
  end

  def test_comparison
    week1 = BujoPdf::PdfDSL::Week.new(2025, 10)
    week2 = BujoPdf::PdfDSL::Week.new(2025, 20)
    week3 = BujoPdf::PdfDSL::Week.new(2025, 10)

    assert week1 < week2
    assert week2 > week1
    assert_equal week1, week3
  end

  def test_equality_and_hash
    week1 = BujoPdf::PdfDSL::Week.new(2025, 10)
    week2 = BujoPdf::PdfDSL::Week.new(2025, 10)
    week3 = BujoPdf::PdfDSL::Week.new(2025, 11)

    assert week1.eql?(week2)
    refute week1.eql?(week3)
    assert_equal week1.hash, week2.hash
  end

  def test_to_s
    week = BujoPdf::PdfDSL::Week.new(2025, 42)
    assert_equal 'Week 42 of 2025', week.to_s
  end
end

class TestMonth < Minitest::Test
  def test_basic_creation
    month = BujoPdf::PdfDSL::Month.new(2025, 6)

    assert_equal 2025, month.year
    assert_equal 6, month.number
  end

  def test_name
    month = BujoPdf::PdfDSL::Month.new(2025, 1)
    assert_equal 'January', month.name
  end

  def test_abbrev
    month = BujoPdf::PdfDSL::Month.new(2025, 1)
    assert_equal 'Jan', month.abbrev
  end

  def test_start_and_end_date
    month = BujoPdf::PdfDSL::Month.new(2025, 2)

    assert_equal Date.new(2025, 2, 1), month.start_date
    assert_equal Date.new(2025, 2, 28), month.end_date
  end

  def test_days
    month = BujoPdf::PdfDSL::Month.new(2025, 2)
    days = month.days

    assert_equal 28, days.length
    assert_equal Date.new(2025, 2, 1), days.first
    assert_equal Date.new(2025, 2, 28), days.last
  end

  def test_weeks
    month = BujoPdf::PdfDSL::Month.new(2025, 6)
    weeks = month.weeks

    # June 2025 spans multiple weeks
    assert weeks.length >= 4
    weeks.each { |w| assert_instance_of BujoPdf::PdfDSL::Week, w }
  end

  def test_season
    assert_equal 'Winter', BujoPdf::PdfDSL::Month.new(2025, 1).season
    assert_equal 'Spring', BujoPdf::PdfDSL::Month.new(2025, 4).season
    assert_equal 'Summer', BujoPdf::PdfDSL::Month.new(2025, 7).season
    assert_equal 'Fall', BujoPdf::PdfDSL::Month.new(2025, 10).season
  end

  def test_months_in_year
    months = BujoPdf::PdfDSL::Month.months_in(2025)

    assert_equal 12, months.length
    assert_equal 1, months.first.number
    assert_equal 12, months.last.number
  end

  def test_to_s
    month = BujoPdf::PdfDSL::Month.new(2025, 6)
    assert_equal 'June 2025', month.to_s
  end
end
