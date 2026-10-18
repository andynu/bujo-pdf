# frozen_string_literal: true

require_relative '../../../test_helper'
require 'bujo_pdf/pdf_dsl'
require 'pdf/reader'

# A grid is the page's background: chrome drawn before it would be painted over.
class TestGridNavOrder < Minitest::Test
  GRID_PAGES = %i[grid_dot grid_graph grid_lined grid_isometric grid_perspective grid_perspective_2 grid_hexagon].freeze

  def setup
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_grid_is_drawn_before_the_nav
    pdf = BujoPdf::PdfDSL.generate(year: 2026) do
      chrome { right :section_nav }
      nav_section :grids, label: 'Grids', items: GRID_PAGES.map { |id| [id, id.to_s] }
      GRID_PAGES.each { |type| page type }
    end
    reader = PDF::Reader.new(StringIO.new(pdf.render))

    GRID_PAGES.each_with_index do |type, index|
      content = reader.pages[index].raw_content
      # The last stamp is the grid (a dot background, if any, comes first).
      # Prawn writes text as hex and may kern "Gr", splitting the string, so
      # match the start of the tab label "Grids" (<4772...). Page titles also
      # start "Gr" but are drawn after chrome, so the first match is the nav.
      stamp_at = content.rindex(/\/Stamp\d+ Do/)
      nav_text_at = content.index('<4772')

      refute_nil stamp_at, "#{type}: grid stamp drawn"
      refute_nil nav_text_at, "#{type}: nav drawn"
      assert_operator stamp_at, :<, nav_text_at, "#{type}: grid must be drawn before the nav"
    end
  end
end
