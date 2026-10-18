#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/pdf_import_fixture'
require_relative '../support/pdf_assertions'
require 'bujo_pdf'
require 'bujo_pdf/pdf_dsl'
require 'bujo_pdf/pages/all'

class TestPdfImportGeneration < Minitest::Test
  include PdfImportFixture
  include PdfAssertions

  def setup
    BujoPdf::PdfDSL.clear_recipes!
  end

  def build(manifest, prefix: nil, &recipe)
    BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :front, outline: 'Front') { body { h1(2, 1, 'Front') } }
      instance_exec(import_pdf(manifest, prefix: prefix), &recipe)
    end
  end

  def test_imported_pages_are_inserted_in_order
    with_deck do |_dir, manifest|
      pdf = PdfInspector.new(build(manifest) { |deck| import_pages(deck) })

      assert_page_count pdf, 4
      assert_equal %w[ALPHA BRAVO CHARLIE], (2..4).map { |n| pdf.text(n).strip }
    end
  end

  def test_imported_pages_get_recipe_chrome
    with_deck do |_dir, manifest|
      pdf = PdfInspector.new(
        build(manifest) do |deck|
          chrome { right :section_nav }
          nav_section :deck, label: 'Deck', items: deck.pages.map { |entry| [deck.page_id(entry.key), entry.title] }
          import_pages(deck)
        end
      )

      # Page 2 is the first deck page: the deck section is expanded, so the
      # other two deck pages are one tap away
      dests = pdf.links(2).map(&:dest)
      assert_includes dests, 'second'
      assert_includes dests, 'third'
      assert_includes pdf.text(2), 'ALPHA', 'the imported content survives under the chrome'
    end
  end

  # The ritual deck's pages open with a top-level transform (cm) they never
  # restore. Chrome drawn after it must still land in page coordinates.
  def test_chrome_over_a_page_with_a_leftover_transform_lands_on_the_page_edge
    manifest = File.expand_path('../../assets/ritual_deck/manifest.yml', __dir__)
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      deck = import_pdf(manifest, prefix: :ritual)
      chrome { right :section_nav }
      nav_section :rituals, label: 'Rituals', items: deck.pages.map { |entry| [deck.page_id(entry.key), entry.nav] }
      page(id: :front) { body { h1(2, 1, 'Front') } }
      import_page(deck, :daily)
    end
    reader = PDF::Reader.new(StringIO.new(pdf.render))
    # Rotated text reads back one character per run; the deck itself has no
    # marks past x = 547, so anything in the right-hand column is the nav
    right_column = reader.pages[1].runs(merge: false).select { |run| run.x > 590 }.map(&:text).join

    assert_includes right_column, 'R', 'the Rituals tab sits in the right-hand column, not inside the deck transform'
  end

  def test_imported_page_without_chrome_is_unchanged
    with_deck do |_dir, manifest|
      pdf = PdfInspector.new(build(manifest) { |deck| import_pages(deck) })

      assert_empty pdf.links(2)
      assert_equal 'ALPHA', pdf.text(2).strip
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
      pdf = PdfInspector.new(pdf)

      assert_page_count pdf, 4
      assert_equal 'CHARLIE', pdf.text(2).strip
      assert_equal 'ALPHA', pdf.text(4).strip
    end
  end

  def test_named_destinations_point_at_imported_pages
    with_deck do |_dir, manifest|
      pdf = PdfInspector.new(build(manifest, prefix: :ritual) { |deck| import_pages(deck) })

      assert_destination pdf, :front, page: 1
      assert_destination pdf, :ritual_first, page: 2
      assert_destination pdf, :ritual_second, page: 3
      assert_destination pdf, :ritual_third, page: 4
    end
  end

  def test_outline_entries_for_imported_pages
    with_deck do |_dir, manifest|
      pdf = build(manifest) { |deck| import_pages(deck, outline: true) }

      assert_outline pdf, ['Front', 'First', 'The Second One', 'Third']
    end
  end

  def test_pages_after_an_imported_page_render_normally
    with_deck do |_dir, manifest|
      pdf = BujoPdf::PdfDSL.generate(year: 2025) do
        page(id: :front) { body { h1(2, 1, 'Front') } }
        import_page(import_pdf(manifest), :first)
        page(id: :after) { body { h1(2, 1, 'After') } }
      end
      pdf = PdfInspector.new(pdf)

      assert_page_count pdf, 3
      assert_pdf_text_on_page pdf, 3, 'After'
      assert_equal [612.0, 792.0], pdf.reader.page(3).attributes[:MediaBox].last(2).map(&:to_f)
    end
  end

  # Page dictionaries are written uncompressed, so unreachable copies of the
  # source deck's other pages show up as extra /Type /Page objects.
  def test_unused_pages_of_the_source_deck_are_not_copied
    with_deck do |_dir, manifest|
      pdf = BujoPdf::PdfDSL.generate(year: 2025) do
        page(id: :front) { body { h1(2, 1, 'Front') } }
        import_page(import_pdf(manifest), :first)
      end

      assert_equal 2, pdf.render.scan(%r{/Type /Page\b}).size
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

      assert_page_count out, 4
    end
  end
end
