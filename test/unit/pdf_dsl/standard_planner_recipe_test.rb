#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestStandardPlannerRecipe < Minitest::Test
  def setup
    # Clear and reload recipes before each test
    BujoPdf::PdfDSL.clear_recipes!
    BujoPdf::PdfDSL.load_recipes!
  end

  def teardown
    BujoPdf::PdfDSL.clear_recipes!
  end

  # Recipe registration tests

  def test_standard_planner_is_registered
    assert BujoPdf::PdfDSL.recipe?(:standard_planner)
  end

  # Declaration structure tests

  def test_standard_planner_has_correct_page_count
    context = evaluate_recipe(year: 2025)

    total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(2025)
    expected_pages = 4 + total_weeks + 8 + 3  # 4 overview + weeks + 8 grids + 3 templates

    assert_equal expected_pages, context.pages.length
  end

  def test_standard_planner_page_order
    context = evaluate_recipe(year: 2025)

    # First 4 pages are overview pages
    assert_equal :seasonal, context.pages[0].type
    assert_equal :year_events, context.pages[1].type
    assert_equal :year_highlights, context.pages[2].type
    assert_equal :multi_year, context.pages[3].type

    # After weekly pages come grid pages
    total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(2025)
    grid_start = 4 + total_weeks

    assert_equal :grid_showcase, context.pages[grid_start].type
    assert_equal :grids_overview, context.pages[grid_start + 1].type
    assert_equal :grid_dot, context.pages[grid_start + 2].type
    assert_equal :grid_graph, context.pages[grid_start + 3].type
    assert_equal :grid_lined, context.pages[grid_start + 4].type
    assert_equal :grid_isometric, context.pages[grid_start + 5].type
    assert_equal :grid_perspective, context.pages[grid_start + 6].type
    assert_equal :grid_hexagon, context.pages[grid_start + 7].type

    # Final 3 pages are templates
    assert_equal :reference, context.pages[-3].type
    assert_equal :daily_wheel, context.pages[-2].type
    assert_equal :year_wheel, context.pages[-1].type
  end

  def test_standard_planner_weekly_pages
    context = evaluate_recipe(year: 2025)

    total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(2025)
    weekly_pages = context.pages.select { |p| p.type == :weekly }

    assert_equal total_weeks, weekly_pages.length

    # Verify week numbers
    weekly_pages.each_with_index do |page, index|
      week = page.params[:week]
      assert_equal index + 1, week.number, "Week #{index + 1} should have correct number"
    end
  end

  def test_standard_planner_destination_keys
    context = evaluate_recipe(year: 2025)

    # Check explicit destination keys are set
    assert context.pages.any? { |p| p.destination_key == 'seasonal' }
    assert context.pages.any? { |p| p.destination_key == 'year_events' }
    assert context.pages.any? { |p| p.destination_key == 'year_highlights' }
    assert context.pages.any? { |p| p.destination_key == 'multi_year' }
    assert context.pages.any? { |p| p.destination_key == 'grid_showcase' }
    assert context.pages.any? { |p| p.destination_key == 'reference' }

    # Check weekly page destination keys
    assert context.pages.any? { |p| p.destination_key == 'week_1' }
    assert context.pages.any? { |p| p.destination_key == 'week_52' }
  end

  def test_standard_planner_grids_group
    context = evaluate_recipe(year: 2025)

    assert_equal 1, context.groups.length

    grids_group = context.groups.first
    assert_equal :grids, grids_group.name
    assert grids_group.cycle?, "Grids group should have cycling enabled"
    assert_equal 8, grids_group.pages.length
  end

  def test_standard_planner_metadata
    context = evaluate_recipe(year: 2025)

    metadata = context.prawn_metadata
    assert_equal "Planner 2025", metadata[:Title]
    assert_equal "BujoPdf", metadata[:Author]
  end

  def test_standard_planner_multi_year_params
    context = evaluate_recipe(year: 2025)

    multi_year_page = context.pages.find { |p| p.type == :multi_year }
    assert_equal 4, multi_year_page.params[:year_count]
    assert_equal 2025, multi_year_page.params[:year]
  end

  def test_standard_planner_works_for_different_years
    [2024, 2025, 2026, 2030].each do |year|
      context = evaluate_recipe(year: year)

      total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(year)
      expected_pages = 4 + total_weeks + 8 + 3

      assert_equal expected_pages, context.pages.length, "Wrong page count for year #{year}"

      # Verify metadata updates
      assert_equal "Planner #{year}", context.prawn_metadata[:Title]
    end
  end

  def test_standard_planner_theme_optional
    # Without theme
    context1 = evaluate_recipe(year: 2025)
    assert_nil context1.theme_name

    # With theme
    context2 = evaluate_recipe(year: 2025, theme: :earth)
    assert_equal :earth, context2.theme_name
  end

  private

  def evaluate_recipe(**params)
    recipe = BujoPdf::PdfDSL.recipes[:standard_planner]
    context = BujoPdf::PdfDSL::DeclarationContext.new
    recipe.evaluate(context, **params)
    context
  end
end
