# frozen_string_literal: true

require_relative '../../test_helper'

# Concrete test page to access protected methods
class TestablePage < BujoPdf::Pages::Base
  register_page :test_page, title: "Test Page"

  def test_draw_background
    draw_background
  end

  def test_draw_debug_grid_if_enabled
    draw_debug_grid_if_enabled
  end

  def test_draw_diagnostic_grid(label_every: 5)
    draw_diagnostic_grid(label_every: label_every)
  end

  def test_add_component(component)
    add_component(component)
  end

  def test_render_components
    render_components
  end

  def test_styling
    styling
  end

  def test_outline_title
    outline_title
  end

  def test_content_col(offset = 0)
    content_col(offset)
  end

  def test_content_row(offset = 0)
    content_row(offset)
  end

  def test_content_width
    content_width
  end

  def test_content_height
    content_height
  end

  def test_content_rect(col_offset, row_offset, width_boxes, height_boxes)
    content_rect(col_offset, row_offset, width_boxes, height_boxes)
  end

  def test_set_destination(name)
    set_destination(name)
  end

  def test_draw_set_label(**options)
    draw_set_label(**options)
  end

  def test_use_layout(layout_name, **options)
    use_layout(layout_name, **options)
  end

  def test_draw_dot_grid(width = nil, height = nil)
    draw_dot_grid(width, height)
  end

  def render
    # Default implementation for testing
  end
end

# Page that does NOT implement render (tests NotImplementedError)
class NoRenderPage < BujoPdf::Pages::Base
  # Intentionally does not implement render
end

# Page with custom render for testing component lifecycle
class ComponentPage < BujoPdf::Pages::Base
  def render
    render_components
  end
end

