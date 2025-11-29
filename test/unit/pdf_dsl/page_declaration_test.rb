#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestPageDeclaration < Minitest::Test
  def test_basic_creation
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:seasonal_calendar, year: 2025)

    assert_equal :seasonal_calendar, decl.type
    assert_equal({ year: 2025 }, decl.params)
  end

  def test_explicit_id
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:dot_grid, id: :notes_page)

    assert_equal :notes_page, decl.id
    assert_equal 'notes_page', decl.destination_key
  end

  def test_destination_key_without_params
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:reference)

    assert_equal 'reference', decl.destination_key
  end

  def test_destination_key_with_params
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: 12, year: 2025)

    key = decl.destination_key
    assert_includes key, 'weekly'
    assert_includes key, 'week_num_12'
    assert_includes key, 'year_2025'
  end

  def test_destination_key_with_date_param
    date = Date.new(2025, 6, 15)
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:daily, date: date)

    key = decl.destination_key
    assert_includes key, '20250615'
  end

  def test_matches_type_only
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:reference)

    assert decl.matches?(:reference)
    refute decl.matches?(:weekly)
  end

  def test_matches_with_params
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: 12, year: 2025)

    assert decl.matches?(:weekly, week_num: 12)
    assert decl.matches?(:weekly, year: 2025)
    assert decl.matches?(:weekly, week_num: 12, year: 2025)
    refute decl.matches?(:weekly, week_num: 13)
  end
end

class TestGroupDeclaration < Minitest::Test
  def test_basic_creation
    group = BujoPdf::PdfDSL::GroupDeclaration.new(:grids, cycle: true)

    assert_equal :grids, group.name
    assert group.cycle?
  end

  def test_add_pages
    group = BujoPdf::PdfDSL::GroupDeclaration.new(:grids)
    page1 = BujoPdf::PdfDSL::PageDeclaration.new(:grid_dot)
    page2 = BujoPdf::PdfDSL::PageDeclaration.new(:grid_graph)

    group.add_page(page1)
    group.add_page(page2)

    assert_equal 2, group.pages.length
    assert_includes group.pages, page1
    assert_includes group.pages, page2
  end

  def test_destination_keys
    group = BujoPdf::PdfDSL::GroupDeclaration.new(:grids)
    group.add_page(BujoPdf::PdfDSL::PageDeclaration.new(:grid_dot))
    group.add_page(BujoPdf::PdfDSL::PageDeclaration.new(:grid_graph))

    keys = group.destination_keys

    assert_equal 2, keys.length
    assert_includes keys, 'grid_dot'
    assert_includes keys, 'grid_graph'
  end
end
