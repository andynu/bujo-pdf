# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/pdf_assertions'

class TestPdfAssertions < Minitest::Test
  include PdfAssertions

  def setup
    @document = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    %w[alpha bravo charlie].each_with_index do |name, index|
      @document.start_new_page if index.positive?
      @document.add_dest(name, @document.dest_fit)
      @document.text_box "Page #{name.upcase}", at: [50, 700]
    end
    @document.go_to_page(1)
    @document.link_annotation([10, 20, 30, 40], Dest: 'charlie')
    @document.outline.define do
      page destination: 1, title: 'Front'
      section 'Body', destination: 2 do
        page destination: 2, title: 'Bravo'
        page destination: 3, title: 'Charlie'
      end
    end
  end

  def pdf
    @pdf ||= PdfInspector.new(@document)
  end

  def assert_fails_with(pattern, &)
    error = assert_raises(Minitest::Assertion, &)
    assert_match pattern, error.message
  end

  def test_assert_page_count
    assert_page_count pdf, 3
    assert_fails_with(/3 pages/) { assert_page_count pdf, 4 }
  end

  def test_accepts_a_document_or_bytes_as_well_as_an_inspector
    assert_page_count @document, 3
    assert_page_count @document.render, 3
  end

  def test_assert_destination
    assert_destination pdf, :bravo, page: 2
    assert_fails_with(/bravo.*page 2/) { assert_destination pdf, 'bravo', page: 3 }
    assert_fails_with(/delta.*not declared/) { assert_destination pdf, :delta, page: 1 }
  end

  def test_assert_link_to_a_named_destination
    assert_link pdf, from_page: 1, to: :charlie
    assert_link pdf, from_page: :alpha, to: 'charlie'
    assert_fails_with(/page 1.*bravo.*charlie/m) { assert_link pdf, from_page: 1, to: :bravo }
  end

  def test_assert_link_to_a_page_number
    assert_link pdf, from_page: 1, to: 3
    assert_fails_with(/page 2/) { assert_link pdf, from_page: 1, to: 2 }
  end

  def test_refute_link
    refute_link pdf, from_page: 2, to: :charlie
    assert_fails_with(/page 1.*charlie/) { refute_link pdf, from_page: 1, to: :charlie }
  end

  def test_assert_links_resolve
    assert_links_resolve pdf

    @document.go_to_page(2)
    @document.link_annotation([1, 1, 2, 2], Dest: 'nowhere')
    assert_fails_with(/page 2.*nowhere/) { assert_links_resolve PdfInspector.new(@document) }
  end

  def test_assert_outline_compares_the_whole_tree
    assert_outline pdf, ['Front', { 'Body' => %w[Bravo Charlie] }]
    assert_fails_with(/Body/) { assert_outline pdf, %w[Front Body] }
  end

  def test_assert_outline_to_a_depth
    assert_outline pdf, %w[Front Body], depth: 1
  end

  def test_assert_pdf_text_on_page
    assert_pdf_text_on_page pdf, 2, 'Page BRAVO'
    assert_pdf_text_on_page pdf, :charlie, /CHAR+LIE/
    assert_fails_with(/ALPHA.*page 2.*BRAVO/m) { assert_pdf_text_on_page pdf, 2, 'ALPHA' }
  end
end
