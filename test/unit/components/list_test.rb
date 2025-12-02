#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/components/list'
require 'bujo_pdf/utilities/grid_system'
require 'bujo_pdf/canvas'
require 'prawn'

class TestList < Minitest::Test
  include TestHelpers

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_required_params
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 8
    )
    assert_instance_of BujoPdf::Components::List, list
  end

  def test_initialize_with_all_options
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 8,
      show_numbers: true,
      start_num: 5,
      marker: :checkbox,
      divider: :dashed,
      show_page_box: true,
      row_height: 2,
      divider_color: 'AAAAAA',
      number_color: '666666',
      marker_color: '333333',
      line_color: 'DDDDDD'
    )
    assert_instance_of BujoPdf::Components::List, list
  end

  def test_raises_without_canvas
    assert_raises ArgumentError do
      BujoPdf::Components::List.new(
        canvas: nil,
        col: 5,
        row: 10,
        width: 20,
        rows: 8
      )
    end
  end

  def test_raises_with_invalid_width
    assert_raises ArgumentError do
      BujoPdf::Components::List.new(
        canvas: @canvas,
        col: 5,
        row: 10,
        width: 0,
        rows: 8
      )
    end
  end

  def test_raises_with_invalid_rows
    assert_raises ArgumentError do
      BujoPdf::Components::List.new(
        canvas: @canvas,
        col: 5,
        row: 10,
        width: 20,
        rows: 0
      )
    end
  end

  def test_raises_with_invalid_marker
    assert_raises ArgumentError do
      BujoPdf::Components::List.new(
        canvas: @canvas,
        col: 5,
        row: 10,
        width: 20,
        rows: 8,
        marker: :invalid
      )
    end
  end

  def test_raises_with_invalid_divider
    assert_raises ArgumentError do
      BujoPdf::Components::List.new(
        canvas: @canvas,
        col: 5,
        row: 10,
        width: 20,
        rows: 8,
        divider: :invalid
      )
    end
  end

  def test_raises_with_invalid_row_height
    assert_raises ArgumentError do
      BujoPdf::Components::List.new(
        canvas: @canvas,
        col: 5,
        row: 10,
        width: 20,
        rows: 8,
        row_height: 0
      )
    end
  end

  # ============================================
  # Rendering Tests - Marker Styles
  # ============================================

  def test_render_with_no_marker
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      marker: :none
    )
    list.render  # Should not raise
  end

  def test_render_with_bullet_marker
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      marker: :bullet
    )
    list.render
  end

  def test_render_with_checkbox_marker
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      marker: :checkbox
    )
    list.render
  end

  def test_render_with_circle_marker
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      marker: :circle
    )
    list.render
  end

  # ============================================
  # Rendering Tests - Divider Styles
  # ============================================

  def test_render_with_no_divider
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      divider: :none
    )
    list.render
  end

  def test_render_with_solid_divider
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      divider: :solid
    )
    list.render
  end

  def test_render_with_dashed_divider
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      divider: :dashed
    )
    list.render
  end

  # ============================================
  # Rendering Tests - Numbers and Page Box
  # ============================================

  def test_render_with_numbers
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      show_numbers: true
    )
    list.render
  end

  def test_render_with_custom_start_num
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      show_numbers: true,
      start_num: 26
    )
    list.render
  end

  def test_render_with_page_box
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      show_page_box: true
    )
    list.render
  end

  # ============================================
  # Rendering Tests - Combinations (use cases)
  # ============================================

  def test_render_as_simple_todo_list
    # marker only
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 8,
      marker: :bullet,
      divider: :dashed
    )
    list.render
  end

  def test_render_as_index_entry
    # numbers + page box, 2-row height
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 2,
      row: 4,
      width: 18,
      rows: 25,
      show_numbers: true,
      show_page_box: true,
      row_height: 2
    )
    list.render
  end

  def test_render_as_numbered_checklist
    # numbers + marker
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 10,
      show_numbers: true,
      marker: :checkbox
    )
    list.render
  end

  def test_render_with_all_elements
    # numbers + marker + divider + page_box
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 25,
      rows: 5,
      show_numbers: true,
      marker: :circle,
      divider: :solid,
      show_page_box: true,
      row_height: 2
    )
    list.render
  end

  # ============================================
  # Rectangle Helper Tests
  # ============================================

  def test_row_rect_returns_correct_dimensions
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5
    )

    rect = list.row_rect(0)
    assert_in_delta @grid.x(5), rect[:x], 0.01
    assert_in_delta @grid.y(10), rect[:y], 0.01
    assert_in_delta @grid.width(20), rect[:width], 0.01
    assert_in_delta Styling::Grid::DOT_SPACING, rect[:height], 0.01
  end

  def test_row_rect_with_row_height_2
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      row_height: 2
    )

    rect = list.row_rect(0)
    assert_in_delta 2 * Styling::Grid::DOT_SPACING, rect[:height], 0.01

    # Second row should be at row 12 (10 + 2*1)
    rect2 = list.row_rect(1)
    assert_in_delta @grid.y(12), rect2[:y], 0.01
  end

  def test_row_rect_raises_for_invalid_index
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5
    )

    assert_raises ArgumentError do
      list.row_rect(5)
    end

    assert_raises ArgumentError do
      list.row_rect(-1)
    end
  end

  def test_content_rect_excludes_number_and_marker_columns
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      show_numbers: true,
      marker: :bullet
    )

    full_rect = list.row_rect(0)
    content_rect = list.content_rect(0)

    # Number column (2) + gap (1) + marker column (1) = 4 boxes offset
    expected_col = 5 + 2 + 1 + 1  # = 9
    assert_in_delta @grid.x(expected_col), content_rect[:x], 0.01
    # Width should be 20 - 4 left columns = 16
    assert_in_delta @grid.width(16), content_rect[:width], 0.01
  end

  def test_content_rect_excludes_page_box
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      show_page_box: true
    )

    content_rect = list.content_rect(0)
    # Width should be 20 - 3 (page box) = 17
    assert_in_delta @grid.width(17), content_rect[:width], 0.01
  end

  def test_height_calculation
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 8
    )

    expected_height = 8 * Styling::Grid::DOT_SPACING
    assert_in_delta expected_height, list.height, 0.01
  end

  def test_height_calculation_with_row_height_2
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 5,
      row_height: 2
    )

    expected_height = 5 * 2 * Styling::Grid::DOT_SPACING
    assert_in_delta expected_height, list.height, 0.01
  end

  # ============================================
  # Edge Cases
  # ============================================

  def test_single_row
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 1
    )
    list.render
  end

  def test_single_row_with_dividers_draws_nothing
    # Dividers only appear between rows, so 1 row = no dividers
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    list = BujoPdf::Components::List.new(
      canvas: canvas,
      col: 5,
      row: 10,
      width: 20,
      rows: 1,
      divider: :solid
    )
    list.render
    # Should not crash, divider logic should handle single row
  end

  def test_narrow_width
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 8,
      rows: 3
    )
    list.render
  end

  def test_at_origin
    list = BujoPdf::Components::List.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 20,
      rows: 3
    )
    list.render
  end
