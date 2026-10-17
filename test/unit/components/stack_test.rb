# frozen_string_literal: true

require_relative '../../test_helper'

class TestStack < Minitest::Test
  def rect(col, row, width, height)
    BujoPdf::GridRect.new(col, row, width, height)
  end

  def column(area = rect(2, 4, 38, 20), gap: 0)
    stack = BujoPdf::Components::Stack.new(area, axis: :vertical, gap: gap)
    yield stack
    stack.cells
  end

  def row(area = rect(2, 4, 30, 10), gap: 0)
    stack = BujoPdf::Components::Stack.new(area, axis: :horizontal, gap: gap)
    yield stack
    stack.cells
  end

  # ============================================
  # Cursor
  # ============================================

  def test_column_stacks_slots_top_down
    cells = column { |c| c.slot(3); c.slot(5) }

    assert_equal [rect(2, 4, 38, 3), rect(2, 7, 38, 5)], cells
  end

  def test_gap_goes_between_slots_not_after_the_last
    cells = column(rect(2, 4, 38, 9), gap: 1) { |c| c.slot(4); c.slot(4) }

    assert_equal [rect(2, 4, 38, 4), rect(2, 9, 38, 4)], cells
  end

  def test_unclaimed_rows_are_left_at_the_end
    cells = column { |c| c.slot(3) }

    assert_equal [rect(2, 4, 38, 3)], cells
  end

  def test_empty_stack_has_no_cells
    assert_equal [], column { |_c| nil }
  end

  # ============================================
  # :fill
  # ============================================

  def test_fill_takes_the_remainder_wherever_it_is_declared
    cells = column(rect(2, 4, 38, 20), gap: 1) do |c|
      c.slot(3)
      c.slot(:fill)
      c.slot(5)
    end

    assert_equal [rect(2, 4, 38, 3), rect(2, 8, 38, 10), rect(2, 19, 38, 5)], cells
  end

  def test_fills_share_the_remainder_with_leftover_rows_going_first
    cells = column(rect(0, 0, 10, 11)) do |c|
      c.slot(:fill)
      c.slot(:fill)
      c.slot(:fill)
    end

    assert_equal [4, 4, 3], cells.map(&:height)
    assert_equal [0, 4, 8], cells.map(&:row)
  end

  # ============================================
  # Overflow
  # ============================================

  def test_fixed_slots_taller_than_the_area_raise
    error = assert_raises(ArgumentError) do
      column(rect(2, 4, 38, 10), gap: 1) { |c| c.slot(5); c.slot(5) }
    end

    assert_match(/11 rows/, error.message)
    assert_match(/10/, error.message)
  end

  def test_fill_with_no_room_left_raises
    assert_raises(ArgumentError) do
      column(rect(2, 4, 38, 10), gap: 1) { |c| c.slot(9); c.slot(:fill) }
    end
  end

  # ============================================
  # Validation
  # ============================================

  def test_slot_size_must_be_a_positive_integer_or_fill
    [0, -1, 1.5, :auto, nil].each do |size|
      assert_raises(ArgumentError, "expected #{size.inspect} to be rejected") do
        column { |c| c.slot(size) }
      end
    end
  end

  def test_gap_must_be_a_non_negative_integer
    assert_raises(ArgumentError) { column(gap: -1) { |c| c.slot(1) } }
  end

  def test_axis_must_be_vertical_or_horizontal
    assert_raises(ArgumentError) do
      BujoPdf::Components::Stack.new(rect(0, 0, 10, 10), axis: :diagonal)
    end
  end

  # ============================================
  # Horizontal
  # ============================================

  def test_row_lays_slots_out_left_to_right
    cells = row(rect(2, 4, 30, 10), gap: 2) do |r|
      r.slot(8)
      r.slot(:fill)
    end

    assert_equal [rect(2, 4, 8, 10), rect(12, 4, 20, 10)], cells
  end

  def test_row_overflow_names_columns
    error = assert_raises(ArgumentError) { row(rect(0, 0, 5, 1)) { |r| r.slot(6) } }

    assert_match(/columns/, error.message)
  end

  # ============================================
  # Rendering
  # ============================================

  def test_render_calls_each_slot_block_with_its_cell_in_order
    stack = BujoPdf::Components::Stack.new(rect(2, 4, 38, 20), axis: :vertical, gap: 1)
    seen = []
    stack.slot(3) { |cell| seen << [:a, cell] }
    stack.slot(2)
    stack.slot(:fill) { |cell| seen << [:b, cell] }

    cells = stack.render

    assert_equal [[:a, rect(2, 4, 38, 3)], [:b, rect(2, 11, 38, 13)]], seen
    assert_equal 3, cells.length
  end
end

class TestStackMixin < Minitest::Test
  class TestIncluder
    include BujoPdf::Components::Stack::Mixin

    attr_reader :pdf, :grid

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
    end
  end

  def setup
    @includer = TestIncluder.new
  end

  def test_pages_get_column_and_row_verbs
    assert BujoPdf::Pages::Base.method_defined?(:column)
    assert BujoPdf::Pages::Base.method_defined?(:row)
  end

  def test_column_takes_coordinates_and_returns_cells
    cells = @includer.column(2, 4, 38, 10, gap: 1) do |c|
      c.slot(4)
      c.slot(:fill)
    end

    assert_equal [BujoPdf::GridRect.new(2, 4, 38, 4), BujoPdf::GridRect.new(2, 9, 38, 5)], cells
  end

  def test_row_takes_a_cell
    cells = @includer.row(BujoPdf::GridRect.new(2, 4, 10, 3)) do |r|
      r.slot(:fill)
      r.slot(4)
    end

    assert_equal [BujoPdf::GridRect.new(2, 4, 6, 3), BujoPdf::GridRect.new(8, 4, 4, 3)], cells
  end

  def test_slot_blocks_are_plain_closures
    @includer.column(2, 4, 38, 10) do |c|
      c.slot(2) { |cell| @seen = cell }
    end

    assert_equal BujoPdf::GridRect.new(2, 4, 38, 2), @seen
  end

  def test_stacks_nest
    inner_cells = nil
    @includer.column(0, 0, 20, 10) do |c|
      c.slot(4) do |cell|
        inner_cells = @includer.row(cell, gap: 2) { |r| r.slot(:fill); r.slot(:fill) }
      end
    end

    assert_equal [BujoPdf::GridRect.new(0, 0, 9, 4), BujoPdf::GridRect.new(11, 0, 9, 4)], inner_cells
  end
end
