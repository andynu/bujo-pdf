#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestText < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_default_size_constant
    assert_equal 10, BujoPdf::Components::Text::DEFAULT_SIZE
  end

  def test_initialize_sets_properties
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Test content"
    )

    assert_equal 5, text.instance_variable_get(:@col)
    assert_equal 10, text.instance_variable_get(:@row)
    assert_equal "Test content", text.instance_variable_get(:@content)
    assert_equal 10, text.instance_variable_get(:@size)  # DEFAULT_SIZE
    assert_equal 1, text.instance_variable_get(:@height)
    assert_nil text.instance_variable_get(:@color)
    assert_equal :normal, text.instance_variable_get(:@style)
    assert_equal :center, text.instance_variable_get(:@valign)
    assert_equal :left, text.instance_variable_get(:@align)
    assert_nil text.instance_variable_get(:@width)
    assert_equal 0, text.instance_variable_get(:@rotation)
    assert_nil text.instance_variable_get(:@pt_x)
    assert_nil text.instance_variable_get(:@pt_y)
    assert_nil text.instance_variable_get(:@pt_width)
    assert_nil text.instance_variable_get(:@pt_height)
    assert_equal false, text.instance_variable_get(:@centered)
  end

  def test_initialize_with_all_options
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Test",
      size: 14,
      height: 2,
      color: 'FF0000',
      style: :bold,
      valign: :top,
      align: :center,
      width: 20,
      rotation: 90,
      pt_x: 100.0,
      pt_y: 500.0,
      pt_width: 50.0,
      pt_height: 30.0,
      centered: true
    )

    assert_equal 14, text.instance_variable_get(:@size)
    assert_equal 2, text.instance_variable_get(:@height)
    assert_equal 'FF0000', text.instance_variable_get(:@color)
    assert_equal :bold, text.instance_variable_get(:@style)
    assert_equal :top, text.instance_variable_get(:@valign)
    assert_equal :center, text.instance_variable_get(:@align)
    assert_equal 20, text.instance_variable_get(:@width)
    assert_equal 90, text.instance_variable_get(:@rotation)
    assert_equal 100.0, text.instance_variable_get(:@pt_x)
    assert_equal 500.0, text.instance_variable_get(:@pt_y)
    assert_equal 50.0, text.instance_variable_get(:@pt_width)
    assert_equal 30.0, text.instance_variable_get(:@pt_height)
    assert_equal true, text.instance_variable_get(:@centered)
  end

  def test_render_basic_text
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Hello World"
    )

    # Should render without error
    text.render
  end

  def test_render_with_bold_style
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Bold Text",
      style: :bold
    )

    text.render
  end

  def test_render_with_italic_style
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Italic Text",
      style: :italic
    )

    text.render
  end

  def test_render_with_custom_color
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Colored",
      color: 'FF6B6B'
    )

    text.render
  end

  def test_render_with_center_alignment
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Centered",
      align: :center,
      width: 20
    )

    text.render
  end

  def test_render_with_right_alignment
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Right Aligned",
      align: :right,
      width: 20
    )

    text.render
  end

  def test_render_with_larger_font
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Large Text",
      size: 24
    )

    text.render
  end

  def test_render_with_multi_row_height
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Multi Row",
      height: 3
    )

    text.render
  end

  def test_render_with_top_valign
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Top",
      valign: :top
    )

    text.render
  end

  def test_render_with_bottom_valign
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Bottom",
      valign: :bottom
    )

    text.render
  end

  def test_render_with_pt_coordinates
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 0, row: 0,  # Ignored when pt_* provided
      content: "Pixel Position",
      pt_x: 100.0,
      pt_y: 500.0,
      pt_width: 200.0,
      pt_height: 30.0
    )

    text.render
  end
end

class TestTextRotation < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_render_with_90_degree_rotation
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Rotated 90",
      rotation: 90,
      width: 5
    )

    text.render
  end

  def test_render_with_negative_90_degree_rotation
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Rotated -90",
      rotation: -90,
      width: 5
    )

    text.render
  end

  def test_render_rotated_with_pt_coordinates
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 0, row: 0,
      content: "Rotated PT",
      rotation: 90,
      pt_x: 100.0,
      pt_y: 500.0,
      pt_width: 100.0,
      pt_height: 20.0
    )

    text.render
  end

  def test_render_rotated_with_centered_mode
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 0, row: 0,
      content: "Centered",
      rotation: 90,
      pt_x: 300.0,  # Center point
      pt_y: 400.0,  # Center point
      pt_width: 100.0,
      pt_height: 20.0,
      centered: true
    )

    text.render
  end

  def test_render_rotated_without_centered_mode
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 0, row: 0,
      content: "Not Centered",
      rotation: 90,
      pt_x: 300.0,  # Top-left corner
      pt_y: 400.0,
      pt_width: 100.0,
      pt_height: 20.0,
      centered: false
    )

    text.render
  end

  def test_render_rotated_using_grid_coordinates
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 20, row: 25,
      content: "Grid Rotated",
      rotation: -90,
      width: 10,
      height: 2
    )

    text.render
  end
