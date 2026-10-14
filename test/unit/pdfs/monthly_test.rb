#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestMonthlyRecipe < Minitest::Test
  def setup
    BujoPdf::PdfDSL.clear_recipes!
    BujoPdf::PdfDSL.load_recipes!
  end

  def teardown
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_monthly_is_registered
    assert BujoPdf::PdfDSL.recipe?(:monthly)
  end

  def test_page_count_has_no_weekly_pages
    pages = evaluate_recipe(year: 2025).pages
    collections_count = BujoPdf::CollectionsConfiguration.load.length
    # 1 seasonal + 2 index + 2 future_log + 3 overview + 4 quarterly + 12 monthly
    # + 8 grids + 4 templates + N collections
    expected = 1 + 2 + 2 + 3 + 4 + 12 + 8 + 4 + collections_count

    assert_equal expected, pages.length
    assert_empty pages.select { |p| p.type == :weekly }
  end

  def test_each_quarter_opens_with_its_planning_page
    keys = evaluate_recipe(year: 2025).pages.map(&:destination_key)

    { 1 => 1, 2 => 4, 3 => 7, 4 => 10 }.each do |quarter, first_month|
      assert_equal keys.index("review_#{first_month}") - 1, keys.index("quarter_#{quarter}"),
                   "Q#{quarter} planning should directly precede review_#{first_month}"
    end
  end

  def test_monthly_reviews_cover_every_month_in_order
    reviews = evaluate_recipe(year: 2025).pages.select { |p| p.type == :monthly_review }

    assert_equal (1..12).to_a, reviews.map { |p| p.params[:month] }
    assert_equal (1..12).to_a, reviews.map { |p| p.params[:review_month] }
  end

  def test_outline_names_reviews_by_month_and_year
    titles = evaluate_recipe(year: 2026).outline_entries.map(&:title)

    assert_includes titles, 'Quarterly Planning'
    assert_includes titles, 'Monthly Reviews'
    assert_includes titles, 'January 2026'
    assert_includes titles, 'December 2026'
  end

  def test_metadata
    metadata = evaluate_recipe(year: 2025).prawn_metadata

    assert_equal 'Monthly Planner 2025', metadata[:Title]
    assert_equal 'BujoPdf', metadata[:Author]
  end

  def test_theme_is_optional
    assert_nil evaluate_recipe(year: 2025).theme_name
    assert_equal :earth, evaluate_recipe(year: 2025, theme: :earth).theme_name
  end

  private

  def evaluate_recipe(**params)
    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:monthly].evaluate(context, **params)
    context
  end
end
