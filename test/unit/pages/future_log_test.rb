#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestFutureLog < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :future_log_1,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      future_log_page: 1,
      future_log_page_count: 2,
      future_log_start_month: 1
    )
  end

  def test_page_has_registered_type
    assert_equal :future_log, BujoPdf::Pages::FutureLog.page_type
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
  end

  def test_layout_constants
    assert_equal 6, BujoPdf::Pages::FutureLog::MONTHS_PER_PAGE
    assert_equal 1, BujoPdf::Pages::FutureLog::COLUMN_GAP
    assert_equal 1, BujoPdf::Pages::FutureLog::ENTRY_COLUMN_GAP
    assert_equal 1, BujoPdf::Pages::FutureLog::HEADER_ROW
    assert_equal 4, BujoPdf::Pages::FutureLog::CONTENT_START_ROW
    assert_equal 3, BujoPdf::Pages::FutureLog::MONTHS_PER_COLUMN
  end

  def test_render_calls_all_sections
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_header
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)
  end

  def test_draw_two_column_layout
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_two_column_layout)
  end

  def test_draw_month_section
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_month_section, 1, 5, 10, 20, 15)
  end

  def test_draw_month_header
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_month_header, 1, 5, 10, 20)
  end

  def test_draw_entry_lines
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_entry_lines, 5, 12, 18, 10)
  end

  def test_content_col
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    assert_equal 2, page.send(:content_col)
  end

  def test_content_row
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    assert_equal 0, page.send(:content_row)
  end

  def test_content_width
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    assert_equal 40, page.send(:content_width)
  end

  def test_first_page_shows_months_1_to_6
    page = BujoPdf::Pages::FutureLog.new(@pdf, @context)
    page.send(:setup)
    assert_equal 1, page.instance_variable_get(:@start_month)
  end

  def test_second_page_shows_months_7_to_12
    context = BujoPdf::RenderContext.new(
      page_key: :future_log_2,
      page_number: 2,
      year: 2025,
      total_weeks: 53,
      future_log_page: 2,
      future_log_page_count: 2,
      future_log_start_month: 7
    )
    page = BujoPdf::Pages::FutureLog.new(@pdf, context)
    page.send(:setup)
    assert_equal 7, page.instance_variable_get(:@start_month)
  end

  def test_defaults_without_explicit_context_values
    context = BujoPdf::RenderContext.new(
      page_key: :future_log_1,
      page_number: 1,
      year: 2025
    )
    page = BujoPdf::Pages::FutureLog.new(@pdf, context)
    page.send(:setup)

    assert_equal 1, page.instance_variable_get(:@future_log_page)
    assert_equal 2, page.instance_variable_get(:@future_log_page_count)
    assert_equal 53, page.instance_variable_get(:@total_weeks)
  end
end

class TestFutureLogWithPageSetContext < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_uses_page_set_context_when_available
    # Create a page set context (not null context)
    set_context = BujoPdf::PageSetContext::Context.new(
      page: 2,
      total: 2,
      label: "Future Log 2 of 2"
    )

    context = BujoPdf::RenderContext.new(
      page_key: :future_log_2,
      page_number: 2,
      year: 2025,
      total_weeks: 53,
      future_log_start_month: 7
    )
    context.set = set_context

    page = BujoPdf::Pages::FutureLog.new(@pdf, context)
    page.send(:setup)

    assert_equal 2, page.instance_variable_get(:@future_log_page)
    assert_equal 2, page.instance_variable_get(:@future_log_page_count)
  end
end

class TestFutureLogMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::FutureLog::Mixin

    attr_reader :pdf, :year, :date_config, :event_store, :total_pages

    def initialize
      @year = 2025
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @date_config = nil
      @event_store = nil
      @total_pages = 100
      @first_page_used = false
      @current_page_set_index = 0
      DotGrid.create_stamp(@pdf, "page_dots")
    end
  end

  def test_mixin_provides_future_log_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:future_log_page), "Expected future_log_page method"
  end

  def test_mixin_provides_future_log_pages_method
    builder = TestBuilder.new
    assert builder.respond_to?(:future_log_pages), "Expected future_log_pages method"
  end

  def test_future_log_page_generates_page
    builder = TestBuilder.new
    builder.future_log_page(num: 1)

    assert_equal 1, builder.pdf.page_count
  end

  def test_future_log_page_with_total
    builder = TestBuilder.new
    builder.future_log_page(num: 1, total: 3)

    assert_equal 1, builder.pdf.page_count
  end

  def test_future_log_pages_generates_default_2_pages
    builder = TestBuilder.new
    builder.future_log_pages

    assert_equal 2, builder.pdf.page_count
  end

  def test_future_log_pages_with_custom_count
    builder = TestBuilder.new
    # Note: count must be <= 2 as there are only 12 months (6 per page)
    builder.future_log_pages(count: 2)

    assert_equal 2, builder.pdf.page_count
  end
end

class TestFutureLogIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_1_generation
    context = BujoPdf::RenderContext.new(
      page_key: :future_log_1,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      future_log_page: 1,
      future_log_page_count: 2,
      future_log_start_month: 1
    )

    page = BujoPdf::Pages::FutureLog.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_full_page_2_generation
    context = BujoPdf::RenderContext.new(
      page_key: :future_log_2,
      page_number: 2,
      year: 2025,
      total_weeks: 53,
      future_log_page: 2,
      future_log_page_count: 2,
      future_log_start_month: 7
    )

    page = BujoPdf::Pages::FutureLog.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_both_pages_generate_correctly
    [1, 2].each do |page_num|
      pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      DotGrid.create_stamp(pdf, "page_dots")
      start_month = (page_num - 1) * 6 + 1
      context = BujoPdf::RenderContext.new(
        page_key: :"future_log_#{page_num}",
        page_number: page_num,
        year: 2025,
        total_weeks: 53,
        future_log_page: page_num,
        future_log_page_count: 2,
        future_log_start_month: start_month
      )
      page = BujoPdf::Pages::FutureLog.new(pdf, context)
      page.generate
      assert_equal 1, pdf.page_count, "Future log page #{page_num} should produce 1 page"
    end
  end
end
