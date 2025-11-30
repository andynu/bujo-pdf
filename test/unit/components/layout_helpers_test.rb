#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf'

class TestGridSystemMargins < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_margins_uniform
    result = @grid.margins(col: 0, row: 0, width: 43, height: 55, all: 2)

    assert_equal 2, result.col
    assert_equal 2, result.row
    assert_equal 39, result.width
    assert_equal 51, result.height
  end

  def test_margins_specific_sides
    result = @grid.margins(col: 0, row: 0, width: 43, height: 55,
                           left: 3, right: 1, top: 2, bottom: 5)

    assert_equal 3, result.col
    assert_equal 2, result.row
    assert_equal 39, result.width  # 43 - 3 - 1
    assert_equal 48, result.height # 55 - 2 - 5
  end

  def test_margins_with_offset_origin
    result = @grid.margins(col: 5, row: 10, width: 30, height: 40, all: 2)

    assert_equal 7, result.col   # 5 + 2
    assert_equal 12, result.row  # 10 + 2
    assert_equal 26, result.width
    assert_equal 36, result.height
  end

  def test_margins_all_with_override
    # 'all' provides defaults, but specific values override
    result = @grid.margins(col: 0, row: 0, width: 43, height: 55,
                           all: 2, left: 5)

    assert_equal 5, result.col   # left overrides all
    assert_equal 2, result.row   # top uses all
    assert_equal 36, result.width  # 43 - 5 - 2
    assert_equal 51, result.height # 55 - 2 - 2
  end

  def test_margins_returns_cell_struct
    result = @grid.margins(col: 0, row: 0, width: 43, height: 55, all: 1)

    assert_instance_of Cell, result
    assert_respond_to result, :col
    assert_respond_to result, :row
    assert_respond_to result, :width
    assert_respond_to result, :height
  end

  def test_margins_no_margins_returns_same_dimensions
    result = @grid.margins(col: 5, row: 10, width: 20, height: 30)

    assert_equal 5, result.col
    assert_equal 10, result.row
    assert_equal 20, result.width
    assert_equal 30, result.height
  end
end

class TestLayoutHelpersMixin < Minitest::Test
  include BujoPdf::Components::LayoutHelpers::Mixin

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_margins_verb
    result = margins(0, 0, 43, 55, all: 2)

    assert_instance_of Cell, result
    assert_equal 2, result.col
    assert_equal 2, result.row
    assert_equal 39, result.width
    assert_equal 51, result.height
  end

  def test_margins_verb_specific_sides
    result = margins(0, 0, 43, 55, left: 3, right: 1, top: 2, bottom: 5)

    assert_equal 3, result.col
    assert_equal 2, result.row
    assert_equal 39, result.width
    assert_equal 48, result.height
  end

  def test_composability_margins_then_divide_columns
    # Common pattern: margin first, then split using grid
    inner = margins(0, 0, 43, 55, all: 2)
    cols = @grid.divide_columns(col: inner.col, width: inner.width, count: 2, gap: 1)

    left = cols[0]
    assert_equal 2, left.col    # Starts at margin
    assert_equal 19, left.width  # (39 - 1) / 2
  end
end
