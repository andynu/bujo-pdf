#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf'
require 'bujo_pdf/pdf_dsl'
require 'bujo_pdf/pages/all'

class TestNavDeclaration < Minitest::Test
  def setup
    BujoPdf::PdfDSL.clear_recipes!
    @context = BujoPdf::PdfDSL::DeclarationContext.new
  end

  def test_nav_section_records_items_in_order
    @context.nav_section(:grids, label: 'Grids', items: [[:grid_dot, 'Dot'], [:grid_graph, 'Graph']])

    section = @context.nav_sections.first
    assert_equal :grids, section.key
    assert_equal 'Grids', section.label
    assert_equal %i[grid_dot grid_graph], section.items.map(&:id)
    assert_equal %w[Dot Graph], section.items.map(&:label)
  end

  def test_nav_section_landing_defaults_to_first_item
    @context.nav_section(:year, label: 'Year', items: [[:seasonal, 'Seasonal'], [:year_events, 'Events']])
    @context.nav_section(:grids, label: 'Grids', landing: :grids_index, items: [[:grid_dot, 'Dot']])

    assert_equal %i[seasonal grids_index], @context.nav_sections.map(&:landing)
  end

  def test_empty_nav_section_is_skipped
    @context.nav_section(:collections, label: 'Collections', items: [])

    assert_empty @context.nav_sections
  end

  def test_duplicate_nav_section_raises
    @context.nav_section(:year, label: 'Year', items: [[:seasonal, 'Seasonal']])

    error = assert_raises(ArgumentError) do
      @context.nav_section(:year, label: 'Year', items: [[:year_events, 'Events']])
    end
    assert_match(/:year/, error.message)
  end

  def test_nav_month_label_and_first_week
    @context.nav_month(3, first_week: :week_10, items: [[:week_10, 'w10'], [:review_3, 'Mar Review']])

    month = @context.nav_months.first
    assert_equal 3, month.month
    assert_equal 'Mar', month.label
    assert_equal :week_10, month.first_week
    assert_equal %i[week_10 review_3], month.items.map(&:id)
  end

  def test_duplicate_nav_month_raises
    @context.nav_month(3, first_week: :week_10, items: [[:week_10, 'w10']])

    assert_raises(ArgumentError) { @context.nav_month(3, first_week: :week_11, items: [[:week_11, 'w11']]) }
  end

  def test_build_passes_nav_to_page_context
    seen = {}
    BujoPdf::PdfDSL.generate(year: 2026) do
      nav_section :s, label: 'S', items: [[:a, 'A'], [:b, 'B']]
      nav_month 1, first_week: :a, items: [[:a, 'w01']]
      page(id: :a) { body { seen[:sections] = context[:nav_sections] } }
      page(id: :b) { body { seen[:months] = context[:nav_months] } }
    end

    assert_equal %i[a b], seen[:sections].first.items.map(&:id)
    assert_equal [1], seen[:months].map(&:month)
  end

  def test_nav_is_empty_when_undeclared
    seen = nil
    BujoPdf::PdfDSL.generate(year: 2026) do
      page(id: :a) { body { seen = [context[:nav_sections], context[:nav_months]] } }
    end

    assert_equal [[], []], seen
  end
end
