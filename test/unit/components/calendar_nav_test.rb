#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/pdf_inspector'
require 'bujo_pdf'
require 'bujo_pdf/pdf_dsl'
require 'bujo_pdf/pages/all'

# Grid pages stand in for calendar pages: they render recipe chrome, and
# the nav only cares about page ids.
class TestCalendarNav < Minitest::Test
  LEFT_EDGE_X = 40

  def setup
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_months_link_to_first_week
    assert_equal %w[grid_dot grid_lined], left_links(:grid_hexagon)
  end

  def test_current_month_lists_its_items_in_order
    # January, then its items w01 and w02 (w02 current, unlinked), then February
    assert_equal %w[grid_dot grid_dot grid_lined], left_links(:grid_graph)
  end

  def test_current_item_is_unlinked
    refute_includes left_links(:grid_graph), 'grid_graph'
  end

  def test_no_expansion_outside_the_calendar
    assert_equal 2, left_links(:grid_hexagon).size
  end

  def test_later_months_shift_down_below_the_expansion
    feb_outside = left_rects(:grid_hexagon).last
    feb_inside = left_rects(:grid_graph).last

    assert_operator feb_inside[3], :<, feb_outside[3], 'February sits lower when January is expanded'
  end

  private

  def pdf
    @pdf ||= PdfInspector.new(
      BujoPdf::PdfDSL.generate(year: 2026) do
        chrome { left :calendar_nav }
        nav_month 1, first_week: :grid_dot, items: [[:grid_dot, 'w01'], [:grid_graph, 'w02']]
        nav_month 2, first_week: :grid_lined, items: [[:grid_lined, 'w03']]
        %i[grid_dot grid_graph grid_lined grid_hexagon].each { |type| page type }
      end
    )
  end

  def left(page)
    pdf.links(page).select { |link| link.rect[0] < LEFT_EDGE_X }.sort_by { |link| -link.rect[3] }
  end

  def left_links(page) = left(page).map(&:dest)
  def left_rects(page) = left(page).map(&:rect)
end
