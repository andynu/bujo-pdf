# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/pdf_inspector'
require 'tmpdir'

class TestPdfInspector < Minitest::Test
  # Three pages, each with a named destination, text, and links of every kind
  # Prawn writes: by name, by explicit page reference, and through a GoTo action.
  def build
    pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    %w[alpha bravo charlie].each_with_index do |name, index|
      pdf.start_new_page if index.positive?
      pdf.add_dest(name, pdf.dest_fit)
      pdf.text_box name.upcase, at: [50, 700]
    end
    pdf.go_to_page(1)
    pdf.link_annotation([10, 20, 30, 40], Dest: 'charlie')
    pdf.link_annotation([50, 60, 70, 80], Dest: pdf.dest_fit(pdf.state.pages[1]))
    pdf.link_annotation([90, 100, 110, 120], A: { S: :GoTo, D: 'bravo' })
    pdf.link_annotation([0, 0, 5, 5], A: { S: :URI, URI: 'https://example.com' })
    yield pdf if block_given?
    pdf
  end

  def inspect_pdf(pdf = build)
    PdfInspector.new(pdf)
  end

  def test_page_count
    assert_equal 3, inspect_pdf.page_count
  end

  def test_reads_bytes_a_path_and_a_prawn_document
    bytes = build.render
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'out.pdf')
      File.binwrite(path, bytes)

      assert_equal 3, PdfInspector.new(bytes).page_count
      assert_equal 3, PdfInspector.new(path).page_count
      assert_equal 3, PdfInspector.new(Pathname.new(path)).page_count
      assert_equal 3, PdfInspector.new(build).page_count
    end
  end

  def test_destinations_map_names_to_page_numbers
    assert_equal({ 'alpha' => 1, 'bravo' => 2, 'charlie' => 3 }, inspect_pdf.destinations)
  end

  # Prawn splits the name tree into /Kids once it outgrows one node, which is
  # the shape every full planner has.
  def test_destinations_are_read_through_name_tree_kids
    pdf = build { |doc| 30.times { |i| doc.add_dest("extra_#{i}", doc.dest_fit(doc.state.pages[2])) } }
    inspector = inspect_pdf(pdf)

    objects = inspector.reader.objects
    names = objects.deref(objects.deref(objects.trailer[:Root])[:Names])

    assert objects.deref(names[:Dests]).key?(:Kids), 'fixture should produce a name tree with /Kids'
    assert_equal 33, inspector.destinations.size
    assert_equal 3, inspector.destinations['extra_29']
  end

  def test_links_report_rect_destination_name_and_target_page
    links = inspect_pdf.links(1)

    assert_equal [[10, 20, 30, 40], [50, 60, 70, 80], [90, 100, 110, 120]], links.first(3).map(&:rect)
    assert_equal ['charlie', nil, 'bravo'], links.first(3).map(&:dest)
    assert_equal [3, 2, 2], links.first(3).map(&:page)
  end

  def test_uri_links_have_a_uri_and_no_target
    link = inspect_pdf.links(1).last

    assert_equal 'https://example.com', link.uri
    assert_nil link.page
  end

  def test_a_page_without_links_has_none
    assert_empty inspect_pdf.links(2)
  end

  def test_links_without_a_page_number_lists_every_page
    assert_equal [1, 1, 1, 1], inspect_pdf.links.map(&:from_page)
  end

  # Prawn writes /Annots inline; other writers put the array behind a reference.
  def test_links_are_read_from_a_referenced_annots_array
    pdf = build do |doc|
      page = doc.state.pages[0].dictionary
      page.data[:Annots] = doc.ref!(page.data[:Annots])
    end

    assert_equal ['charlie', nil, 'bravo', nil], inspect_pdf(pdf).links(1).map(&:dest)
  end

  def test_a_link_to_an_undeclared_name_has_no_page
    pdf = build { |doc| doc.link_annotation([1, 1, 2, 2], Dest: 'nowhere') }
    link = inspect_pdf(pdf).links(1).last

    assert_equal 'nowhere', link.dest
    assert_nil link.page
  end

  def test_outline_tree_with_titles_pages_and_children
    pdf = build do |doc|
      doc.outline.define do
        page destination: 1, title: 'Front'
        section 'Body', destination: 2 do
          page destination: 2, title: 'Bravo'
          page destination: 3, title: 'Charlie'
        end
      end
    end
    outline = inspect_pdf(pdf).outline

    assert_equal %w[Front Body], outline.map(&:title)
    assert_equal [1, 2], outline.map(&:page)
    assert_equal [%w[Bravo 2], %w[Charlie 3]], outline[1].children.map { |item| [item.title, item.page.to_s] }
    assert_empty outline[0].children
  end

  def test_outline_titles_are_decoded_from_utf16
    pdf = build { |doc| doc.outline.define { page destination: 1, title: 'Café' } }

    assert_equal 'Café', inspect_pdf(pdf).outline.first.title
  end

  def test_no_outline_is_empty
    assert_empty inspect_pdf.outline
  end

  def test_text_per_page
    inspector = inspect_pdf

    assert_includes inspector.text(2), 'BRAVO'
    refute_includes inspector.text(2), 'ALPHA'
  end

  def test_page_number_accepts_a_page_or_a_destination_name
    inspector = inspect_pdf

    assert_equal 2, inspector.page_number(2)
    assert_equal 3, inspector.page_number(:charlie)
    assert_equal 3, inspector.page_number('charlie')
    assert_raises(KeyError) { inspector.page_number(:nowhere) }
  end
end
