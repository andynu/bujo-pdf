#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'
require 'pdf/reader'
require 'stringio'

class TestPdfBuilderDebug < Minitest::Test
  Overlay = BujoPdf::Debug::Overlay

  def setup
    @builder = BujoPdf::PdfDSL::PdfBuilder.new
    @definition = BujoPdf::PdfDSL::PdfDefinition.new(:debug_test) do |year:|
      page :seasonal, id: :seasonal, year: year
      page id: :day do
        layout :daily_with_sidebars, year: year
        body do
          fieldset(2, 4, 38, 12, legend: 'Tasks')
        end
      end
    end
  end

  def test_debug_off_installs_nothing
    pdf = @builder.build(@definition, year: 2026)

    refute_respond_to pdf, :debug_overlay
  end

  def test_debug_false_matches_debug_omitted
    omitted = @builder.build(@definition, year: 2026).render
    off = @builder.build(@definition, year: 2026, debug: false).render

    assert_equal omitted, off
  end

  def test_debug_is_not_passed_to_the_definition
    pdf = @builder.build(@definition, year: 2026, debug: true)

    assert_equal 2, pdf.page_count
  end

  def test_debug_only_appends_to_each_page
    off = page_contents(@builder.build(@definition, year: 2026))
    on = page_contents(@builder.build(@definition, year: 2026, debug: true))

    off.zip(on).each do |page_off, page_on|
      assert page_on.start_with?(page_off.delete_suffix("Q\n")), 'debug changed content drawn before the overlay'
      assert_operator page_on.length, :>, page_off.length
    end
  end

  def test_debug_outlines_chrome_fieldsets_and_links
    pdf = @builder.build(@definition, year: 2026, debug: %i[chrome fieldset link])
    day = page_contents(pdf).last

    %i[chrome fieldset link].each do |kind|
      assert_includes day, "#{color_op(Overlay::COLORS[kind])} SCN", "no #{kind} outline"
    end
    refute_includes day, "#{color_op(Overlay::COLORS[:content])} SCN"
  end

  def test_unknown_debug_kind_raises
    assert_raises(ArgumentError) { @builder.build(@definition, year: 2026, debug: 'sparkles') }
  end

  def test_generate_from_recipe_passes_debug_through
    pdf = BujoPdf.generate_from_recipe(year: 2026, debug: true) do |year:|
      page :seasonal, year: year
    end

    assert_kind_of Overlay, BujoPdf::Debug.overlay(pdf)
  end

  def test_generate_passes_debug_to_the_standard_recipe
    received = nil
    BujoPdf.stub(:generate_from_recipe, ->(name, **params) { received = [name, params] }) do
      BujoPdf.generate(2026, output_path: 'x.pdf', debug: 'grid')
    end

    assert_equal [:standard_planner, { year: 2026, theme: nil, output: 'x.pdf', debug: 'grid' }], received
  end

  private

  # Prawn numbers transparency states per document, so the overlay's opacity
  # shifts the names later pages use for the same states.
  def page_contents(pdf)
    PDF::Reader.new(StringIO.new(pdf.render)).pages.map { |page| page.raw_content.gsub(%r{/Tr\d+ gs}, '/Tr gs') }
  end

  def color_op(hex)
    PDF::Core.real_params(hex.scan(/../).map { |c| c.to_i(16) / 255.0 })
  end
end
