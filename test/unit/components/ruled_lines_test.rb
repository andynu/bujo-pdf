# frozen_string_literal: true

require_relative '../../test_helper'

class TestRuledLines < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_required_params
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10
    )
    ruled.render
  end

  def test_initialize_with_all_params
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10,
      color: 'CCCCCC',
      stroke: 1.0
    )
    ruled.render
  end

  def test_initialize_with_default_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10
    )
    ruled.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert color_calls.any? { |c| c[:args][0] == 'E5E5E5' }, "Expected default color E5E5E5"
  end

  def test_initialize_with_default_stroke
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10
    )
    ruled.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert line_width_calls.any? { |c| c[:args][0] == 0.5 }, "Expected default stroke 0.5"
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_draws_lines
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10
    )
    ruled.render

    assert mock_pdf.called?(:stroke_line), "Expected stroke_line to be called"
  end

  def test_render_draws_correct_number_of_lines
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10
    )
    ruled.render

    line_count = mock_pdf.call_count(:stroke_line)
    assert_equal 10, line_count, "Expected 10 lines for height: 10"
  end

  def test_render_redraws_dots_on_top
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10
    )
    ruled.render

    # GridDots draws filled circles for dots
    assert mock_pdf.called?(:fill_circle), "Expected dots to be redrawn via fill_circle"
  end

  def test_render_sets_custom_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10,
      color: 'CCCCCC'
    )
    ruled.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert color_calls.any? { |c| c[:args][0] == 'CCCCCC' }, "Expected color CCCCCC"
  end

  def test_render_sets_custom_stroke_width
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10,
      stroke: 1.5
    )
    ruled.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert line_width_calls.any? { |c| c[:args][0] == 1.5 }, "Expected stroke width 1.5"
  end

  def test_render_resets_color_to_black
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10,
      color: 'CCCCCC'
    )
    ruled.render

    stroke_color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    # Find the last stroke_color call that sets to black (reset)
    assert stroke_color_calls.any? { |c| c[:args][0] == '000000' }, "Expected color reset to black"
  end

  def test_render_resets_line_width_to_default
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10,
      stroke: 2.0
    )
    ruled.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert line_width_calls.any? { |c| c[:args][0] == 0.5 }, "Expected line width reset to 0.5"
  end

  # ============================================
  # Real Prawn Document Tests
  # ============================================

  def test_render_with_real_prawn_document
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10,
      color: 'CCCCCC',
      stroke: 1.0
    )
    ruled.render

    assert_kind_of Prawn::Document, @pdf
  end
end

class TestRuledLinesMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::RuledLines::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::RuledLines::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_ruled_lines_method
    component = TestComponent.new
    assert component.respond_to?(:ruled_lines), "Expected ruled_lines method"
  end

  def test_mixin_ruled_lines_with_defaults
    component = TestComponent.new
    component.ruled_lines(2, 5, 20, 10)
  end

  def test_mixin_ruled_lines_with_options
    component = TestComponent.new
    component.ruled_lines(2, 5, 20, 10, color: 'CCCCCC', stroke: 1.0)
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.ruled_lines(2, 5, 20, 10)
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestRuledLinesEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_zero_height
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 0
    )
    ruled.render

    # Should draw no lines for height 0
    assert_equal 0, mock_pdf.call_count(:stroke_line), "Expected no lines for height: 0"
  end

  def test_single_line
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruled = BujoPdf::Components::RuledLines.new(
      canvas: canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 1
    )
    ruled.render

    assert_equal 1, mock_pdf.call_count(:stroke_line), "Expected 1 line for height: 1"
  end

  def test_full_page_width
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 0,
      row: 5,
      width: 43,
      height: 10
    )
    ruled.render
  end

  def test_full_page_height
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 2,
      row: 0,
      width: 20,
      height: 55
    )
    ruled.render
  end

  def test_starting_at_origin
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 20,
      height: 10
    )
    ruled.render
  end

  def test_narrow_width
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 10,
      row: 5,
      width: 1,
      height: 10
    )
    ruled.render
  end

  def test_very_thin_stroke
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10,
      stroke: 0.1
    )
    ruled.render
  end

  def test_thick_stroke
    ruled = BujoPdf::Components::RuledLines.new(
      canvas: @canvas,
      col: 2,
      row: 5,
      width: 20,
      height: 10,
      stroke: 3.0
    )
    ruled.render
  end
end
