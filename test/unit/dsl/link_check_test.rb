#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestLinkCheck < Minitest::Test
  def setup
    @builder = BujoPdf::PdfDSL::PdfBuilder.new
  end

  def test_clean_build_has_no_warnings
    @builder.build(definition { blank_page :home }, year: 2026)

    assert_empty @builder.warnings.to_a
  end

  def test_link_to_missing_destination_warns_with_page_number
    @builder.build(definition {
      blank_page :home
      page(id: :notes) do
        body { link_box(2, 2, 6, 2, 'Nowhere', dest: 'nowhere') }
      end
    }, year: 2026)

    messages = @builder.warnings.map(&:message)
    assert_equal ['link to "nowhere" on page 2 has no matching destination'], messages
  end

  def test_tab_to_missing_destination_warns_once_per_page
    @builder.build(definition {
      chrome do
        right :tab_sidebar do
          tab 'Ghost', dest: :ghost
        end
      end
      page :reference, id: :reference
      page :reference, id: :reference_two
    }, year: 2026)

    unresolved = @builder.warnings.grep(BujoPdf::PdfDSL::Warnings::UnresolvedLink).map(&:message)
    assert_equal ['link to "ghost" on page 1 has no matching destination',
                  'link to "ghost" on page 2 has no matching destination'], unresolved
  end

  def test_outline_entry_to_missing_destination_warns
    @builder.build(definition {
      blank_page :home
      outline_entry :ghost, 'Ghost Page'
    }, year: 2026)

    messages = @builder.warnings.map(&:message)
    assert_equal ['outline entry "Ghost Page" points at "ghost", which no page declares'], messages
  end

  def test_duplicate_page_id_warns
    @builder.build(definition {
      blank_page :overview
      blank_page :overview
    }, year: 2026)

    messages = @builder.warnings.map(&:message)
    assert_includes messages, 'page id "overview" on page 2 is already used by page 1'
  end

  def test_duplicate_destination_warns
    @builder.build(definition {
      page :reference
      page :reference, id: :reference_again
    }, year: 2026)

    messages = @builder.warnings.map(&:message)
    assert_equal ['destination "reference" on page 2 is already defined on page 1'], messages
  end

  def test_strict_keyword_raises_with_every_warning
    error = assert_raises(BujoPdf::PdfDSL::WarningsError) do
      @builder.build(definition {
        blank_page :home
        outline_entry :ghost_one, 'One'
        outline_entry :ghost_two, 'Two'
      }, year: 2026, strict: true)
    end

    assert_equal 2, error.warnings.size
    assert_includes error.message, '"ghost_one"'
    assert_includes error.message, '"ghost_two"'
  end

  def test_strict_recipe_raises_and_writes_nothing
    output = 'tmp/test_link_check_strict.pdf'
    FileUtils.mkdir_p('tmp')
    FileUtils.rm_f(output)

    assert_raises(BujoPdf::PdfDSL::WarningsError) do
      @builder.build(definition {
        strict
        blank_page :home
        outline_entry :ghost, 'Ghost'
      }, year: 2026, output: output)
    end

    refute File.exist?(output)
  ensure
    FileUtils.rm_f(output)
  end

  def test_strict_false_keyword_overrides_strict_recipe
    pdf = @builder.build(definition {
      strict
      blank_page :home
      outline_entry :ghost, 'Ghost'
    }, year: 2026, strict: false)

    assert_kind_of Prawn::Document, pdf
    assert_equal 1, @builder.warnings.size
  end

  def test_strict_build_without_warnings_succeeds
    pdf = @builder.build(definition { blank_page :home }, year: 2026, strict: true)

    assert_kind_of Prawn::Document, pdf
  end

  private

  # Inline pages with an empty body draw no links, so only the link under
  # test can warn.
  def definition(&block)
    BujoPdf::PdfDSL::PdfDefinition.new(:link_check_test) do |year:|
      define_singleton_method(:blank_page) { |id| page(id: id) { body {} } }
      instance_eval(&block)
    end
  end
end
