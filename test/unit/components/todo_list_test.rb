#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/components/todo_list'
require 'bujo_pdf/utilities/grid_system'
require 'prawn'

class TestTodoList < Minitest::Test
  include TestHelpers

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  # Initialization tests

  def test_initialize_with_required_params
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 8
    )

    assert_instance_of BujoPdf::Components::TodoList, todo
  end

  def test_initialize_with_all_options
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 8,
      bullet_style: :checkbox,
      divider: :dashed,
      divider_color: 'AAAAAA',
      bullet_color: '333333'
    )

    assert_instance_of BujoPdf::Components::TodoList, todo
  end

  def test_raises_without_pdf
    assert_raises ArgumentError do
      BujoPdf::Components::TodoList.new(
        pdf: nil,
        x: 100,
        y: 700,
        width: 200,
        rows: 8
      )
    end
  end

  def test_raises_with_invalid_width
    assert_raises ArgumentError do
      BujoPdf::Components::TodoList.new(
        pdf: @pdf,
        x: 100,
        y: 700,
        width: 0,
        rows: 8
      )
    end
  end

  def test_raises_with_invalid_rows
    assert_raises ArgumentError do
      BujoPdf::Components::TodoList.new(
        pdf: @pdf,
        x: 100,
        y: 700,
        width: 200,
        rows: 0
      )
    end
  end

  def test_raises_with_invalid_bullet_style
    assert_raises ArgumentError do
      BujoPdf::Components::TodoList.new(
        pdf: @pdf,
        x: 100,
        y: 700,
        width: 200,
        rows: 8,
        bullet_style: :invalid
      )
    end
  end

  def test_raises_with_invalid_divider
    assert_raises ArgumentError do
      BujoPdf::Components::TodoList.new(
        pdf: @pdf,
        x: 100,
        y: 700,
        width: 200,
        rows: 8,
        divider: :invalid
      )
    end
  end

  # Rendering tests

  def test_render_with_bullet_style
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5,
      bullet_style: :bullet
    )

    # Should not raise
    todo.render
  end

  def test_render_with_checkbox_style
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5,
      bullet_style: :checkbox
    )

    todo.render
  end

  def test_render_with_circle_style
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5,
      bullet_style: :circle
    )

    todo.render
  end

  def test_render_with_solid_divider
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5,
      divider: :solid
    )

    todo.render
  end

  def test_render_with_dashed_divider
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5,
      divider: :dashed
    )

    todo.render
  end

  # Rectangle helpers

  def test_row_rect_returns_correct_dimensions
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5
    )

    rect = todo.row_rect(0)
    assert_equal 100, rect[:x]
    assert_equal 700, rect[:y]
    assert_equal 200, rect[:width]
    assert_in_delta Styling::Grid::DOT_SPACING, rect[:height], 0.01
  end

  def test_row_rect_second_row
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5
    )

    rect = todo.row_rect(1)
    expected_y = 700 - Styling::Grid::DOT_SPACING
    assert_in_delta expected_y, rect[:y], 0.01
  end

  def test_row_rect_raises_for_invalid_index
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5
    )

    assert_raises ArgumentError do
      todo.row_rect(5)  # Out of range
    end

    assert_raises ArgumentError do
      todo.row_rect(-1)  # Negative
    end
  end

  def test_text_rect_excludes_marker_column
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 5
    )

    full_rect = todo.row_rect(0)
    text_rect = todo.text_rect(0)

    # Text rect should start after marker column (1 box width)
    marker_width = Styling::Grid::DOT_SPACING
    assert_in_delta 100 + marker_width, text_rect[:x], 0.01
    assert_in_delta 200 - marker_width, text_rect[:width], 0.01
    assert_equal full_rect[:y], text_rect[:y]
    assert_equal full_rect[:height], text_rect[:height]
  end

  def test_height_calculation
    todo = BujoPdf::Components::TodoList.new(
      pdf: @pdf,
      x: 100,
      y: 700,
      width: 200,
      rows: 8
    )

    expected_height = 8 * Styling::Grid::DOT_SPACING
    assert_in_delta expected_height, todo.height, 0.01
  end

  # Grid factory method tests

  def test_from_grid
    todo = BujoPdf::Components::TodoList.from_grid(
      pdf: @pdf,
      grid: @grid,
      col: 5,
      row: 10,
      width_boxes: 20,
      rows: 8
    )

    assert_instance_of BujoPdf::Components::TodoList, todo

    rect = todo.row_rect(0)
    assert_in_delta @grid.x(5), rect[:x], 0.01
    assert_in_delta @grid.y(10), rect[:y], 0.01
    assert_in_delta @grid.width(20), rect[:width], 0.01
  end

  def test_from_grid_with_options
    todo = BujoPdf::Components::TodoList.from_grid(
      pdf: @pdf,
      grid: @grid,
      col: 5,
      row: 10,
      width_boxes: 20,
      rows: 8,
      bullet_style: :checkbox,
      divider: :solid
    )

    # Should render without error
    todo.render
  end

  # Grid helper method tests

  def test_grid_helper_method
    todo = @grid.todo_list(5, 10, 20, 8)

    assert_instance_of BujoPdf::Components::TodoList, todo
  end

  def test_grid_helper_with_options
    todo = @grid.todo_list(5, 10, 20, 8, bullet_style: :circle, divider: :dashed)

    # Should render without error
    todo.render
  end

  # All bullet styles rendering test

  def test_all_styles_render_correctly
    %i[bullet checkbox circle].each do |style|
      todo = BujoPdf::Components::TodoList.new(
        pdf: @pdf,
        x: 100,
        y: 700,
        width: 200,
        rows: 3,
        bullet_style: style
      )

      # Each style should render without error
      todo.render
    end
  end

  # All divider styles rendering test

  def test_all_dividers_render_correctly
    %i[none solid dashed].each do |divider|
      todo = BujoPdf::Components::TodoList.new(
        pdf: @pdf,
        x: 100,
        y: 700,
        width: 200,
        rows: 3,
        divider: divider
      )

      todo.render
    end
  end
end