end

class TestTextDotErasure < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_no_erasure_for_centered_single_row
    # valign :center with height 1 should not erase
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "No Erase",
      valign: :center,
      height: 1
    )

    text.render
    # Should complete without error
  end

  def test_erase_for_top_valign
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Top",
      valign: :top
    )

    text.render
  end

  def test_erase_for_bottom_valign
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Bottom",
      valign: :bottom
    )

    text.render
  end

  def test_erase_for_multi_row_center_text
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Multi Row",
      valign: :center,
      height: 3  # Should erase middle rows
    )

    text.render
  end

  def test_erase_col_calculation_left_align
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Left",
      align: :left,
      valign: :top
    )

    # Left align starts erasure at col
    erase_col = text.send(:calculate_erase_col, 4)
    assert_equal 5, erase_col
  end

  def test_erase_col_calculation_center_align
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Center",
      align: :center,
      width: 20,
      valign: :top
    )

    # Center align calculates offset
    erase_col = text.send(:calculate_erase_col, 8)
    # (20 - 8) / 2 = 6, so 5 + 6 = 11
    assert_equal 11, erase_col
  end

  def test_erase_col_calculation_right_align
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Right",
      align: :right,
      width: 20,
      valign: :top
    )

    # Right align: col + width - text_width
    erase_col = text.send(:calculate_erase_col, 6)
    # 5 + 20 - 6 = 19
    assert_equal 19, erase_col
  end

  def test_erase_col_calculation_no_width_specified
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "No Width",
      align: :center,  # Align ignored without width
      width: nil,
      valign: :top
    )

    # Without width, returns col regardless of alignment
    erase_col = text.send(:calculate_erase_col, 8)
    assert_equal 5, erase_col
  end
end

class TestTextYOffset < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_y_offset_for_center_valign
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Center",
      valign: :center
    )

    offset = text.send(:calculate_y_offset)
    assert_equal 0, offset
  end

  def test_y_offset_for_top_valign
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Top",
      valign: :top
    )

    offset = text.send(:calculate_y_offset)
    expected = @grid.height(0.5)
    assert_equal expected, offset
  end

  def test_y_offset_for_bottom_valign
    text = BujoPdf::Components::Text.new(
      canvas: @canvas,
      col: 5, row: 10,
      content: "Bottom",
      valign: :bottom
    )

    offset = text.send(:calculate_y_offset)
    expected = -@grid.height(0.5)
    assert_equal expected, offset
  end
end

class TestTextMixin < Minitest::Test
  class TestPage
    include BujoPdf::Components::Text::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  def setup
    @page = TestPage.new
  end

  def test_mixin_provides_text_method
    assert @page.respond_to?(:text), "Expected text method from mixin"
  end

  def test_mixin_text_method_renders
    # Should not raise
    @page.text(5, 10, "Mixin Text")
  end

  def test_mixin_text_method_with_options
    @page.text(5, 10, "Styled",
      size: 14,
      color: 'FF0000',
      style: :bold,
      align: :center,
      width: 20
    )
  end

  def test_mixin_text_method_with_rotation
    @page.text(5, 10, "Rotated",
      rotation: 90,
      width: 5
    )
  end

  def test_mixin_text_method_with_pt_coordinates
    @page.text(0, 0, "Pixels",
      pt_x: 100.0,
      pt_y: 500.0,
      pt_width: 200.0,
      pt_height: 30.0
    )
  end
end

class TestTextMixinWithoutCanvas < Minitest::Test
  class TestPageNoCanvas
    include BujoPdf::Components::Text::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # No @canvas - mixin should create one
    end
  end

  def setup
    @page = TestPageNoCanvas.new
  end

  def test_mixin_creates_canvas_when_not_present
    # Should work even without @canvas
    @page.text(5, 10, "Auto Canvas")
  end
end
