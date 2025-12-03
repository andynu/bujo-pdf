#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestMultiYearOverview < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :multi_year,
      page_number: 1,
      year: 2025,
      total_weeks: 52,
      year_count: 4
    )
  end

  def test_page_has_registered_type
    assert_equal :multi_year, BujoPdf::Pages::MultiYearOverview.page_type
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.send(:setup)
  end

  def test_month_names_constant
    months = BujoPdf::Pages::MultiYearOverview::MONTH_NAMES
    assert_equal 12, months.length
    assert_equal 'Jan', months[0]
    assert_equal 'Dec', months[11]
  end

  def test_layout_constants
    assert_equal 4, BujoPdf::Pages::MultiYearOverview::MONTH_HEIGHT_BOXES
    assert_equal 3, BujoPdf::Pages::MultiYearOverview::MONTH_LABEL_WIDTH
    assert_equal 2, BujoPdf::Pages::MultiYearOverview::HEADER_HEIGHT
    assert_equal 0, BujoPdf::Pages::MultiYearOverview::HEADER_START_ROW
  end

  def test_highlight_tab_returns_multi_year
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.send(:setup)
    assert_equal :multi_year, page.send(:highlight_tab)
  end

  def test_render_calls_all_sections
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_header
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)
  end

  def test_draw_month_labels
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_month_labels)
  end

  def test_draw_year_columns
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_year_columns)
  end

  def test_draw_grid_lines
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_grid_lines)
  end

  def test_draw_cell
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    page.send(:setup)
    # Cell should be empty - intentionally blank for manual data entry
    page.send(:draw_cell, 2025, 1, 5, 10, 8, 4)
  end

  def test_with_different_year_counts
    [2, 3, 4, 5].each do |year_count|
      pdf = create_fast_test_pdf  # Use stub stamp for speed
      context = BujoPdf::RenderContext.new(
        page_key: :multi_year,
        page_number: 1,
        year: 2025,
        total_weeks: 52,
        year_count: year_count
      )
      page = BujoPdf::Pages::MultiYearOverview.new(pdf, context)
      page.generate
      assert_equal 1, pdf.page_count, "Year count #{year_count} should produce 1 page"
    end
  end

  def test_default_year_count_is_4
    context = BujoPdf::RenderContext.new(
      page_key: :multi_year,
      page_number: 1,
      year: 2025,
      total_weeks: 52
      # No year_count specified
    )
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, context)
    assert_equal 4, page.instance_variable_get(:@year_count)
  end

  def test_start_year_from_context
    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, @context)
    assert_equal 2025, page.instance_variable_get(:@start_year)
  end
end

class TestMultiYearOverviewMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::MultiYearOverview::Mixin

    attr_reader :pdf, :year, :date_config, :event_store, :total_pages

    def initialize
      @year = 2025
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @date_config = nil
      @event_store = nil
      @total_pages = 100
      @first_page_used = false
      DotGrid.create_stamp(@pdf, "page_dots")
    end
  end

  def test_mixin_provides_multi_year_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:multi_year_page), "Expected multi_year_page method"
  end

  def test_multi_year_page_generates_page
    builder = TestBuilder.new
    builder.multi_year_page

    assert_equal 1, builder.pdf.page_count
  end

  def test_multi_year_page_with_custom_year_count
    builder = TestBuilder.new
    builder.multi_year_page(year_count: 3)

    assert_equal 1, builder.pdf.page_count
  end
end

class TestMultiYearOverviewIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :multi_year,
      page_number: 1,
      year: 2025,
      total_weeks: 52,
      year_count: 4
    )

    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_page_uses_standard_layout
    context = BujoPdf::RenderContext.new(
      page_key: :multi_year,
      page_number: 1,
      year: 2025,
      total_weeks: 52,
      year_count: 4
    )

    page = BujoPdf::Pages::MultiYearOverview.new(@pdf, context)
    page.send(:setup)

    content_area = page.send(:content_area)
    assert_equal 2, content_area[:col]
    assert_equal 0, content_area[:row]
    assert_equal 40, content_area[:width_boxes]
    assert_equal 55, content_area[:height_boxes]
  end
end