class TestPagesBase < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :test_page,
      page_number: 1,
      year: 2025
    )
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_render_context
    page = TestablePage.new(@pdf, @context)

    assert_equal @pdf, page.pdf
    assert_equal @context, page.context
    assert_kind_of GridSystem, page.grid_system
    assert_equal page.grid_system, page.grid  # Alias
  end

  def test_initialize_with_hash_context
    hash_context = {
      page_key: :test_page,
      page_number: 1,
      year: 2025,
      week_num: 42,
      total_weeks: 52
    }

    page = TestablePage.new(@pdf, hash_context)

    assert_kind_of BujoPdf::RenderContext, page.context
    assert_equal :test_page, page.context.page_key
    assert_equal 42, page.context.week_num
  end

  def test_initialize_with_custom_layout
    custom_layout = BujoPdf::Layout.with_sidebars(left_width: 5, right_width: 3)
    page = TestablePage.new(@pdf, @context, layout: custom_layout)

    assert_equal custom_layout, page.layout
  end

  def test_initialize_calculates_content_area
    page = TestablePage.new(@pdf, @context)

    assert page.content_area
    assert_equal 0, page.content_area[:col]
    assert_equal 0, page.content_area[:row]
    assert_equal 43, page.content_area[:width_boxes]
    assert_equal 55, page.content_area[:height_boxes]
  end

  def test_default_layout_is_full_page
    page = TestablePage.new(@pdf, @context)

    assert_equal "full_page", page.layout.name
  end

  # ============================================
  # Generate Lifecycle Tests
  # ============================================

  def test_generate_creates_new_layout_when_nil
    page = TestablePage.new(@pdf, @context)

    assert_nil page.new_layout

    page.generate

    refute_nil page.new_layout
  end

  def test_generate_raises_not_implemented_without_render
    page = NoRenderPage.new(@pdf, @context)

    error = assert_raises(NotImplementedError) do
      page.generate
    end

    assert_match(/must implement #render/, error.message)
  end

  # ============================================
  # use_layout Tests
  # ============================================

  def test_use_layout_creates_layout
    page = TestablePage.new(@pdf, @context)

    page.test_use_layout(:full_page)

    refute_nil page.new_layout
  end

  def test_use_layout_updates_content_area
    page = TestablePage.new(@pdf, @context)
    original_content_area = page.content_area.dup

    page.test_use_layout(:standard_with_sidebars, current_week: 1)

    refute_equal original_content_area[:width_boxes], page.content_area[:width_boxes]
  end

  def test_use_layout_merges_context_values
    context = BujoPdf::RenderContext.new(
      page_key: :test_page,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )
    page = TestablePage.new(@pdf, context)

    page.test_use_layout(:standard_with_sidebars)

    refute_nil page.new_layout
  end

  # ============================================
  # Background Drawing Tests
  # ============================================

  def test_draw_background_stamps_dot_grid
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    page.test_draw_background

    assert mock_pdf.called?(:stamp)
  end

  def test_draw_background_with_non_white_background
    # Use dark theme which has non-white background
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")

    # Save original theme and set dark theme (which has non-white background)
    original_theme = BujoPdf::Themes.current_name
    BujoPdf::Themes.set(:dark)

    page = TestablePage.new(mock_pdf, @context)
    page.test_draw_background

    # Should have called fill_rectangle for background
    assert mock_pdf.called?(:fill_rectangle)

    # Restore original theme
    BujoPdf::Themes.set(original_theme)
  end

  # ============================================
  # Debug Grid Tests
  # ============================================

  def test_draw_debug_grid_if_enabled_when_disabled
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    # Default layout has debug_mode? = false
    page.test_draw_debug_grid_if_enabled

    # Diagnostics.draw_grid not called when disabled
    # (no fill_circle calls from Diagnostics)
  end

  def test_draw_debug_grid_if_enabled_when_enabled
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    debug_layout = BujoPdf::Layout.full_page(debug: true)
    page = TestablePage.new(mock_pdf, @context, layout: debug_layout)

    page.test_draw_debug_grid_if_enabled

    # Should draw diagnostic grid
    assert mock_pdf.called?(:fill_circle)
    assert mock_pdf.called?(:stroke_line)
    assert mock_pdf.called?(:text_box)
  end

  def test_draw_diagnostic_grid
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    page.test_draw_diagnostic_grid(label_every: 10)

    assert mock_pdf.called?(:fill_circle)
    assert mock_pdf.called?(:stroke_line)
  end

  # ============================================
  # Component Management Tests
  # ============================================

  def test_add_component
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    mock_component = Object.new
    mock_component.define_singleton_method(:render) { }
    page.test_add_component(mock_component)

    # Verify component was added
    components = page.instance_variable_get(:@components)
    assert_equal 1, components.size
    assert_equal mock_component, components.first
  end

  def test_render_components_calls_render_on_each
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    render_count = 0
    mock_component = Object.new
    mock_component.define_singleton_method(:render) { render_count += 1 }

    page.test_add_component(mock_component)
    page.test_add_component(mock_component)
    page.test_render_components

    assert_equal 2, render_count
  end

  def test_render_components_empty_list
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    # Should not raise
    page.test_render_components
  end

  # ============================================
  # Helper Method Tests
  # ============================================

  def test_styling_returns_styling_module
    page = TestablePage.new(@pdf, @context)

    assert_equal Styling, page.test_styling
  end

  def test_outline_title_uses_page_registry
    page = TestablePage.new(@pdf, @context)

    title = page.test_outline_title

    assert_equal "Test Page", title
  end

  def test_set_destination
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    page.test_set_destination("test_dest")

    assert mock_pdf.called?(:add_dest)
  end

  # ============================================
  # Content Area Helper Tests
  # ============================================

  def test_content_col_without_offset
    page = TestablePage.new(@pdf, @context)

    assert_equal 0, page.test_content_col
  end

  def test_content_col_with_offset
    page = TestablePage.new(@pdf, @context)

    assert_equal 5, page.test_content_col(5)
  end

  def test_content_col_with_sidebar_layout
    page = TestablePage.new(@pdf, @context)
    page.test_use_layout(:standard_with_sidebars)

    # standard_with_sidebars has left sidebar of 2 columns, content starts at col 2
    assert_equal 2, page.test_content_col
    assert_equal 7, page.test_content_col(5)
  end

  def test_content_row_without_offset
    page = TestablePage.new(@pdf, @context)

    assert_equal 0, page.test_content_row
  end

  def test_content_row_with_offset
    page = TestablePage.new(@pdf, @context)

    assert_equal 5, page.test_content_row(5)
  end

  def test_content_width
    page = TestablePage.new(@pdf, @context)

    assert_equal 43, page.test_content_width
  end

  def test_content_width_with_sidebars
    page = TestablePage.new(@pdf, @context)
    page.test_use_layout(:standard_with_sidebars)

    # standard_with_sidebars has 2 left + 1 right = 3 cols used, leaving 40 for content
    assert_equal 40, page.test_content_width
  end

  def test_content_height
    page = TestablePage.new(@pdf, @context)

    assert_equal 55, page.test_content_height
  end

  def test_content_rect
    page = TestablePage.new(@pdf, @context)

    rect = page.test_content_rect(5, 10, 15, 20)

    assert_respond_to rect, :x
    assert_respond_to rect, :y
    assert_respond_to rect, :width
    assert_respond_to rect, :height
  end

  def test_content_rect_with_sidebar_layout
    page = TestablePage.new(@pdf, @context)
    page.test_use_layout(:standard_with_sidebars)

    # Content area starts at col 2 (left sidebar is 2 boxes)
    rect = page.test_content_rect(0, 0, 10, 10)

    # The x should be at grid.x(2) not grid.x(0)
    expected_x = page.grid_system.x(2)
    assert_in_delta expected_x, rect[:x], 0.01
  end

  # ============================================
  # Page Set Label Tests
  # ============================================

  def test_draw_set_label_returns_early_without_set
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    # Context.set? returns false by default
    page.test_draw_set_label

    # Should not render anything
    refute mock_pdf.called?(:text_box)
  end

  def test_draw_set_label_renders_with_set
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")

    set_context = BujoPdf::PageSetContext::Context.new(
      page: 1,
      total: 3,
      label: "Test 1 of 3"
    )

    context = BujoPdf::RenderContext.new(
      page_key: :test_page,
      page_number: 1,
      year: 2025
    )
    context.set = set_context

    page = TestablePage.new(mock_pdf, context)
    page.test_draw_set_label

    # Should render text_box with label
    assert mock_pdf.called?(:text_box)
  end

  def test_draw_set_label_with_custom_position
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")

    set_context = BujoPdf::PageSetContext::Context.new(
      page: 2,
      total: 5,
      label: "Page 2 of 5"
    )

    context = BujoPdf::RenderContext.new(
      page_key: :test_page,
      page_number: 1,
      year: 2025
    )
    context.set = set_context

    page = TestablePage.new(mock_pdf, context)
    page.test_draw_set_label(col: 5, row: 53, width: 30)

    assert mock_pdf.called?(:text_box)
  end
end

class TestPagesBaseDrawDotGrid < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :test_page,
      page_number: 1,
      year: 2025
    )
  end

  def test_draw_dot_grid_uses_stamp
    mock_pdf = MockPDF.new
    DotGrid.create_stamp(mock_pdf, "page_dots")
    page = TestablePage.new(mock_pdf, @context)

    page.test_draw_dot_grid

    assert mock_pdf.called?(:stamp)
    last_stamp = mock_pdf.last_call(:stamp)
    assert_equal ["page_dots"], last_stamp[:args]
  end
