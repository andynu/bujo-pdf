#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestInlinePageContext < Minitest::Test
  def test_default_values
    ctx = BujoPdf::PdfDSL::InlinePageContext.new

    assert_equal :full_page, ctx.layout_name
    assert_equal({}, ctx.layout_options)
    assert_nil ctx.theme_override
    assert_equal :dot_grid, ctx.background_type
    assert_nil ctx.body_block
  end

  def test_layout_configuration
    ctx = BujoPdf::PdfDSL::InlinePageContext.new
    ctx.evaluate do
      layout :standard_with_sidebars, current_week: 5
    end

    assert_equal :standard_with_sidebars, ctx.layout_name
    assert_equal({ current_week: 5 }, ctx.layout_options)
  end

  def test_theme_override
    ctx = BujoPdf::PdfDSL::InlinePageContext.new
    ctx.evaluate do
      theme :dark
    end

    assert_equal :dark, ctx.theme_override
  end

  def test_background_type
    ctx = BujoPdf::PdfDSL::InlinePageContext.new
    ctx.evaluate do
      background :ruled
    end

    assert_equal :ruled, ctx.background_type
  end

  def test_body_block_capture
    ctx = BujoPdf::PdfDSL::InlinePageContext.new
    ctx.evaluate do
      body { "test content" }
    end

    refute_nil ctx.body_block
    assert_equal "test content", ctx.body_block.call
  end

  def test_full_configuration
    ctx = BujoPdf::PdfDSL::InlinePageContext.new
    ctx.evaluate do
      layout :full_page
      theme :earth
      background :blank
      body { "rendered" }
    end

    assert_equal :full_page, ctx.layout_name
    assert_equal :earth, ctx.theme_override
    assert_equal :blank, ctx.background_type
    refute_nil ctx.body_block
  end
end

class TestInlinePageDeclaration < Minitest::Test
  def setup
    @ctx = BujoPdf::PdfDSL::InlinePageContext.new
    @ctx.evaluate do
      layout :full_page
      background :ruled
      body { "content" }
    end
  end

  def test_inline_predicate
    decl = BujoPdf::PdfDSL::InlinePageDeclaration.new(
      id: :test,
      inline_context: @ctx
    )

    assert decl.inline?
  end

  def test_type_is_inline
    decl = BujoPdf::PdfDSL::InlinePageDeclaration.new(
      id: :test,
      inline_context: @ctx
    )

    assert_equal :inline, decl.type
  end

  def test_delegates_to_context
    decl = BujoPdf::PdfDSL::InlinePageDeclaration.new(
      id: :notes,
      outline: 'Notes',
      inline_context: @ctx
    )

    assert_equal :full_page, decl.layout_name
    assert_equal :ruled, decl.background_type
    refute_nil decl.body_block
    assert_nil decl.theme_override
  end

  def test_standard_declaration_not_inline
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:seasonal_calendar, year: 2025)

    refute decl.inline?
  end
end

class TestDeclarationContextInlinePages < Minitest::Test
  def setup
    @context = BujoPdf::PdfDSL::DeclarationContext.new
  end

  def test_inline_page_with_block
    @context.page(id: :notes, outline: 'Notes') do
      layout :full_page
      background :ruled
      body { "content" }
    end

    assert_equal 1, @context.pages.length
    decl = @context.pages.first
    assert decl.inline?
    assert_equal :notes, decl.id
    assert_equal 'Notes', decl.outline_title
  end

  def test_inline_page_without_id
    @context.page do
      body { "minimal" }
    end

    assert_equal 1, @context.pages.length
    decl = @context.pages.first
    assert decl.inline?
    assert_nil decl.id
  end

  def test_inline_page_outline_true_uses_id
    @context.page(id: :my_notes, outline: true) do
      body { "content" }
    end

    decl = @context.pages.first
    assert_equal 'My Notes', decl.outline_title
  end

  def test_inline_page_outline_true_without_id
    @context.page(outline: true) do
      body { "content" }
    end

    decl = @context.pages.first
    assert_equal 'Untitled', decl.outline_title
  end

  def test_mixed_standard_and_inline_pages
    @context.page :seasonal_calendar, year: 2025

    @context.page(id: :notes) do
      layout :full_page
      body { "notes" }
    end

    @context.page :reference

    assert_equal 3, @context.pages.length
    refute @context.pages[0].inline?
    assert @context.pages[1].inline?
    refute @context.pages[2].inline?
  end

  def test_inline_page_adds_outline_entry
    @context.page(id: :notes, outline: 'Notes Page') do
      body { "content" }
    end

    assert_equal 1, @context.outline_entries.length
    assert_equal 'Notes Page', @context.outline_entries.first.title
    assert_equal :notes, @context.outline_entries.first.dest
  end

  def test_inline_page_in_group
    @context.group(:custom) do
      page(id: :custom_1) do
        body { "page 1" }
      end
      page(id: :custom_2) do
        body { "page 2" }
      end
    end

    # Pages should be in both group and main list
    assert_equal 2, @context.pages.length
    assert_equal 1, @context.groups.length
    assert_equal 2, @context.groups.first.pages.length

    # All should be inline
    @context.pages.each do |p|
      assert p.inline?
    end
  end

  def test_page_without_type_and_block_raises
    assert_raises(ArgumentError) do
      @context.page(id: :test)
    end
  end
end
