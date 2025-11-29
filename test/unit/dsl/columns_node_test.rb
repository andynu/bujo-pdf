#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl'

class TestColumnsNode < Minitest::Test
  def test_columns_with_count
    columns = BujoPdf::DSL::ColumnsNode.new(count: 7)

    assert_equal 7, columns.column_count
  end

  def test_columns_with_widths
    columns = BujoPdf::DSL::ColumnsNode.new(widths: [8, 35])

    assert_equal 2, columns.column_count
  end

  def test_columns_requires_count_or_widths
    assert_raises ArgumentError do
      BujoPdf::DSL::ColumnsNode.new
    end
  end

  def test_columns_forbids_both_count_and_widths
    assert_raises ArgumentError do
      BujoPdf::DSL::ColumnsNode.new(count: 7, widths: [10, 10])
    end
  end

  def test_equal_columns_layout
    columns = BujoPdf::DSL::ColumnsNode.new(count: 7)
    columns.compute_bounds(col: 0, row: 0, width: 35, height: 55)

    # 35 / 7 = 5 boxes per column (perfect division)
    columns.each_column do |index, bounds|
      assert_equal 5, bounds[:width], "Column #{index} should be 5 boxes wide"
      assert_equal index * 5, bounds[:col], "Column #{index} should start at #{index * 5}"
    end
  end

  def test_equal_columns_with_remainder
    columns = BujoPdf::DSL::ColumnsNode.new(count: 7)
    columns.compute_bounds(col: 0, row: 0, width: 37, height: 55)

    # 37 / 7 = 5 with remainder 2
    # First 6 columns get 5, last gets 5 + 2 = 7
    (0..5).each do |i|
      assert_equal 5, columns.column_bounds(i)[:width], "Column #{i} should be 5"
    end
    assert_equal 7, columns.column_bounds(6)[:width], "Last column should get remainder"
  end

  def test_specified_widths
    columns = BujoPdf::DSL::ColumnsNode.new(widths: [8, 35])
    columns.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    assert_equal 8, columns.column_bounds(0)[:width]
    assert_equal 35, columns.column_bounds(1)[:width]
    assert_equal 0, columns.column_bounds(0)[:col]
    assert_equal 8, columns.column_bounds(1)[:col]
  end

  def test_columns_with_gap
    columns = BujoPdf::DSL::ColumnsNode.new(count: 7, gap: 1)
    columns.compute_bounds(col: 0, row: 0, width: 42, height: 55) # 42 - 6 gaps = 36 / 7 = 5.14...

    # Check columns are separated by gap
    col0 = columns.column_bounds(0)
    col1 = columns.column_bounds(1)

    # col1 should start 1 box after col0 ends
    expected_start = col0[:col] + col0[:width] + 1
    assert_equal expected_start, col1[:col]
  end

  def test_columns_full_height
    columns = BujoPdf::DSL::ColumnsNode.new(count: 3)
    columns.compute_bounds(col: 0, row: 0, width: 30, height: 55)

    columns.each_column do |_index, bounds|
      assert_equal 55, bounds[:height], "Each column should get full height"
    end
  end

  def test_week_columns_quantize_perfectly
    # 35 boxes / 7 days = 5 boxes per day
    columns = BujoPdf::DSL::ColumnsNode.new(count: 7)
    columns.compute_bounds(col: 0, row: 0, width: 35, height: 55)

    columns.each_column do |index, bounds|
      assert_equal 5, bounds[:width], "Day column should be exactly 5 boxes"
      assert_equal index * 5, bounds[:col], "Column starts align to grid"
    end
  end
end

class TestRowsNode < Minitest::Test
  def test_rows_with_count
    rows = BujoPdf::DSL::RowsNode.new(count: 4)

    assert_equal 4, rows.row_count
  end

  def test_rows_with_heights
    rows = BujoPdf::DSL::RowsNode.new(heights: [3, 1, 8])

    assert_equal 3, rows.row_count
  end

  def test_equal_rows_layout
    rows = BujoPdf::DSL::RowsNode.new(count: 5)
    rows.compute_bounds(col: 0, row: 0, width: 43, height: 50)

    # 50 / 5 = 10 boxes per row
    rows.each_row do |index, bounds|
      assert_equal 10, bounds[:height], "Row #{index} should be 10 boxes tall"
      assert_equal index * 10, bounds[:row], "Row #{index} should start at #{index * 10}"
    end
  end

  def test_specified_heights
    rows = BujoPdf::DSL::RowsNode.new(heights: [3, 1, 8])
    rows.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    assert_equal 3, rows.row_bounds(0)[:height]
    assert_equal 1, rows.row_bounds(1)[:height]
    assert_equal 8, rows.row_bounds(2)[:height]

    assert_equal 0, rows.row_bounds(0)[:row]
    assert_equal 3, rows.row_bounds(1)[:row]
    assert_equal 4, rows.row_bounds(2)[:row]
  end

  def test_rows_full_width
    rows = BujoPdf::DSL::RowsNode.new(count: 3)
    rows.compute_bounds(col: 0, row: 0, width: 43, height: 30)

    rows.each_row do |_index, bounds|
      assert_equal 43, bounds[:width], "Each row should get full width"
    end
  end
end

class TestGridNode < Minitest::Test
  def test_grid_creates_cells
    grid = BujoPdf::DSL::GridNode.new(cols: 7, rows: 5)
    grid.compute_bounds(col: 0, row: 0, width: 35, height: 50)

    # Should have 35 children (7 * 5)
    assert_equal 35, grid.children.length
  end

  def test_grid_cell_bounds
    grid = BujoPdf::DSL::GridNode.new(cols: 7, rows: 5)
    grid.compute_bounds(col: 0, row: 0, width: 35, height: 50)

    # 35 / 7 = 5 boxes wide, 50 / 5 = 10 boxes tall
    cell = grid.cell_bounds(0, 0)
    assert_equal 0, cell[:col]
    assert_equal 0, cell[:row]
    assert_equal 5, cell[:width]
    assert_equal 10, cell[:height]

    # Cell at (2, 3)
    cell = grid.cell_bounds(2, 3)
    assert_equal 15, cell[:col]  # 3 columns * 5
    assert_equal 20, cell[:row]  # 2 rows * 10
  end

  def test_grid_each_cell
    grid = BujoPdf::DSL::GridNode.new(cols: 3, rows: 2)
    grid.compute_bounds(col: 0, row: 0, width: 30, height: 20)

    cells = []
    grid.each_cell do |row_idx, col_idx, bounds|
      cells << [row_idx, col_idx]
    end

    expected = [
      [0, 0], [0, 1], [0, 2],
      [1, 0], [1, 1], [1, 2]
    ]
    assert_equal expected, cells
  end
end
