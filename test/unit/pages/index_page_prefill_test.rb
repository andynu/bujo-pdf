# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/pdf_assertions'
require 'bujo_pdf/pdf_dsl'

class TestIndexPagePrefill < Minitest::Test
  include PdfAssertions

  ENTRIES = [
    { title: 'The Daily Protocol', dest: :ritual_daily },
    { title: 'The Weekly Review', dest: :ritual_weekly },
    { title: 'The Mood Meter', dest: :ritual_mood_grid }
  ].freeze

  # Above 50 so they cannot be confused with the page's own entry numbers 1-50
  PAGE_NUMBERS = { ritual_daily: 109, ritual_weekly: 110, ritual_mood_grid: 118 }.freeze

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, 'page_dots')
  end

  def resolver
    registry = BujoPdf::PdfDSL::LinkRegistry.new
    PAGE_NUMBERS.each do |id, number|
      registry.register(BujoPdf::PdfDSL::PageDeclaration.new(:imported_pdf, id: id), page_number: number)
    end
    BujoPdf::PdfDSL::LinkResolver.new(registry)
  end

  def generate(page_num: 1, prefill: ENTRIES, link_resolver: resolver)
    context = BujoPdf::RenderContext.new(
      page_key: :"index_#{page_num}", page_number: page_num, year: 2025,
      index_page_num: page_num, index_page_count: 2,
      prefill: prefill, link_resolver: link_resolver
    )
    BujoPdf::Pages::IndexPage.new(@pdf, context).generate
    PdfInspector.new(@pdf)
  end

  def test_prefilled_titles_and_page_numbers_are_printed
    pdf = generate

    assert_pdf_text_on_page pdf, 1, 'The Daily Protocol'
    assert_pdf_text_on_page pdf, 1, 'The Mood Meter'
    assert_pdf_text_on_page pdf, 1, /\b109\b/
    assert_pdf_text_on_page pdf, 1, /\b118\b/
  end

  def test_each_entry_links_to_its_page
    assert_equal %w[ritual_daily ritual_weekly ritual_mood_grid], generate.links(1).map(&:dest)
  end

  def test_link_covers_the_whole_entry_row_and_rows_stack_downward
    rects = generate.links(1).map(&:rect)

    assert_equal rects.map { |r| r[3] }.sort.reverse, rects.map { |r| r[3] }
    rects.each do |left, bottom, right, top|
      assert_operator right - left, :>, 150
      assert_in_delta 2 * Styling::Grid::DOT_SPACING, top - bottom, 0.5
    end
  end

  def test_entries_beyond_one_column_continue_in_the_second
    many = Array.new(27) { |i| { title: "Entry #{i}", dest: :ritual_daily } }
    rects = generate(prefill: many).links(1).map(&:rect)

    assert_operator rects[25][0], :>, rects[24][2], 'entry 26 should start in the right column'
    assert_in_delta rects[0][3], rects[25][3], 0.5, 'right column restarts at the first row'
  end

  def test_second_index_page_is_not_prefilled
    pdf = generate(page_num: 2)

    assert_empty pdf.links(1)
    refute_includes pdf.text(1), 'The Daily Protocol'
  end

  def test_no_prefill_adds_no_links
    assert_empty generate(prefill: nil).links(1)
  end

  def test_an_entry_for_an_undeclared_page_raises
    error = assert_raises(ArgumentError) do
      generate(prefill: [{ title: 'Ghost', dest: :ritual_ghost }])
    end

    assert_match(/ritual_ghost/, error.message)
  end

  def test_more_entries_than_fit_on_a_page_raises
    too_many = Array.new(51) { { title: 'x', dest: :ritual_daily } }

    assert_raises(ArgumentError) { generate(prefill: too_many) }
  end

  def test_entries_are_still_linked_without_a_resolver_but_show_no_page_number
    pdf = generate(link_resolver: nil)

    assert_equal 3, pdf.links(1).length
    refute_match(/\b1[01]\d\b/, pdf.text(1))
  end
end
