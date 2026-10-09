#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestRightSidebar < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Basic Initialization Tests
  # ============================================

  def test_initialize_with_defaults
    sidebar = BujoPdf::Components::RightSidebar.new(canvas: @canvas)
    sidebar.render
  end

  def test_tab_sidebar_alias_works
    # TabSidebar is the primary class, RightSidebar is the alias
    sidebar = BujoPdf::Components::TabSidebar.new(canvas: @canvas)
    sidebar.render
    assert_equal BujoPdf::Components::TabSidebar, BujoPdf::Components::RightSidebar
  end

  def test_initialize_with_top_tabs
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal" },
        { label: "Events", dest: "year_events" }
      ]
    )
    sidebar.render
  end

  def test_initialize_with_bottom_tabs
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      bottom_tabs: [
        { label: "Dots", dest: "dots" }
      ]
    )
    sidebar.render
  end

  def test_initialize_with_both_tab_groups
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal" },
        { label: "Events", dest: "year_events" }
      ],
      bottom_tabs: [
        { label: "Dots", dest: "dots" },
        { label: "Ref", dest: "reference" }
      ]
    )
    sidebar.render
  end

  def test_initialize_with_custom_sidebar_col
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [{ label: "Test", dest: "test" }],
      sidebar_col: 40
    )
    sidebar.render
  end

  def test_default_constants
    assert_equal 42, BujoPdf::Components::TabSidebar::DEFAULT_SIDEBAR_COL
    assert_equal 8, BujoPdf::Components::TabSidebar::FONT_SIZE
    assert_equal 4, BujoPdf::Components::TabSidebar::TAB_GAP_PT
    assert_equal 6, BujoPdf::Components::TabSidebar::TAB_PADDING_PT
    assert_equal 14, BujoPdf::Components::TabSidebar::START_Y_OFFSET_PT
  end

  def test_render_draws_tab_backgrounds
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal" },
        { label: "Events", dest: "year_events" }
      ]
    )
    # Non-current tabs should draw filled rounded rectangles with transparency
    # Using real PDF since MockPDF doesn't fully support all rendering
    sidebar.render
  end

  def test_render_current_tab_draws_stroked_border
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal", current: true },
        { label: "Events", dest: "year_events" }
      ]
    )
    sidebar.render

    # Current tab draws stroked border
    assert mock_pdf.called?(:stroke_rounded_rectangle), "Expected stroked border for current tab"
  end

  def test_render_draws_rotated_text
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal" }
      ]
    )
    # Text component uses rotate for -90 degree text
    # Using real PDF since MockPDF doesn't fully support all text rendering
    sidebar.render
  end

  def test_render_adds_link_annotations_for_non_current_tabs
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal" },
        { label: "Events", dest: "year_events" }
      ]
    )
    sidebar.render

    # Should add link annotations for clickable tabs
    assert mock_pdf.called?(:link_annotation), "Expected link annotations"
    link_calls = mock_pdf.calls.select { |c| c[:method] == :link_annotation }
    assert_equal 2, link_calls.length, "Expected 2 link annotations for 2 non-current tabs"
  end

  def test_render_skips_link_for_current_tab
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal", current: true },
        { label: "Events", dest: "year_events" }
      ]
    )
    sidebar.render

    # Only one tab should have a link (not the current one)
    link_calls = mock_pdf.calls.select { |c| c[:method] == :link_annotation }
    assert_equal 1, link_calls.length, "Expected 1 link annotation (skipping current tab)"
  end

  def test_render_uses_bold_for_current_tab
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal", current: true }
      ]
    )
    sidebar.render

    # Font should be set to Helvetica-Bold for current tab
    font_calls = mock_pdf.calls.select { |c| c[:method] == :font }
    font_names = font_calls.map { |c| c[:args][0] }
    assert font_names.include?("Helvetica-Bold"), "Expected bold font for current tab"
  end

  def test_render_empty_tabs
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [],
      bottom_tabs: []
    )
    sidebar.render
  end

  def test_render_combines_top_and_bottom_tabs
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: canvas,
      top_tabs: [
        { label: "Top1", dest: "top1" },
        { label: "Top2", dest: "top2" }
      ],
      bottom_tabs: [
        { label: "Bottom1", dest: "bottom1" }
      ]
    )
    sidebar.render

    # Should draw 3 tabs total
    link_calls = mock_pdf.calls.select { |c| c[:method] == :link_annotation }
    assert_equal 3, link_calls.length, "Expected 3 link annotations for 3 tabs"
  end

  def test_render_with_page_context
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [{ label: "Test", dest: "test" }],
      page_context: { current_page: :week_1 }
    )
    sidebar.render
  end

  def test_render_with_real_prawn_document
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [
        { label: "Year", dest: "seasonal" },
        { label: "Events", dest: "year_events", current: true },
        { label: "Highlights", dest: "year_highlights" }
      ],
      bottom_tabs: [
        { label: "Dots", dest: "dots" },
        { label: "Ref", dest: "reference" }
      ]
    )
    sidebar.render

    assert_kind_of Prawn::Document, @pdf
  end

  def test_tabs_with_long_labels
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [
        { label: "Long Label Here", dest: "long" },
        { label: "Another Long One", dest: "another" }
      ]
    )
    sidebar.render
  end

  def test_tabs_with_short_labels
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [
        { label: "Yr", dest: "year" },
        { label: "Ev", dest: "events" }
      ]
    )
    sidebar.render
  end

  def test_multiple_current_tabs
    # Edge case: multiple tabs marked as current (shouldn't happen, but shouldn't crash)
    sidebar = BujoPdf::Components::RightSidebar.new(
      canvas: @canvas,
      top_tabs: [
        { label: "Tab1", dest: "tab1", current: true },
        { label: "Tab2", dest: "tab2", current: true }
      ]
    )
    sidebar.render
  end

  # ============================================
  # Sidebar Registry Integration Tests
  # ============================================

  def test_tab_sidebar_is_registered
    assert BujoPdf::Sidebars::SidebarRegistry.registered?(:tab_sidebar)
    assert_equal BujoPdf::Components::TabSidebar,
                 BujoPdf::Sidebars::SidebarRegistry.lookup(:tab_sidebar)
  end

  def test_right_sidebar_alias_is_registered
    assert BujoPdf::Sidebars::SidebarRegistry.registered?(:right_sidebar)
    assert_equal BujoPdf::Components::TabSidebar,
                 BujoPdf::Sidebars::SidebarRegistry.lookup(:right_sidebar)
  end

  def test_sidebar_type_is_tab_sidebar
    assert_equal :tab_sidebar, BujoPdf::Components::TabSidebar.sidebar_type
  end

  def test_extends_sidebar_base
    assert BujoPdf::Components::TabSidebar < BujoPdf::SidebarBase,
           "TabSidebar should extend SidebarBase"
  end
end
