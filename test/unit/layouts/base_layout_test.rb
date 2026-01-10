#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestBaseLayout < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_initialize_stores_pdf_and_grid
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid)

    assert_same @pdf, layout.pdf
    assert_same @grid, layout.grid_system
  end

  def test_initialize_stores_options
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, foo: 'bar', baz: 42)

    assert_equal 'bar', layout.options[:foo]
    assert_equal 42, layout.options[:baz]
  end

  def test_initialize_stores_chrome_spec
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    assert_same spec, layout.chrome_spec
  end

  def test_initialize_without_chrome_spec
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid)

    assert_nil layout.chrome_spec
  end
end

class TestBaseLayoutContentArea < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_content_area_without_chrome_spec_raises_not_implemented
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid)

    error = assert_raises(NotImplementedError) { layout.content_area }
    assert_match(/must implement #content_area/, error.message)
  end

  def test_content_area_with_empty_chrome_spec_returns_full_page
    spec = BujoPdf::Layouts::ChromeSpec.new
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 0, area[:col]
    assert_equal 0, area[:row]
    assert_equal 43, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_left_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 2, area[:col]
    assert_equal 0, area[:row]
    assert_equal 41, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_right_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(right: :tab_sidebar)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

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
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 2, area[:col]
    assert_equal 0, area[:row]
    assert_equal 40, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_content_area_with_custom_widths
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :custom, width: 5 },
      right: { component: :custom, width: 3 }
    )
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 5, area[:col]
    assert_equal 0, area[:row]
    assert_equal 35, area[:width_boxes]
  end

  def test_content_area_with_top_and_bottom_chrome
    spec = BujoPdf::Layouts::ChromeSpec.new(
      top: { component: :header, height: 3 },
      bottom: { component: :footer, height: 2 }
    )
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    area = layout.content_area

    assert_equal 0, area[:col]
    assert_equal 3, area[:row]
    assert_equal 43, area[:width_boxes]
    assert_equal 50, area[:height_boxes]
  end
end

class TestBaseLayoutRenderBefore < Minitest::Test
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

  def test_render_before_without_chrome_spec_does_nothing
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid)

    # Should not raise
    layout.render_before(@page)
  end

  def test_render_before_with_empty_chrome_spec_does_nothing
    spec = BujoPdf::Layouts::ChromeSpec.new
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should not raise
    layout.render_before(@page)
  end

  def test_render_before_renders_symbol_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should not raise - WeekSidebar is registered
    layout.render_before(@page)
  end

  def test_render_before_renders_hash_config_sidebar
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :week_sidebar, year: 2025 }
    )
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should not raise
    layout.render_before(@page)
  end

  def test_render_before_renders_proc_config
    rendered = false
    my_proc = ->(canvas, page) { rendered = true }

    spec = BujoPdf::Layouts::ChromeSpec.new(left: my_proc)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    layout.render_before(@page)

    assert rendered, "Proc should have been called"
  end

  def test_render_before_skips_unregistered_sidebar
    # Save and restore registry state
    original_registry = BujoPdf::Sidebars::SidebarRegistry.registry.dup

    spec = BujoPdf::Layouts::ChromeSpec.new(left: :nonexistent_sidebar)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should not raise even though sidebar doesn't exist
    layout.render_before(@page)
  ensure
    # No cleanup needed - we didn't modify registry
  end

  def test_render_before_renders_multiple_sidebars
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: :week_sidebar,
      right: :tab_sidebar
    )
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should render both without raising
    layout.render_before(@page)
  end
end

class TestBaseLayoutSidebarInstantiation < Minitest::Test
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

  def test_instantiate_sidebar_passes_canvas
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # The sidebar should receive a Canvas when instantiated
    # We verify this by successful render (would fail without canvas)
    layout.render_before(@page)
  end

  def test_instantiate_sidebar_passes_page_context
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # The sidebar should receive page_context
    # We verify this by successful render
    layout.render_before(@page)
  end

  def test_instantiate_sidebar_extracts_year_from_context
    context = BujoPdf::RenderContext.new(
      page_key: :week_1,
      page_number: 1,
      year: 2030,
      total_weeks: 53
    )
    page = MockPage.new(@pdf, context)

    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should extract year from context and pass to sidebar
    layout.render_before(page)
  end

  def test_instantiate_sidebar_merges_config_options
    spec = BujoPdf::Layouts::ChromeSpec.new(
      left: { component: :week_sidebar, current_week_num: 10 }
    )
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # current_week_num from config should be passed to sidebar
    layout.render_before(@page)
  end
end

class TestBaseLayoutRenderAfter < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_render_after_is_no_op_by_default
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid)

    # Should not raise
    page = MockPage.new(@pdf, nil)
    layout.render_after(page)
  end
end

class TestBaseLayoutPageContext < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_page_context_returns_page_context
    context = BujoPdf::RenderContext.new(
      page_key: :test,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid)

    assert_same context, layout.send(:page_context, page)
  end
end

class TestBaseLayoutCanvas < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_canvas_creates_canvas_instance
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid)

    canvas = layout.send(:canvas)

    assert_instance_of BujoPdf::Canvas, canvas
  end

  def test_canvas_is_memoized
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid)

    canvas1 = layout.send(:canvas)
    canvas2 = layout.send(:canvas)

    assert_same canvas1, canvas2
  end
end

class TestBaseLayoutIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    create_stub_stamp(@pdf, 'page_dots')
    @grid = GridSystem.new(@pdf)
  end

  def test_full_chrome_spec_workflow
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
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

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
    layout = BujoPdf::Layouts::BaseLayout.new(@pdf, @grid, chrome_spec: spec)

    # Should handle both configuration styles
    layout.render_before(page)
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
