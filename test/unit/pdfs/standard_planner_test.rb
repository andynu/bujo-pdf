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
    # Structure: 1 seasonal + 2 index + 2 future_log + 3 overview + 4 quarterly + 12 monthly
    #           + weekly pages + 8 grids + 4 templates + N collections (from config/collections.yml if present)
    collections_count = BujoPdf::CollectionsConfiguration.load.length
    expected_pages = 1 + 2 + 2 + 3 + 4 + 12 + total_weeks + 8 + 4 + collections_count

    assert_equal expected_pages, context.pages.length
  end

  def test_standard_planner_page_order
    context = evaluate_recipe(year: 2025)

    # First are index pages
    assert_equal :index, context.pages[0].type
    assert_equal :index, context.pages[1].type

    # Then the year set: seasonal calendar and the year overview pages
    assert_equal :seasonal, context.pages[2].type
    assert_equal :year_events, context.pages[3].type
    assert_equal :year_highlights, context.pages[4].type
    assert_equal :multi_year, context.pages[5].type

    # Then future log pages
    assert_equal :future_log, context.pages[6].type
    assert_equal :future_log, context.pages[7].type

    # Weekly pages with interleaved monthly reviews and quarterly planning
    # The exact order depends on the week structure for the year

    # Grid pages come after all weekly/review/quarterly pages
    grids_index_page = context.pages.find { |p| p.type == :grids_index }
    refute_nil grids_index_page

    # Verify order of grid pages (sequential in the grids group, in nav order)
    grid_types = [:grids_index, :grid_dot, :grid_isometric, :grid_perspective,
                  :grid_perspective_2, :grid_graph, :grid_lined, :grid_hexagon]
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

  def test_monthly_review_follows_the_weeks_of_the_month_it_reviews
    [2024, 2025, 2026, 2027].each do |year|
      context = evaluate_recipe(year: year)
      pages = context.pages

      (1..12).each do |month|
        review_index = pages.index { |p| p.destination_key == "review_#{month}" }
        refute_nil review_index, "#{year}: missing review for month #{month}"

        weeks_of_month = pages.each_with_index.select do |p, _i|
          p.type == :weekly && p.params[:week].interleaving_month == month
        end
        refute_empty weeks_of_month, "#{year}: no weeks filed under month #{month}"

        last_week_index = weeks_of_month.map(&:last).max
        assert_operator review_index, :>, last_week_index,
                        "#{year}: review for month #{month} precedes that month's last week"
      end
    end
  end

  def test_no_weekly_page_precedes_the_first_quarterly_planning_page
    # Week 1 starts in the previous December in most years; it must still be
    # filed under January, after Q1 planning.
    [2024, 2025, 2026, 2027].each do |year|
      pages = evaluate_recipe(year: year).pages

      quarter_1_index = pages.index { |p| p.destination_key == 'quarter_1' }
      first_weekly_index = pages.index { |p| p.type == :weekly }

      assert_operator quarter_1_index, :<, first_weekly_index,
                      "#{year}: week 1 appears before Q1 planning"
    end
  end

  def test_quarterly_planning_precedes_every_week_in_its_quarter
    pages = evaluate_recipe(year: 2026).pages

    (1..4).each do |quarter|
      quarter_index = pages.index { |p| p.destination_key == "quarter_#{quarter}" }
      months = ((quarter - 1) * 3 + 1..(quarter - 1) * 3 + 3)

      first_week_index = pages.index do |p|
        p.type == :weekly && months.include?(p.params[:week].interleaving_month)
      end

      assert_operator quarter_index, :<, first_week_index,
                      "Q#{quarter} planning appears after its first week"
    end
  end

  def test_standard_planner_destination_keys
    context = evaluate_recipe(year: 2025)

    # Check explicit destination keys are set
    assert context.pages.any? { |p| p.destination_key == 'seasonal' }
    assert context.pages.any? { |p| p.destination_key == 'year_events' }
    assert context.pages.any? { |p| p.destination_key == 'year_highlights' }
    assert context.pages.any? { |p| p.destination_key == 'multi_year' }
    assert context.pages.any? { |p| p.destination_key == 'grids_index' }
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
    refute grids_group.cycle?, 'the section nav lists every grid page, so the Grids tab no longer cycles'
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
    collections_count = BujoPdf::CollectionsConfiguration.load.length

    [2024, 2025, 2026, 2030].each do |year|
      context = evaluate_recipe(year: year)

      total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(year)
      # 1 seasonal + 2 index + 2 future_log + 3 overview + 4 quarterly + 12 monthly
      # + weekly pages + 8 grids + 4 templates + N collections
      expected_pages = 1 + 2 + 2 + 3 + 4 + 12 + total_weeks + 8 + 4 + collections_count

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

  # Navigation

  def test_chrome_is_calendar_nav_and_section_nav
    chrome = evaluate_recipe(year: 2025).chrome_config

    assert_equal :calendar_nav, chrome.left_config.sidebar_name
    assert_equal :section_nav, chrome.right_config.sidebar_name
  end

  def test_every_page_carries_the_chrome
    pages = evaluate_recipe(year: 2025, rituals: true).pages

    assert(pages.none? { |page| page.chrome == false }, 'no page opts out of the nav')
  end

  def test_sections_in_pdf_order
    labels = evaluate_recipe(year: 2025).nav_sections.map(&:label)

    assert_equal %w[Index Year Future Grids Templates], labels.first(5)
  end

  def test_rituals_section_sits_between_future_and_grids
    labels = evaluate_recipe(year: 2025, rituals: true).nav_sections.map(&:label)

    assert_equal %w[Index Year Future Rituals Grids Templates], labels.first(6)
  end

  # A section's tab and its expanded list read as one run of pages
  def test_every_section_is_one_run_of_consecutive_pages
    [false, true].each do |rituals|
      context = evaluate_recipe(year: 2025, rituals: rituals)
      order = context.pages.map(&:id)

      context.nav_sections.each do |section|
        positions = ([section.landing] + section.items.map(&:id)).uniq.map { |id| order.index(id) }.sort

        assert_equal (positions.first..positions.last).to_a, positions,
                     "#{section.label} pages are not consecutive (rituals: #{rituals})"
      end
    end
  end

  def test_section_items_and_landings
    sections = evaluate_recipe(year: 2025).nav_sections.to_h { |section| [section.key, section] }

    assert_equal %w[Seasonal Events Highlights Multi], sections[:year].items.map(&:label)
    assert_equal %i[seasonal year_events year_highlights multi_year], sections[:year].items.map(&:id)
    assert_equal %w[Jan-Jun Jul-Dec], sections[:future].items.map(&:label)
    assert_equal :grids_index, sections[:grids].landing
    assert_equal %w[Dot Iso 1pp 2pp Graph Ruled Hex], sections[:grids].items.map(&:label)
    assert_equal %i[grid_dot grid_isometric grid_perspective grid_perspective_2 grid_graph grid_lined grid_hexagon],
                 sections[:grids].items.map(&:id)
    assert_equal ['Tracker', 'Reference', 'Daily Wheel', 'Year Wheel'], sections[:templates].items.map(&:label)
  end

  def test_ritual_items_use_manifest_nav_labels
    rituals = evaluate_recipe(year: 2025, rituals: true).nav_sections.find { |section| section.key == :rituals }

    assert_equal %w[Daily Weekly Monthly Seasonal Quarterly Migration Birthday Pausing Feelings Mood],
                 rituals.items.map(&:label)
    assert_equal :ritual_daily, rituals.landing
  end

  def test_every_page_in_a_section_exists
    context = evaluate_recipe(year: 2025, rituals: true)
    ids = context.pages.map(&:id)

    context.nav_sections.flat_map(&:items).each { |item| assert_includes ids, item.id }
  end

  def test_twelve_months_each_linking_to_their_first_week
    months = evaluate_recipe(year: 2026).nav_months

    assert_equal (1..12).to_a, months.map(&:month)
    assert_equal :week_1, months.first.first_week
    assert(months.all? { |month| month.items.map(&:id).include?(month.first_week) })
  end

  def test_each_week_appears_in_exactly_one_month
    [2024, 2025, 2026].each do |year|
      weeks = evaluate_recipe(year: year).nav_months.flat_map(&:items).map(&:id).grep(/\Aweek_/)
      total = BujoPdf::Utilities::DateCalculator.total_weeks(year)

      assert_equal (1..total).map { |n| :"week_#{n}" }, weeks, "weeks for #{year}"
    end
  end

  def test_month_items_follow_pdf_order
    context = evaluate_recipe(year: 2026)
    order = context.pages.map(&:id)
    april = context.nav_months.find { |month| month.month == 4 }

    assert_equal :quarter_2, april.items.first.id
    assert_equal 'Q2', april.items.first.label
    assert_equal :review_4, april.items.last.id
    # Listed under its month's own entry, so the month name would only crowd the narrow column
    assert_equal 'Review', april.items.last.label
    assert_equal april.items.map(&:id), april.items.map(&:id).sort_by { |id| order.index(id) }
  end

  # Ritual deck (opt-in)

  def test_rituals_are_off_by_default
    context = evaluate_recipe(year: 2025)

    assert_empty context.pages.select(&:imported?)
  end

  def test_rituals_adds_one_imported_page_per_manifest_key
    deck = BujoPdf::PdfDSL::PdfImport.new(File.expand_path('../../../assets/ritual_deck/manifest.yml', __dir__))
    context = evaluate_recipe(year: 2025, rituals: true)
    imported = context.pages.select(&:imported?)

    assert_equal deck.keys.map { |key| :"ritual_#{key}" }, imported.map(&:id)
  end

  def test_rituals_sit_between_the_year_overview_and_the_weeks
    ids = evaluate_recipe(year: 2025, rituals: true).pages.map(&:destination_key)

    assert_operator ids.index('multi_year'), :<, ids.index('ritual_daily')
    assert_operator ids.index('ritual_pausing'), :<, ids.index('week_1')
  end

  def test_rituals_are_not_prefilled_into_the_index
    pages = evaluate_recipe(year: 2025, rituals: true).pages.select { |page| page.type == :index }

    assert(pages.none? { |page| page.params.key?(:prefill) }, 'the Rituals tab replaces the index listing')
  end

  def test_index_pages_have_no_prefill_without_rituals
    pages = evaluate_recipe(year: 2025).pages.select { |page| page.type == :index }

    assert(pages.none? { |page| page.params.key?(:prefill) })
  end

  def test_rituals_get_an_outline_section
    context = evaluate_recipe(year: 2025, rituals: true)
    section = context.outline_entries.find { |entry| entry.title == 'Rituals' }

    assert_equal ['The Daily Protocol', 'The Weekly Review'], section.children.first(2).map(&:title)
    assert_equal :ritual_daily, section.children.first.dest
  end

  private

  def evaluate_recipe(**params)
    recipe = BujoPdf::PdfDSL.recipes[:standard_planner]
    context = BujoPdf::PdfDSL::DeclarationContext.new
    recipe.evaluate(context, **params)
    context
  end
end
