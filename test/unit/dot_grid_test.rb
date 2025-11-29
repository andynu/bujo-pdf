#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'

# Mock PDF class for testing DotGrid
class MockPDFForDotGrid
  attr_reader :circles, :fill_colors

  def initialize
    @circles = []
    @fill_colors = []
  end

  def fill_color(color)
    @fill_colors << color
  end

  def fill_circle(position, radius)
    @circles << { position: position, radius: radius }
  end
end

class TestDotGrid < Minitest::Test
  def setup
    @pdf = MockPDFForDotGrid.new
  end

  def test_draws_dots_at_grid_intersections
    # Draw on a small area: 2 boxes wide × 2 boxes tall
    width = 2 * Styling::Grid::DOT_SPACING
    height = 2 * Styling::Grid::DOT_SPACING

    DotGrid.draw(@pdf, width, height)

    # Should have 3×3 = 9 dots (including edges)
    assert_equal 9, @pdf.circles.length
  end

  def test_uses_correct_dot_radius
    DotGrid.draw(@pdf, 50, 50)

    # Check that all dots use default radius
    @pdf.circles.each do |circle|
      assert_equal Styling::Grid::DOT_RADIUS, circle[:radius]
    end
  end

  def test_uses_custom_radius
    DotGrid.draw(@pdf, 50, 50, radius: 1.0)

    # Check that all dots use custom radius
    @pdf.circles.each do |circle|
      assert_equal 1.0, circle[:radius]
    end
  end

  def test_sets_and_restores_color
    DotGrid.draw(@pdf, 50, 50)

    # Should set dot grid color first
    assert_equal Styling::Colors.DOT_GRID, @pdf.fill_colors[0]

    # Should restore to black at end
    assert_equal Styling::Colors.TEXT_BLACK, @pdf.fill_colors[-1]
  end

  def test_uses_custom_color
    DotGrid.draw(@pdf, 50, 50, color: 'FF0000')

    # Should use custom color
    assert_equal 'FF0000', @pdf.fill_colors[0]

    # Still restores to black
    assert_equal Styling::Colors.TEXT_BLACK, @pdf.fill_colors[-1]
  end

  def test_calculates_correct_grid_positions
    # Draw 1 box wide × 1 box tall
    spacing = 20
    DotGrid.draw(@pdf, spacing, spacing, spacing: spacing)

    # Should have 4 dots: (0,0), (0,20), (20,0), (20,20)
    # But in Prawn coordinates: (0,20), (0,0), (20,20), (20,0)
    assert_equal 4, @pdf.circles.length

    positions = @pdf.circles.map { |c| c[:position] }

    # Check corners exist
    assert_includes positions, [0, spacing]  # Top-left
    assert_includes positions, [0, 0]        # Bottom-left
    assert_includes positions, [spacing, spacing]  # Top-right
    assert_includes positions, [spacing, 0]        # Bottom-right
  end

  def test_full_page_grid
    # Full page should have many dots
    DotGrid.draw(@pdf, Styling::Grid::PAGE_WIDTH, Styling::Grid::PAGE_HEIGHT)

    # 43 cols × 55 rows = 44 × 56 dots (including edges)
    expected_dots = 44 * 56
    assert_equal expected_dots, @pdf.circles.length
  end
end
