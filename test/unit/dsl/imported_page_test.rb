#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/pdf_import_fixture'
require 'bujo_pdf/pdf_dsl'

class TestImportedPageDeclaration < Minitest::Test
  include PdfImportFixture

  def setup
    @context = BujoPdf::PdfDSL::DeclarationContext.new
  end

  def test_import_pdf_returns_the_import
    with_deck do |_dir, manifest|
      deck = @context.import_pdf(manifest)

      assert_instance_of BujoPdf::PdfDSL::PdfImport, deck
      assert_empty @context.pages
    end
  end

  def test_import_page_declares_an_imported_page
    with_deck do |dir, manifest|
      deck = @context.import_pdf(manifest)
      decl = @context.import_page(deck, :second)

      assert_same decl, @context.pages.last
      assert_predicate decl, :imported?
      refute_predicate decl, :inline?
      assert_equal :second, decl.id
      assert_equal 'second', decl.destination_key
      assert_equal File.join(dir, 'deck.pdf'), decl.pdf_path
      assert_equal 2, decl.template_page
    end
  end

  def test_standard_pages_are_not_imported
    @context.page(:seasonal_calendar, year: 2025)

    refute_predicate @context.pages.first, :imported?
  end

  def test_prefix_forms_the_page_id
    with_deck do |_dir, manifest|
      deck = @context.import_pdf(manifest, prefix: :ritual)

      assert_equal :ritual_first, @context.import_page(deck, :first).id
    end
  end

  def test_id_can_be_overridden
    with_deck do |_dir, manifest|
      deck = @context.import_pdf(manifest)

      assert_equal :custom, @context.import_page(deck, :first, id: :custom).id
    end
  end

  def test_unknown_key_raises
    with_deck do |_dir, manifest|
      deck = @context.import_pdf(manifest)

      assert_raises(BujoPdf::PdfDSL::PdfImport::Error) { @context.import_page(deck, :nope) }
    end
  end

  def test_declaring_a_key_twice_raises
    with_deck do |_dir, manifest|
      deck = @context.import_pdf(manifest)
      @context.import_page(deck, :first)

      error = assert_raises(ArgumentError) { @context.import_page(deck, :first) }

      assert_match(/first/, error.message)
    end
  end

  def test_same_key_twice_with_distinct_ids_is_allowed
    with_deck do |_dir, manifest|
      deck = @context.import_pdf(manifest)
      @context.import_page(deck, :first)
      @context.import_page(deck, :first, id: :first_again)

      assert_equal %w[first first_again], @context.pages.map(&:destination_key)
    end
  end

  def test_import_pages_declares_all_in_pdf_order
    with_deck do |_dir, manifest|
      deck = @context.import_pdf(manifest, prefix: :r)
      decls = @context.import_pages(deck)

      assert_equal %i[r_first r_second r_third], @context.pages.map(&:id)
      assert_equal decls, @context.pages
      assert_equal [1, 2, 3], @context.pages.map(&:template_page)
    end
  end

  def test_no_outline_entry_by_default_in_manual_mode
    with_deck do |_dir, manifest|
      @context.import_page(@context.import_pdf(manifest), :second)

      assert_empty @context.outline_entries
    end
  end

  def test_outline_true_uses_the_manifest_title
    with_deck do |_dir, manifest|
      @context.import_page(@context.import_pdf(manifest), :second, outline: true)

      entry = @context.outline_entries.first
      assert_equal 'The Second One', entry.title
      assert_equal :second, entry.dest
    end
  end

  def test_outline_string_overrides_the_title
    with_deck do |_dir, manifest|
      @context.import_page(@context.import_pdf(manifest), :second, outline: 'Custom')

      assert_equal 'Custom', @context.outline_entries.first.title
    end
  end

  def test_auto_outline_mode_adds_entries_and_false_suppresses
    with_deck do |_dir, manifest|
      @context.outline_mode :auto
      deck = @context.import_pdf(manifest)
      @context.import_page(deck, :first)
      @context.import_page(deck, :second, outline: false)

      assert_equal ['First'], @context.outline_entries.map(&:title)
    end
  end

  def test_import_pages_forwards_outline
    with_deck do |_dir, manifest|
      @context.import_pages(@context.import_pdf(manifest), outline: true)

      assert_equal ['First', 'The Second One', 'Third'], @context.outline_entries.map(&:title)
    end
  end

  def test_imported_pages_join_the_enclosing_group
    with_deck do |_dir, manifest|
      deck = @context.import_pdf(manifest)
      @context.group(:rituals, cycle: true) { import_pages(deck) }

      assert_equal %w[first second third], @context.groups.first.destination_keys
    end
  end
end
