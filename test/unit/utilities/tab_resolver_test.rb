#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestTabResolver < Minitest::Test
  TabResolver = BujoPdf::Utilities::TabResolver

  # ============================================
  # Basic Resolution Tests
  # ============================================

  def test_resolve_single_string_destination
    resolver = TabResolver.new
    result = resolver.resolve(label: "Year", dest: "seasonal")

    assert_equal "Year", result[:label]
    assert_equal "seasonal", result[:dest]
    assert_equal false, result[:current]
  end

  def test_resolve_single_symbol_destination
    resolver = TabResolver.new
    result = resolver.resolve(label: "Year", dest: :seasonal)

    assert_equal "Year", result[:label]
    assert_equal "seasonal", result[:dest]
    assert_equal false, result[:current]
  end

  def test_resolve_passes_through_already_resolved_tab
    resolver = TabResolver.new
    tab = { label: "Year", dest: "seasonal", current: true }
    result = resolver.resolve(tab)

    assert_same tab, result
  end

  def test_resolve_raises_for_invalid_destination_type
    resolver = TabResolver.new

    assert_raises(ArgumentError) do
      resolver.resolve(label: "Test", dest: 123)
    end
  end

  # ============================================
  # Page Context Tests
  # ============================================

  def test_resolve_with_current_page_match
    page_context = MockPageContext.new(:seasonal)
    resolver = TabResolver.new(page_context: page_context)

    result = resolver.resolve(label: "Year", dest: :seasonal)

    assert_equal true, result[:current]
  end

  def test_resolve_with_current_page_no_match
    page_context = MockPageContext.new(:week_1)
    resolver = TabResolver.new(page_context: page_context)

    result = resolver.resolve(label: "Year", dest: :seasonal)

    assert_equal false, result[:current]
  end

  def test_resolve_with_hash_page_context
    page_context = { page_key: :seasonal }
    resolver = TabResolver.new(page_context: page_context)

    result = resolver.resolve(label: "Year", dest: :seasonal)

    assert_equal true, result[:current]
  end

  # ============================================
  # Highlight Tab Tests
  # ============================================

  def test_resolve_with_highlight_tab_match
    resolver = TabResolver.new(highlight_tab: :seasonal)

    result = resolver.resolve(label: "Year", dest: :seasonal)

    assert_equal true, result[:current]
  end

  def test_resolve_with_highlight_tab_no_match
    resolver = TabResolver.new(highlight_tab: :other)

    result = resolver.resolve(label: "Year", dest: :seasonal)

    assert_equal false, result[:current]
  end

  # ============================================
  # Cyclic Destination Tests
  # ============================================

  def test_resolve_array_destination_not_in_cycle
    resolver = TabResolver.new
    result = resolver.resolve(label: "Grids", dest: [:grids_overview, :grid_dot, :grid_graph])

    assert_equal "Grids", result[:label]
    assert_equal "grids_overview", result[:dest]  # First in array
    assert_equal false, result[:current]
  end

  def test_resolve_array_destination_on_first_page
    page_context = MockPageContext.new(:grids_overview)
    resolver = TabResolver.new(page_context: page_context)

    result = resolver.resolve(label: "Grids", dest: [:grids_overview, :grid_dot, :grid_graph])

    assert_equal "Grids", result[:label]
    assert_equal "grid_dot", result[:dest]  # Next in cycle
    assert_equal true, result[:current]
  end

  def test_resolve_array_destination_on_last_page_wraps
    page_context = MockPageContext.new(:grid_graph)
    resolver = TabResolver.new(page_context: page_context)

    result = resolver.resolve(label: "Grids", dest: [:grids_overview, :grid_dot, :grid_graph])

    assert_equal "Grids", result[:label]
    assert_equal "grids_overview", result[:dest]  # Wraps to first
    assert_equal true, result[:current]
  end

  def test_resolve_array_destination_with_highlight_tab
    resolver = TabResolver.new(highlight_tab: :grid_dot)

    result = resolver.resolve(label: "Grids", dest: [:grids_overview, :grid_dot, :grid_graph])

    assert_equal "grid_graph", result[:dest]  # Next after highlighted
    assert_equal true, result[:current]
  end

  # ============================================
  # Resolve All Tests
  # ============================================

  def test_resolve_all_resolves_multiple_tabs
    resolver = TabResolver.new

    tabs = [
      { label: "Year", dest: :seasonal },
      { label: "Events", dest: :year_events }
    ]

    results = resolver.resolve_all(tabs)

    assert_equal 2, results.length
    assert_equal "seasonal", results[0][:dest]
    assert_equal "year_events", results[1][:dest]
  end

  def test_resolve_all_handles_mixed_tab_types
    resolver = TabResolver.new

    tabs = [
      { label: "Year", dest: :seasonal },
      { label: "Grids", dest: [:grids_overview, :grid_dot] },
      { label: "Current", dest: :current, current: true }
    ]

    results = resolver.resolve_all(tabs)

    assert_equal 3, results.length
    assert_equal "seasonal", results[0][:dest]
    assert_equal "grids_overview", results[1][:dest]
    assert_equal true, results[2][:current]
  end

  # ============================================
  # Edge Cases
  # ============================================

  def test_resolve_with_empty_array_destination_returns_empty_dest
    # Edge case: empty array returns empty string dest (nil.to_s), caller should validate
    resolver = TabResolver.new
    result = resolver.resolve(label: "Empty", dest: [])

    assert_equal "", result[:dest]
    assert_equal false, result[:current]
  end

  def test_resolve_preserves_label_exactly
    resolver = TabResolver.new

    result = resolver.resolve(label: "My Special Label!", dest: :test)

    assert_equal "My Special Label!", result[:label]
  end

  # Helper class for testing page context
  class MockPageContext
    def initialize(current_page)
      @current_page = current_page
    end

    def current_page?(dest)
      @current_page.to_s == dest.to_s
    end
  end
end
