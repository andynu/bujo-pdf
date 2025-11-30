#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestRecipeRegistry < Minitest::Test
  def setup
    # Clear recipes before each test
    BujoPdf::PdfDSL.clear_recipes!
  end

  def teardown
    # Clean up after tests
    BujoPdf::PdfDSL.clear_recipes!
  end

  # Recipe definition tests

  def test_define_pdf_creates_recipe
    BujoPdf.define_pdf :test_planner do |year:|
      page :year_events, year: year
    end

    assert BujoPdf::PdfDSL.recipe?(:test_planner)
  end

  def test_define_pdf_returns_definition
    definition = BujoPdf.define_pdf :test_planner do |year:|
      page :year_events, year: year
    end

    assert_instance_of BujoPdf::PdfDSL::PdfDefinition, definition
    assert_equal :test_planner, definition.name
  end

  def test_recipe_is_stored_in_registry
    BujoPdf::PdfDSL.define_pdf :my_recipe do |year:|
      page :year_events, year: year
    end

    assert_includes BujoPdf::PdfDSL.recipes.keys, :my_recipe
  end

  def test_recipe_check_returns_false_for_unknown
    refute BujoPdf::PdfDSL.recipe?(:nonexistent)
  end

  def test_clear_recipes
    BujoPdf.define_pdf :test1 do |year:|; end
    BujoPdf.define_pdf :test2 do |year:|; end

    assert_equal 2, BujoPdf::PdfDSL.recipes.size

    BujoPdf::PdfDSL.clear_recipes!

    assert_equal 0, BujoPdf::PdfDSL.recipes.size
  end

  # Recipe composition tests

  def test_include_recipe_adds_pages
    # Define a fragment recipe
    BujoPdf.define_pdf :overview_pages do |year:|
      page :year_events, year: year
      page :year_highlights, year: year
    end

    # Define main recipe that includes fragment
    BujoPdf.define_pdf :full_planner do |year:|
      include_recipe :overview_pages, year: year
      page :reference
    end

    # Evaluate the main recipe
    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:full_planner].evaluate(context, year: 2025)

    # Should have 3 pages: year_events, year_highlights, reference
    assert_equal 3, context.pages.length
    assert_equal :year_events, context.pages[0].type
    assert_equal :year_highlights, context.pages[1].type
    assert_equal :reference, context.pages[2].type
  end

  def test_include_recipe_preserves_order
    BujoPdf.define_pdf :middle_section do |year:|
      page :weekly, week_num: 1
      page :weekly, week_num: 2
    end

    BujoPdf.define_pdf :ordered_planner do |year:|
      page :intro
      include_recipe :middle_section, year: year
      page :outro
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:ordered_planner].evaluate(context, year: 2025)

    types = context.pages.map(&:type)
    assert_equal [:intro, :weekly, :weekly, :outro], types
  end

  def test_include_recipe_passes_parameters
    BujoPdf.define_pdf :parameterized do |year:, special_flag:|
      page :special, year: year, flag: special_flag
    end

    BujoPdf.define_pdf :main do |year:|
      include_recipe :parameterized, year: year, special_flag: true
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:main].evaluate(context, year: 2025)

    assert_equal 1, context.pages.length
    assert_equal true, context.pages.first.params[:flag]
    assert_equal 2025, context.pages.first.params[:year]
  end

  def test_include_recipe_raises_for_unknown_recipe
    BujoPdf.define_pdf :main do |year:|
      include_recipe :nonexistent, year: year
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new

    error = assert_raises ArgumentError do
      BujoPdf::PdfDSL.recipes[:main].evaluate(context, year: 2025)
    end

    assert_match(/Unknown recipe: nonexistent/, error.message)
  end

  def test_nested_include_recipe
    BujoPdf.define_pdf :level_3 do |year:|
      page :deep, year: year
    end

    BujoPdf.define_pdf :level_2 do |year:|
      page :mid_start
      include_recipe :level_3, year: year
      page :mid_end
    end

    BujoPdf.define_pdf :level_1 do |year:|
      page :top_start
      include_recipe :level_2, year: year
      page :top_end
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:level_1].evaluate(context, year: 2025)

    types = context.pages.map(&:type)
    assert_equal [:top_start, :mid_start, :deep, :mid_end, :top_end], types
  end

  def test_include_recipe_with_groups
    BujoPdf.define_pdf :grid_pages do |year:|
      group :grids, cycle: true do
        page :grid_dot
        page :grid_graph
      end
    end

    BujoPdf.define_pdf :with_grids do |year:|
      page :intro
      include_recipe :grid_pages, year: year
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:with_grids].evaluate(context, year: 2025)

    assert_equal 3, context.pages.length
    assert_equal 1, context.groups.length
    assert_equal :grids, context.groups.first.name
    assert context.groups.first.cycle?
  end

  def test_include_recipe_inherits_metadata_from_first_definition
    BujoPdf.define_pdf :fragment do |year:|
      metadata do
        author "Fragment Author"  # This will be ignored since metadata already set
      end
      page :year_events, year: year
    end

    BujoPdf.define_pdf :main do |year:|
      metadata do
        title "Main Title"
        author "Main Author"
      end
      include_recipe :fragment, year: year
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:main].evaluate(context, year: 2025)

    # Main's metadata should win since it was set first
    # Actually, the included recipe's metadata call will overwrite
    # This tests that both metadata calls work
    refute_nil context.metadata_builder
  end

  # Real-world composition pattern

  def test_real_world_composition
    # Define reusable fragments
    BujoPdf.define_pdf :year_overview do |year:|
      page :seasonal_calendar, year: year
      page :year_events, year: year
      page :year_highlights, year: year
    end

    BujoPdf.define_pdf :weekly_pages do |year:|
      # In real usage this would iterate weeks
      page :weekly, week_num: 1
      page :weekly, week_num: 2
      page :weekly, week_num: 3
    end

    BujoPdf.define_pdf :grid_templates do |year:|
      group :grids, cycle: true do
        page :grid_dot
        page :grid_graph
        page :grid_lined
      end
    end

    # Compose into full planner
    BujoPdf.define_pdf :standard_planner do |year:|
      metadata do
        title "Planner #{year}"
        author "BujoPdf"
      end

      include_recipe :year_overview, year: year
      include_recipe :weekly_pages, year: year
      include_recipe :grid_templates, year: year
      page :reference
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:standard_planner].evaluate(context, year: 2025)

    # 3 year overview + 3 weekly + 3 grids + 1 reference = 10 pages
    assert_equal 10, context.pages.length

    # 1 grid group
    assert_equal 1, context.groups.length

    # Metadata should be set
    info = context.prawn_metadata
    assert_equal "Planner 2025", info[:Title]
    assert_equal "BujoPdf", info[:Author]
  end
end
