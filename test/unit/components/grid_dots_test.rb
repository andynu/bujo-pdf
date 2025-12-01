#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestGridDots < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_initialize_with_required_params
    dots = BujoPdf::Components::GridDots.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5
    )
    dots.render
  end

  def test_initialize_with_custom_color
    dots = BujoPdf::Components::GridDots.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      color: 'FF0000'
    )
    dots.render
  end

  def test_render_draws_circles
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    dots = BujoPdf::Components::GridDots.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 2,
      height: 2
    )
    dots.render

    # Width=2, height=2 means 3 dots wide × 3 dots tall = 9 circles
    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }
    assert_equal 9, fill_circle_calls.length
  end

  def test_render_sets_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    dots = BujoPdf::Components::GridDots.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 2,
      height: 2,
      color: 'FF0000'
    )
    dots.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :fill_color }
    colors = color_calls.map { |c| c[:args][0] }

    assert colors.include?('FF0000'), "Expected custom color to be set"
    assert colors.last == '000000', "Expected color reset to black"
  end

  def test_render_uses_default_color
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    dots = BujoPdf::Components::GridDots.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 2,
      height: 2
    )
    dots.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :fill_color }
    # First call should be the default dot grid color
    default_color = Styling::Colors.DOT_GRID
    assert_equal default_color, color_calls.first[:args][0]
  end

  def test_render_with_real_prawn_document
    dots = BujoPdf::Components::GridDots.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5
    )
    dots.render

    assert_kind_of Prawn::Document, @pdf
  end
end

class TestGridDotsMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::GridDots::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::GridDots::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_grid_dots_method
    component = TestComponent.new
    assert component.respond_to?(:grid_dots), "Expected grid_dots method"
  end

  def test_mixin_grid_dots_with_defaults
    component = TestComponent.new
    component.grid_dots(5, 10, 10, 5)
  end

  def test_mixin_grid_dots_with_color
    component = TestComponent.new
    component.grid_dots(5, 10, 10, 5, color: 'FF0000')
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.grid_dots(5, 10, 10, 5)
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestGridDotsEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_single_dot
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    dots = BujoPdf::Components::GridDots.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 0,
      height: 0
    )
    dots.render

    # Should draw exactly 1 dot
    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }
    assert_equal 1, fill_circle_calls.length
  end

  def test_single_row
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    dots = BujoPdf::Components::GridDots.new(
      canvas: canvas,
      col: 0,
      row: 0,
      width: 5,
      height: 0
    )
    dots.render

    # Should draw 6 dots (0 through 5)
    fill_circle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_circle }
    assert_equal 6, fill_circle_calls.length
  end

  def test_at_origin
    dots = BujoPdf::Components::GridDots.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 5,
      height: 5
    )
    dots.render
  end

  def test_at_edge
    dots = BujoPdf::Components::GridDots.new(
      canvas: @canvas,
      col: 40,
      row: 50,
      width: 2,
      height: 4
    )
    dots.render
  end

  def test_full_page
    dots = BujoPdf::Components::GridDots.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 42,
      height: 54
    )
    dots.render
  end
end
