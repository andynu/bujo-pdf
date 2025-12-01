# frozen_string_literal: true

require_relative '../../../test_helper'

class TestComponentContext < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @dot_spacing = Styling::Grid::DOT_SPACING  # 14.17
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_creates_bounding_box
    block_executed = false

    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      block_executed = true
      assert_kind_of ComponentContext, ctx
    end

    assert block_executed, "Block should be executed"
  end

  def test_initialize_stores_dimensions
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      assert_in_delta 200, ctx.width_pt, 0.01
      assert_in_delta 150, ctx.height_pt, 0.01
    end
  end

  def test_initialize_calculates_grid_dimensions
    width_pt = @dot_spacing * 10  # 10 grid boxes
    height_pt = @dot_spacing * 5  # 5 grid boxes

    ComponentContext.new(@pdf, 100, 500, width_pt, height_pt) do |ctx|
      assert_in_delta 10, ctx.width_boxes, 0.01
      assert_in_delta 5, ctx.height_boxes, 0.01
    end
  end

  def test_initialize_with_fractional_grid_dimensions
    width_pt = @dot_spacing * 7.5
    height_pt = @dot_spacing * 3.25

    ComponentContext.new(@pdf, 100, 500, width_pt, height_pt) do |ctx|
      assert_in_delta 7.5, ctx.width_boxes, 0.01
      assert_in_delta 3.25, ctx.height_boxes, 0.01
    end
  end

  # ============================================
  # Grid Coordinate Tests
  # ============================================

  def test_grid_x_at_origin
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      assert_in_delta 0, ctx.grid_x(0), 0.01
    end
  end

  def test_grid_x_with_integer
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      expected = 5 * @dot_spacing
      assert_in_delta expected, ctx.grid_x(5), 0.01
    end
  end

  def test_grid_x_with_fractional
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      expected = 2.5 * @dot_spacing
      assert_in_delta expected, ctx.grid_x(2.5), 0.01
    end
  end

  def test_grid_y_at_origin
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      # Row 0 is at the top
      assert_in_delta 150, ctx.grid_y(0), 0.01
    end
  end

  def test_grid_y_with_integer
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      expected = 150 - (5 * @dot_spacing)
      assert_in_delta expected, ctx.grid_y(5), 0.01
    end
  end

  def test_grid_y_with_fractional
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      expected = 150 - (2.5 * @dot_spacing)
      assert_in_delta expected, ctx.grid_y(2.5), 0.01
    end
  end

  # ============================================
  # Grid Dimension Tests
  # ============================================

  def test_grid_width
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      expected = 10 * @dot_spacing
      assert_in_delta expected, ctx.grid_width(10), 0.01
    end
  end

  def test_grid_width_fractional
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      expected = 3.5 * @dot_spacing
      assert_in_delta expected, ctx.grid_width(3.5), 0.01
    end
  end

  def test_grid_height
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      expected = 8 * @dot_spacing
      assert_in_delta expected, ctx.grid_height(8), 0.01
    end
  end

  def test_grid_height_fractional
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      expected = 1.5 * @dot_spacing
      assert_in_delta expected, ctx.grid_height(1.5), 0.01
    end
  end

  # ============================================
  # Division Tests
  # ============================================

  def test_divide_width_into_equal_parts
    ComponentContext.new(@pdf, 100, 500, 210, 150) do |ctx|
      part = ctx.divide_width(7)
      assert_in_delta 30, part, 0.01
    end
  end

  def test_divide_width_returns_float
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      part = ctx.divide_width(3)
      assert_kind_of Float, part
      assert_in_delta 66.6667, part, 0.01
    end
  end

  def test_divide_height_into_equal_parts
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      part = ctx.divide_height(5)
      assert_in_delta 30, part, 0.01
    end
  end

  def test_divide_height_returns_float
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      part = ctx.divide_height(4)
      assert_kind_of Float, part
      assert_in_delta 37.5, part, 0.01
    end
  end

  # ============================================
  # Region Tests
  # ============================================

  def test_region_returns_hash_with_coordinates
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      region = ctx.region(1, 2, 5, 3)

      assert_kind_of Hash, region
      assert region.key?(:x)
      assert region.key?(:y)
      assert region.key?(:width)
      assert region.key?(:height)
    end
  end

  def test_region_calculates_correct_values
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      region = ctx.region(1, 2, 5, 3)

      assert_in_delta ctx.grid_x(1), region[:x], 0.01
      assert_in_delta ctx.grid_y(2), region[:y], 0.01
      assert_in_delta ctx.grid_width(5), region[:width], 0.01
      assert_in_delta ctx.grid_height(3), region[:height], 0.01
    end
  end

  def test_region_at_origin
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      region = ctx.region(0, 0, 2, 2)

      assert_in_delta 0, region[:x], 0.01
      assert_in_delta 150, region[:y], 0.01  # Top of component
    end
  end

  # ============================================
  # Method Delegation Tests
  # ============================================

  def test_method_missing_delegates_to_pdf
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      # Test a simple PDF method
      ctx.fill_color '000000'

      # No error means delegation worked
      assert true
    end
  end

  def test_method_missing_with_args
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      ctx.text_box "Hello", at: [10, 100], width: 50

      # No error means delegation worked
      assert true
    end
  end

  def test_method_missing_with_block
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      ctx.bounding_box([0, 50], width: 50, height: 50) do
        # Inner block
      end

      assert true
    end
  end

  def test_respond_to_missing_for_pdf_methods
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      assert ctx.respond_to?(:text_box)
      assert ctx.respond_to?(:stroke_line)
      assert ctx.respond_to?(:fill_rectangle)
    end
  end

  def test_respond_to_missing_for_nonexistent_methods
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      refute ctx.respond_to?(:nonexistent_method_xyz)
    end
  end