end

class TestPagesBaseIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :test_page,
      page_number: 1,
      year: 2025
    )
  end

  def test_full_page_generation
    page = TestablePage.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_page_with_standard_sidebars_layout
    # Need a context with total_weeks for week sidebar
    context = BujoPdf::RenderContext.new(
      page_key: :test_page,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )
    page = TestablePage.new(@pdf, context)
    # Use layout in generate's setup phase would normally happen
    page.test_use_layout(:standard_with_sidebars, current_week: 10)

    page.generate

    assert_equal 1, @pdf.page_count
  end
end

class TestPagesBaseBackgroundTypes < Minitest::Test
  def setup
    @mock_pdf = MockPDF.new
    DotGrid.create_stamp(@mock_pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :test_page,
      page_number: 1,
      year: 2025
    )
  end

  def test_background_type_dot_grid
    layout = BujoPdf::Layout.full_page(background_type: :dot_grid)
    page = TestablePage.new(@mock_pdf, @context, layout: layout)

    page.test_draw_background

    assert @mock_pdf.called?(:stamp)
  end

  def test_background_type_blank
    layout = BujoPdf::Layout.full_page(background_type: :blank)
    page = TestablePage.new(@mock_pdf, @context, layout: layout)

    @mock_pdf.calls.clear
    page.test_draw_background

    # Should not stamp for blank background
    refute @mock_pdf.called?(:stamp)
  end

  def test_background_type_ruled
    layout = BujoPdf::Layout.full_page(background_type: :ruled)
    page = TestablePage.new(@mock_pdf, @context, layout: layout)

    @mock_pdf.calls.clear
    page.test_draw_background

    # Ruled is future implementation - should not stamp
    refute @mock_pdf.called?(:stamp)
  end

  def test_background_disabled
    layout = BujoPdf::Layout.full_page(background: false)
    page = TestablePage.new(@mock_pdf, @context, layout: layout)

    # setup_page should skip background when disabled
    page.send(:setup_page)

    # No stamp when background disabled
    stamp_calls = @mock_pdf.calls.select { |c| c[:method] == :stamp }
    assert_equal 0, stamp_calls.size
  end
end
