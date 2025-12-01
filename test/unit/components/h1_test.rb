# frozen_string_literal: true

require_relative '../../test_helper'

class TestH1 < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_required_params
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header"
    )
    h1.render
  end

  def test_initialize_with_all_params
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      color: 'FF0000',
      style: :normal,
      position: :superscript,
      align: :center,
      width: 20
    )
    h1.render
  end

  def test_font_size_constant
    assert_equal 12, BujoPdf::Components::H1::FONT_SIZE
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_draws_text
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    h1 = BujoPdf::Components::H1.new(
      canvas: canvas,
      col: 5,
      row: 10,
      content: "Header"
    )
    h1.render

    assert mock_pdf.called?(:text_box), "Expected text_box to be called"
  end

  def test_render_with_default_style
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header"
    )
    h1.render
    # Default style is :bold
  end

  def test_render_with_normal_style
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      style: :normal
    )
    h1.render
  end

  def test_render_with_italic_style
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      style: :italic
    )
    h1.render
  end

  def test_render_with_custom_color
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      color: 'FF0000'
    )
    h1.render
  end

  def test_render_with_center_position_default
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header"
    )
    h1.render
  end

  def test_render_with_superscript_position
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      position: :superscript
    )
    h1.render
  end

  def test_render_with_subscript_position
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      position: :subscript
    )
    h1.render
  end

  def test_render_with_left_align_default
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header"
    )
    h1.render
  end

  def test_render_with_center_align
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      align: :center,
      width: 20
    )
    h1.render
  end

  def test_render_with_right_align
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      align: :right,
      width: 20
    )
    h1.render
  end

  def test_render_with_explicit_width
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      width: 15
    )
    h1.render
  end

  def test_render_with_auto_width
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Header",
      width: nil
    )
    h1.render
  end

  # ============================================
  # Real Prawn Document Tests
  # ============================================

  def test_render_with_real_prawn_document
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "Chapter 1",
      color: '333333',
      style: :bold,
      position: :center,
      align: :left
    )
    h1.render

    assert_kind_of Prawn::Document, @pdf
  end
end

class TestH1Mixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::H1::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::H1::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_h1_method
    component = TestComponent.new
    assert component.respond_to?(:h1), "Expected h1 method"
  end

  def test_mixin_h1_with_defaults
    component = TestComponent.new
    component.h1(5, 10, "Header")
  end

  def test_mixin_h1_with_options
    component = TestComponent.new
    component.h1(5, 10, "Header",
                 color: 'FF0000',
                 style: :normal,
                 position: :superscript,
                 align: :center,
                 width: 20)
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.h1(5, 10, "Header")
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestH1EdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_empty_content
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: ""
    )
    h1.render
  end

  def test_long_content
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      content: "This is a very long header that might wrap or overflow"
    )
    h1.render
  end

  def test_origin_position
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      content: "Origin"
    )
    h1.render
  end

  def test_edge_of_page
    h1 = BujoPdf::Components::H1.new(
      canvas: @canvas,
      col: 40,
      row: 54,
      content: "Edge"
    )
    h1.render
  end
end
