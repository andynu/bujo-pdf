#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'

# Mock PDF class for testing WeekGrid
class MockPDFForWeekGrid
  attr_reader :calls, :font_size

  def initialize
    @calls = []
    @font_size = 12
  end

  def text_box(*args, **kwargs)
    @calls << [:text_box, args, kwargs]
  end

  def font(family, size: nil)
    @font_size = size if size
  end

  def method_missing(method, *args, **kwargs, &block)
    @calls << [method, args, kwargs]
    self
  end

  def respond_to_missing?(method, include_private = false)
    true
  end
end

# Mock GridSystem for testing WeekGrid
class MockGridSystem
  DOT_SPACING = 14.17
  PAGE_HEIGHT = 792

  def x(col)
    col * DOT_SPACING
  end

  def y(row)
    PAGE_HEIGHT - (row * DOT_SPACING)
  end

  def width(boxes)
    boxes * DOT_SPACING
  end

  def height(boxes)
    boxes * DOT_SPACING
  end
end

# Mock Canvas for testing WeekGrid
class MockCanvas
  attr_reader :pdf, :grid

  def initialize(pdf, grid)
    @pdf = pdf
    @grid = grid
  end
end

class TestWeekGrid < Minitest::Test
  def setup
    @pdf = MockPDFForWeekGrid.new
    @grid = MockGridSystem.new
    @canvas = MockCanvas.new(@pdf, @grid)
  end

  # Constructor and validation tests

  def test_requires_canvas
    error = assert_raises(ArgumentError) do
      BujoPdf::Components::WeekGrid.new(
        canvas: nil,
        col: 0, row: 0, width: 35, height: 15
      )
    end
    assert_match(/canvas is required/, error.message)
  end

  def test_requires_positive_width
    error = assert_raises(ArgumentError) do
      BujoPdf::Components::WeekGrid.new(
        canvas: @canvas,
        col: 0, row: 0, width: 0, height: 15
      )
    end
    assert_match(/width must be positive/, error.message)
  end

  def test_requires_positive_height
    error = assert_raises(ArgumentError) do
      BujoPdf::Components::WeekGrid.new(
        canvas: @canvas,
        col: 0, row: 0, width: 35, height: -10
      )
    end
    assert_match(/height must be positive/, error.message)
  end

  def test_validates_first_day_values
    error = assert_raises(ArgumentError) do
      BujoPdf::Components::WeekGrid.new(
        canvas: @canvas,
        col: 0, row: 0, width: 35, height: 15,
        first_day: :tuesday
      )
    end
    assert_match(/first_day must be :monday or :sunday/, error.message)
  end

  def test_validates_header_height_vs_total_height
    error = assert_raises(ArgumentError) do
      BujoPdf::Components::WeekGrid.new(
        canvas: @canvas,
        col: 0, row: 0, width: 35, height: 15,
        show_headers: true,
        header_height: 20  # 20 boxes > 15 boxes total
      )
    end
    assert_match(/header_height cannot exceed total height/, error.message)
  end

  # Quantization width calculation tests

  def test_quantized_width_divisible_by_seven
    # 35 boxes, divisible by 7 = 5 boxes per day
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35,
      height: 15,
      quantize: true
    )

    # Each column should be exactly 5 boxes = 70.85pt
    7.times do |i|
      rect = grid.cell_rect(i)
      assert_in_delta 70.85, rect[:width], 0.01,
                      "Day #{i} width should be 70.85pt (5 boxes)"
    end
  end

  def test_quantized_width_not_divisible_by_seven
    # 37 boxes, NOT divisible by 7
    # Should fall back to proportional mode
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 37,
      height: 15,
      quantize: true
    )

    # Width in points = 37 * 14.17 = 524.29pt
    # Each column should be approximately 524.29 / 7 = 74.9pt
    expected_width = (37 * 14.17) / 7.0
    7.times do |i|
      rect = grid.cell_rect(i)
      assert_in_delta expected_width, rect[:width], 0.01,
                      "Day #{i} width should be proportional"
    end
  end

  def test_proportional_mode_divides_equally
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 28, # 28 boxes = 396.76pt
      height: 15,
      quantize: false
    )

    # 28 boxes / 7 = 4 boxes each = 56.68pt
    expected_width = (28 * 14.17) / 7.0
    7.times do |i|
      rect = grid.cell_rect(i)
      assert_in_delta expected_width, rect[:width], 0.01,
                      "Day #{i} width should be #{expected_width}pt"
    end
  end

  def test_quantized_42_boxes_perfect_fit
    # 42 boxes, divisible by 7 = 6 boxes per day
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 42,
      height: 15,
      quantize: true
    )

    # Each column should be exactly 6 boxes = 85.02pt
    7.times do |i|
      rect = grid.cell_rect(i)
      assert_in_delta 85.02, rect[:width], 0.01,
                      "Day #{i} width should be 85.02pt (6 boxes)"
    end
  end

  # Cell positioning tests

  def test_cell_rect_returns_correct_boundaries
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 7, row: 6, # x = 99.19pt, y = 707.02pt
      width: 28, height: 14,
      quantize: false,
      show_headers: false
    )

    col_width = (28 * 14.17) / 7.0  # 56.68pt

    # First day (Monday)
    # col 7 = 7 * 14.17 = 99.19pt
    # row 6 = 792 - (6 * 14.17) = 706.98pt
    rect0 = grid.cell_rect(0)
    assert_in_delta 99.19, rect0[:x], 0.01
    assert_in_delta 706.98, rect0[:y], 0.1
    assert_in_delta col_width, rect0[:width], 0.01
    assert_in_delta 198.38, rect0[:height], 0.01  # 14 boxes

    # Third day (Wednesday)
    rect2 = grid.cell_rect(2)
    assert_in_delta 99.19 + (col_width * 2), rect2[:x], 0.01
    assert_in_delta 706.98, rect2[:y], 0.1
    assert_in_delta col_width, rect2[:width], 0.01

    # Last day (Sunday)
    rect6 = grid.cell_rect(6)
    assert_in_delta 99.19 + (col_width * 6), rect6[:x], 0.01
    assert_in_delta 706.98, rect6[:y], 0.1
    assert_in_delta col_width, rect6[:width], 0.01
  end

  def test_cell_rect_with_headers_adjusts_y_and_height
    header_height_boxes = 2
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35, height: 15,
      show_headers: true,
      header_height: header_height_boxes
    )

    rect = grid.cell_rect(0)

    # Y should be adjusted down by header height (2 boxes = 28.34pt)
    expected_y = 792 - (2 * 14.17)
    assert_in_delta expected_y, rect[:y], 0.01

    # Height should be reduced by header height
    # Total 15 boxes - 2 header boxes = 13 boxes = 184.21pt
    assert_in_delta 184.21, rect[:height], 0.01
  end

  def test_cell_rect_validates_day_index
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0, width: 35, height: 15
    )

    # Valid indices 0-6
    assert grid.cell_rect(0)
    assert grid.cell_rect(6)

    # Invalid indices
    error = assert_raises(ArgumentError) { grid.cell_rect(-1) }
    assert_match(/day_index must be 0-6/, error.message)

    error = assert_raises(ArgumentError) { grid.cell_rect(7) }
    assert_match(/day_index must be 0-6/, error.message)
  end

  # Iterator tests

  def test_each_cell_yields_all_days
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0, width: 35, height: 15
    )

    indices = []
    rects = []

    grid.each_cell do |day_index, rect|
      indices << day_index
      rects << rect
    end

    assert_equal [0, 1, 2, 3, 4, 5, 6], indices
    assert_equal 7, rects.length

    # Each rect should have required keys
    rects.each do |rect|
      assert rect.key?(:x)
      assert rect.key?(:y)
      assert rect.key?(:width)
      assert rect.key?(:height)
    end
  end

  # Rendering tests

  def test_render_with_headers_draws_day_labels
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35, height: 15,
      show_headers: true
    )

    grid.render

    # Should have 7 text_box calls for headers
    text_calls = @pdf.calls.select { |call| call[0] == :text_box }
    assert_equal 7, text_calls.length

    # Check day labels are correct
    day_labels = %w[M T W T F S S]
    text_calls.each_with_index do |call, i|
      text = call[1][0]
      assert_equal day_labels[i], text
    end
  end

  def test_render_without_headers_skips_labels
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35, height: 15,
      show_headers: false
    )

    grid.render

    # Should have no text_box calls
    text_calls = @pdf.calls.select { |call| call[0] == :text_box }
    assert_equal 0, text_calls.length
  end

  def test_render_with_callback_invokes_for_each_cell
    invocations = []

    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35, height: 15,
      cell_callback: ->(day_index, rect) {
        invocations << [day_index, rect]
      }
    )

    grid.render

    # Callback should be called 7 times
    assert_equal 7, invocations.length

    # Check indices
    indices = invocations.map(&:first)
    assert_equal [0, 1, 2, 3, 4, 5, 6], indices

    # Check rects have required keys
    invocations.each do |_day_index, rect|
      assert rect.key?(:x)
      assert rect.key?(:y)
      assert rect.key?(:width)
      assert rect.key?(:height)
    end
  end

  def test_render_without_callback_does_not_error
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35, height: 15,
      cell_callback: nil
    )

    # Should not raise error
    assert_nil grid.render
  end

  # Grid coordinate tests

  def test_grid_coordinates_convert_correctly
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 5,
      row: 10,
      width: 35,
      height: 15
    )

    # col 5 = 5 * 14.17 = 70.85
    # row 10 = 792 - (10 * 14.17) = 650.3
    # With default header_height of 1 box, cell_y = 650.3 - 14.17 = 636.13

    rect = grid.cell_rect(0)
    assert_in_delta 70.85, rect[:x], 0.01
    assert_in_delta 636.13, rect[:y], 0.01
  end

  def test_grid_coordinates_with_no_headers
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0,
      row: 0,
      width: 35,
      height: 20,
      quantize: false,
      show_headers: false
    )

    rect = grid.cell_rect(0)

    # With show_headers: false, y should not be adjusted
    assert_in_delta 792, rect[:y], 0.01
    # Height should be full 20 boxes = 283.4pt
    assert_in_delta 283.4, rect[:height], 0.01
  end

  # Edge case tests

  def test_handles_very_narrow_width
    # 7 boxes = 1 box per column
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 7,
      height: 10,
      quantize: true
    )

    # Each column = 1 box = 14.17pt
    rect = grid.cell_rect(0)
    assert_in_delta 14.17, rect[:width], 0.01
  end

  def test_handles_zero_header_height
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35, height: 15,
      show_headers: true,
      header_height: 0
    )

    rect = grid.cell_rect(0)

    # With zero header height, y and height should not be adjusted
    assert_in_delta 792, rect[:y], 0.01
    assert_in_delta 212.55, rect[:height], 0.01  # 15 boxes
  end

  def test_monday_first_is_default
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35, height: 15
    )

    # Default first_day should be :monday
    # This is implicit in the constructor, testing it doesn't error
    assert grid
  end

  def test_sunday_first_is_accepted
    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35, height: 15,
      first_day: :sunday
    )

    # Should accept :sunday as first_day
    assert grid
  end

  # Integration test: quantization consistency

  def test_quantization_produces_identical_widths_for_same_box_count
    # Create two grids with same box count but different absolute positions
    grid1 = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 0, row: 0,
      width: 35,
      height: 15,
      quantize: true
    )

    grid2 = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 10, row: 20,
      width: 35,
      height: 10,
      quantize: true
    )

    # Column widths should be identical
    7.times do |i|
      width1 = grid1.cell_rect(i)[:width]
      width2 = grid2.cell_rect(i)[:width]
      assert_in_delta width1, width2, 0.01,
                      "Column #{i} widths should match across grids"
    end
  end

  def test_total_width_is_preserved
    total_width_boxes = 37

    grid = BujoPdf::Components::WeekGrid.new(
      canvas: @canvas,
      col: 7, row: 5,
      width: total_width_boxes,
      height: 15,
      quantize: false
    )

    # Sum of all column widths should equal total width in points
    total_column_width = 0
    7.times do |i|
      total_column_width += grid.cell_rect(i)[:width]
    end

    expected_total_pt = total_width_boxes * 14.17
    assert_in_delta expected_total_pt, total_column_width, 0.01,
                    "Sum of column widths should equal total width"
  end
end
