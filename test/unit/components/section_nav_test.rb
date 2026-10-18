#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/pdf_inspector'
require 'bujo_pdf'
require 'bujo_pdf/pdf_dsl'
require 'bujo_pdf/pages/all'

class TestSectionNav < Minitest::Test
  RIGHT_EDGE_X = 590

  def setup
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_collapsed_tabs_link_to_landing_pages
    assert_equal %w[grid_dot grid_lined], right_links(standard_pdf, :grid_isometric)
  end

  def test_current_section_lists_every_item
    # On its landing page the tab is current, so grid_dot is not linked at all
    assert_equal %w[grid_graph grid_lined], right_links(standard_pdf, :grid_dot)
  end

  def test_other_sections_stay_collapsed
    refute_includes right_links(standard_pdf, :grid_dot), 'grid_hexagon'
  end

  # A landing page outside the item list (like the grids index) still opens its section
  def test_landing_page_expands_its_section
    pdf = PdfInspector.new(build_pdf(sections: [[:a, [[:grid_dot, 'Dot'], [:grid_graph, 'Graph']], :grid_hexagon]],
                                     pages: %i[grid_hexagon grid_dot grid_graph]))

    assert_equal %w[grid_dot grid_graph], right_links(pdf, :grid_hexagon)
  end

  def test_section_tab_is_current_only_on_landing
    links = right_links(standard_pdf, :grid_graph)

    assert_equal %w[grid_dot grid_dot grid_lined], links, 'tab and first item both link to the landing page'
  end

  def test_items_run_top_to_bottom_in_declaration_order
    pdf = PdfInspector.new(build_pdf(sections: [[:a, [[:grid_dot, 'Dot'], [:grid_graph, 'Graph'], [:grid_lined, 'Ruled']], nil]],
                                     pages: %i[grid_dot grid_graph grid_lined]))

    # The tab, then the items in order, with the current item (grid_lined) unlinked
    assert_equal %w[grid_dot grid_dot grid_graph], right_links(pdf, :grid_lined)
  end

  def test_overflow_raises_naming_the_section
    items = [[:grid_dot, 'Dot']] + (1..30).map { |i| [:"filler_#{i}", "Filler page #{i}"] }

    error = assert_raises(ArgumentError) do
      build_pdf(sections: [[:big, items, nil]], pages: %i[grid_dot])
    end
    assert_match(/:big/, error.message)
  end

  private

  # Section :a (grid_dot, grid_graph), section :b (grid_lined, grid_hexagon),
  # and grid_isometric in no section.
  def standard_pdf
    @standard_pdf ||= PdfInspector.new(
      build_pdf(sections: [[:a, [[:grid_dot, 'Dot'], [:grid_graph, 'Graph']], nil],
                           [:b, [[:grid_lined, 'Ruled'], [:grid_hexagon, 'Hex']], nil]],
                pages: %i[grid_dot grid_graph grid_lined grid_hexagon grid_isometric])
    )
  end

  def build_pdf(sections:, pages:)
    BujoPdf::PdfDSL.generate(year: 2026) do
      chrome { right :section_nav }
      sections.each do |key, items, landing|
        nav_section key, label: key.to_s.upcase, items: items, landing: landing
      end
      pages.each { |type| page type }
    end
  end

  def right_links(pdf, page)
    pdf.links(page).select { |link| link.rect[0] > RIGHT_EDGE_X }.sort_by { |link| -link.rect[3] }.map(&:dest)
  end
end
