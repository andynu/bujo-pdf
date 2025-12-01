#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestGridRuler < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_initialize_with_defaults
    ruler = BujoPdf::Components::GridRuler.new(canvas: @canvas)
    ruler.render
  end

  def test_initialize_with_custom_font_size
    ruler = BujoPdf::Components::GridRuler.new(
      canvas: @canvas,
      font_size: 8
    )
    ruler.render
  end

  def test_initialize_with_custom_color
    ruler = BujoPdf::Components::GridRuler.new(
      canvas: @canvas,
      color: '00FF00'
    )
    ruler.render
  end

  def test_initialize_with_all_options
    ruler = BujoPdf::Components::GridRuler.new(
      canvas: @canvas,
      font_size: 10,
      color: 'AABBCC'
    )
    ruler.render
  end

  def test_default_constants
    assert_equal 6, BujoPdf::Components::GridRuler::FONT_SIZE
    assert_equal 'FF0000', BujoPdf::Components::GridRuler::COLOR
    assert_equal '0000FF', BujoPdf::Components::GridRuler::DIVISION_COLOR
  end

  def test_render_calls_all_render_methods
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(canvas: canvas)
    ruler.render

    # Should set colors
    assert mock_pdf.called?(:fill_color), "Expected fill_color to be called"

    # Should draw text boxes for column and row numbers
    assert mock_pdf.called?(:text_box), "Expected text_box to be called"

    # Should draw circles for division markers
    assert mock_pdf.called?(:fill_circle), "Expected fill_circle to be called"
  end

  def test_render_columns_draws_column_numbers
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(canvas: canvas)
    ruler.render_columns

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }

    # Should draw one text box per column
    # Grid has 43 columns
    assert_equal grid.cols, text_box_calls.length, "Expected #{grid.cols} column labels"

    # Check that column numbers are present
    texts = text_box_calls.map { |c| c[:args][0] }
    assert texts.include?('0'), "Expected column 0 label"
    assert texts.include?('21'), "Expected column 21 label"
    assert texts.include?('42'), "Expected column 42 label"
  end

  def test_render_rows_draws_row_numbers
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(canvas: canvas)
    ruler.render_rows

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }

    # Should draw one text box per row
    # Grid has 55 rows
    assert_equal grid.rows, text_box_calls.length, "Expected #{grid.rows} row labels"

    # Check that row numbers are present
    texts = text_box_calls.map { |c| c[:args][0] }
    assert texts.include?('0'), "Expected row 0 label"
    assert texts.include?('27'), "Expected row 27 label"
    assert texts.include?('54'), "Expected row 54 label"
  end

  def test_render_division_markers_draws_circles
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(canvas: canvas)
    ruler.render_division_markers

    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }

    # Column divisions: 3 positions (1/3, 1/2, 2/3)
    # 1/3: 3 dots, 1/2: 2 dots, 2/3: 3 dots = 8 dots
    # Row divisions: same = 8 dots
    # Total: 16 dots
    assert_equal 16, fill_circle_calls.length, "Expected 16 division marker dots"
  end

  def test_render_sets_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(
      canvas: canvas,
      color: '00FF00'
    )
    ruler.render_columns

    color_calls = mock_pdf.calls.select { |c| c[:method] == :fill_color }
    colors = color_calls.map { |c| c[:args][0] }

    assert colors.include?('00FF00'), "Expected custom color to be used"
    assert colors.include?('000000'), "Expected color to be reset to black"
  end

  def test_render_division_markers_uses_blue_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(canvas: canvas)
    ruler.render_division_markers

    color_calls = mock_pdf.calls.select { |c| c[:method] == :fill_color }
    colors = color_calls.map { |c| c[:args][0] }

    assert colors.include?('0000FF'), "Expected blue color for division markers"
  end

  def test_render_columns_uses_font_size
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(
      canvas: canvas,
      font_size: 12
    )
    ruler.render_columns

    font_size_calls = mock_pdf.calls.select { |c| c[:method] == :font_size }
    sizes = font_size_calls.map { |c| c[:args][0] }

    assert sizes.include?(12), "Expected custom font size to be used"
  end

  def test_render_with_real_prawn_document
    ruler = BujoPdf::Components::GridRuler.new(canvas: @canvas)
    ruler.render

    assert_kind_of Prawn::Document, @pdf
  end

  def test_render_columns_only
    ruler = BujoPdf::Components::GridRuler.new(canvas: @canvas)
    ruler.render_columns
  end

  def test_render_rows_only
    ruler = BujoPdf::Components::GridRuler.new(canvas: @canvas)
    ruler.render_rows
  end

  def test_render_division_markers_only
    ruler = BujoPdf::Components::GridRuler.new(canvas: @canvas)
    ruler.render_division_markers
  end

  def test_draw_dots_vertical
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(canvas: canvas)
    ruler.send(:draw_dots_vertical, 100, 200, 3, 1.5)

    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }
    assert_equal 3, fill_circle_calls.length, "Expected 3 vertical dots"
  end

  def test_draw_dots_horizontal
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    ruler = BujoPdf::Components::GridRuler.new(canvas: canvas)
    ruler.send(:draw_dots_horizontal, 100, 200, 2, 1.5)

    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }
    assert_equal 2, fill_circle_calls.length, "Expected 2 horizontal dots"
  end
end
