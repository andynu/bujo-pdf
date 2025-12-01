#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestStandardWithSidebarsLayout < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_content_area_returns_correct_dimensions
    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(@pdf, @grid)

    area = layout.content_area
    assert_equal 2, area[:col]
    assert_equal 0, area[:row]
    assert_equal 40, area[:width_boxes]
    assert_equal 55, area[:height_boxes]
  end

  def test_initialize_with_options
    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      current_week: 10,
      highlight_tab: :year_events,
      year: 2025,
      total_weeks: 52
    )

    assert_equal 10, layout.options[:current_week]
    assert_equal :year_events, layout.options[:highlight_tab]
    assert_equal 2025, layout.options[:year]
    assert_equal 52, layout.options[:total_weeks]
  end

  def test_render_before_with_page
    context = BujoPdf::RenderContext.new(
      page_key: :week_10,
      page_number: 10,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      year: 2025,
      total_weeks: 52
    )
    layout.render_before(page)
  end

  def test_render_before_extracts_year_from_page_context
    context = BujoPdf::RenderContext.new(
      page_key: :week_10,
      page_number: 10,
      year: 2025,
      total_weeks: 53
    )
    page = MockPage.new(@pdf, context)

    # Layout without year option should get it from page context
    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(@pdf, @grid)
    layout.render_before(page)
  end

  def test_render_before_with_current_week_highlight
    context = BujoPdf::RenderContext.new(
      page_key: :week_42,
      page_number: 42,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      current_week: 42,
      year: 2025,
      total_weeks: 52
    )
    layout.render_before(page)
  end

  def test_render_before_with_tab_highlight
    context = BujoPdf::RenderContext.new(
      page_key: :year_events,
      page_number: 5,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      highlight_tab: :year_events,
      year: 2025,
      total_weeks: 52
    )
    layout.render_before(page)
  end
end

