#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestLayoutFactory < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_available_layouts_includes_all_registered
    layouts = BujoPdf::Layouts::LayoutFactory.available_layouts

    assert_includes layouts, :full_page
    assert_includes layouts, :standard_with_sidebars
    assert_includes layouts, :daily_with_sidebars
    assert_includes layouts, :configurable
  end

  def test_create_unknown_layout_raises_argument_error
    error = assert_raises(ArgumentError) do
      BujoPdf::Layouts::LayoutFactory.create(:unknown_layout, @pdf, @grid)
    end

    assert_match(/Unknown layout: unknown_layout/, error.message)
    assert_match(/Available layouts:/, error.message)
  end
end

class TestLayoutFactoryNamedPresets < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_create_full_page_layout
    layout = BujoPdf::Layouts::LayoutFactory.create(:full_page, @pdf, @grid)

    assert_instance_of BujoPdf::Layouts::FullPageLayout, layout
  end

  def test_create_standard_with_sidebars_layout
    layout = BujoPdf::Layouts::LayoutFactory.create(:standard_with_sidebars, @pdf, @grid)

    assert_instance_of BujoPdf::Layouts::StandardWithSidebarsLayout, layout
  end

  def test_create_daily_with_sidebars_layout
    layout = BujoPdf::Layouts::LayoutFactory.create(:daily_with_sidebars, @pdf, @grid)

    assert_instance_of BujoPdf::Layouts::DailyWithSidebarsLayout, layout
  end

  def test_create_configurable_layout
    layout = BujoPdf::Layouts::LayoutFactory.create(:configurable, @pdf, @grid)

    assert_instance_of BujoPdf::Layouts::ConfigurableLayout, layout
  end

  def test_create_layout_passes_options
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :standard_with_sidebars,
      @pdf,
      @grid,
      current_week: 42,
      highlight_tab: :seasonal
    )

    assert_equal 42, layout.options[:current_week]
    assert_equal :seasonal, layout.options[:highlight_tab]
  end
end

class TestLayoutFactoryChromeConfiguration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_create_with_chrome_hash_creates_configurable_layout
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: { left: :week_sidebar }
    )

    assert_instance_of BujoPdf::Layouts::ConfigurableLayout, layout
  end

  def test_create_with_chrome_hash_ignores_layout_name
    # When chrome is provided, the layout name is effectively ignored
    # and a ConfigurableLayout is always returned
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :full_page,  # This would normally create FullPageLayout
      @pdf,
      @grid,
      chrome: { left: :week_sidebar }
    )

    assert_instance_of BujoPdf::Layouts::ConfigurableLayout, layout
  end

  def test_create_with_chrome_hash_sets_chrome_spec
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: { left: :week_sidebar, right: :tab_sidebar }
    )

    spec = layout.chrome_spec
    assert_equal :week_sidebar, spec.left
    assert_equal :tab_sidebar, spec.right
    assert_nil spec.top
    assert_nil spec.bottom
  end

  def test_create_with_chrome_hash_passes_options
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: { left: :week_sidebar },
      current_week: 10,
      custom_option: 'value'
    )

    assert_equal 10, layout.options[:current_week]
    assert_equal 'value', layout.options[:custom_option]
  end

  def test_create_with_empty_chrome_hash
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: {}
    )

    assert_instance_of BujoPdf::Layouts::ConfigurableLayout, layout
    assert_empty layout.chrome_spec.active_regions
  end

  def test_create_with_all_chrome_regions
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: {
        left: :week_sidebar,
        right: :tab_sidebar,
        top: { component: :header, title: 'My Header' },
        bottom: { component: :footer }
      }
    )

    spec = layout.chrome_spec
    assert_equal :week_sidebar, spec.left
    assert_equal :tab_sidebar, spec.right
    assert_equal({ component: :header, title: 'My Header' }, spec.top)
    assert_equal({ component: :footer }, spec.bottom)
  end

  def test_create_with_complex_chrome_configuration
    tabs = [
      { label: "Year", dest: "seasonal", current: false },
      { label: "Events", dest: "year_events", current: true }
    ]
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: {
        left: { component: :week_sidebar, year: 2025 },
        right: { component: :tab_sidebar, top_tabs: tabs }
      }
    )

    spec = layout.chrome_spec
    assert_equal({ component: :week_sidebar, year: 2025 }, spec.left)
    assert_equal({ component: :tab_sidebar, top_tabs: tabs }, spec.right)
  end
