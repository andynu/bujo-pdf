#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestLinkBox < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_initialize_with_required_params
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "w42",
      dest: "week_42"
    )
    link_box.render
  end

  def test_initialize_with_all_params
    # Using dimensions that work with rotated text (width/height suitable for rotation)
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 42,
      row: 0,
      width: 1,
      height: 4,
      text: "Year",
      dest: "seasonal",
      current: true,
      rotation: -90,
      font_size: 8,
      inset: 2,
      color: 'FF0000'
    )
    link_box.render
  end

  def test_render_non_current_box
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    link_box = BujoPdf::Components::LinkBox.new(
      canvas: canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "w42",
      dest: "week_42",
      current: false
    )
    link_box.render

    # Non-current: should use transparent call for 20% opacity fill
    # The MockPDF doesn't yield to transparent block, so fill_rounded_rectangle
    # won't be called - just verify transparent was invoked
    assert mock_pdf.called?(:transparent), "Expected transparent call for 20% opacity fill"
    refute mock_pdf.called?(:stroke_rounded_rectangle), "Did not expect stroked rectangle"
    # Should add link annotation
    assert mock_pdf.called?(:link_annotation), "Expected link annotation"
  end

  def test_render_current_box
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    link_box = BujoPdf::Components::LinkBox.new(
      canvas: canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "2025",
      dest: "seasonal",
      current: true
    )
    link_box.render

    # Current: should have stroked rounded rectangle (no fill)
    assert mock_pdf.called?(:stroke_rounded_rectangle), "Expected stroked rounded rectangle"
    # Should NOT add link annotation for current page
    refute mock_pdf.called?(:link_annotation), "Did not expect link annotation for current page"
  end

  def test_render_with_rotation
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    link_box = BujoPdf::Components::LinkBox.new(
      canvas: canvas,
      col: 42,
      row: 2,
      width: 1,
      height: 4,
      text: "Year",
      dest: "seasonal",
      rotation: -90
    )
    link_box.render

    # Should call rotate for rotated text
    assert mock_pdf.called?(:rotate), "Expected rotate call for vertical text"
  end

  def test_link_annotation_has_correct_destination
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    link_box = BujoPdf::Components::LinkBox.new(
      canvas: canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "w42",
      dest: "week_42"
    )
    link_box.render

    link_call = mock_pdf.last_call(:link_annotation)
    assert link_call, "Expected link_annotation call"
    assert_equal "week_42", link_call[:kwargs][:Dest], "Expected destination week_42"
  end

  def test_render_with_point_overrides
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "Test",
      dest: "test_dest",
      pt_x: 100.0,
      pt_y: 500.0,
      pt_width: 50.0,
      pt_height: 20.0
    )
    link_box.render
  end

  def test_render_with_real_prawn_document
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "w42",
      dest: "week_42",
      current: false,
      rotation: 0,
      font_size: 8,
      inset: 2
    )
    link_box.render

    assert_kind_of Prawn::Document, @pdf
  end
end

class TestLinkBoxMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::LinkBox::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::LinkBox::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_link_box_method
    component = TestComponent.new
    assert component.respond_to?(:link_box), "Expected link_box method"
  end

  def test_mixin_link_box_with_minimal_args
    component = TestComponent.new
    component.link_box(0, 0, 2, 1, "Test", dest: "test_dest")
  end

  def test_mixin_link_box_with_all_options
    component = TestComponent.new
    component.link_box(0, 0, 2, 1, "Test",
                       dest: "test_dest",
                       current: true,
                       rotation: -90,
                       font_size: 10,
                       inset: 4,
                       color: 'FF0000')
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.link_box(0, 0, 2, 1, "Test", dest: "test_dest")
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestLinkBoxEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_zero_inset
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "Test",
      dest: "test",
      inset: 0
    )
    link_box.render
  end

  def test_small_box
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 1,
      height: 1,
      text: "X",
      dest: "test"
    )
    link_box.render
  end

  def test_large_box
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 10,
      height: 5,
      text: "Large Box",
      dest: "test"
    )
    link_box.render
  end

  def test_fractional_dimensions
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0.5,
      row: 0.5,
      width: 2.5,
      height: 1.5,
      text: "Fractional",
      dest: "test"
    )
    link_box.render
  end

  def test_long_text
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "Very Long Text That May Overflow",
      dest: "test"
    )
    link_box.render
  end

  def test_empty_text
    link_box = BujoPdf::Components::LinkBox.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 2,
      height: 1,
      text: "",
      dest: "test"
    )
    link_box.render
  end
end
