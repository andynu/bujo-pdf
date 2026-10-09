#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestChromeSpec < Minitest::Test
  def test_initialize_with_no_arguments
    spec = BujoPdf::Layouts::ChromeSpec.new

    assert_nil spec.left
    assert_nil spec.right
    assert_nil spec.top
    assert_nil spec.bottom
  end

  def test_initialize_with_symbol_regions
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )

    assert_equal :week_sidebar, spec.left
    assert_equal :nav_tabs, spec.right
    assert_nil spec.top
    assert_nil spec.bottom
  end

  def test_initialize_with_hash_regions
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :week_sidebar, year: 2025 },
      right: { component: :nav_tabs, highlight: :seasonal }
    )

    assert_equal({ component: :week_sidebar, year: 2025 }, spec.left)
    assert_equal({ component: :nav_tabs, highlight: :seasonal }, spec.right)
  end

  def test_initialize_with_proc_regions
    my_proc = ->(canvas, page) { canvas.draw_custom(page) }
    spec = BujoPdf::Layouts::ChromeSpec.new(left: my_proc)

    assert_instance_of Proc, spec.left
    assert_equal my_proc, spec.left
  end

  def test_initialize_with_all_regions
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :left_sidebar,
      right: :right_sidebar,
      top: :top_bar,
      bottom: :footer
    )

    assert_equal :left_sidebar, spec.left
    assert_equal :right_sidebar, spec.right
    assert_equal :top_bar, spec.top
    assert_equal :footer, spec.bottom
  end
end

class TestChromeSpecActiveRegions < Minitest::Test
  def test_active_regions_returns_empty_hash_when_all_nil
    spec = BujoPdf::Layouts::ChromeSpec.new

    assert_equal({}, spec.active_regions)
  end

  def test_active_regions_returns_only_non_nil_regions
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )

    result = spec.active_regions

    assert_equal 2, result.size
    assert_equal :week_sidebar, result[:left]
    assert_equal :nav_tabs, result[:right]
    refute result.key?(:top)
    refute result.key?(:bottom)
  end

  def test_active_regions_returns_all_regions_when_all_set
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :left_sidebar,
      right: :right_sidebar,
      top: :top_bar,
      bottom: :footer
    )

    result = spec.active_regions

    assert_equal 4, result.size
    assert_equal :left_sidebar, result[:left]
    assert_equal :right_sidebar, result[:right]
    assert_equal :top_bar, result[:top]
    assert_equal :footer, result[:bottom]
  end
end

class TestChromeSpecContentArea < Minitest::Test
  def test_content_area_full_page_when_no_chrome
    spec = BujoPdf::Layouts::ChromeSpec.new

    area = spec.content_area(43, 55)

    assert_equal 0, area[:col]
    assert_equal 0, area[:row]
    assert_equal 43, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_left_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)

    area = spec.content_area(43, 55)

    assert_equal 2, area[:col]
    assert_equal 0, area[:row]
    assert_equal 41, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_right_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(right: :nav_tabs)

    area = spec.content_area(43, 55)

    assert_equal 0, area[:col]
    assert_equal 0, area[:row]
    assert_equal 42, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_left_and_right_sidebars
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )

    area = spec.content_area(43, 55)

    assert_equal 2, area[:col]
    assert_equal 0, area[:row]
    assert_equal 40, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_uses_default_page_dimensions
    spec = BujoPdf::Layouts::ChromeSpec.new

    area = spec.content_area

    assert_equal 0, area[:col]
    assert_equal 0, area[:row]
    assert_equal 43, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_custom_width_in_hash
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :custom_sidebar, width: 5 }
    )

    area = spec.content_area(43, 55)

    assert_equal 5, area[:col]
    assert_equal 38, area[:width_boxes]
  end

  def test_content_area_with_top_and_bottom_chrome
    spec = BujoPdf::Layouts::ChromeSpec.new(
      top: { component: :header, height: 3 },
      bottom: { component: :footer, height: 2 }
    )

    area = spec.content_area(43, 55)

    assert_equal 0, area[:col]
    assert_equal 3, area[:row]
    assert_equal 43, area[:width_boxes]
    assert_equal 50, area[:height_boxes]
  end

  def test_content_area_with_all_regions
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :left, width: 3 },
      right: { component: :right, width: 2 },
      top: { component: :top, height: 4 },
      bottom: { component: :bottom, height: 1 }
    )

    area = spec.content_area(43, 55)

    assert_equal 3, area[:col]
    assert_equal 4, area[:row]
    assert_equal 38, area[:width_boxes]
    assert_equal 50, area[:height_boxes]
  end
