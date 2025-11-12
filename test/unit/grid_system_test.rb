#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'

# Mock PDF class for testing GridSystem
class MockPDFForGridSystem
  attr_reader :calls

  def initialize
    @calls = []
  end

  def text_box(*args)
    @calls << [:text_box, args]
  end

  def link_annotation(*args)
    @calls << [:link_annotation, args]
  end
end

class TestGridSystem < Minitest::Test
  def setup
    @pdf = MockPDFForGridSystem.new
    @grid = GridSystem.new(@pdf)
  end

  def test_x_converts_column_to_coordinate
    assert_equal 0.0, @grid.x(0)
    assert_equal 14.17, @grid.x(1)
    assert_in_delta 297.57, @grid.x(21), 0.1
  end

  def test_y_converts_row_to_coordinate
    # Row 0 is at top of page (y = page_height)
    assert_equal 792, @grid.y(0)

    # Row increases downward, so y decreases
    assert_in_delta 777.83, @grid.y(1), 0.1

    # Near bottom
    assert_in_delta 12.65, @grid.y(55), 0.1
  end

  def test_width_converts_boxes_to_points
    assert_equal 14.17, @grid.width(1)
    assert_equal 141.7, @grid.width(10)
    assert_equal 7.085, @grid.width(0.5)
  end

  def test_height_converts_boxes_to_points
    assert_equal 14.17, @grid.height(1)
    assert_equal 141.7, @grid.height(10)
    assert_equal 7.085, @grid.height(0.5)
  end

  def test_rect_returns_hash_with_coordinates
    rect = @grid.rect(0, 0, 43, 55)

    assert_equal 0, rect[:x]
    assert_equal 792, rect[:y]
    assert_in_delta 609.31, rect[:width], 0.1
    assert_in_delta 779.35, rect[:height], 0.1
  end

  def test_rect_with_offset
    rect = @grid.rect(5, 10, 10, 5)

    assert_equal 70.85, rect[:x]
    assert_in_delta 650.3, rect[:y], 0.1
    assert_equal 141.7, rect[:width]
    assert_equal 70.85, rect[:height]
  end

  def test_inset_applies_padding
    rect = @grid.rect(5, 10, 10, 10)
    padded = @grid.inset(rect, 0.5)

    # Padding of 0.5 boxes = 7.085 points
    assert_in_delta rect[:x] + 7.085, padded[:x], 0.01
    assert_in_delta rect[:y] - 7.085, padded[:y], 0.01
    assert_in_delta rect[:width] - 14.17, padded[:width], 0.01
    assert_in_delta rect[:height] - 14.17, padded[:height], 0.01
  end

  def test_bottom_calculates_bottom_y
    top = @grid.y(10)
    bottom = @grid.bottom(10, 2)

    # Bottom should be 2 boxes (28.34 points) below top
    assert_in_delta top - 28.34, bottom, 0.1

    # Should equal y(10 + 2)
    assert_equal @grid.y(12), bottom
  end

  def test_text_box_calls_pdf
    @grid.text_box("Hello", 5, 10, 10, 2, align: :center)

    assert_equal 1, @pdf.calls.length
    call = @pdf.calls[0]

    assert_equal :text_box, call[0]
    assert_equal "Hello", call[1][0]
    # Check that options were passed (args will include keyword args)
    assert call[1].any? { |arg| arg.is_a?(Hash) && arg[:align] == :center }
  end

  def test_link_calls_pdf
    @grid.link(5, 10, 10, 2, "week_1")

    assert_equal 1, @pdf.calls.length
    call = @pdf.calls[0]

    assert_equal :link_annotation, call[0]
  end

  def test_configurable_dot_spacing
    grid = GridSystem.new(@pdf, dot_spacing: 20)

    assert_equal 20, grid.x(1)
    assert_equal 200, grid.width(10)
  end

  def test_configurable_page_dimensions
    grid = GridSystem.new(@pdf, page_width: 500, page_height: 700)

    assert_equal 500, grid.page_width
    assert_equal 700, grid.page_height
    assert_equal 700, grid.y(0)  # Top of page
  end

  def test_cols_and_rows_calculated
    assert_equal 43, @grid.cols
    assert_equal 55, @grid.rows
  end
end