end

class TestComponentContextUsagePatterns < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
  end

  def test_weekly_columns_pattern
    ComponentContext.new(@pdf, 50, 700, 350, 100) do |ctx|
      day_width = ctx.divide_width(7)

      assert_in_delta 50, day_width, 0.01

      # Simulate drawing 7 columns
      7.times do |i|
        day_x = i * day_width
        assert day_x < ctx.width_pt
      end
    end
  end

  def test_cornell_notes_pattern
    ComponentContext.new(@pdf, 50, 700, 400, 300) do |ctx|
      # 25%/75% split
      cues_width = ctx.divide_width(4)
      notes_width = cues_width * 3

      assert_in_delta 100, cues_width, 0.01
      assert_in_delta 300, notes_width, 0.01
      assert_in_delta ctx.width_pt, cues_width + notes_width, 0.01
    end
  end

  def test_grid_aligned_header
    ComponentContext.new(@pdf, 50, 700, 350, 100) do |ctx|
      header_height = ctx.grid_height(1.5)

      assert header_height < ctx.height_pt
      assert_in_delta 1.5 * Styling::Grid::DOT_SPACING, header_height, 0.01
    end
  end
end

class TestComponentContextEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
  end

  def test_zero_offset_grid_coordinates
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      assert_in_delta 0, ctx.grid_x(0), 0.01
      assert_in_delta ctx.height_pt, ctx.grid_y(0), 0.01
    end
  end

  def test_single_grid_box
    dot_spacing = Styling::Grid::DOT_SPACING

    ComponentContext.new(@pdf, 100, 500, dot_spacing, dot_spacing) do |ctx|
      assert_in_delta 1, ctx.width_boxes, 0.01
      assert_in_delta 1, ctx.height_boxes, 0.01
    end
  end

  def test_very_small_component
    ComponentContext.new(@pdf, 100, 500, 10, 10) do |ctx|
      assert ctx.width_boxes < 1
      assert ctx.height_boxes < 1
    end
  end

  def test_divide_by_one
    ComponentContext.new(@pdf, 100, 500, 200, 150) do |ctx|
      assert_in_delta 200, ctx.divide_width(1), 0.01
      assert_in_delta 150, ctx.divide_height(1), 0.01
    end
  end
end
