#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestMonthNav < Minitest::Test
  YEAR = 2026

  def setup
    BujoPdf::Components::MonthNav.reset_cache!
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def teardown
    BujoPdf::Components::MonthNav.reset_cache!
  end

  def nav(**opts)
    BujoPdf::Components::MonthNav.new(
      canvas: @canvas, year: YEAR, col: 2, row: 0, **opts
    )
  end

  # Grouping

  def test_every_week_of_the_year_belongs_to_exactly_one_month
    by_month = BujoPdf::Components::MonthNav.weeks_by_month(YEAR)
    all = by_month.values.flatten

    assert_equal all.uniq.length, all.length, "a week appears under two months"
    total = BujoPdf::Utilities::DateCalculator.total_weeks(YEAR)
    assert_equal (1..total).to_a, all.sort
  end

  def test_cross_year_first_week_is_filed_under_january
    assert_includes BujoPdf::Components::MonthNav.weeks_by_month(YEAR)[1], 1
  end

  def test_grouping_matches_the_recipe_sequencing_rule
    # MonthNav and the planner recipe must agree, or navigation would point
    # at weeks that sit under a different month heading in the page order.
    BujoPdf::Components::MonthNav.weeks_by_month(YEAR).each do |month, weeks|
      weeks.each do |num|
        week = BujoPdf::Week.new(year: YEAR, number: num)
        assert_equal month, week.interleaving_month, "week #{num} disagrees"
      end
    end
  end

  # Anchoring

  def test_month_is_derived_from_the_current_week
    january = BujoPdf::Components::MonthNav.weeks_by_month(YEAR)[1]

    assert_equal january, nav(week_num: 3).weeks
    assert_equal 5, nav(week_num: 3).weeks.length, "January 2026 has five weeks"
  end

  def test_explicit_month_overrides_the_current_week
    assert_equal BujoPdf::Components::MonthNav.weeks_by_month(YEAR)[7],
                 nav(week_num: 3, month: 7).weeks
  end

  def test_anchored_month_contains_the_current_week
    total = BujoPdf::Utilities::DateCalculator.total_weeks(YEAR)
    (1..total).each do |num|
      assert_includes nav(week_num: num).weeks, num, "week #{num} missing from its own strip"
    end
  end

  # Layout stability - the whole point of anchoring

  def test_strip_width_is_identical_for_every_week_of_the_year
    total = BujoPdf::Utilities::DateCalculator.total_weeks(YEAR)
    widths = (1..total).map { |num| nav(week_num: num).width_boxes }

    assert_equal 1, widths.uniq.length, "strip width changes between weeks: #{widths.uniq.inspect}"
  end

  def test_slots_reserved_match_the_widest_month_in_the_year
    assert_equal 5, BujoPdf::Components::MonthNav.slots_for(2026)
    assert_equal 6, BujoPdf::Components::MonthNav.slots_for(2028), "2028 has a six-week January"
  end

  # Rendering

  def test_links_every_week_of_the_month_except_the_current_one
    mock_pdf = MockPDF.new
    canvas = BujoPdf::Canvas.new(mock_pdf, GridSystem.new(mock_pdf))

    BujoPdf::Components::MonthNav.new(
      canvas: canvas, year: YEAR, col: 2, row: 0, week_num: 17
    ).render

    dests = mock_pdf.calls.select { |c| c[:method] == :link_annotation }
                          .map { |c| c[:kwargs][:Dest] }

    # April 2026 is weeks 15-18; current week 17 is not linked.
    assert_includes dests, 'week_15'
    assert_includes dests, 'week_18'
    refute_includes dests, 'week_17', "current week should not be linked"
  end

  def test_neighbouring_month_chips_link_to_those_months_first_weeks
    mock_pdf = MockPDF.new
    canvas = BujoPdf::Canvas.new(mock_pdf, GridSystem.new(mock_pdf))

    BujoPdf::Components::MonthNav.new(
      canvas: canvas, year: YEAR, col: 2, row: 0, week_num: 17
    ).render

    dests = mock_pdf.calls.select { |c| c[:method] == :link_annotation }
                          .map { |c| c[:kwargs][:Dest] }
    by_month = BujoPdf::Components::MonthNav.weeks_by_month(YEAR)

    assert_includes dests, "week_#{by_month[3].first}", "expected a March chip"
    assert_includes dests, "week_#{by_month[5].first}", "expected a May chip"
  end

  def test_january_omits_the_previous_month_chip
    mock_pdf = MockPDF.new
    canvas = BujoPdf::Canvas.new(mock_pdf, GridSystem.new(mock_pdf))

    BujoPdf::Components::MonthNav.new(
      canvas: canvas, year: YEAR, col: 2, row: 0, week_num: 1
    ).render

    dests = mock_pdf.calls.select { |c| c[:method] == :link_annotation }
                          .map { |c| c[:kwargs][:Dest] }
    by_month = BujoPdf::Components::MonthNav.weeks_by_month(YEAR)

    assert_includes dests, "week_#{by_month[2].first}", "expected a February chip"
    assert_equal by_month[1].length - 1 + 1, dests.length,
                 "January should link its other weeks plus February only"
  end

  def test_december_omits_the_next_month_chip
    mock_pdf = MockPDF.new
    canvas = BujoPdf::Canvas.new(mock_pdf, GridSystem.new(mock_pdf))
    december = BujoPdf::Components::MonthNav.weeks_by_month(YEAR)[12]

    BujoPdf::Components::MonthNav.new(
      canvas: canvas, year: YEAR, col: 2, row: 0, week_num: december.first
    ).render

    dests = mock_pdf.calls.select { |c| c[:method] == :link_annotation }
                          .map { |c| c[:kwargs][:Dest] }
    by_month = BujoPdf::Components::MonthNav.weeks_by_month(YEAR)

    assert_includes dests, "week_#{by_month[11].first}", "expected a November chip"
    assert_equal december.length - 1 + 1, dests.length,
                 "December should link its other weeks plus November only"
  end

  def test_renders_every_week_of_the_year_without_error
    total = BujoPdf::Utilities::DateCalculator.total_weeks(YEAR)
    (1..total).each { |num| nav(week_num: num).render }
  end

  def test_renders_nothing_without_a_week_or_month
    mock_pdf = MockPDF.new
    canvas = BujoPdf::Canvas.new(mock_pdf, GridSystem.new(mock_pdf))

    BujoPdf::Components::MonthNav.new(
      canvas: canvas, year: YEAR, col: 2, row: 0
    ).render

    assert_empty mock_pdf.calls.select { |c| c[:method] == :link_annotation }
  end
end
