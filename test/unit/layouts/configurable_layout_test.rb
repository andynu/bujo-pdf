#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestConfigurableLayout < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_initialize_creates_empty_chrome_spec_when_none_provided
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid)

    assert_instance_of BujoPdf::Layouts::ChromeSpec, layout.chrome_spec
    assert_empty layout.chrome_spec.active_regions
  end

  def test_initialize_accepts_chrome_spec
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    assert_same spec, layout.chrome_spec
  end

  def test_initialize_stores_options
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, foo: 'bar', baz: 42)

    assert_equal 'bar', layout.options[:foo]
    assert_equal 42, layout.options[:baz]
  end
end

class TestConfigurableLayoutContentArea < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_content_area_without_chrome_spec_returns_full_page
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid)

    area = layout.content_area

    assert_equal 0, area[:col]
    assert_equal 0, area[:row]
    assert_equal 43, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_empty_chrome_spec_returns_full_page
    spec = BujoPdf::Layouts::ChromeSpec.new
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 0, area[:col]
    assert_equal 0, area[:row]
    assert_equal 43, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_left_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 2, area[:col]
    assert_equal 0, area[:row]
    assert_equal 41, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_right_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(right: :tab_sidebar)
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 0, area[:col]
    assert_equal 0, area[:row]
    assert_equal 42, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_left_and_right_sidebars
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :tab_sidebar
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 2, area[:col]
    assert_equal 0, area[:row]
    assert_equal 40, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end
end

class TestConfigurableLayoutRenderBefore < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    create_stub_stamp(@pdf, 'page_dots')
    @grid = GridSystem.new(@pdf)
    @context = BujoPdf::RenderContext.new(
      page_key: :week_10,
      page_number: 10,
      year: 2025,
      total_weeks: 52
    )
    @page = MockPage.new(@pdf, @context)
  end

  def test_render_before_without_chrome_renders_nothing
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid)

    # Should not raise
    layout.render_before(@page)
  end

  def test_render_before_renders_left_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should render week sidebar without raising
    layout.render_before(@page)
  end

  def test_render_before_renders_right_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(right: :tab_sidebar)
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should render tab sidebar without raising
    layout.render_before(@page)
  end

  def test_render_before_renders_both_sidebars
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :tab_sidebar
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should render both sidebars without raising
    layout.render_before(@page)
  end

  def test_render_before_with_hash_config
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :week_sidebar, year: 2025 }
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should handle hash configuration
    layout.render_before(@page)
  end

  def test_render_before_with_tab_sidebar_and_tabs
    tabs = [
      { label: "Year", dest: "seasonal", current: false },
      { label: "Events", dest: "year_events", current: false }
    ]
    spec = BujoPdf::Layouts::ChromeSpec.new(
      right: { component: :tab_sidebar, top_tabs: tabs }
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should render tab sidebar with custom tabs
    layout.render_before(@page)
  end
end

class TestConfigurableLayoutStandardPreset < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    create_stub_stamp(@pdf, 'page_dots')
    @grid = GridSystem.new(@pdf)
    @context = BujoPdf::RenderContext.new(
      page_key: :week_10,
      page_number: 10,
      year: 2025,
      total_weeks: 52
    )
    @page = MockPage.new(@pdf, @context)
  end

  def test_standard_preset_content_area
    # ConfigurableLayout with week + tab sidebars (standard preset)
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :tab_sidebar
    )
    configurable = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Expected content area for standard layout
    expected = { col: 2, row: 0, width_boxes: 40, height_boxes: 55 }
    assert_equal expected, configurable.content_area
  end

  def test_can_render_with_standard_preset
    # ConfigurableLayout with week + tab sidebars
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :tab_sidebar
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should render successfully
    layout.render_before(@page)
    layout.render_after(@page)
  end
end

class TestConfigurableLayoutDailyPreset < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    create_stub_stamp(@pdf, 'page_dots')
    @grid = GridSystem.new(@pdf)
    @context = BujoPdf::RenderContext.new(
      page_key: :day_20250315,
      page_number: 100,
      year: 2025,
      total_weeks: 52
    )
    @page = MockPage.new(@pdf, @context)
  end

  def test_daily_preset_content_area
    # ConfigurableLayout with month + tab sidebars (daily preset)
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :month_sidebar,
      right: :tab_sidebar
    )
    configurable = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Expected content area for daily layout
    expected = { col: 2, row: 0, width_boxes: 40, height_boxes: 55 }
    assert_equal expected, configurable.content_area
  end

  def test_can_render_with_daily_preset
    # ConfigurableLayout with month + tab sidebars
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :month_sidebar,
      right: :tab_sidebar
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should render successfully
    layout.render_before(@page)
    layout.render_after(@page)
  end
end

class TestConfigurableLayoutReplicatesFullPageLayout < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_content_area_matches_full_page_layout
    # ConfigurableLayout with no chrome
    configurable = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid)

    # FullPageLayout
    full_page = BujoPdf::Layouts::FullPageLayout.new(@pdf, @grid)

    assert_equal full_page.content_area, configurable.content_area
  end

  def test_can_render_like_full_page_layout
    context = BujoPdf::RenderContext.new(
      page_key: :reference,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    # ConfigurableLayout with no chrome
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid)

    # Should render successfully like FullPageLayout
    layout.render_before(page)
    layout.render_after(page)
  end

  def test_explicit_empty_chrome_spec_works
    # Explicitly passing empty ChromeSpec should work the same
    spec = BujoPdf::Layouts::ChromeSpec.new
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    full_page = BujoPdf::Layouts::FullPageLayout.new(@pdf, @grid)

    assert_equal full_page.content_area, layout.content_area
  end
end

class TestConfigurableLayoutIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    create_stub_stamp(@pdf, 'page_dots')
    @grid = GridSystem.new(@pdf)
  end

  def test_full_workflow_with_week_sidebar
    context = BujoPdf::RenderContext.new(
      page_key: :week_42,
      page_number: 42,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :tab_sidebar
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Verify content area
    area = layout.content_area
    assert_equal 2, area[:col]
    assert_equal 40, area[:width_boxes]

    # Verify render lifecycle
    layout.render_before(page)
    layout.render_after(page)
  end

  def test_full_workflow_with_month_sidebar
    context = BujoPdf::RenderContext.new(
      page_key: :day_20250315,
      page_number: 100,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :month_sidebar,
      right: :tab_sidebar
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Verify content area
    area = layout.content_area
    assert_equal 2, area[:col]
    assert_equal 40, area[:width_boxes]

    # Verify render lifecycle
    layout.render_before(page)
    layout.render_after(page)
  end

  def test_mixed_sidebar_configurations
    context = BujoPdf::RenderContext.new(
      page_key: :week_1,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    # Mix symbol and hash configurations
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: { component: :tab_sidebar, top_tabs: [] }
    )
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should handle both configuration styles
    layout.render_before(page)
  end

  def test_proc_based_chrome
    rendered = false
    my_proc = ->(canvas, page) { rendered = true }

    spec = BujoPdf::Layouts::ChromeSpec.new(left: my_proc)
    layout = BujoPdf::Layouts::ConfigurableLayout.new(@pdf, @grid, chrome_spec: spec)

    context = BujoPdf::RenderContext.new(
      page_key: :test,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    layout.render_before(page)

    assert rendered, "Proc should have been called"
  end
end

# Mock page class for testing
class MockPage
  attr_reader :context

  def initialize(pdf, context)
    @pdf = pdf
    @context = context
  end
end
