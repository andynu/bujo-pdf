# frozen_string_literal: true

require_relative '../../test_helper'

class TestGridRectFrom < Minitest::Test
  def test_from_returns_a_grid_rect_unchanged
    rect = BujoPdf::GridRect.new(2, 4, 38, 12)

    assert_same rect, BujoPdf::GridRect.from(rect)
  end

  def test_from_builds_a_rect_from_explicit_coordinates
    assert_equal BujoPdf::GridRect.new(2, 4, 38, 12), BujoPdf::GridRect.from(2, 4, 38, 12)
  end

  def test_from_rejects_a_rect_plus_coordinates
    rect = BujoPdf::GridRect.new(2, 4, 38, 12)

    assert_raises(ArgumentError) { BujoPdf::GridRect.from(rect, 4) }
  end

  def test_from_rejects_partial_coordinates
    assert_raises(ArgumentError) { BujoPdf::GridRect.from(2, 4, 38) }
  end
end
