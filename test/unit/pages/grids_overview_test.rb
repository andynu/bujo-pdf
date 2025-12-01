# frozen_string_literal: true

require_relative '../../test_helper'

class TestGridsOverview < Minitest::Test
  include Styling::Grid

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :grids_overview,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
  end

  # ============================================
  # Registration Tests
  # ============================================

  def test_page_has_registered_type
    assert_equal :grids_overview, BujoPdf::Pages::GridsOverview.page_type
  end

  def test_page_has_registered_title
    assert_equal "Grids Overview", BujoPdf::Pages::GridsOverview.default_title
  end

  def test_page_has_registered_dest
    assert_equal "grids_overview", BujoPdf::Pages::GridsOverview.default_dest
  end

  # ============================================
  # GRID_SAMPLES Constant Tests
  # ============================================

  def test_grid_samples_constant_exists
    assert_equal 3, BujoPdf::Pages::GridsOverview::GRID_SAMPLES.size
  end

  def test_grid_samples_includes_dot_grid
    sample = BujoPdf::Pages::GridsOverview::GRID_SAMPLES.find { |s| s[:dest] == 'grid_dot' }
    assert sample
    assert_equal 'Dot Grid', sample[:label]
    assert sample[:description]
  end

  def test_grid_samples_includes_graph_grid
    sample = BujoPdf::Pages::GridsOverview::GRID_SAMPLES.find { |s| s[:dest] == 'grid_graph' }
    assert sample
    assert_equal 'Graph Grid', sample[:label]
    assert sample[:description]
  end

  def test_grid_samples_includes_lined_grid
    sample = BujoPdf::Pages::GridsOverview::GRID_SAMPLES.find { |s| s[:dest] == 'grid_lined' }
    assert sample
    assert_equal 'Ruled Lines', sample[:label]
    assert sample[:description]
  end

  # ============================================
  # Setup Tests
  # ============================================

  def test_setup_sets_destination
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)

    dest_called = nil
    page.define_singleton_method(:set_destination) { |name| dest_called = name }

    page.send(:setup)

    assert_equal 'grids_overview', dest_called
  end

  def test_setup_uses_standard_with_sidebars_layout
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_calls_draw_title
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    title_called = false
    page.define_singleton_method(:draw_title) { title_called = true }
    page.define_singleton_method(:draw_grid_samples) {}

    page.send(:render)

    assert title_called
  end

  def test_render_calls_draw_grid_samples
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    samples_called = false
    page.define_singleton_method(:draw_title) {}
    page.define_singleton_method(:draw_grid_samples) { samples_called = true }

    page.send(:render)

    assert samples_called
  end

  # ============================================
  # Private Method Tests
  # ============================================

  def test_draw_title
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_title)

    # Should render without error
  end

  def test_draw_grid_samples
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_grid_samples)

    # Should render 3 sample boxes without error
  end

  def test_draw_sample_box
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    sample = { label: 'Test Grid', dest: 'grid_dot', description: 'Test description' }
    page.send(:draw_sample_box, sample, 5, 15)

    # Should render without error
  end

  def test_draw_grid_preview_dot
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    box = { x: 100, y: 700, width: 200, height: 100 }
    page.send(:draw_grid_preview, 'grid_dot', box)

    # Should render dot preview without error
  end

  def test_draw_grid_preview_graph
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    box = { x: 100, y: 700, width: 200, height: 100 }
    page.send(:draw_grid_preview, 'grid_graph', box)

    # Should render graph preview without error
  end

  def test_draw_grid_preview_lined
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    box = { x: 100, y: 700, width: 200, height: 100 }
    page.send(:draw_grid_preview, 'grid_lined', box)

    # Should render lined preview without error
  end

  def test_draw_grid_preview_unknown_type
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    box = { x: 100, y: 700, width: 200, height: 100 }
    # Should not error on unknown type - just doesn't draw anything
    page.send(:draw_grid_preview, 'unknown_grid', box)
  end

  def test_draw_dot_preview
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_dot_preview, 100, 700, 200, 100)

    # Should render dot pattern without error
  end

  def test_draw_graph_preview
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_graph_preview, 100, 700, 200, 100)

    # Should render graph pattern without error
  end

  def test_draw_lined_preview
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_lined_preview, 100, 700, 200, 100)

    # Should render lined pattern without error
  end

  def test_content_area_rect
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.send(:setup)

    rect = page.send(:content_area_rect, 0, 0, 10, 5)

    # GridRect or Hash-like object
    assert rect.respond_to?(:[])
    assert rect[:width] > 0
    assert rect[:height] > 0
  end

  # ============================================
  # Full Generation Tests
  # ============================================

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::GridsOverview.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end
end

class TestGridsOverviewMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::GridsOverview::Mixin

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

  def test_mixin_provides_grids_overview_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:grids_overview_page), "Expected grids_overview_page method"
  end

  def test_grids_overview_page_generates_page
    builder = TestBuilder.new
    builder.grids_overview_page

    assert_equal 1, builder.pdf.page_count
  end
end

class TestGridsOverviewIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :grids_overview,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::GridsOverview.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end
end
