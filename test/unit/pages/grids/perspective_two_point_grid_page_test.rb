# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../support/pdf_inspector'
require 'bujo_pdf/pdf_dsl'

class TestPerspectiveTwoPointGridPage < Minitest::Test
  def setup
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_page_has_registered_type
    assert_equal :grid_perspective_2, BujoPdf::Pages::Grids::PerspectiveTwoPointGridPage.page_type
  end

  def test_two_point_page_writes_its_destination
    pdf = PdfInspector.new(BujoPdf::PdfDSL.generate(year: 2026) { page :grid_perspective_2 })

    assert_equal 1, pdf.destinations['grid_perspective_2']
  end

  def test_two_point_page_is_titled
    pdf = PdfInspector.new(BujoPdf::PdfDSL.generate(year: 2026) { page :grid_perspective_2 })

    assert_includes pdf.text(1), 'Perspective Grid (2-point)'
  end
end