end

class TestLayoutFactoryChromePresets < Minitest::Test
  def test_chrome_preset_for_full_page
    preset = BujoPdf::Layouts::LayoutFactory.chrome_preset(:full_page)

    assert_equal({}, preset)
  end

  def test_chrome_preset_for_standard_with_sidebars
    preset = BujoPdf::Layouts::LayoutFactory.chrome_preset(:standard_with_sidebars)

    assert_equal({ left: :week_sidebar, right: :tab_sidebar }, preset)
  end

  def test_chrome_preset_for_daily_with_sidebars
    preset = BujoPdf::Layouts::LayoutFactory.chrome_preset(:daily_with_sidebars)

    assert_equal({ left: :month_sidebar, right: :tab_sidebar }, preset)
  end

  def test_chrome_preset_for_unknown_layout
    preset = BujoPdf::Layouts::LayoutFactory.chrome_preset(:unknown)

    assert_nil preset
  end

  def test_chrome_preset_for_configurable
    preset = BujoPdf::Layouts::LayoutFactory.chrome_preset(:configurable)

    assert_nil preset
  end
end

class TestLayoutFactoryContentAreaConsistency < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_chrome_config_matches_standard_layout_content_area
    # Standard layout created via preset
    standard = BujoPdf::Layouts::LayoutFactory.create(:standard_with_sidebars, @pdf, @grid)

    # Equivalent layout created via chrome config
    chrome_config = BujoPdf::Layouts::LayoutFactory.chrome_preset(:standard_with_sidebars)
    configurable = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: chrome_config
    )

    assert_equal standard.content_area, configurable.content_area
  end

  def test_chrome_config_matches_daily_layout_content_area
    # Daily layout created via preset
    daily = BujoPdf::Layouts::LayoutFactory.create(:daily_with_sidebars, @pdf, @grid)

    # Equivalent layout created via chrome config
    chrome_config = BujoPdf::Layouts::LayoutFactory.chrome_preset(:daily_with_sidebars)
    configurable = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: chrome_config
    )

    assert_equal daily.content_area, configurable.content_area
  end

  def test_chrome_config_matches_full_page_layout_content_area
    # Full page layout created via preset
    full_page = BujoPdf::Layouts::LayoutFactory.create(:full_page, @pdf, @grid)

    # Equivalent layout created via chrome config
    chrome_config = BujoPdf::Layouts::LayoutFactory.chrome_preset(:full_page)
    configurable = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: chrome_config
    )

    assert_equal full_page.content_area, configurable.content_area
  end
end

class TestLayoutFactoryArbitraryChromeConfigurations < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_left_sidebar_only
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: { left: :week_sidebar }
    )

    area = layout.content_area
    assert_equal 2, area[:col]      # Left sidebar uses 2 boxes
    assert_equal 0, area[:row]
    assert_equal 41, area[:width_boxes]  # 43 - 2
    assert_equal 55, area[:height_boxes]
  end

  def test_right_sidebar_only
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: { right: :tab_sidebar }
    )

    area = layout.content_area
    assert_equal 0, area[:col]
    assert_equal 0, area[:row]
    assert_equal 42, area[:width_boxes]  # 43 - 1
    assert_equal 55, area[:height_boxes]
  end

  def test_month_sidebar_with_tab_sidebar
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: { left: :month_sidebar, right: :tab_sidebar }
    )

    area = layout.content_area
    assert_equal 2, area[:col]
    assert_equal 0, area[:row]
    assert_equal 40, area[:width_boxes]  # 43 - 2 - 1
    assert_equal 55, area[:height_boxes]
  end

  def test_custom_width_override
    layout = BujoPdf::Layouts::LayoutFactory.create(
      :configurable,
      @pdf,
      @grid,
      chrome: { left: { component: :week_sidebar, width: 3 } }
    )

    area = layout.content_area
    assert_equal 3, area[:col]      # Custom width
    assert_equal 0, area[:row]
    assert_equal 40, area[:width_boxes]  # 43 - 3
    assert_equal 55, area[:height_boxes]
  end
end