class TestStandardWithSidebarsLayoutTabBuilding < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_build_top_tabs_returns_correct_tabs
    context = BujoPdf::RenderContext.new(
      page_key: :week_1,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    tabs = layout.send(:build_top_tabs)
    labels = tabs.map { |t| t[:label] }

    assert_includes labels, "Year"
    assert_includes labels, "Future"
    assert_includes labels, "Events"
    assert_includes labels, "Highlights"
    assert_includes labels, "Multi"
    assert_includes labels, "Grids"
    assert_equal 6, tabs.length
  end

  def test_resolve_single_destination
    context = BujoPdf::RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    tab = { label: "Year", dest: "seasonal" }
    result = layout.send(:resolve_tab_destination, tab)

    assert_equal "Year", result[:label]
    assert_equal "seasonal", result[:dest]
    assert_equal true, result[:current]
  end

  def test_resolve_single_destination_not_current
    context = BujoPdf::RenderContext.new(
      page_key: :week_1,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    tab = { label: "Year", dest: "seasonal" }
    result = layout.send(:resolve_tab_destination, tab)

    assert_equal "Year", result[:label]
    assert_equal "seasonal", result[:dest]
    assert_equal false, result[:current]
  end

  def test_resolve_symbol_destination
    context = BujoPdf::RenderContext.new(
      page_key: :year_events,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    tab = { label: "Events", dest: :year_events }
    result = layout.send(:resolve_tab_destination, tab)

    assert_equal "year_events", result[:dest]
    assert_equal true, result[:current]
  end

  def test_resolve_cyclic_destination_not_in_cycle
    context = BujoPdf::RenderContext.new(
      page_key: :week_1,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    result = layout.send(:resolve_cyclic_destination, "Grids", [:grid_showcase, :grids_overview, :grid_dot])

    assert_equal "Grids", result[:label]
    assert_equal "grid_showcase", result[:dest]
    assert_equal false, result[:current]
  end

  def test_resolve_cyclic_destination_on_first_page
    context = BujoPdf::RenderContext.new(
      page_key: :grid_showcase,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    result = layout.send(:resolve_cyclic_destination, "Grids", [:grid_showcase, :grids_overview, :grid_dot])

    assert_equal "Grids", result[:label]
    assert_equal "grids_overview", result[:dest]
    assert_equal true, result[:current]
  end

  def test_resolve_cyclic_destination_on_middle_page
    context = BujoPdf::RenderContext.new(
      page_key: :grids_overview,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    result = layout.send(:resolve_cyclic_destination, "Grids", [:grid_showcase, :grids_overview, :grid_dot])

    assert_equal "Grids", result[:label]
    assert_equal "grid_dot", result[:dest]
    assert_equal true, result[:current]
  end

  def test_resolve_cyclic_destination_on_last_page_wraps
    context = BujoPdf::RenderContext.new(
      page_key: :grid_dot,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    result = layout.send(:resolve_cyclic_destination, "Grids", [:grid_showcase, :grids_overview, :grid_dot])

    assert_equal "Grids", result[:label]
    assert_equal "grid_showcase", result[:dest]
    assert_equal true, result[:current]
  end

  def test_resolve_cyclic_destination_with_highlight_tab
    context = BujoPdf::RenderContext.new(
      page_key: :week_1,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      highlight_tab: :grid_showcase,
      year: 2025,
      total_weeks: 52
    )

    result = layout.send(:resolve_cyclic_destination, "Grids", [:grid_showcase, :grids_overview, :grid_dot])

    assert_equal true, result[:current]
    assert_equal "grids_overview", result[:dest]
  end

  def test_resolve_tab_destination_raises_for_invalid_type
    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(@pdf, @grid)

    error = assert_raises(ArgumentError) do
      layout.send(:resolve_tab_destination, { label: "Test", dest: 123 })
    end

    assert_match(/must be String, Symbol, or Array/, error.message)
  end
end

class TestStandardWithSidebarsLayoutCurrentPage < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_current_page_returns_false_without_page_context
    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(@pdf, @grid)

    assert_equal false, layout.send(:current_page?, :seasonal)
  end

  def test_current_page_returns_true_when_on_page
    context = BujoPdf::RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context
    )

    assert_equal true, layout.send(:current_page?, :seasonal)
  end

  def test_current_page_returns_false_when_not_on_page
    context = BujoPdf::RenderContext.new(
      page_key: :week_1,
      page_number: 1,
      year: 2025,
      total_weeks: 52
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context
    )

    assert_equal false, layout.send(:current_page?, :seasonal)
  end

  def test_highlight_matches_returns_false_without_option
    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(@pdf, @grid)

    assert_equal false, layout.send(:highlight_matches?, :seasonal)
  end

  def test_highlight_matches_returns_true_when_matches
    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      highlight_tab: :year_events
    )

    assert_equal true, layout.send(:highlight_matches?, :year_events)
    assert_equal true, layout.send(:highlight_matches?, "year_events")
  end

  def test_highlight_matches_returns_false_when_not_matches
    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      highlight_tab: :year_events
    )

    assert_equal false, layout.send(:highlight_matches?, :seasonal)
  end
end

class TestStandardWithSidebarsLayoutSidebarOverrides < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  def test_resolve_cyclic_with_sidebar_override
    overrides = BujoPdf::PdfDSL::SidebarOverrides.new
    overrides.set(from: :week_1, tab: :future, to: :future_log_1)

    context = BujoPdf::RenderContext.new(
      page_key: :week_1,
      page_number: 1,
      year: 2025,
      total_weeks: 52,
      sidebar_overrides: overrides
    )

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      page_context: context,
      year: 2025,
      total_weeks: 52
    )

    result = layout.send(:resolve_cyclic_destination, "Future", [:future_log_1, :future_log_2])

    assert_equal "future_log_1", result[:dest]
    assert_equal false, result[:current]
  end
end

class TestStandardWithSidebarsLayoutIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_render_on_weekly_page
    context = BujoPdf::RenderContext.new(
      page_key: :week_42,
      page_number: 42,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      current_week: 42,
      highlight_tab: nil,
      year: 2025,
      total_weeks: 52
    )

    layout.render_before(page)
    layout.render_after(page)

    assert_kind_of Prawn::Document, @pdf
  end

  def test_full_render_on_year_events_page
    context = BujoPdf::RenderContext.new(
      page_key: :year_events,
      page_number: 5,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      current_week: nil,
      highlight_tab: :year_events,
      year: 2025,
      total_weeks: 52
    )

    layout.render_before(page)

    assert_kind_of Prawn::Document, @pdf
  end

  def test_full_render_on_grid_page
    context = BujoPdf::RenderContext.new(
      page_key: :grid_showcase,
      page_number: 60,
      year: 2025,
      total_weeks: 52
    )
    page = MockPage.new(@pdf, context)

    layout = BujoPdf::Layouts::StandardWithSidebarsLayout.new(
      @pdf, @grid,
      current_week: nil,
      highlight_tab: :grid_showcase,
      year: 2025,
      total_weeks: 52
    )

    layout.render_before(page)

    assert_kind_of Prawn::Document, @pdf
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
