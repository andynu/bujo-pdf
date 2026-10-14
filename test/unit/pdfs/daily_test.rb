#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestDailyRecipe < Minitest::Test
  def setup
    BujoPdf::PdfDSL.clear_recipes!
    BujoPdf::PdfDSL.load_recipes!
  end

  def teardown
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_daily_is_registered
    assert BujoPdf::PdfDSL.recipe?(:daily)
  end

  def test_one_inline_page_per_day
    [[2025, 365], [2024, 366]].each do |year, days|
      daily_pages = evaluate_recipe(year: year).pages.select(&:inline?)

      assert_equal days, daily_pages.length, "Wrong day count for #{year}"
      assert_equal :"day_#{year}0101", daily_pages.first.id
      assert_equal :"day_#{year}1231", daily_pages.last.id
    end
  end

  def test_page_count
    collections_count = BujoPdf::CollectionsConfiguration.load.length
    # 1 seasonal + 2 index + 2 future_log + 3 overview + days + 8 grids + 4 templates + N collections
    expected = 1 + 2 + 2 + 3 + 365 + 8 + 4 + collections_count

    assert_equal expected, evaluate_recipe(year: 2025).pages.length
  end

  def test_daily_pages_sit_between_year_overview_and_grids
    ids = evaluate_recipe(year: 2025).pages.map(&:destination_key)

    assert_operator ids.index('multi_year'), :<, ids.index('day_20250101')
    assert_operator ids.index('day_20251231'), :<, ids.index('grid_showcase')
  end

  def test_outline_has_a_daily_pages_entry_then_one_entry_per_day
    entries = evaluate_recipe(year: 2025).outline_entries
    daily_index = entries.index { |entry| entry.title == 'Daily Pages' }

    assert_equal :day_20250101, entries[daily_index].dest
    assert_equal 'January 1, 2025', entries[daily_index + 1].title
    assert_equal :day_20250101, entries[daily_index + 1].dest
    assert(entries.any? { |entry| entry.title == 'December 31, 2025' && entry.dest == :day_20251231 })
  end

  def test_grids_group_cycles
    group = evaluate_recipe(year: 2025).groups.find { |g| g.name == :grids }

    assert group.cycle?
    assert_equal 8, group.pages.length
  end

  def test_metadata
    metadata = evaluate_recipe(year: 2025).prawn_metadata

    assert_equal 'Daily Planner 2025', metadata[:Title]
    assert_equal 'BujoPdf', metadata[:Author]
  end

  def test_theme_is_optional
    assert_nil evaluate_recipe(year: 2025).theme_name
    assert_equal :earth, evaluate_recipe(year: 2025, theme: :earth).theme_name
  end

  private

  def evaluate_recipe(**params)
    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:daily].evaluate(context, **params)
    context
  end
end
