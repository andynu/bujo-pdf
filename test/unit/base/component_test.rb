# frozen_string_literal: true

require_relative '../../test_helper'

class TestComponent < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_canvas_only
    component = BujoPdf::Component.new(canvas: @canvas)

    assert_equal @canvas, component.canvas
    assert_nil component.content_area
  end

  def test_initialize_with_content_area
    content_area = { col: 5, row: 10, width_boxes: 20, height_boxes: 30 }
    component = BujoPdf::Component.new(canvas: @canvas, content_area: content_area)

    assert_equal content_area, component.content_area
  end

  def test_canvas_accessor
    component = BujoPdf::Component.new(canvas: @canvas)

    assert_equal @canvas, component.canvas
  end

  # ============================================
  # Convenience Accessor Tests
  # ============================================

  def test_pdf_convenience_accessor
    component = BujoPdf::Component.new(canvas: @canvas)

    assert_equal @pdf, component.pdf
  end

  def test_grid_convenience_accessor
    component = BujoPdf::Component.new(canvas: @canvas)

    assert_equal @grid, component.grid
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_raises_not_implemented
    component = BujoPdf::Component.new(canvas: @canvas)

    error = assert_raises(NotImplementedError) do
      component.render
    end

    assert_match(/must implement #render/, error.message)
  end
end

class TestComponentStyleContextManagers < Minitest::Test
  # Concrete test component to access protected methods
  class TestableComponent < BujoPdf::Component
    def test_with_fill_color(color, &block)
      with_fill_color(color, &block)
    end

    def test_with_stroke_color(color, &block)
      with_stroke_color(color, &block)
    end

    def test_with_font(family, size = nil, &block)
      with_font(family, size, &block)
    end

    def render
      # Noop for testing
    end
  end

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    @component = TestableComponent.new(canvas: @canvas)
  end

  def test_with_fill_color_sets_and_restores
    original = @pdf.fill_color
    captured_inside = nil

    @component.test_with_fill_color('FF0000') do
      captured_inside = @pdf.fill_color
    end

    assert_equal 'FF0000', captured_inside
    assert_equal original, @pdf.fill_color
  end

  def test_with_fill_color_restores_on_exception
    original = @pdf.fill_color

    assert_raises(RuntimeError) do
      @component.test_with_fill_color('FF0000') do
        raise "Test error"
      end
    end

    assert_equal original, @pdf.fill_color
  end

  def test_with_stroke_color_sets_and_restores
    original = @pdf.stroke_color
    captured_inside = nil

    @component.test_with_stroke_color('00FF00') do
      captured_inside = @pdf.stroke_color
    end

    assert_equal '00FF00', captured_inside
    assert_equal original, @pdf.stroke_color
  end

  def test_with_stroke_color_restores_on_exception
    original = @pdf.stroke_color

    assert_raises(RuntimeError) do
      @component.test_with_stroke_color('00FF00') do
        raise "Test error"
      end
    end

    assert_equal original, @pdf.stroke_color
  end

  def test_with_font_sets_family_and_size_and_restores
    original_family = @pdf.font.family
    original_size = @pdf.font_size
    captured_size = nil

    @component.test_with_font('Courier', 20) do
      captured_size = @pdf.font_size
    end

    assert_equal 20, captured_size
    assert_equal original_family, @pdf.font.family
    assert_equal original_size, @pdf.font_size
  end

  def test_with_font_sets_family_only_when_no_size
    original_family = @pdf.font.family
    original_size = @pdf.font_size

    @component.test_with_font('Courier') do
      # Just changes family
    end

    assert_equal original_family, @pdf.font.family
    assert_equal original_size, @pdf.font_size
  end

  def test_with_font_restores_on_exception
    original_family = @pdf.font.family
    original_size = @pdf.font_size

    assert_raises(RuntimeError) do
      @component.test_with_font('Courier', 20) do
        raise "Test error"
      end
    end

    assert_equal original_family, @pdf.font.family
    assert_equal original_size, @pdf.font_size
  end
end

class TestComponentContentAreaHelpers < Minitest::Test
  # Concrete test component to access protected methods
  class TestableComponent < BujoPdf::Component
    def test_content_col(offset = 0)
      content_col(offset)
    end

    def test_content_row(offset = 0)
      content_row(offset)
    end

    def test_available_width
      available_width
    end

    def test_available_height
      available_height
    end

    def test_content_rect(col_offset, row_offset, width_boxes, height_boxes)
      content_rect(col_offset, row_offset, width_boxes, height_boxes)
    end

    def render
      # Noop for testing
    end
  end

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_content_col_without_content_area
    component = TestableComponent.new(canvas: @canvas)

    assert_equal 0, component.test_content_col
    assert_equal 5, component.test_content_col(5)
  end

  def test_content_col_with_content_area
    content_area = { col: 10, row: 5, width_boxes: 20, height_boxes: 30 }
    component = TestableComponent.new(canvas: @canvas, content_area: content_area)

    assert_equal 10, component.test_content_col
    assert_equal 15, component.test_content_col(5)
  end

  def test_content_row_without_content_area
    component = TestableComponent.new(canvas: @canvas)

    assert_equal 0, component.test_content_row
    assert_equal 5, component.test_content_row(5)
  end

  def test_content_row_with_content_area
    content_area = { col: 10, row: 5, width_boxes: 20, height_boxes: 30 }
    component = TestableComponent.new(canvas: @canvas, content_area: content_area)

    assert_equal 5, component.test_content_row
    assert_equal 10, component.test_content_row(5)
  end

  def test_available_width_without_content_area
    component = TestableComponent.new(canvas: @canvas)

    assert_equal 43, component.test_available_width
  end

  def test_available_width_with_content_area
    content_area = { col: 10, row: 5, width_boxes: 20, height_boxes: 30 }
    component = TestableComponent.new(canvas: @canvas, content_area: content_area)

    assert_equal 20, component.test_available_width
  end

  def test_available_height_without_content_area
    component = TestableComponent.new(canvas: @canvas)

    assert_equal 55, component.test_available_height
  end

  def test_available_height_with_content_area
    content_area = { col: 10, row: 5, width_boxes: 20, height_boxes: 30 }
    component = TestableComponent.new(canvas: @canvas, content_area: content_area)

    assert_equal 30, component.test_available_height
  end

  def test_content_rect_without_content_area
    component = TestableComponent.new(canvas: @canvas)
    rect = component.test_content_rect(5, 10, 15, 20)

    # GridRect supports to_h conversion
    assert_respond_to rect, :x
    assert_respond_to rect, :y
    assert_respond_to rect, :width
    assert_respond_to rect, :height
  end

  def test_content_rect_with_content_area
    content_area = { col: 10, row: 5, width_boxes: 20, height_boxes: 30 }
    component = TestableComponent.new(canvas: @canvas, content_area: content_area)
    rect = component.test_content_rect(2, 3, 10, 8)

    # Should position relative to content area start
    expected_x = @grid.x(12) # content_col(10) + offset(2)
    expected_y = @grid.y(8)  # content_row(5) + offset(3)

    assert_in_delta expected_x, rect[:x], 0.01
    assert_in_delta expected_y, rect[:y], 0.01
  end
end

class TestComponentGridDelegators < Minitest::Test
  # Concrete test component to access protected methods
  class TestableComponent < BujoPdf::Component
    def test_grid_x(col)
      grid_x(col)
    end

    def test_grid_y(row)
      grid_y(row)
    end

    def test_grid_width(boxes)
      grid_width(boxes)
    end

    def test_grid_height(boxes)
      grid_height(boxes)
    end

    def test_grid_rect(col, row, width_boxes, height_boxes)
      grid_rect(col, row, width_boxes, height_boxes)
    end

    def render
      # Noop for testing
    end
  end

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    @component = TestableComponent.new(canvas: @canvas)
  end

  def test_grid_x_delegates_to_grid
    expected = @grid.x(10)
    actual = @component.test_grid_x(10)

    assert_in_delta expected, actual, 0.01
  end

  def test_grid_y_delegates_to_grid
    expected = @grid.y(10)
    actual = @component.test_grid_y(10)

    assert_in_delta expected, actual, 0.01
  end

  def test_grid_width_delegates_to_grid
    expected = @grid.width(10)
    actual = @component.test_grid_width(10)

    assert_in_delta expected, actual, 0.01
  end

  def test_grid_height_delegates_to_grid
    expected = @grid.height(10)
    actual = @component.test_grid_height(10)

    assert_in_delta expected, actual, 0.01
  end

  def test_grid_rect_delegates_to_grid
    expected = @grid.rect(5, 10, 15, 20)
    actual = @component.test_grid_rect(5, 10, 15, 20)

    assert_equal expected, actual
  end
end