end

class TestListMixin < Minitest::Test
  class TestComponent
    include BujoPdf::Components::List::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    end
  end

  class TestComponentWithoutCanvas
    include BujoPdf::Components::List::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
    end
  end

  def test_mixin_provides_list_method
    component = TestComponent.new
    assert component.respond_to?(:list), "Expected list method"
  end

  def test_mixin_list_with_defaults
    component = TestComponent.new
    component.list(5, 10, 20, rows: 8)
  end

  def test_mixin_list_as_todo
    component = TestComponent.new
    component.list(5, 10, 20, rows: 8, marker: :bullet, divider: :dashed)
  end

  def test_mixin_list_as_index
    component = TestComponent.new
    component.list(2, 4, 18, rows: 25, show_numbers: true, show_page_box: true, row_height: 2)
  end

  def test_mixin_list_with_all_options
    component = TestComponent.new
    component.list(5, 10, 20,
                   rows: 8,
                   show_numbers: true,
                   start_num: 10,
                   marker: :checkbox,
                   divider: :solid,
                   show_page_box: true,
                   row_height: 2,
                   divider_color: 'AAAAAA',
                   number_color: '666666',
                   marker_color: '333333',
                   line_color: 'DDDDDD')
  end

  def test_mixin_creates_canvas_if_not_present
    component = TestComponentWithoutCanvas.new
    component.list(5, 10, 20, rows: 5)
    # Should not raise - creates canvas from pdf and grid
  end
end