end

class TestChromeSpecRegionWidth < Minitest::Test
  def test_region_width_returns_zero_for_nil_region
    spec = BujoPdf::Layouts::ChromeSpec.new

    assert_equal 0, spec.region_width(:left)
    assert_equal 0, spec.region_width(:right)
    assert_equal 0, spec.region_width(:top)
    assert_equal 0, spec.region_width(:bottom)
  end

  def test_region_width_returns_default_for_symbol
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )

    assert_equal 2, spec.region_width(:left)
    assert_equal 1, spec.region_width(:right)
  end

  def test_region_width_returns_custom_width_from_hash
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :custom, width: 5 }
    )

    assert_equal 5, spec.region_width(:left)
  end

  def test_region_width_returns_custom_height_from_hash
    spec = BujoPdf::Layouts::ChromeSpec.new(
      top: { component: :header, height: 4 }
    )

    assert_equal 4, spec.region_width(:top)
  end

  def test_region_width_falls_back_to_default_when_hash_lacks_width
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :sidebar, year: 2025 }
    )

    assert_equal 2, spec.region_width(:left)
  end
end

class TestChromeSpecWith < Minitest::Test
  def test_with_returns_new_instance
    original = BujoPdf::Layouts::ChromeSpec.new(left: :original)
    modified = original.with(right: :added)

    refute_same original, modified
    assert_equal :original, original.left
    assert_nil original.right
    assert_equal :original, modified.left
    assert_equal :added, modified.right
  end

  def test_with_replaces_existing_region
    original = BujoPdf::Layouts::ChromeSpec.new(left: :original)
    modified = original.with(left: :replaced)

    assert_equal :original, original.left
    assert_equal :replaced, modified.left
  end

  def test_with_multiple_changes
    original = BujoPdf::Layouts::ChromeSpec.new(left: :left_only)
    modified = original.with(
      right: :new_right,
      top: :new_top
    )

    assert_equal :left_only, modified.left
    assert_equal :new_right, modified.right
    assert_equal :new_top, modified.top
    assert_nil modified.bottom
  end
end

class TestChromeSpecEquality < Minitest::Test
  def test_equal_specs_are_equal
    spec1 = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )
    spec2 = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )

    assert_equal spec1, spec2
    assert spec1.eql?(spec2)
  end

  def test_different_specs_are_not_equal
    spec1 = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    spec2 = BujoPdf::Layouts::ChromeSpec.new(left: :other_sidebar)

    refute_equal spec1, spec2
  end

  def test_equality_with_non_chrome_spec
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :sidebar)

    refute_equal spec, { left: :sidebar }
    refute_equal spec, nil
    refute_equal spec, "sidebar"
  end

  def test_hash_equality
    spec1 = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )
    spec2 = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )

    assert_equal spec1.hash, spec2.hash
  end

  def test_hash_can_be_used_as_hash_key
    spec1 = BujoPdf::Layouts::ChromeSpec.new(left: :sidebar)
    spec2 = BujoPdf::Layouts::ChromeSpec.new(left: :sidebar)

    hash = {}
    hash[spec1] = "value"

    assert_equal "value", hash[spec2]
  end
end

class TestChromeSpecInspect < Minitest::Test
  def test_inspect_empty_spec
    spec = BujoPdf::Layouts::ChromeSpec.new

    assert_match(/ChromeSpec.*full page/, spec.inspect)
  end

  def test_inspect_with_regions
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :nav_tabs
    )

    result = spec.inspect

    assert_match(/ChromeSpec/, result)
    assert_match(/left:.*week_sidebar/, result)
    assert_match(/right:.*nav_tabs/, result)
  end
end
