#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/pdf_import_fixture'
require 'bujo_pdf/pdf_dsl'

class TestPdfImport < Minitest::Test
  include PdfImportFixture

  Error = BujoPdf::PdfDSL::PdfImport::Error

  def load_deck(manifest, prefix: nil)
    BujoPdf::PdfDSL::PdfImport.new(manifest, prefix: prefix)
  end

  def test_loads_keys_and_page_numbers
    with_deck do |_dir, manifest|
      deck = load_deck(manifest)

      assert_equal %i[first second third], deck.keys
      assert_equal 3, deck.page_count
      assert_equal 2, deck.page(:second).page_number
    end
  end

  def test_pdf_defaults_to_manifest_basename
    with_deck do |dir, manifest|
      assert_equal File.join(dir, 'deck.pdf'), load_deck(manifest).pdf_path
    end
  end

  def test_pdf_can_be_named_in_manifest
    yaml = "pdf: other.pdf\npages:\n  only: 1\n"
    with_deck(manifest: yaml) do |dir, manifest|
      FileUtils.cp(File.join(dir, 'deck.pdf'), File.join(dir, 'other.pdf'))

      assert_equal File.join(dir, 'other.pdf'), load_deck(manifest).pdf_path
    end
  end

  def test_title_defaults_to_titleized_key
    with_deck(manifest: "pages:\n  yearly_migration: 1\n") do |_dir, manifest|
      assert_equal 'Yearly Migration', load_deck(manifest).page(:yearly_migration).title
    end
  end

  def test_title_can_be_given_in_manifest
    with_deck do |_dir, manifest|
      assert_equal 'The Second One', load_deck(manifest).page(:second).title
    end
  end

  def test_nav_label_can_be_given_in_manifest
    with_deck(manifest: "pages:\n  first:\n    page: 1\n    title: The First One\n    nav: First\n") do |_dir, manifest|
      assert_equal 'First', load_deck(manifest).page(:first).nav
    end
  end

  def test_nav_label_is_nil_when_not_given
    with_deck do |_dir, manifest|
      assert_nil load_deck(manifest).page(:second).nav
    end
  end

  def test_pages_are_in_pdf_order_not_manifest_order
    yaml = "pages:\n  last: 3\n  first: 1\n  middle: 2\n"
    with_deck(manifest: yaml) do |_dir, manifest|
      assert_equal %i[first middle last], load_deck(manifest).pages.map(&:key)
    end
  end

  def test_page_id_without_prefix_is_the_key
    with_deck do |_dir, manifest|
      assert_equal :first, load_deck(manifest).page_id(:first)
    end
  end

  def test_page_id_with_prefix
    with_deck do |_dir, manifest|
      assert_equal :ritual_first, load_deck(manifest, prefix: :ritual).page_id(:first)
    end
  end

  def test_unknown_key_lists_known_keys
    with_deck do |_dir, manifest|
      error = assert_raises(Error) { load_deck(manifest).page(:nope) }

      assert_match(/:nope/, error.message)
      assert_match(/first, second, third/, error.message)
    end
  end

  def test_error_is_an_argument_error
    assert_operator Error, :<, ArgumentError
  end

  def test_missing_manifest
    error = assert_raises(Error) { load_deck('/nonexistent/deck.yml') }

    assert_match(/manifest not found/, error.message)
  end

  def test_missing_pdf
    with_deck(manifest: "pdf: gone.pdf\npages:\n  a: 1\n") do |_dir, manifest|
      error = assert_raises(Error) { load_deck(manifest) }

      assert_match(/gone\.pdf/, error.message)
    end
  end

  def test_unreadable_pdf
    with_deck do |dir, manifest|
      File.write(File.join(dir, 'deck.pdf'), 'not a pdf')

      error = assert_raises(Error) { load_deck(manifest) }

      assert_match(/not a readable PDF/, error.message)
    end
  end

  def test_malformed_yaml
    with_deck(manifest: "pages: [unclosed\n") do |_dir, manifest|
      assert_raises(Error) { load_deck(manifest) }
    end
  end

  def test_manifest_without_pages
    with_deck(manifest: "pdf: deck.pdf\n") do |_dir, manifest|
      error = assert_raises(Error) { load_deck(manifest) }

      assert_match(/pages/, error.message)
    end
  end

  def test_page_beyond_pdf_length
    with_deck(manifest: "pages:\n  far: 4\n") do |_dir, manifest|
      error = assert_raises(Error) { load_deck(manifest) }

      assert_match(/far/, error.message)
      assert_match(/3 pages/, error.message)
    end
  end

  def test_page_zero_and_non_integer
    ['0', '"2"', '1.5', '-1'].each do |value|
      with_deck(manifest: "pages:\n  bad: #{value}\n") do |_dir, manifest|
        assert_raises(Error, "page: #{value} should be rejected") { load_deck(manifest) }
      end
    end
  end

  def test_two_keys_for_one_page
    with_deck(manifest: "pages:\n  a: 1\n  b: 1\n") do |_dir, manifest|
      error = assert_raises(Error) { load_deck(manifest) }

      assert_match(/page 1/, error.message)
    end
  end

  def test_unknown_entry_option_is_rejected
    with_deck(manifest: "pages:\n  a:\n    page: 1\n    titel: Typo\n") do |_dir, manifest|
      error = assert_raises(Error) { load_deck(manifest) }

      assert_match(/titel/, error.message)
    end
  end

  def test_key_must_be_identifier_like
    with_deck(manifest: "pages:\n  'has space': 1\n") do |_dir, manifest|
      assert_raises(Error) { load_deck(manifest) }
    end
  end

  def test_unlisted_pdf_pages_warn_but_load
    with_deck(manifest: "pages:\n  first: 1\n") do |_dir, manifest|
      deck = nil
      _out, err = capture_io { deck = load_deck(manifest) }

      assert_equal [:first], deck.keys
      assert_match(/pages? 2, 3/, err)
    end
  end

  def test_fully_listed_deck_is_silent
    with_deck do |_dir, manifest|
      _out, err = capture_io { load_deck(manifest) }

      assert_empty err
    end
  end
end
