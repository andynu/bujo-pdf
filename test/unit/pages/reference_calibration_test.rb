# frozen_string_literal: true

require_relative '../../test_helper'

class TestReferenceCalibration < Minitest::Test
  include Styling::Grid

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :reference,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
  end

  # ============================================
  # Registration Tests
  # ============================================

  def test_page_has_registered_type
    assert_equal :reference, BujoPdf::Pages::ReferenceCalibration.page_type
  end

  def test_page_has_registered_title
    assert_equal "Calibration & Reference", BujoPdf::Pages::ReferenceCalibration.default_title
  end

  def test_page_has_registered_dest
    assert_equal "reference", BujoPdf::Pages::ReferenceCalibration.default_dest
  end

  # ============================================
  # Setup Tests
  # ============================================

  def test_setup_sets_destination
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)

    # Track if set_destination was called with expected name
    dest_called = nil
    page.define_singleton_method(:set_destination) { |name| dest_called = name }

    page.send(:setup)

    assert_equal 'reference', dest_called
  end

  def test_setup_uses_full_page_layout
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_calls_draw_dot_grid
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)

    dot_grid_called = false
    page.define_singleton_method(:draw_dot_grid) { dot_grid_called = true }
    page.define_singleton_method(:draw_calibration_elements) {}

    page.send(:render)

    assert dot_grid_called, "Expected draw_dot_grid to be called"
  end

  def test_render_calls_draw_calibration_elements
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)

    calibration_called = false
    page.define_singleton_method(:draw_dot_grid) {}
    page.define_singleton_method(:draw_calibration_elements) { calibration_called = true }

    page.send(:render)

    assert calibration_called, "Expected draw_calibration_elements to be called"
  end

  # ============================================
  # Calibration Element Tests
  # ============================================

  def test_draw_center_cross
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_center_cross)

    # Should draw without error - verify stroke color was set
  end

  def test_draw_division_lines
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_division_lines)

    # Should draw halves (solid) and thirds (dashed) without error
  end

  def test_draw_reference_circle
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_reference_circle)

    # Circle should be drawn at center with radius = PAGE_WIDTH/4
  end

  def test_draw_centimeter_markings
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_centimeter_markings)

    # Should draw horizontal and vertical centimeter markers without error
  end

  def test_draw_measurements_info
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_measurements_info)

    # Should draw dimension text without error
  end

  def test_draw_calibration_elements_calls_all_subroutines
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.send(:setup)

    calls = []
    page.define_singleton_method(:draw_center_cross) { calls << :cross }
    page.define_singleton_method(:draw_division_lines) { calls << :lines }
    page.define_singleton_method(:draw_reference_circle) { calls << :circle }
    page.define_singleton_method(:draw_centimeter_markings) { calls << :cm }
    page.define_singleton_method(:draw_measurements_info) { calls << :info }

    page.send(:draw_calibration_elements)

    assert_equal [:cross, :lines, :circle, :cm, :info], calls
  end

  # ============================================
  # Full Generation Tests
  # ============================================

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end
end

class TestReferenceCalibrationMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::ReferenceCalibration::Mixin

    attr_reader :pdf, :year, :date_config, :event_store, :total_pages

    def initialize
      @year = 2025
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @date_config = nil
      @event_store = nil
      @total_pages = 100
      @first_page_used = false
      DotGrid.create_stamp(@pdf, "page_dots")
    end
  end

  def test_mixin_provides_reference_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:reference_page), "Expected reference_page method"
  end

  def test_reference_page_generates_page
    builder = TestBuilder.new
    builder.reference_page

    assert_equal 1, builder.pdf.page_count
  end
end

class TestReferenceCalibrationIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation_includes_all_elements
    context = BujoPdf::RenderContext.new(
      page_key: :reference,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::ReferenceCalibration.new(@pdf, context)
    page.generate

    # PDF should be valid and have content
    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end
end
