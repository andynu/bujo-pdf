# frozen_string_literal: true

require_relative '../../test_helper'

class TestRuledList < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_required_params
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 10
    )
    list.render
  end

  def test_initialize_with_all_params
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 10,
      start_num: 5,
      show_page_box: false,
      line_color: 'FF0000',
      num_color: '333333'
    )
    list.render
  end

  def test_layout_constants
    assert_equal 2, BujoPdf::Components::RuledList::LINE_HEIGHT
    assert_equal 2, BujoPdf::Components::RuledList::NUM_WIDTH
    assert_equal 3, BujoPdf::Components::RuledList::PAGE_BOX_WIDTH
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_draws_entry_lines
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    list = BujoPdf::Components::RuledList.new(
      canvas: canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 5
    )
    list.render

    # Should draw text_box for entry numbers
    assert mock_pdf.called?(:text_box), "Expected text_box for entry numbers"
    # Should draw stroke_line for ruled lines
    assert mock_pdf.called?(:stroke_line), "Expected stroke_line for ruled lines"
    # Should draw stroke_rectangle for page boxes
    assert mock_pdf.called?(:stroke_rectangle), "Expected stroke_rectangle for page boxes"
  end

  def test_render_draws_correct_number_of_entries
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    list = BujoPdf::Components::RuledList.new(
      canvas: canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 5
    )
    list.render

    # 5 entries = 5 text_box calls for numbers, 5 stroke_line calls for lines
    # (fill_circle calls are for dot erasure from hline)
    text_box_count = mock_pdf.call_count(:text_box)
    assert_equal 5, text_box_count, "Expected 5 entry number text boxes"
  end

  def test_render_with_custom_start_num
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    list = BujoPdf::Components::RuledList.new(
      canvas: canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 3,
      start_num: 10
    )
    list.render

    # Should draw entry numbers starting from 10
    assert mock_pdf.called?(:text_box)
  end

  def test_render_without_page_boxes
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    list = BujoPdf::Components::RuledList.new(
      canvas: canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 5,
      show_page_box: false
    )
    list.render

    # Should not draw stroke_rectangle when show_page_box is false
    refute mock_pdf.called?(:stroke_rectangle), "Expected no page boxes when show_page_box: false"
  end

  def test_render_with_page_boxes
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    list = BujoPdf::Components::RuledList.new(
      canvas: canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 3,
      show_page_box: true
    )
    list.render

    # Should draw 3 stroke_rectangles for page boxes
    rect_count = mock_pdf.call_count(:stroke_rectangle)
    assert_equal 3, rect_count, "Expected 3 page boxes"
  end

  def test_render_with_custom_line_color
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 3,
      line_color: 'FF0000'
    )
    list.render
  end

  def test_render_with_custom_num_color
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 3,
      num_color: '333333'
    )
    list.render
  end

  # ============================================
  # Real Prawn Document Tests
  # ============================================

  def test_render_with_real_prawn_document
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 10,
      start_num: 1,
      show_page_box: true,
      line_color: 'CCCCCC',
      num_color: '999999'
    )
    list.render

    assert_kind_of Prawn::Document, @pdf
  end
end

class TestRuledListMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::RuledList::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::RuledList::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      # Note: no @canvas set
    end
  end

  def test_mixin_provides_ruled_list_method
    component = TestComponent.new
    assert component.respond_to?(:ruled_list), "Expected ruled_list method"
  end

  def test_mixin_ruled_list_with_defaults
    component = TestComponent.new
    component.ruled_list(2, 4, 18, entries: 10)
  end

  def test_mixin_ruled_list_with_options
    component = TestComponent.new
    component.ruled_list(2, 4, 18,
                         entries: 10,
                         start_num: 5,
                         show_page_box: false,
                         line_color: 'FF0000',
                         num_color: '333333')
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.ruled_list(2, 4, 18, entries: 5)
    # Should not raise - creates canvas from pdf and grid
  end
end

class TestRuledListEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_single_entry
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 1
    )
    list.render
  end

  def test_zero_entries
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    list = BujoPdf::Components::RuledList.new(
      canvas: canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 0
    )
    list.render

    # Should draw nothing for 0 entries
    refute mock_pdf.called?(:text_box)
    refute mock_pdf.called?(:stroke_line)
  end

  def test_many_entries
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 2,
      width: 30,
      entries: 25
    )
    list.render
  end

  def test_narrow_width
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 10,
      entries: 5
    )
    list.render
  end

  def test_large_start_num
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 18,
      entries: 5,
      start_num: 100
    )
    list.render
  end

  def test_at_origin
    list = BujoPdf::Components::RuledList.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 20,
      entries: 3
    )
    list.render
  end
end
