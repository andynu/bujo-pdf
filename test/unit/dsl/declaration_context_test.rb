#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestDeclarationContext < Minitest::Test
  def setup
    @context = BujoPdf::PdfDSL::DeclarationContext.new
  end

  def test_page_declaration
    @context.page(:seasonal_calendar, year: 2025)

    assert_equal 1, @context.pages.length
    assert_equal :seasonal_calendar, @context.pages.first.type
    assert_equal({ year: 2025 }, @context.pages.first.params)
  end

  def test_multiple_pages
    @context.page(:seasonal_calendar, year: 2025)
    @context.page(:year_events, year: 2025)

    assert_equal 2, @context.pages.length
  end

  def test_page_with_explicit_id
    @context.page(:dot_grid, id: :notes)

    assert_equal :notes, @context.pages.first.id
  end

  def test_group_declaration
    @context.group(:grids, cycle: true) do
      page :grid_dot
      page :grid_graph
    end

    assert_equal 1, @context.groups.length
    group = @context.groups.first
    assert_equal :grids, group.name
    assert group.cycle?
    assert_equal 2, group.pages.length
  end

  def test_pages_in_group_also_in_main_list
    @context.group(:grids) do
      page :grid_dot
    end

    # Pages should be in both group and main list
    assert_equal 1, @context.pages.length
    assert_equal :grid_dot, @context.pages.first.type
  end

  def test_metadata
    @context.metadata do
      title "My Planner"
      author "Test"
    end

    refute_nil @context.metadata_builder
    prawn_info = @context.prawn_metadata
    assert_equal "My Planner", prawn_info[:Title]
    assert_equal "Test", prawn_info[:Author]
  end

  def test_theme
    @context.theme(:earth)

    assert_equal :earth, @context.theme_name
  end

  def test_weeks_in
    weeks = @context.weeks_in(2025)

    refute_empty weeks
    assert_instance_of BujoPdf::PdfDSL::Week, weeks.first
    assert_equal 1, weeks.first.number
  end

  def test_months_in
    months = @context.months_in(2025)

    assert_equal 12, months.length
    assert_instance_of BujoPdf::PdfDSL::Month, months.first
  end

  def test_each_month
    count = 0
    @context.each_month(2025) do |month|
      count += 1
      assert_instance_of BujoPdf::PdfDSL::Month, month
    end

    assert_equal 12, count
  end

  def test_each_week_with_year
    weeks = []
    @context.each_week(2025) do |week|
      weeks << week
    end

    total = BujoPdf::Utilities::DateCalculator.total_weeks(2025)
    assert_equal total, weeks.length
  end

  def test_each_week_with_month
    month = BujoPdf::PdfDSL::Month.new(2025, 6)
    weeks = []
    @context.each_week(month) do |week|
      weeks << week
    end

    # June typically spans 4-5 weeks
    assert weeks.length >= 4
    assert weeks.length <= 6
  end

  def test_outline_mode_defaults_to_manual
    assert_equal :manual, @context.current_outline_mode
  end

  def test_outline_mode_can_be_set_to_auto
    @context.outline_mode(:auto)
    assert_equal :auto, @context.current_outline_mode
  end

  def test_outline_mode_can_be_set_to_none
    @context.outline_mode(:none)
    assert_equal :none, @context.current_outline_mode
  end

  def test_outline_mode_rejects_invalid_modes
    assert_raises(ArgumentError) do
      @context.outline_mode(:invalid)
    end
  end

  def test_auto_outline_mode_generates_outline_for_standard_pages
    @context.outline_mode(:auto)
    @context.page(:seasonal_calendar, year: 2025)

    assert_equal 1, @context.outline_entries.length
    # Title depends on page registration, should be "Seasonal Calendar" or similar
    assert @context.outline_entries.first.title
  end

  def test_auto_outline_mode_generates_outline_for_inline_pages
    @context.outline_mode(:auto)
    @context.page(id: :my_notes) do
      layout :full_page
      body { h1(2, 2, "Notes") }
    end

    assert_equal 1, @context.outline_entries.length
    assert_equal "My Notes", @context.outline_entries.first.title
  end

  def test_manual_mode_requires_explicit_outline_param
    # Manual mode (default) - no outline entry without explicit outline param
    @context.page(:seasonal_calendar, year: 2025)
    assert_equal 0, @context.outline_entries.length

    # With explicit outline: true
    @context.page(:seasonal_calendar, year: 2025, outline: true)
    assert_equal 1, @context.outline_entries.length
  end

  def test_none_mode_never_generates_outline
    @context.outline_mode(:none)

    # Even with explicit outline: true, no entry should be added
    @context.page(:seasonal_calendar, year: 2025, outline: true)
    assert_equal 0, @context.outline_entries.length

    @context.page(id: :notes, outline: "Notes") do
      layout :full_page
      body { h1(2, 2, "Notes") }
    end
    assert_equal 0, @context.outline_entries.length
  end

  def test_auto_mode_respects_explicit_outline_false
    @context.outline_mode(:auto)

    # Explicit false should suppress outline entry
    @context.page(:seasonal_calendar, year: 2025, outline: false)
    assert_equal 0, @context.outline_entries.length
  end
end
