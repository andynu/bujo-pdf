# frozen_string_literal: true

require_relative '../../test_helper'

class TestHLine < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_required_params
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20
    )
    hline.render
  end

  def test_initialize_with_all_params
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      color: 'FF0000',
      stroke: 2.0
    )
    hline.render
  end

  def test_initialize_with_default_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20
    )
    hline.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert color_calls.any? { |c| c[:args][0] == 'CCCCCC' }, "Expected default color CCCCCC"
  end

  def test_initialize_with_default_stroke
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20
    )
    hline.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert line_width_calls.any? { |c| c[:args][0] == 0.5 }, "Expected default stroke 0.5"
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_draws_horizontal_line
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20
    )
    hline.render

    assert mock_pdf.called?(:stroke_line), "Expected stroke_line to be called"
  end

  def test_render_sets_custom_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20,
      color: 'FF0000'
    )
    hline.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert color_calls.any? { |c| c[:args][0] == 'FF0000' }, "Expected color FF0000"
  end

  def test_render_sets_custom_stroke_width
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20,
      stroke: 2.0
    )
    hline.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert line_width_calls.any? { |c| c[:args][0] == 2.0 }, "Expected stroke width 2.0"
  end

  def test_render_resets_color_to_black
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20,
      color: 'FF0000'
    )
    hline.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert_equal '000000', color_calls.last[:args][0], "Expected final color reset to black"
  end

  def test_render_resets_line_width_to_default
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20,
      stroke: 2.0
    )
    hline.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert_equal 0.5, line_width_calls.last[:args][0], "Expected final line width reset to 0.5"
  end

  # ============================================
  # On-Grid Dot Erasure Tests
  # ============================================

  def test_render_erases_dots_for_integer_coordinates
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20
    )
    hline.render

    # EraseDots draws filled circles to cover dots
    assert mock_pdf.called?(:fill_circle), "Expected dot erasure via fill_circle"
  end

  def test_render_skips_dot_erasure_for_float_col
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5.5,
      row: 10,
      width: 20
    )
    hline.render

    refute mock_pdf.called?(:fill_circle), "Did not expect dot erasure for float column"
  end

  def test_render_skips_dot_erasure_for_float_row
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10.5,
      width: 20
    )
    hline.render

    refute mock_pdf.called?(:fill_circle), "Did not expect dot erasure for float row"
  end

  def test_render_skips_dot_erasure_for_float_width
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20.5
    )
    hline.render

    refute mock_pdf.called?(:fill_circle), "Did not expect dot erasure for float width"
  end

  def test_render_skips_dot_erasure_for_all_float_coords
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5.25,
      row: 10.5,
      width: 20.75
    )
    hline.render

    refute mock_pdf.called?(:fill_circle), "Did not expect dot erasure for all float coordinates"
  end

  # ============================================
  # Real Prawn Document Tests
  # ============================================

  def test_render_with_real_prawn_document
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      color: 'FF0000',
      stroke: 1.5
    )
    hline.render

    assert_kind_of Prawn::Document, @pdf
  end
end

class TestHLineMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::HLine::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::HLine::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_hline_method
    component = TestComponent.new
    assert component.respond_to?(:hline), "Expected hline method"
  end

  def test_mixin_hline_with_defaults
    component = TestComponent.new
    component.hline(5, 10, 20)
  end

  def test_mixin_hline_with_options
    component = TestComponent.new
    component.hline(5, 10, 20, color: 'FF0000', stroke: 2.0)
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.hline(5, 10, 20)
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestHLineEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_zero_width_line
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 0
    )
    hline.render
  end

  def test_single_unit_width_line
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 1
    )
    hline.render
  end

  def test_full_page_width_line
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 0,
      row: 10,
      width: 43
    )
    hline.render
  end

  def test_top_row_line
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 0,
      width: 20
    )
    hline.render
  end

  def test_bottom_row_line
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 54,
      width: 20
    )
    hline.render
  end

  def test_fractional_coordinates_near_integers
    # 5.0 should be treated as integer
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    hline = BujoPdf::Components::HLine.new(
      canvas: canvas,
      col: 5.0,
      row: 10.0,
      width: 20.0
    )
    hline.render

    # 5.0 == 5.0.to_i is true, so dots should be erased
    assert mock_pdf.called?(:fill_circle), "Expected dot erasure for integer-equivalent floats"
  end

  def test_very_thin_stroke
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      stroke: 0.1
    )
    hline.render
  end

  def test_thick_stroke
    hline = BujoPdf::Components::HLine.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      stroke: 5.0
    )
    hline.render
  end
end
