# frozen_string_literal: true

require_relative '../../../test_helper'

class TestGraphGridPage < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :grid_graph,
      page_number: 1,
      year: 2025
    )
  end

  def test_page_has_registered_type
    assert_equal :grid_graph, BujoPdf::Pages::Grids::GraphGridPage.page_type
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::Grids::GraphGridPage.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::Grids::GraphGridPage.new(@pdf, @context)
    page.send(:setup)
  end

  def test_uses_full_page_layout
    page = BujoPdf::Pages::Grids::GraphGridPage.new(@pdf, @context)
    page.send(:setup)

    assert page.instance_variable_get(:@layout)
  end

  def test_render_calls_all_sections
    page = BujoPdf::Pages::Grids::GraphGridPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_title
    page = BujoPdf::Pages::Grids::GraphGridPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_title)
  end

  def test_draw_graph_grid
    page = BujoPdf::Pages::Grids::GraphGridPage.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_graph_grid)
  end
end

class TestGraphGridPageMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::Grids::GraphGridPage::Mixin

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

  def test_mixin_provides_graph_grid_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:graph_grid_page), "Expected graph_grid_page method"
  end

  def test_graph_grid_page_generates_page
    builder = TestBuilder.new
    builder.graph_grid_page

    assert_equal 1, builder.pdf.page_count
  end
end

class TestGraphGridPageIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :grid_graph,
      page_number: 1,
      year: 2025
    )

    page = BujoPdf::Pages::Grids::GraphGridPage.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end
end
