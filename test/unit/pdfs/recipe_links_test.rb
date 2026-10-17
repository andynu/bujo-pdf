#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

# Every shipped recipe builds without link warnings.
#
# The daily, monthly and project planners have no weekly pages, but their
# overview pages still link each week to "week_N". Those dead links are
# pinned here by count, so any other warning fails, and so does fixing them
# without updating this list.
class TestRecipeLinks < Minitest::Test
  YEAR = 2026

  KNOWN_DEAD_WEEK_LINKS = {
    daily: 159,
    monthly: 207,
    project_planner: 63
  }.freeze

  RUNS = [
    [:standard_planner, {}],
    [:standard_planner, { rituals: true }],
    [:daily, {}],
    [:monthly, {}],
    [:project_planner, {}]
  ].freeze

  def setup
    BujoPdf::PdfDSL.clear_recipes!
    BujoPdf::PdfDSL.load_recipes!
  end

  def teardown
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_every_shipped_recipe_is_covered
    assert_equal BujoPdf::PdfDSL.recipes.keys.sort, RUNS.map(&:first).uniq.sort
  end

  RUNS.each do |name, extra|
    define_method("test_#{name}#{extra.keys.map { |k| "_#{k}" }.join}_links_resolve") do
      builder = BujoPdf::PdfDSL::PdfBuilder.new
      builder.build(BujoPdf::PdfDSL.recipes.fetch(name), year: YEAR, **extra)

      dead_week, other = builder.warnings.partition do |w|
        w.is_a?(BujoPdf::PdfDSL::Warnings::UnresolvedLink) && w.dest.match?(/\Aweek_\d+\z/)
      end

      assert_empty other.map(&:message)
      assert_equal KNOWN_DEAD_WEEK_LINKS.fetch(name, 0), dead_week.size
    end
  end
end
