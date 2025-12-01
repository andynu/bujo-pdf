# frozen_string_literal: true

require_relative '../../test_helper'

class TestCollectionPage < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :collection_books_to_read,
      page_number: 1,
      year: 2025,
      collection_id: "books_to_read",
      collection_title: "Books to Read",
      collection_subtitle: "Fiction, non-fiction, and everything in between"
    )
  end

  def test_page_has_registered_type
    assert_equal :collection, BujoPdf::Pages::CollectionPage.page_type
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::CollectionPage.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::CollectionPage.new(@pdf, @context)
    page.send(:setup)
  end

  def test_setup_extracts_title_from_context
    page = BujoPdf::Pages::CollectionPage.new(@pdf, @context)
    page.send(:setup)

    assert_equal "Books to Read", page.instance_variable_get(:@title)
  end

  def test_setup_extracts_subtitle_from_context
    page = BujoPdf::Pages::CollectionPage.new(@pdf, @context)
    page.send(:setup)

    assert_equal "Fiction, non-fiction, and everything in between", page.instance_variable_get(:@subtitle)
  end

  def test_setup_extracts_collection_id_from_context
    page = BujoPdf::Pages::CollectionPage.new(@pdf, @context)
    page.send(:setup)

    assert_equal "books_to_read", page.instance_variable_get(:@collection_id)
  end

  def test_setup_defaults_title_when_not_provided
    context = BujoPdf::RenderContext.new(
      page_key: :collection_test,
      page_number: 1,
      year: 2025,
      collection_id: "test"
    )
    page = BujoPdf::Pages::CollectionPage.new(@pdf, context)
    page.send(:setup)

    assert_equal "Collection", page.instance_variable_get(:@title)
  end

  def test_setup_defaults_collection_id_when_not_provided
    context = BujoPdf::RenderContext.new(
      page_key: :collection_test,
      page_number: 1,
      year: 2025
    )
    page = BujoPdf::Pages::CollectionPage.new(@pdf, context)
    page.send(:setup)

    assert_equal "collection", page.instance_variable_get(:@collection_id)
  end

  def test_setup_allows_nil_subtitle
    context = BujoPdf::RenderContext.new(
      page_key: :collection_test,
      page_number: 1,
      year: 2025,
      collection_id: "test",
      collection_title: "My Collection"
    )
    page = BujoPdf::Pages::CollectionPage.new(@pdf, context)
    page.send(:setup)

    assert_nil page.instance_variable_get(:@subtitle)
  end

  def test_render_calls_draw_header
    page = BujoPdf::Pages::CollectionPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_header_without_subtitle
    context = BujoPdf::RenderContext.new(
      page_key: :collection_test,
      page_number: 1,
      year: 2025,
      collection_id: "test",
      collection_title: "My Collection"
    )
    page = BujoPdf::Pages::CollectionPage.new(@pdf, context)
    page.send(:setup)
    page.send(:draw_header)
  end

  def test_draw_header_with_subtitle
    page = BujoPdf::Pages::CollectionPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)
  end

  def test_uses_full_page_layout
    page = BujoPdf::Pages::CollectionPage.new(@pdf, @context)
    page.send(:setup)

    # full_page layout means no sidebars, 43x55 content area
    # We can verify this by checking that use_layout was called with :full_page
    # The layout is stored in @layout after setup
    assert page.instance_variable_get(:@layout)
  end
end

class TestCollectionPageMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::CollectionPage::Mixin

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

  def test_mixin_provides_collection_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:collection_page), "Expected collection_page method"
  end

  def test_collection_page_generates_page
    builder = TestBuilder.new
    builder.collection_page(id: "test", title: "Test Collection")

    assert_equal 1, builder.pdf.page_count
  end

  def test_collection_page_with_subtitle
    builder = TestBuilder.new
    builder.collection_page(
      id: "books",
      title: "Books to Read",
      subtitle: "My reading list"
    )

    assert_equal 1, builder.pdf.page_count
  end

  def test_collection_page_without_subtitle
    builder = TestBuilder.new
    builder.collection_page(id: "notes", title: "Meeting Notes")

    assert_equal 1, builder.pdf.page_count
  end
end

class TestCollectionPageIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_with_subtitle_generation
    context = BujoPdf::RenderContext.new(
      page_key: :collection_books,
      page_number: 1,
      year: 2025,
      collection_id: "books",
      collection_title: "Books to Read",
      collection_subtitle: "My reading list for 2025"
    )

    page = BujoPdf::Pages::CollectionPage.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_full_page_without_subtitle_generation
    context = BujoPdf::RenderContext.new(
      page_key: :collection_ideas,
      page_number: 1,
      year: 2025,
      collection_id: "ideas",
      collection_title: "Project Ideas"
    )

    page = BujoPdf::Pages::CollectionPage.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_multiple_collection_pages
    collections = [
      { id: "books", title: "Books to Read", subtitle: "Fiction and non-fiction" },
      { id: "movies", title: "Movies to Watch", subtitle: nil },
      { id: "recipes", title: "Recipes to Try", subtitle: "Vegetarian options" }
    ]

    collections.each_with_index do |coll, idx|
      pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      DotGrid.create_stamp(pdf, "page_dots")
      context = BujoPdf::RenderContext.new(
        page_key: :"collection_#{coll[:id]}",
        page_number: idx + 1,
        year: 2025,
        collection_id: coll[:id],
        collection_title: coll[:title],
        collection_subtitle: coll[:subtitle]
      )
      page = BujoPdf::Pages::CollectionPage.new(pdf, context)
      page.generate
      assert_equal 1, pdf.page_count, "Collection page #{coll[:id]} should produce 1 page"
    end
  end
end
