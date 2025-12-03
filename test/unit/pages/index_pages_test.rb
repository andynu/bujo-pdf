# frozen_string_literal: true

require_relative '../../test_helper'

class TestIndexPage < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :index_1,
      page_number: 1,
      year: 2025,
      index_page_num: 1,
      index_page_count: 2
    )
  end

  def test_page_has_registered_type
    assert_equal :index, BujoPdf::Pages::IndexPage.page_type
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::IndexPage.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::IndexPage.new(@pdf, @context)
    page.send(:setup)
  end

  def test_layout_constants
    assert_equal 2, BujoPdf::Pages::IndexPage::LEFT_MARGIN
    assert_equal 41, BujoPdf::Pages::IndexPage::RIGHT_MARGIN
    assert_equal 1, BujoPdf::Pages::IndexPage::COLUMN_GAP
    assert_equal 1, BujoPdf::Pages::IndexPage::HEADER_ROW
    assert_equal 4, BujoPdf::Pages::IndexPage::CONTENT_START_ROW
    assert_equal 25, BujoPdf::Pages::IndexPage::LINES_PER_COLUMN
    assert_equal 50, BujoPdf::Pages::IndexPage::ENTRIES_PER_PAGE
  end

  def test_render_calls_all_sections
    page = BujoPdf::Pages::IndexPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_header
    page = BujoPdf::Pages::IndexPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)
  end

  def test_draw_two_column_layout
    page = BujoPdf::Pages::IndexPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_two_column_layout)
  end

  def test_draw_column_divider
    page = BujoPdf::Pages::IndexPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_column_divider)
  end

  def test_content_width
    page = BujoPdf::Pages::IndexPage.new(@pdf, @context)
    page.send(:setup)
    assert_equal 39, page.send(:content_width)
  end

  def test_first_page_starts_at_entry_1
    page = BujoPdf::Pages::IndexPage.new(@pdf, @context)
    page.send(:setup)
    assert_equal 1, page.instance_variable_get(:@index_page_num)
  end

  def test_second_page_starts_at_entry_51
    context = BujoPdf::RenderContext.new(
      page_key: :index_2,
      page_number: 2,
      year: 2025,
      index_page_num: 2,
      index_page_count: 2
    )
    page = BujoPdf::Pages::IndexPage.new(@pdf, context)
    page.send(:setup)
    assert_equal 2, page.instance_variable_get(:@index_page_num)
  end

  def test_defaults_without_explicit_context_values
    context = BujoPdf::RenderContext.new(
      page_key: :index_1,
      page_number: 1,
      year: 2025
    )
    page = BujoPdf::Pages::IndexPage.new(@pdf, context)
    page.send(:setup)

    assert_equal 1, page.instance_variable_get(:@index_page_num)
    assert_equal 2, page.instance_variable_get(:@index_page_count)
  end
end

class TestIndexPageWithPageSetContext < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_uses_page_set_context_when_available
    set_context = BujoPdf::PageSetContext::Context.new(
      page: 2,
      total: 3,
      label: "Index 2 of 3"
    )

    context = BujoPdf::RenderContext.new(
      page_key: :index_2,
      page_number: 2,
      year: 2025
    )
    context.set = set_context

    page = BujoPdf::Pages::IndexPage.new(@pdf, context)
    page.send(:setup)

    assert_equal 2, page.instance_variable_get(:@index_page_num)
    assert_equal 3, page.instance_variable_get(:@index_page_count)
  end
end

class TestIndexPageMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::IndexPage::Mixin

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

  def test_mixin_provides_index_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:index_page), "Expected index_page method"
  end

  def test_mixin_provides_index_pages_method
    builder = TestBuilder.new
    assert builder.respond_to?(:index_pages), "Expected index_pages method"
  end

  def test_index_page_generates_page
    builder = TestBuilder.new
    builder.index_page(num: 1)

    assert_equal 1, builder.pdf.page_count
  end

  def test_index_page_with_total
    builder = TestBuilder.new
    builder.index_page(num: 1, total: 4)

    assert_equal 1, builder.pdf.page_count
  end

  def test_index_pages_generates_default_2_pages
    builder = TestBuilder.new
    builder.index_pages

    assert_equal 2, builder.pdf.page_count
  end

  def test_index_pages_with_custom_count
    builder = TestBuilder.new
    builder.index_pages(count: 3)

    assert_equal 3, builder.pdf.page_count
  end
end

class TestIndexPageIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_1_generation
    context = BujoPdf::RenderContext.new(
      page_key: :index_1,
      page_number: 1,
      year: 2025,
      index_page_num: 1,
      index_page_count: 2
    )

    page = BujoPdf::Pages::IndexPage.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_full_page_2_generation
    context = BujoPdf::RenderContext.new(
      page_key: :index_2,
      page_number: 2,
      year: 2025,
      index_page_num: 2,
      index_page_count: 2
    )

    page = BujoPdf::Pages::IndexPage.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_both_pages_generate_correctly
    [1, 2].each do |page_num|
      pdf = create_fast_test_pdf  # Use stub stamp for speed
      context = BujoPdf::RenderContext.new(
        page_key: :"index_#{page_num}",
        page_number: page_num,
        year: 2025,
        index_page_num: page_num,
        index_page_count: 2
      )
      page = BujoPdf::Pages::IndexPage.new(pdf, context)
      page.generate
      assert_equal 1, pdf.page_count, "Index page #{page_num} should produce 1 page"
    end
  end
end
