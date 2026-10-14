#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'
require 'fileutils'
require 'tmpdir'

class TestProjectPlannerRecipe < Minitest::Test
  def setup
    BujoPdf::PdfDSL.clear_recipes!
    BujoPdf::PdfDSL.load_recipes!
  end

  def teardown
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_project_planner_is_registered
    assert BujoPdf::PdfDSL.recipe?(:project_planner)
  end

  def test_pages_are_cover_twelve_months_then_notes
    pages = evaluate_recipe(year: 2026).pages

    assert_equal 14, pages.length
    assert_equal :cover, pages.first.id
    assert pages.first.inline?
    assert_equal (1..12).map { |m| :"month_#{m}" }, pages[1..12].map(&:id)
    assert_equal [:monthly_overview], pages[1..12].map(&:type).uniq
    assert_equal :notes, pages.last.id
    assert pages.last.inline?
  end

  def test_uses_auto_outline_mode
    assert_equal :auto, evaluate_recipe(year: 2026).current_outline_mode
  end

  def test_outline_top_level_is_overview_months_notes
    entries = evaluate_recipe(year: 2026).outline_entries

    assert_equal ['Year Overview', 'Months', 'Notes'], entries.map(&:title)
    assert_equal %i[cover month_1 notes], entries.map(&:dest)
  end

  def test_months_section_nests_every_month_except_june
    months = evaluate_recipe(year: 2026).outline_entries.find { |e| e.title == 'Months' }

    assert_equal [1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12].map { |m| :"month_#{m}" },
                 months.children.map(&:dest)
  end

  def test_metadata
    metadata = evaluate_recipe(year: 2026).prawn_metadata

    assert_equal 'Project Planner 2026', metadata[:Title]
    assert_equal 'BujoPdf', metadata[:Author]
  end

  def test_theme_is_optional
    assert_nil evaluate_recipe(year: 2026).theme_name
    assert_equal :earth, evaluate_recipe(year: 2026, theme: :earth).theme_name
  end

  def test_generates_a_pdf_including_the_inline_pages
    Dir.mktmpdir('bujo_pdf_test') do |dir|
      output_path = File.join(dir, 'project_planner_2026.pdf')
      BujoPdf.generate_from_recipe(:project_planner, year: 2026, output: output_path)

      assert_operator File.size(output_path), :>, 0
    end
  end

  private

  def evaluate_recipe(**params)
    context = BujoPdf::PdfDSL::DeclarationContext.new
    BujoPdf::PdfDSL.recipes[:project_planner].evaluate(context, **params)
    context
  end
end
