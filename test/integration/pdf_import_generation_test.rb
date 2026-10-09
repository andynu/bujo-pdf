#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/pdf_import_fixture'
require 'bujo_pdf'
require 'bujo_pdf/pdf_dsl'
require 'bujo_pdf/pages/all'
require 'pdf/reader'
require 'stringio'

class TestPdfImportGeneration < Minitest::Test
  include PdfImportFixture

  def setup
    BujoPdf::PdfDSL.clear_recipes!
  end

  def build(manifest, prefix: nil, &recipe)
    BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :front, outline: 'Front') { body { h1(2, 1, 'Front') } }
      instance_exec(import_pdf(manifest, prefix: prefix), &recipe)
    end
  end

  def reader_for(pdf)
    PDF::Reader.new(StringIO.new(pdf.render))
  end

  def page_text(reader, number)
    reader.page(number).text.strip
  end

  # name => 1-based page number, read from the rendered PDF's name tree
  def named_destinations(reader)
    objects = reader.objects
    root = objects.deref(objects.trailer[:Root])
    tree = objects.deref(objects.deref(root[:Names])[:Dests])
    pages = reader.pages.map(&:page_object)

    leaves(objects, tree).each_slice(2).to_h do |name, dest|
      page_ref = objects.deref(dest).then { |d| d.is_a?(Hash) ? d[:D] : d }.first
      [name, pages.index(objects.deref(page_ref)) + 1]
    end
  end

  def leaves(objects, node)
    node = objects.deref(node)
    return node[:Names] if node[:Names]

    node[:Kids].flat_map { |kid| leaves(objects, kid) }
  end

  def outline_titles(reader)
    objects = reader.objects
    root = objects.deref(objects.trailer[:Root])
    node = objects.deref(objects.deref(root[:Outlines])[:First])
    titles = []
    while node
      titles << node[:Title].byteslice(2..).force_encoding('UTF-16BE').encode('UTF-8')
      node = node[:Next] && objects.deref(node[:Next])
    end
    titles
  end

  def test_imported_pages_are_inserted_in_order
    with_deck do |_dir, manifest|
      pdf = build(manifest) { |deck| import_pages(deck) }
      reader = reader_for(pdf)

      assert_equal 4, reader.page_count
      assert_equal %w[ALPHA BRAVO CHARLIE], (2..4).map { |n| page_text(reader, n) }
    end
  end

  def test_single_pages_can_be_placed_anywhere
    with_deck do |_dir, manifest|
      pdf = BujoPdf::PdfDSL.generate(year: 2025) do
        deck = import_pdf(manifest)
        page(id: :front) { body { h1(2, 1, 'Front') } }
        import_page(deck, :third)
        page(id: :middle) { body { h1(2, 1, 'Middle') } }
        import_page(deck, :first)
      end
      reader = reader_for(pdf)

      assert_equal 4, reader.page_count
      assert_equal 'CHARLIE', page_text(reader, 2)
      assert_equal 'ALPHA', page_text(reader, 4)
    end
  end

  def test_named_destinations_point_at_imported_pages
    with_deck do |_dir, manifest|
      pdf = build(manifest, prefix: :ritual) { |deck| import_pages(deck) }
      destinations = named_destinations(reader_for(pdf))

      assert_equal 1, destinations['front']
      assert_equal 2, destinations['ritual_first']
      assert_equal 3, destinations['ritual_second']
      assert_equal 4, destinations['ritual_third']
    end
  end

  def test_outline_entries_for_imported_pages
    with_deck do |_dir, manifest|
      pdf = build(manifest) { |deck| import_pages(deck, outline: true) }

      assert_equal ['Front', 'First', 'The Second One', 'Third'], outline_titles(reader_for(pdf))
    end
  end

  def test_pages_after_an_imported_page_render_normally
    with_deck do |_dir, manifest|
      pdf = BujoPdf::PdfDSL.generate(year: 2025) do
        page(id: :front) { body { h1(2, 1, 'Front') } }
        import_page(import_pdf(manifest), :first)
        page(id: :after) { body { h1(2, 1, 'After') } }
      end
      reader = reader_for(pdf)

      assert_equal 3, reader.page_count
      assert_includes page_text(reader, 3), 'After'
      assert_equal [612.0, 792.0], reader.page(3).attributes[:MediaBox].last(2).map(&:to_f)
    end
  end

  def test_imported_page_cannot_be_first
    with_deck do |_dir, manifest|
      error = assert_raises(ArgumentError) do
        BujoPdf::PdfDSL.generate(year: 2025) do
          import_page(import_pdf(manifest), :first)
        end
      end

      assert_match(/first page/, error.message)
    end
  end

  def test_output_is_written_when_requested
    with_deck do |dir, manifest|
      out = File.join(dir, 'out.pdf')
      BujoPdf::PdfDSL.generate(year: 2025, output: out) do
        page(id: :front) { body { h1(2, 1, 'Front') } }
        import_pages(import_pdf(manifest))
      end

      assert_equal 4, PDF::Reader.new(out).page_count
    end
  end
end
