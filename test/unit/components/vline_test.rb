# frozen_string_literal: true

require_relative '../../test_helper'

class TestVLine < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_required_params
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 10,
      row: 5,
      height: 20
    )
    vline.render
  end

  def test_initialize_with_all_params
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 10,
      row: 5,
      height: 20,
      color: 'FF0000',
      stroke: 2.0
    )
    vline.render
  end

  def test_initialize_with_default_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20
    )
    vline.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert color_calls.any? { |c| c[:args][0] == 'CCCCCC' }, "Expected default color CCCCCC"
  end

  def test_initialize_with_default_stroke
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20
    )
    vline.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert line_width_calls.any? { |c| c[:args][0] == 0.5 }, "Expected default stroke 0.5"
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_draws_vertical_line
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20
    )
    vline.render

    assert mock_pdf.called?(:stroke_line), "Expected stroke_line to be called"
  end

  def test_render_sets_custom_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20,
      color: 'FF0000'
    )
    vline.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert color_calls.any? { |c| c[:args][0] == 'FF0000' }, "Expected color FF0000"
  end

  def test_render_sets_custom_stroke_width
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20,
      stroke: 2.0
    )
    vline.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert line_width_calls.any? { |c| c[:args][0] == 2.0 }, "Expected stroke width 2.0"
  end

  def test_render_resets_color_to_black
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20,
      color: 'FF0000'
    )
    vline.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert_equal '000000', color_calls.last[:args][0], "Expected final color reset to black"
  end

  def test_render_resets_line_width_to_default
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20,
      stroke: 2.0
    )
    vline.render

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

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20
    )
    vline.render

    # EraseDots draws filled circles to cover dots
    assert mock_pdf.called?(:fill_circle), "Expected dot erasure via fill_circle"
  end

  def test_render_skips_dot_erasure_for_float_col
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10.5,
      row: 5,
      height: 20
    )
    vline.render

    refute mock_pdf.called?(:fill_circle), "Did not expect dot erasure for float column"
  end

  def test_render_skips_dot_erasure_for_float_row
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5.5,
      height: 20
    )
    vline.render

    refute mock_pdf.called?(:fill_circle), "Did not expect dot erasure for float row"
  end

  def test_render_skips_dot_erasure_for_float_height
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10,
      row: 5,
      height: 20.5
    )
    vline.render

    refute mock_pdf.called?(:fill_circle), "Did not expect dot erasure for float height"
  end

  def test_render_skips_dot_erasure_for_all_float_coords
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10.25,
      row: 5.5,
      height: 20.75
    )
    vline.render

    refute mock_pdf.called?(:fill_circle), "Did not expect dot erasure for all float coordinates"
  end

  # ============================================
  # Real Prawn Document Tests
  # ============================================

  def test_render_with_real_prawn_document
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 10,
      row: 5,
      height: 20,
      color: 'FF0000',
      stroke: 1.5
    )
    vline.render

    assert_kind_of Prawn::Document, @pdf
  end
end

class TestVLineMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::VLine::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::VLine::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_vline_method
    component = TestComponent.new
    assert component.respond_to?(:vline), "Expected vline method"
  end

  def test_mixin_vline_with_defaults
    component = TestComponent.new
    component.vline(10, 5, 20)
  end

  def test_mixin_vline_with_options
    component = TestComponent.new
    component.vline(10, 5, 20, color: 'FF0000', stroke: 2.0)
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.vline(10, 5, 20)
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestVLineEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_zero_height_line
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 10,
      row: 5,
      height: 0
    )
    vline.render
  end

  def test_single_unit_height_line
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 10,
      row: 5,
      height: 1
    )
    vline.render
  end

  def test_full_page_height_line
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 10,
      row: 0,
      height: 55
    )
    vline.render
  end

  def test_leftmost_column_line
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 0,
      row: 5,
      height: 20
    )
    vline.render
  end

  def test_rightmost_column_line
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 42,
      row: 5,
      height: 20
    )
    vline.render
  end

  def test_fractional_coordinates_near_integers
    # 10.0 should be treated as integer
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    vline = BujoPdf::Components::VLine.new(
      canvas: canvas,
      col: 10.0,
      row: 5.0,
      height: 20.0
    )
    vline.render

    # 10.0 == 10.0.to_i is true, so dots should be erased
    assert mock_pdf.called?(:fill_circle), "Expected dot erasure for integer-equivalent floats"
  end

  def test_very_thin_stroke
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 10,
      row: 5,
      height: 20,
      stroke: 0.1
    )
    vline.render
  end

  def test_thick_stroke
    vline = BujoPdf::Components::VLine.new(
      canvas: @canvas,
      col: 10,
      row: 5,
      height: 20,
      stroke: 5.0
    )
    vline.render
  end
end
