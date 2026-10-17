# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/pdf_assertions'
require 'bujo_pdf/pdf_dsl'

# Navigation of the standard planner, read back from the rendered PDF.
# The planner is generated once for the whole class.
class TestPlannerNavigation < Minitest::Test
  include PdfAssertions

  YEAR = 2025

  TAB_DESTINATIONS = %i[seasonal index_1 future_log_1 year_events year_highlights multi_year grid_showcase].freeze

  def self.planner
    @planner ||= begin
      BujoPdf::PdfDSL.load_recipes!
      PdfInspector.new(BujoPdf::PdfDSL.generate(:standard_planner, year: YEAR))
    end
  end

  def pdf = self.class.planner
  def total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(YEAR)

  def test_every_link_lands_on_a_declared_destination
    assert_links_resolve pdf
  end

  def test_every_week_has_a_destination_on_a_page_showing_that_week
    (1..total_weeks).each do |week|
      assert_pdf_text_on_page pdf, :"week_#{week}", "Week #{week}:"
    end
  end

  def test_each_week_links_to_its_neighbours_but_not_to_itself
    (1..total_weeks).each do |week|
      from = :"week_#{week}"
      assert_link pdf, from_page: from, to: :"week_#{week - 1}" if week > 1
      assert_link pdf, from_page: from, to: :"week_#{week + 1}" if week < total_weeks
      refute_link pdf, from_page: from, to: from
    end
  end

  def test_weekly_pages_carry_every_tab
    TAB_DESTINATIONS.each do |dest|
      assert_link pdf, from_page: :week_10, to: dest
    end
  end

  def test_front_matter_comes_first
    assert_destination pdf, :seasonal, page: 1
    assert_destination pdf, :index_1, page: 2
    assert_destination pdf, :index_2, page: 3
  end

  def test_outline_top_level
    months = Date::MONTHNAMES.compact.map { |month| "#{month} #{YEAR}" }
    collections = BujoPdf::CollectionsConfiguration.load.map(&:title)

    assert_outline pdf, [
      'Seasonal Calendar', 'Index', 'Future Log', 'Events', 'Highlights', 'Multi-Year Overview',
      'Quarterly Planning', 'Monthly Reviews', *months, 'Grid Types Showcase',
      'Tracker Ideas', 'Calibration & Reference', 'Daily Wheel', 'Year Wheel', *collections
    ], depth: 1
  end

  def test_month_entries_open_on_the_first_week_of_the_month
    january = pdf.outline.find { |item| item.title == "January #{YEAR}" }

    assert_equal pdf.page_number(:week_1), january.page
  end
end
