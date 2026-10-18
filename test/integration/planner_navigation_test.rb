# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/pdf_assertions'
require 'bujo_pdf/pdf_dsl'

# Navigation of the standard planner, read back from the rendered PDF.
# The planner is generated once for the whole class.
class TestPlannerNavigation < Minitest::Test
  include PdfAssertions

  YEAR = 2025
  LEFT_EDGE_X = 40
  RIGHT_EDGE_X = 590

  SECTION_LANDINGS = %i[seasonal index_1 future_log_1 grids_index tracker_example].freeze

  def self.planner
    @planner ||= begin
      BujoPdf::PdfDSL.load_recipes!
      PdfInspector.new(BujoPdf::PdfDSL.generate(:standard_planner, year: YEAR))
    end
  end

  def self.declarations
    @declarations ||= begin
      BujoPdf::PdfDSL.load_recipes!
      context = BujoPdf::PdfDSL::DeclarationContext.new
      BujoPdf::PdfDSL.recipes[:standard_planner].evaluate(context, year: YEAR)
      context
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

  # The next week is always one tap: within a month it is listed, and across a
  # boundary it is the next month's first week. The previous week is one tap
  # except from a month's first week, where the collapsed previous month links
  # to its own first week.
  def test_each_week_links_to_its_neighbours_but_not_to_itself
    first_weeks = self.class.declarations.nav_months.map(&:first_week)

    (1..total_weeks).each do |week|
      from = :"week_#{week}"
      assert_link pdf, from_page: from, to: :"week_#{week - 1}" if week > 1 && !first_weeks.include?(from)
      assert_link pdf, from_page: from, to: :"week_#{week + 1}" if week < total_weeks
      refute_link pdf, from_page: from, to: from
    end
  end

  def test_weekly_pages_carry_every_section_tab
    SECTION_LANDINGS.each do |dest|
      assert_link pdf, from_page: :week_10, to: dest
    end
  end

  def test_every_section_item_links_from_every_page_in_its_section
    self.class.declarations.nav_sections.each do |section|
      ids = section.items.map(&:id)
      ids.each do |from|
        (ids - [from]).each { |to| assert_link pdf, from_page: from, to: to }
      end
    end
  end

  def test_months_link_to_their_first_week
    first_weeks = self.class.declarations.nav_months.map { |month| month.first_week.to_s }

    assert_equal first_weeks, left_links(:grid_dot)
  end

  def test_no_week_list_outside_the_calendar
    assert_equal 12, left_links(:tracker_example).size
  end

  # Its rulers run along the physical left edge, so the calendar nav would cover them
  def test_reference_page_keeps_its_left_ruler_clear
    assert_empty left_links(:reference)
    assert_link pdf, from_page: :reference, to: :tracker_example
  end

  def test_a_weekly_page_opens_its_month
    march = self.class.declarations.nav_months.find { |month| month.month == 3 }
    week = march.items.find { |item| item.id.to_s.start_with?('week_') }.id
    others = march.items.map(&:id).reject { |id| id == week }

    others.each { |id| assert_includes left_links(week), id.to_s }
  end

  # Checks the drawn text, not the declared label: a label too wide for its box gets clipped
  def test_review_label_is_drawn_whole
    assert_includes pdf.text(:review_3), 'Review'
  end

  def test_grids_index_opens_the_grids_section
    %i[grid_dot grid_isometric grid_perspective grid_perspective_2 grid_graph grid_lined grid_hexagon].each do |dest|
      assert_includes right_links(:grids_index), dest.to_s
    end
  end

  def test_front_matter_comes_first
    assert_destination pdf, :index_1, page: 1
    assert_destination pdf, :index_2, page: 2
    assert_destination pdf, :seasonal, page: 3
  end

  def test_outline_top_level
    months = Date::MONTHNAMES.compact.map { |month| "#{month} #{YEAR}" }
    collections = BujoPdf::CollectionsConfiguration.load.map(&:title)

    assert_outline pdf, [
      'Index', 'Seasonal Calendar', 'Events', 'Highlights', 'Multi-Year Overview', 'Future Log',
      'Quarterly Planning', 'Monthly Reviews', *months, 'Grids',
      'Tracker Ideas', 'Calibration & Reference', 'Daily Wheel', 'Year Wheel', *collections
    ], depth: 1
  end

  def test_month_entries_open_on_the_first_week_of_the_month
    january = pdf.outline.find { |item| item.title == "January #{YEAR}" }

    assert_equal pdf.page_number(:week_1), january.page
  end

  def test_zero_link_warnings_with_and_without_rituals
    [false, true].each do |rituals|
      builder = BujoPdf::PdfDSL::PdfBuilder.new
      builder.build(BujoPdf::PdfDSL.recipes[:standard_planner], year: YEAR, rituals: rituals)

      assert_empty builder.warnings.map(&:message), "rituals: #{rituals}"
    end
  end

  private

  def left_links(page)
    pdf.links(page).select { |link| link.rect[0] < LEFT_EDGE_X }.sort_by { |link| -link.rect[3] }.map(&:dest)
  end

  def right_links(page)
    pdf.links(page).select { |link| link.rect[0] > RIGHT_EDGE_X }.map(&:dest)
  end
end
