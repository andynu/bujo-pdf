#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl/chrome_builder'

class TestChromeBuilder < Minitest::Test
  def setup
    @builder = BujoPdf::PdfDSL::ChromeBuilder.new
  end

  def test_empty_by_default
    assert @builder.empty?
    refute @builder.any?
  end

  def test_left_sidebar
    @builder.left(:week_sidebar)

    refute @builder.empty?
    assert @builder.any?
    assert_equal :week_sidebar, @builder.left_config.sidebar_name
    assert_equal({}, @builder.left_config.options)
    assert_nil @builder.left_config.tabs
  end

  def test_left_sidebar_with_options
    @builder.left(:week_sidebar, current_week: 27)

    assert_equal :week_sidebar, @builder.left_config.sidebar_name
    assert_equal({ current_week: 27 }, @builder.left_config.options)
  end

  def test_right_sidebar
    @builder.right(:right_sidebar)

    assert_equal :right_sidebar, @builder.right_config.sidebar_name
    assert_equal({}, @builder.right_config.options)
    refute @builder.right_config.tabs?
  end

  def test_right_sidebar_with_options
    @builder.right(:nav_tabs, style: :compact)

    assert_equal :nav_tabs, @builder.right_config.sidebar_name
    assert_equal({ style: :compact }, @builder.right_config.options)
  end

  def test_right_sidebar_with_tabs_block
    @builder.right(:right_sidebar) do
      tab "Index", dest: :index
      tab "Future", dest: :future_log_1
    end

    assert @builder.right_config.tabs?
    assert_equal 2, @builder.right_config.tabs.length

    tab1 = @builder.right_config.tabs[0]
    assert_equal "Index", tab1.label
    assert_equal :index, tab1.dest
    assert_equal({}, tab1.options)

    tab2 = @builder.right_config.tabs[1]
    assert_equal "Future", tab2.label
    assert_equal :future_log_1, tab2.dest
  end

  def test_right_sidebar_tabs_with_options
    @builder.right(:right_sidebar) do
      tab "Index", dest: :index, icon: :home
    end

    tab = @builder.right_config.tabs.first
    assert_equal({ icon: :home }, tab.options)
  end

  def test_right_sidebar_tabs_with_cycling_destinations
    @builder.right(:right_sidebar) do
      tab "Weeks", dest: [:week_1, :week_2, :week_3]
      tab "Notes", dest: :notes
    end

    assert_equal 2, @builder.right_config.tabs.length

    # Cycling tab stores array of destinations
    weeks_tab = @builder.right_config.tabs[0]
    assert_equal "Weeks", weeks_tab.label
    assert_equal [:week_1, :week_2, :week_3], weeks_tab.dest

    # Single destination unchanged
    notes_tab = @builder.right_config.tabs[1]
    assert_equal "Notes", notes_tab.label
    assert_equal :notes, notes_tab.dest
  end

  def test_tab_config_cycling_predicate
    # TabConfig with cycling destination
    cycling_tab = BujoPdf::PdfDSL::ChromeBuilder::TabConfig.new(
      label: "Weeks",
      dest: [:week_1, :week_2, :week_3],
      options: {}
    )
    assert cycling_tab.cycling?

    # TabConfig with single destination
    single_tab = BujoPdf::PdfDSL::ChromeBuilder::TabConfig.new(
      label: "Year",
      dest: :seasonal,
      options: {}
    )
    refute single_tab.cycling?
  end

  def test_top_sidebar
    @builder.top(:header_bar)

    assert_equal :header_bar, @builder.top_config.sidebar_name
    assert_equal({}, @builder.top_config.options)
  end

  def test_top_sidebar_with_options
    @builder.top(:header_bar, title: "My Planner")

    assert_equal :header_bar, @builder.top_config.sidebar_name
    assert_equal({ title: "My Planner" }, @builder.top_config.options)
  end

  def test_bottom_sidebar
    @builder.bottom(:footer_bar)

    assert_equal :footer_bar, @builder.bottom_config.sidebar_name
  end

  def test_bottom_sidebar_with_options
    @builder.bottom(:footer_bar, show_page_number: true)

    assert_equal({ show_page_number: true }, @builder.bottom_config.options)
  end

  def test_all_four_edges
    @builder.top(:header)
    @builder.bottom(:footer)
    @builder.left(:week_sidebar)
    @builder.right(:nav_tabs)

    assert @builder.any?
    refute @builder.empty?
    assert_equal :header, @builder.top_config.sidebar_name
    assert_equal :footer, @builder.bottom_config.sidebar_name
    assert_equal :week_sidebar, @builder.left_config.sidebar_name
    assert_equal :nav_tabs, @builder.right_config.sidebar_name
  end

  def test_to_h
    @builder.left(:week_sidebar)
    @builder.right(:right_sidebar, style: :compact)

    result = @builder.to_h

    assert_equal :week_sidebar, result[:left].sidebar_name
    assert_equal :right_sidebar, result[:right].sidebar_name
    assert_nil result[:top]
    assert_nil result[:bottom]
  end

  def test_sidebar_config_tabs_predicate
    config_with_tabs = BujoPdf::PdfDSL::ChromeBuilder::SidebarConfig.new(
      sidebar_name: :right_sidebar,
      options: {},
      tabs: [BujoPdf::PdfDSL::ChromeBuilder::TabConfig.new(label: "Test", dest: :test, options: {})]
    )
    assert config_with_tabs.tabs?

    config_without_tabs = BujoPdf::PdfDSL::ChromeBuilder::SidebarConfig.new(
      sidebar_name: :right_sidebar,
      options: {},
      tabs: nil
    )
    refute config_without_tabs.tabs?

    config_with_empty_tabs = BujoPdf::PdfDSL::ChromeBuilder::SidebarConfig.new(
      sidebar_name: :right_sidebar,
      options: {},
      tabs: []
    )
    refute config_with_empty_tabs.tabs?
  end
end
