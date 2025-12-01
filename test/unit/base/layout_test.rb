#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestLayout < Minitest::Test
  def test_initialize_with_required_params
    layout = BujoPdf::Layout.new(
      content_area: { col: 0, row: 0, width: 43, height: 55 }
    )

    assert_equal "default", layout.name
    assert_equal({ col: 0, row: 0, width: 43, height: 55 }, layout.content_area_spec)
  end

  def test_initialize_with_name
    layout = BujoPdf::Layout.new(
      name: "custom",
      content_area: { col: 0, row: 0, width: 43, height: 55 }
    )

    assert_equal "custom", layout.name
  end

  def test_initialize_with_sidebars
    sidebars = [
      { position: :left, col: 0, row: 0, width: 2, height: 55 }
    ]

    layout = BujoPdf::Layout.new(
      content_area: { col: 2, row: 0, width: 41, height: 55 },
      sidebars: sidebars
    )

    assert_equal 1, layout.sidebar_specs.length
    assert_equal :left, layout.sidebar_specs.first[:position]
  end

  def test_initialize_with_options
    layout = BujoPdf::Layout.new(
      content_area: { col: 0, row: 0, width: 43, height: 55 },
      background: false,
      debug: true,
      footer: true,
      background_type: :ruled
    )

    assert_equal false, layout.background_enabled?
    assert_equal true, layout.debug_mode?
    assert_equal true, layout.footer_enabled?
    assert_equal :ruled, layout.background_type
  end

  def test_background_enabled_default
    layout = BujoPdf::Layout.new(
      content_area: { col: 0, row: 0, width: 43, height: 55 }
    )

    assert_equal true, layout.background_enabled?
  end

  def test_background_type_default
    layout = BujoPdf::Layout.new(
      content_area: { col: 0, row: 0, width: 43, height: 55 }
    )

    assert_equal :dot_grid, layout.background_type
  end

  def test_debug_mode_default
    layout = BujoPdf::Layout.new(
      content_area: { col: 0, row: 0, width: 43, height: 55 }
    )

    assert_equal false, layout.debug_mode?
  end

  def test_footer_enabled_default
    layout = BujoPdf::Layout.new(
      content_area: { col: 0, row: 0, width: 43, height: 55 }
    )

    assert_equal false, layout.footer_enabled?
  end

  def test_sidebar_finds_by_position
    sidebars = [
      { position: :left, col: 0, row: 0, width: 2, height: 55 },
      { position: :right, col: 42, row: 0, width: 1, height: 55 }
    ]

    layout = BujoPdf::Layout.new(
      content_area: { col: 2, row: 0, width: 40, height: 55 },
      sidebars: sidebars
    )

    left = layout.sidebar(:left)
    right = layout.sidebar(:right)
    top = layout.sidebar(:top)

    assert_equal :left, left[:position]
    assert_equal :right, right[:position]
    assert_nil top
  end

  def test_validate_content_area_missing_keys
    error = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 0, row: 0 }  # Missing width and height
      )
    end

    assert_match(/missing required keys/, error.message)
    assert_match(/width/, error.message)
    assert_match(/height/, error.message)
  end

  def test_validate_content_area_col_out_of_bounds
    error = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: -1, row: 0, width: 43, height: 55 }
      )
    end

    assert_match(/col must be 0-42/, error.message)

    error2 = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 43, row: 0, width: 10, height: 55 }
      )
    end

    assert_match(/col must be 0-42/, error2.message)
  end

  def test_validate_content_area_row_out_of_bounds
    error = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 0, row: -1, width: 43, height: 55 }
      )
    end

    assert_match(/row must be 0-54/, error.message)

    error2 = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 0, row: 55, width: 43, height: 10 }
      )
    end

    assert_match(/row must be 0-54/, error2.message)
  end

  def test_validate_content_area_width_invalid
    error = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 0, row: 0, width: 0, height: 55 }
      )
    end

    assert_match(/width invalid/, error.message)

    error2 = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 40, row: 0, width: 10, height: 55 }  # Would exceed grid
      )
    end

    assert_match(/width invalid/, error2.message)
  end

  def test_validate_content_area_height_invalid
    error = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 0, row: 0, width: 43, height: 0 }
      )
    end

    assert_match(/height invalid/, error.message)

    error2 = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 0, row: 50, width: 43, height: 10 }  # Would exceed grid
      )
    end

    assert_match(/height invalid/, error2.message)
  end

  def test_validate_sidebars_missing_keys
    error = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 0, row: 0, width: 43, height: 55 },
        sidebars: [
          { position: :left, col: 0 }  # Missing row, width, height
        ]
      )
    end

    assert_match(/missing required keys/, error.message)
  end

  def test_validate_sidebars_invalid_position
    error = assert_raises(ArgumentError) do
      BujoPdf::Layout.new(
        content_area: { col: 0, row: 0, width: 43, height: 55 },
        sidebars: [
          { position: :invalid, col: 0, row: 0, width: 2, height: 55 }
        ]
      )
    end

    assert_match(/invalid position/, error.message)
  end
