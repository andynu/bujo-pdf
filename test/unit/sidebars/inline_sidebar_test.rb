# frozen_string_literal: true

require_relative '../../test_helper'

class TestInlineSidebar < Minitest::Test
  def setup
    @pdf = create_fast_test_pdf
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Registration Tests
  # ============================================

  def test_registered_as_inline_sidebar
    assert BujoPdf::Sidebars::SidebarRegistry.registered?(:inline_sidebar)
    assert_equal BujoPdf::Sidebars::InlineSidebar,
                 BujoPdf::Sidebars::SidebarRegistry.lookup(:inline_sidebar)
  end

  def test_sidebar_type_is_inline_sidebar
    assert_equal :inline_sidebar, BujoPdf::Sidebars::InlineSidebar.sidebar_type
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_stores_position
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc {}
    )

    assert_equal :left, sidebar.position
  end

  def test_stores_right_position
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :right,
      width: 3,
      body_block: proc {}
    )

    assert_equal :right, sidebar.position
  end

  def test_calculates_start_col_for_left_position
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc {}
    )

    # For left position, start_col should be 0
    assert_equal 0, sidebar.send(:sidebar_start_col)
  end

  def test_calculates_start_col_for_right_position
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :right,
      width: 3,
      body_block: proc {}
    )

    # For right position with width 3, start_col should be 43 - 3 = 40
    assert_equal 40, sidebar.send(:sidebar_start_col)
  end

  def test_stores_width
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 5,
      body_block: proc {}
    )

    assert_equal 5, sidebar.send(:sidebar_width_boxes)
  end

  def test_stores_context
    context = { page_id: :week_1 }
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc {},
      context: context
    )

    assert_equal context, sidebar.send(:page_context)
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_executes_body_block
    executed = false

    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc { executed = true }
    )

    sidebar.render
    assert executed, "Body block should be executed during render"
  end

  def test_render_passes_context_to_block
    received_context = nil
    provided_context = { page_id: :week_42 }

    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc { |ctx| received_context = ctx },
      context: provided_context
    )

    sidebar.render
    assert_equal provided_context, received_context
  end

  def test_render_does_nothing_without_body_block
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: nil
    )

    # Should not raise
    sidebar.render
  end

  # ============================================
  # Component Verb Availability Tests
  # ============================================

  def test_component_verbs_available_in_block
    h1_called = false

    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc do |_ctx|
        # Check that h1 method is available
        h1_called = respond_to?(:h1)
      end
    )

    sidebar.render
    assert h1_called, "Component verb h1 should be available in block"
  end

  def test_ruled_lines_verb_available_in_block
    has_ruled_lines = false

    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc do |_ctx|
        has_ruled_lines = respond_to?(:ruled_lines)
      end
    )

    sidebar.render
    assert has_ruled_lines, "Component verb ruled_lines should be available"
  end

  def test_box_verb_available_in_block
    has_box = false

    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc do |_ctx|
        has_box = respond_to?(:box)
      end
    )

    sidebar.render
    assert has_box, "Component verb box should be available"
  end

  # ============================================
  # Integration Tests
  # ============================================

  def test_can_use_h1_in_block
    # Verify that h1 can actually be called (not just that the method exists)
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 10,
      body_block: proc do |_ctx|
        h1(0, 0, "Test Title")
      end
    )

    # Should not raise
    sidebar.render
  end

  def test_can_use_ruled_lines_in_block
    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 10,
      body_block: proc do |_ctx|
        ruled_lines(0, 2, 8, 10)
      end
    )

    # Should not raise
    sidebar.render
  end

  def test_canvas_accessible_in_block
    canvas_accessible = false

    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc do |_ctx|
        canvas_accessible = !canvas.nil?
      end
    )

    sidebar.render
    assert canvas_accessible, "Canvas should be accessible in block"
  end

  def test_grid_accessible_in_block
    grid_accessible = false

    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc do |_ctx|
        grid_accessible = !grid.nil?
      end
    )

    sidebar.render
    assert grid_accessible, "Grid should be accessible in block"
  end

  def test_pdf_accessible_in_block
    pdf_accessible = false

    sidebar = BujoPdf::Sidebars::InlineSidebar.new(
      canvas: @canvas,
      position: :left,
      width: 3,
      body_block: proc do |_ctx|
        pdf_accessible = !pdf.nil?
      end
    )

    sidebar.render
    assert pdf_accessible, "PDF should be accessible in block"
  end
end
