#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

# Tests for per-page chrome override functionality in PdfBuilder
class TestBuilderChrome < Minitest::Test
  def setup
    @builder = BujoPdf::PdfDSL::PdfBuilder.new
  end

  # resolve_page_chrome tests

  def test_resolve_page_chrome_nil_inherits_pdf_chrome
    pdf_chrome = create_chrome_config(left: :week_sidebar)

    result = @builder.send(:resolve_page_chrome, nil, pdf_chrome)

    assert_equal pdf_chrome, result
  end

  def test_resolve_page_chrome_false_returns_nil
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    result = @builder.send(:resolve_page_chrome, false, pdf_chrome)

    assert_nil result
  end

  def test_resolve_page_chrome_false_with_nil_pdf_chrome
    result = @builder.send(:resolve_page_chrome, false, nil)

    assert_nil result
  end

  def test_resolve_page_chrome_hash_merges_with_pdf_chrome
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)
    page_chrome = { right: false }

    result = @builder.send(:resolve_page_chrome, page_chrome, pdf_chrome)

    # Left should remain, right should be disabled
    assert_equal :week_sidebar, result.left_config.sidebar_name
    assert_nil result.right_config
  end

  # merge_chrome_configs tests

  def test_merge_chrome_configs_disable_right
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    result = @builder.send(:merge_chrome_configs, pdf_chrome, { right: false })

    assert_equal :week_sidebar, result.left_config.sidebar_name
    assert_nil result.right_config
  end

  def test_merge_chrome_configs_disable_left
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    result = @builder.send(:merge_chrome_configs, pdf_chrome, { left: false })

    assert_nil result.left_config
    assert_equal :right_sidebar, result.right_config.sidebar_name
  end

  def test_merge_chrome_configs_replace_left_sidebar
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    result = @builder.send(:merge_chrome_configs, pdf_chrome, { left: :month_sidebar })

    assert_equal :month_sidebar, result.left_config.sidebar_name
    assert_equal :right_sidebar, result.right_config.sidebar_name
  end

  def test_merge_chrome_configs_replace_right_sidebar
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    result = @builder.send(:merge_chrome_configs, pdf_chrome, { right: :nav_tabs })

    assert_equal :week_sidebar, result.left_config.sidebar_name
    assert_equal :nav_tabs, result.right_config.sidebar_name
  end

  def test_merge_chrome_configs_add_top_sidebar
    pdf_chrome = create_chrome_config(left: :week_sidebar)

    result = @builder.send(:merge_chrome_configs, pdf_chrome, { top: :header_bar })

    assert_equal :week_sidebar, result.left_config.sidebar_name
    assert_equal :header_bar, result.top_config.sidebar_name
  end

  def test_merge_chrome_configs_disable_all
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    result = @builder.send(:merge_chrome_configs, pdf_chrome,
                           { left: false, right: false })

    assert_nil result
  end

  def test_merge_chrome_configs_nil_pdf_chrome_with_new_sidebar
    result = @builder.send(:merge_chrome_configs, nil, { left: :week_sidebar })

    assert_equal :week_sidebar, result.left_config.sidebar_name
  end

  def test_merge_chrome_configs_nil_pdf_chrome_all_false
    result = @builder.send(:merge_chrome_configs, nil, { left: false, right: false })

    assert_nil result
  end

  def test_merge_chrome_configs_preserves_sidebar_options
    pdf_chrome = BujoPdf::PdfDSL::ChromeBuilder.new
    pdf_chrome.left(:week_sidebar, current_week: 27)

    result = @builder.send(:merge_chrome_configs, pdf_chrome, { right: :nav_tabs })

    assert_equal :week_sidebar, result.left_config.sidebar_name
    assert_equal({ current_week: 27 }, result.left_config.options)
  end

  def test_merge_chrome_configs_override_with_hash_options
    pdf_chrome = create_chrome_config(left: :week_sidebar)

    result = @builder.send(:merge_chrome_configs, pdf_chrome,
                           { left: { component: :month_sidebar, show_all: true } })

    assert_equal :month_sidebar, result.left_config.sidebar_name
    assert_equal({ show_all: true }, result.left_config.options)
  end

  # apply_chrome_override tests

  def test_apply_chrome_override_symbol
    builder = BujoPdf::PdfDSL::ChromeBuilder.new

    @builder.send(:apply_chrome_override, builder, :left, :week_sidebar)

    assert_equal :week_sidebar, builder.left_config.sidebar_name
  end

  def test_apply_chrome_override_hash_with_component
    builder = BujoPdf::PdfDSL::ChromeBuilder.new

    @builder.send(:apply_chrome_override, builder, :right,
                  { component: :nav_tabs, style: :compact })

    assert_equal :nav_tabs, builder.right_config.sidebar_name
    assert_equal({ style: :compact }, builder.right_config.options)
  end

  # Integration with build_page_context

  def test_build_page_context_applies_chrome_false
    # Create mock objects needed for build_page_context
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:cover, id: :cover, chrome: false)
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    base_context = {
      year: 2025,
      total_weeks: 52,
      total_pages: 1,
      link_registry: BujoPdf::PdfDSL::LinkRegistry.new,
      chrome_config: pdf_chrome
    }

    context = @builder.send(:build_page_context, page_decl, base_context, 0)

    # Chrome should be nil (full opt-out)
    assert_nil context[:chrome_config]
  end

  def test_build_page_context_applies_chrome_hash
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:notes, id: :notes,
                                                     chrome: { right: false })
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    base_context = {
      year: 2025,
      total_weeks: 52,
      total_pages: 1,
      link_registry: BujoPdf::PdfDSL::LinkRegistry.new,
      chrome_config: pdf_chrome
    }

    context = @builder.send(:build_page_context, page_decl, base_context, 0)

    # Left should remain, right should be disabled
    refute_nil context[:chrome_config]
    assert_equal :week_sidebar, context[:chrome_config].left_config.sidebar_name
    assert_nil context[:chrome_config].right_config
  end

  def test_build_page_context_inherits_chrome_when_nil
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: 1)
    pdf_chrome = create_chrome_config(left: :week_sidebar, right: :right_sidebar)

    base_context = {
      year: 2025,
      total_weeks: 52,
      total_pages: 1,
      link_registry: BujoPdf::PdfDSL::LinkRegistry.new,
      chrome_config: pdf_chrome
    }

    context = @builder.send(:build_page_context, page_decl, base_context, 0)

    # Chrome should be inherited unchanged
    assert_equal pdf_chrome, context[:chrome_config]
  end

  private

  def create_chrome_config(**regions)
    builder = BujoPdf::PdfDSL::ChromeBuilder.new
    regions.each do |region, sidebar_name|
      builder.send(region, sidebar_name)
    end
    builder
  end
end