end

class TestLayoutFactories < Minitest::Test
  def test_full_page_factory
    layout = BujoPdf::Layout.full_page

    assert_equal "full_page", layout.name
    assert_equal 0, layout.content_area_spec[:col]
    assert_equal 0, layout.content_area_spec[:row]
    assert_equal 43, layout.content_area_spec[:width]
    assert_equal 55, layout.content_area_spec[:height]
    assert_empty layout.sidebar_specs
  end

  def test_full_page_factory_with_options
    layout = BujoPdf::Layout.full_page(debug: true)

    assert_equal true, layout.debug_mode?
  end

  def test_with_sidebars_left_only
    layout = BujoPdf::Layout.with_sidebars(left_width: 3)

    assert_equal "with_sidebars", layout.name
    assert_equal 3, layout.content_area_spec[:col]
    assert_equal 0, layout.content_area_spec[:row]
    assert_equal 40, layout.content_area_spec[:width]
    assert_equal 55, layout.content_area_spec[:height]

    assert_equal 1, layout.sidebar_specs.length
    assert_equal :left, layout.sidebar_specs.first[:position]
    assert_equal 3, layout.sidebar_specs.first[:width]
  end

  def test_with_sidebars_right_only
    layout = BujoPdf::Layout.with_sidebars(right_width: 2)

    assert_equal 0, layout.content_area_spec[:col]
    assert_equal 41, layout.content_area_spec[:width]

    assert_equal 1, layout.sidebar_specs.length
    assert_equal :right, layout.sidebar_specs.first[:position]
    assert_equal 41, layout.sidebar_specs.first[:col]
    assert_equal 2, layout.sidebar_specs.first[:width]
  end

  def test_with_sidebars_both
    layout = BujoPdf::Layout.with_sidebars(left_width: 2, right_width: 1)

    assert_equal 2, layout.content_area_spec[:col]
    assert_equal 40, layout.content_area_spec[:width]
    assert_equal 2, layout.sidebar_specs.length
  end

  def test_with_sidebars_top_nav
    layout = BujoPdf::Layout.with_sidebars(top_height: 2)

    assert_equal 0, layout.content_area_spec[:col]
    assert_equal 2, layout.content_area_spec[:row]
    assert_equal 43, layout.content_area_spec[:width]
    assert_equal 53, layout.content_area_spec[:height]

    top = layout.sidebar(:top)
    assert_equal 0, top[:row]
    assert_equal 2, top[:height]
  end

  def test_with_sidebars_all_three
    layout = BujoPdf::Layout.with_sidebars(left_width: 2, right_width: 1, top_height: 2)

    assert_equal 2, layout.content_area_spec[:col]
    assert_equal 2, layout.content_area_spec[:row]
    assert_equal 40, layout.content_area_spec[:width]
    assert_equal 53, layout.content_area_spec[:height]

    assert_equal 3, layout.sidebar_specs.length
  end

  def test_with_sidebars_with_options
    layout = BujoPdf::Layout.with_sidebars(left_width: 2, footer: true)

    assert_equal true, layout.footer_enabled?
  end

  def test_weekly_layout_factory
    layout = BujoPdf::Layout.weekly_layout

    assert_equal 2, layout.content_area_spec[:col]
    assert_equal 2, layout.content_area_spec[:row]
    assert_equal 40, layout.content_area_spec[:width]
    assert_equal 53, layout.content_area_spec[:height]
    assert_equal 3, layout.sidebar_specs.length
  end

  def test_weekly_layout_with_options
    layout = BujoPdf::Layout.weekly_layout(debug: true)

    assert_equal true, layout.debug_mode?
  end

  def test_year_overview_layout_factory
    layout = BujoPdf::Layout.year_overview_layout

    # Same structure as weekly layout
    assert_equal 2, layout.content_area_spec[:col]
    assert_equal 2, layout.content_area_spec[:row]
    assert_equal 40, layout.content_area_spec[:width]
    assert_equal 53, layout.content_area_spec[:height]
  end

  def test_year_overview_layout_with_options
    layout = BujoPdf::Layout.year_overview_layout(background_type: :ruled)

    assert_equal :ruled, layout.background_type
  end
end
