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
    # New structure: 1 seasonal + 2 index + 2 future_log + 3 overview + 4 quarterly + 12 monthly
    #               + weekly pages + 8 grids + 4 templates + 3 collections (from config/collections.yml)
    expected_pages = 1 + 2 + 2 + 3 + 4 + 12 + total_weeks + 8 + 4 + 3

    assert_equal expected_pages, context.pages.length
  end

  def test_standard_planner_page_order
    context = evaluate_recipe(year: 2025)

    # First page is seasonal calendar
    assert_equal :seasonal, context.pages[0].type

    # Next are index pages
    assert_equal :index, context.pages[1].type
    assert_equal :index, context.pages[2].type

    # Then future log pages
    assert_equal :future_log, context.pages[3].type
    assert_equal :future_log, context.pages[4].type

    # Then year overview pages
    assert_equal :year_events, context.pages[5].type
    assert_equal :year_highlights, context.pages[6].type
    assert_equal :multi_year, context.pages[7].type

    # Weekly pages with interleaved monthly reviews and quarterly planning
    # The exact order depends on the week structure for the year

    # Grid pages come after all weekly/review/quarterly pages
    grid_showcase_page = context.pages.find { |p| p.type == :grid_showcase }
    refute_nil grid_showcase_page

    # Verify order of grid pages (sequential in the grids group)
    grid_types = [:grid_showcase, :grids_overview, :grid_dot, :grid_graph,
                  :grid_lined, :grid_isometric, :grid_perspective, :grid_hexagon]
    grid_pages = context.pages.select { |p| grid_types.include?(p.type) }
    assert_equal grid_types, grid_pages.map(&:type)

    # Final pages are template pages (before collections)
    template_start = context.pages.index { |p| p.type == :tracker_example }
    assert_equal :tracker_example, context.pages[template_start].type
    assert_equal :reference, context.pages[template_start + 1].type
    assert_equal :daily_wheel, context.pages[template_start + 2].type
    assert_equal :year_wheel, context.pages[template_start + 3].type
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

  def test_standard_planner_index_pages
    context = evaluate_recipe(year: 2025)

    index_pages = context.pages.select { |p| p.type == :index }
    assert_equal 2, index_pages.length

    assert_equal 1, index_pages[0].params[:index_page_num]
    assert_equal 2, index_pages[1].params[:index_page_num]
  end

  def test_standard_planner_future_log_pages
    context = evaluate_recipe(year: 2025)

    future_log_pages = context.pages.select { |p| p.type == :future_log }
    assert_equal 2, future_log_pages.length

    assert_equal 1, future_log_pages[0].params[:future_log_start_month]
    assert_equal 7, future_log_pages[1].params[:future_log_start_month]
  end

  def test_standard_planner_quarterly_planning_pages
    context = evaluate_recipe(year: 2025)

    quarterly_pages = context.pages.select { |p| p.type == :quarterly_planning }
    assert_equal 4, quarterly_pages.length

    quarters = quarterly_pages.map { |p| p.params[:quarter] }
    assert_equal [1, 2, 3, 4], quarters
  end

  def test_standard_planner_monthly_review_pages
    context = evaluate_recipe(year: 2025)

    review_pages = context.pages.select { |p| p.type == :monthly_review }
    assert_equal 12, review_pages.length

    months = review_pages.map { |p| p.params[:month] }
    assert_equal (1..12).to_a, months
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
    assert context.pages.any? { |p| p.destination_key == 'index_1' }
    assert context.pages.any? { |p| p.destination_key == 'index_2' }
    assert context.pages.any? { |p| p.destination_key == 'future_log_1' }
    assert context.pages.any? { |p| p.destination_key == 'future_log_2' }
    assert context.pages.any? { |p| p.destination_key == 'quarter_1' }
    assert context.pages.any? { |p| p.destination_key == 'review_1' }
    assert context.pages.any? { |p| p.destination_key == 'tracker_example' }

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
      # 1 seasonal + 2 index + 2 future_log + 3 overview + 4 quarterly + 12 monthly
      # + weekly pages + 8 grids + 4 templates + 3 collections
      expected_pages = 1 + 2 + 2 + 3 + 4 + 12 + total_weeks + 8 + 4 + 3

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
