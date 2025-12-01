#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestBox < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_initialize_with_required_params
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5
    )
    box.render
  end

  def test_initialize_with_all_params
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      stroke: 'FF0000',
      stroke_width: 1.0,
      fill: 'EEEEEE',
      radius: 3,
      opacity: 0.5
    )
    box.render
  end

  def test_render_stroked_box
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5
    )
    box.render

    assert mock_pdf.called?(:stroke_rectangle), "Expected stroked rectangle"
    refute mock_pdf.called?(:fill_rectangle), "Did not expect fill for default box"
  end

  def test_render_filled_box
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      fill: 'EEEEEE',
      stroke: nil
    )
    box.render

    assert mock_pdf.called?(:fill_rectangle), "Expected filled rectangle"
    refute mock_pdf.called?(:stroke_rectangle), "Did not expect stroke when nil"
  end

  def test_render_box_with_both_stroke_and_fill
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      fill: 'EEEEEE',
      stroke: 'FF0000'
    )
    box.render

    assert mock_pdf.called?(:fill_rectangle), "Expected filled rectangle"
    assert mock_pdf.called?(:stroke_rectangle), "Expected stroked rectangle"
  end

  def test_render_rounded_box_stroke
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      radius: 3
    )
    box.render

    assert mock_pdf.called?(:stroke_rounded_rectangle), "Expected rounded stroked rectangle"
  end

  def test_render_rounded_box_fill
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      fill: 'EEEEEE',
      stroke: nil,
      radius: 3
    )
    box.render

    assert mock_pdf.called?(:fill_rounded_rectangle), "Expected rounded filled rectangle"
  end

  def test_render_with_opacity
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      opacity: 0.5
    )
    box.render

    assert mock_pdf.called?(:transparent), "Expected transparent call for opacity < 1"
  end

  def test_render_without_opacity
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      opacity: 1.0
    )
    box.render

    refute mock_pdf.called?(:transparent), "Did not expect transparent call for full opacity"
  end

  def test_render_sets_colors
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      stroke: 'FF0000',
      fill: 'EEEEEE'
    )
    box.render

    color_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color || c[:method] == :fill_color }
    stroke_colors = mock_pdf.calls.select { |c| c[:method] == :stroke_color }.map { |c| c[:args][0] }
    fill_colors = mock_pdf.calls.select { |c| c[:method] == :fill_color }.map { |c| c[:args][0] }

    assert stroke_colors.include?('FF0000'), "Expected stroke color FF0000"
    assert fill_colors.include?('EEEEEE'), "Expected fill color EEEEEE"
  end

  def test_render_sets_line_width
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      stroke_width: 2.0
    )
    box.render

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    widths = line_width_calls.map { |c| c[:args][0] }

    assert widths.include?(2.0), "Expected line width 2.0"
  end

  def test_render_resets_defaults
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    box = BujoPdf::Components::Box.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      stroke: 'FF0000'
    )
    box.render

    # Should reset to black and default line width at end
    stroke_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_color }
    assert stroke_calls.last[:args][0] == '000000', "Expected final stroke color reset to black"

    line_width_calls = mock_pdf.calls.select { |c| c[:method] == :line_width }
    assert_equal 0.5, line_width_calls.last[:args][0], "Expected final line width reset to 0.5"
  end

  def test_render_with_real_prawn_document
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      stroke: 'FF0000',
      fill: 'EEEEEE',
      radius: 2,
      opacity: 0.8
    )
    box.render

    assert_kind_of Prawn::Document, @pdf
  end
end

class TestBoxMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::Box::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::Box::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_box_method
    component = TestComponent.new
    assert component.respond_to?(:box), "Expected box method"
  end

  def test_mixin_box_with_defaults
    component = TestComponent.new
    component.box(5, 10, 10, 5)
  end

  def test_mixin_box_with_options
    component = TestComponent.new
    component.box(5, 10, 10, 5,
                  stroke: 'FF0000',
                  fill: 'EEEEEE',
                  radius: 2,
                  opacity: 0.5)
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.box(5, 10, 10, 5)
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestBoxEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_zero_radius
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      radius: 0
    )
    box.render
  end

  def test_small_box
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 1,
      height: 1
    )
    box.render
  end

  def test_large_box
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 43,
      height: 55
    )
    box.render
  end

  def test_full_opacity
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      opacity: 1.0
    )
    box.render
  end

  def test_very_low_opacity
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 10,
      height: 5,
      opacity: 0.1
    )
    box.render
  end

  def test_fractional_dimensions
    box = BujoPdf::Components::Box.new(
      canvas: @canvas,
      col: 5.5,
      row: 10.5,
      width: 10.25,
      height: 5.75
    )
    box.render
  end
end
