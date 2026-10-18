#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/pdf_inspector'
require 'bujo_pdf/pdf_dsl'

class TestGridsIndex < Minitest::Test
  GRID_DESTS = %w[grid_dot grid_isometric grid_perspective grid_perspective_2 grid_graph grid_lined grid_hexagon].freeze

  def setup
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_page_has_registered_type
    assert_equal :grids_index, BujoPdf::Pages::GridsIndex.page_type
  end

  def test_every_tile_links_to_its_grid
    links = pdf.links(:grids_index).map(&:dest)

    GRID_DESTS.each { |dest| assert_includes links, dest }
  end

  def test_tiles_link_in_nav_order
    tiles = pdf.links(:grids_index).sort_by { |link| [-link.rect[3].round, link.rect[0]] }

    assert_equal GRID_DESTS, tiles.map(&:dest)
  end

  def test_tile_captions
    text = pdf.text(:grids_index)

    ['Grids', 'Dot', 'Isometric', '1-point perspective', '2-point perspective', 'Graph', 'Ruled', 'Hexagon']
      .each { |caption| assert_includes text, caption }
  end

  private

  def pdf
    @pdf ||= PdfInspector.new(
      BujoPdf::PdfDSL.generate(year: 2026) do
        page :grids_index
        %i[grid_dot grid_isometric grid_perspective grid_perspective_2 grid_graph grid_lined grid_hexagon]
          .each { |type| page type }
      end
    )
  end
end
