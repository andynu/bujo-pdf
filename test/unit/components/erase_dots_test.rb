#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestEraseDots < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_initialize_with_required_params
    eraser = BujoPdf::Components::EraseDots.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10
    )
    eraser.render
  end

  def test_initialize_with_height
    eraser = BujoPdf::Components::EraseDots.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 3
    )
    eraser.render
  end

  def test_render_draws_circles
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    eraser = BujoPdf::Components::EraseDots.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 3
    )
    eraser.render

    # Should draw circles to cover dots
    assert mock_pdf.called?(:fill_circle), "Expected circles to be drawn"

    # For width=3 and height=0, should draw 4 circles (5, 6, 7, 8) = 4 dots
    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }
    assert_equal 4, fill_circle_calls.length
  end

  def test_render_draws_multiple_rows
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    eraser = BujoPdf::Components::EraseDots.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 2,
      height: 2
    )
    eraser.render

    # Width=2, height=2 means 3 dots wide × 3 dots tall = 9 circles
    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }
    assert_equal 9, fill_circle_calls.length
  end

  def test_render_sets_background_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    eraser = BujoPdf::Components::EraseDots.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 2
    )
    eraser.render

    # Should set fill color to background color
    assert mock_pdf.called?(:fill_color), "Expected fill_color to be set"

    color_calls = mock_pdf.calls.select { |c| c[:method] == :fill_color }
    # First call sets background, last call resets to black
    assert color_calls.last[:args][0] == '000000', "Expected color reset to black"
  end

  def test_render_with_real_prawn_document
    eraser = BujoPdf::Components::EraseDots.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5
    )
    eraser.render

    assert_kind_of Prawn::Document, @pdf
  end

  def test_single_dot_erase
    eraser = BujoPdf::Components::EraseDots.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 0,
      height: 0
    )
    eraser.render
  end

  def test_zero_height_erases_single_row
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    eraser = BujoPdf::Components::EraseDots.new(
      canvas: canvas,
      col: 0,
      row: 0,
      width: 5,
      height: 0
    )
    eraser.render

    # Should erase 6 dots (0 through 5)
    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }
    assert_equal 6, fill_circle_calls.length
  end
end

class TestEraseDotsMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::EraseDots::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::EraseDots::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_erase_dots_method
    component = TestComponent.new
    assert component.respond_to?(:erase_dots), "Expected erase_dots method"
  end

  def test_mixin_erase_dots_with_defaults
    component = TestComponent.new
    component.erase_dots(5, 10, 10)
  end

  def test_mixin_erase_dots_with_height
    component = TestComponent.new
    component.erase_dots(5, 10, 10, 5)
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.erase_dots(5, 10, 10)
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestEraseDotsEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_erase_at_origin
    eraser = BujoPdf::Components::EraseDots.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 5,
      height: 5
    )
    eraser.render
  end

  def test_erase_at_edge
    eraser = BujoPdf::Components::EraseDots.new(
      canvas: @canvas,
      col: 40,
      row: 50,
      width: 2,
      height: 4
    )
    eraser.render
  end

  def test_erase_full_width
    eraser = BujoPdf::Components::EraseDots.new(
      canvas: @canvas,
      col: 0,
      row: 10,
      width: 42
    )
    eraser.render
  end

  def test_erase_full_height
    eraser = BujoPdf::Components::EraseDots.new(
      canvas: @canvas,
      col: 10,
      row: 0,
      width: 5,
      height: 54
    )
    eraser.render
  end
end
