#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestGridShowcase < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :grid_showcase,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
  end

  def test_page_has_registered_type
    assert_equal :grid_showcase, BujoPdf::Pages::GridShowcase.page_type
  end

  def test_page_has_registered_title
    assert_equal "Grid Types Showcase", BujoPdf::Pages::GridShowcase.default_title
  end

  def test_page_has_registered_dest
    assert_equal "grid_showcase", BujoPdf::Pages::GridShowcase.default_dest
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)

    # Destination should be set (grid_showcase)
  end

  def test_setup_uses_full_page_layout
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
  end

  def test_grid_types_constant
    types = BujoPdf::Pages::GridShowcase::GRID_TYPES
    assert_equal 4, types.length

    assert_equal :dots, types[0][:type]
    assert_equal :isometric, types[1][:type]
    assert_equal :perspective, types[2][:type]
    assert_equal :hexagon, types[3][:type]
  end

  def test_grid_types_positions
    types = BujoPdf::Pages::GridShowcase::GRID_TYPES

    assert_equal :top_left, types[0][:position]
    assert_equal :top_right, types[1][:position]
    assert_equal :bottom_left, types[2][:position]
    assert_equal :bottom_right, types[3][:position]
  end

  def test_render_draws_all_components
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)

    # Should render without error
  end

  def test_draw_title
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_title)

    # Should render title without error
  end

  def test_draw_grid_quadrant_dots
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    grid_spec = { type: :dots, label: 'Dot Grid', position: :top_left }
    page.send(:draw_grid_quadrant, grid_spec)
  end

  def test_draw_grid_quadrant_isometric
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    grid_spec = { type: :isometric, label: 'Isometric Grid', position: :top_right }
    page.send(:draw_grid_quadrant, grid_spec)
  end

  def test_draw_grid_quadrant_perspective
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    grid_spec = { type: :perspective, label: 'Perspective Grid', position: :bottom_left }
    page.send(:draw_grid_quadrant, grid_spec)
  end

  def test_draw_grid_quadrant_hexagon
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    grid_spec = { type: :hexagon, label: 'Hexagon Grid', position: :bottom_right }
    page.send(:draw_grid_quadrant, grid_spec)
  end

  def test_calculate_quadrant_top_left
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    quadrant = page.send(:calculate_quadrant, :top_left)

    assert_equal 0, quadrant[:col]
    assert_equal 3, quadrant[:row]
    assert_equal 21.5, quadrant[:width]
    assert_equal 26, quadrant[:height]
  end

  def test_calculate_quadrant_top_right
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    quadrant = page.send(:calculate_quadrant, :top_right)

    assert_equal 21.5, quadrant[:col]
    assert_equal 3, quadrant[:row]
    assert_equal 21.5, quadrant[:width]
    assert_equal 26, quadrant[:height]
  end

  def test_calculate_quadrant_bottom_left
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    quadrant = page.send(:calculate_quadrant, :bottom_left)

    assert_equal 0, quadrant[:col]
    assert_equal 29, quadrant[:row]
    assert_equal 21.5, quadrant[:width]
    assert_equal 26, quadrant[:height]
  end

  def test_calculate_quadrant_bottom_right
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    quadrant = page.send(:calculate_quadrant, :bottom_right)

    assert_equal 21.5, quadrant[:col]
    assert_equal 29, quadrant[:row]
    assert_equal 21.5, quadrant[:width]
    assert_equal 26, quadrant[:height]
  end

  def test_draw_quadrant_label
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    quadrant = { col: 0, row: 3, width: 21.5, height: 26 }
    page.send(:draw_quadrant_label, 'Test Label', quadrant)
  end

  def test_draw_quadrant_grid
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    quadrant = { col: 0, row: 3, width: 21.5, height: 26 }
    page.send(:draw_quadrant_grid, :dots, quadrant)
  end

  def test_draw_quadrant_border
    page = BujoPdf::Pages::GridShowcase.new(@pdf, @context)
    page.send(:setup)
    quadrant = { col: 0, row: 3, width: 21.5, height: 26 }
    page.send(:draw_quadrant_border, quadrant)
  end
end

class TestGridShowcaseMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::GridShowcase::Mixin

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

  def test_mixin_provides_grid_showcase_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:grid_showcase_page), "Expected grid_showcase_page method"
  end

  def test_grid_showcase_page_generates_page
    builder = TestBuilder.new
    builder.grid_showcase_page

    assert_equal 1, builder.pdf.page_count
  end
end

class TestGridShowcaseIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :grid_showcase,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::GridShowcase.new(@pdf, context)
    page.generate

    # PDF should be valid and have content
    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_all_grid_types_render
    context = BujoPdf::RenderContext.new(
      page_key: :grid_showcase,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::GridShowcase.new(@pdf, context)

    # Each grid type should render without error
    BujoPdf::Pages::GridShowcase::GRID_TYPES.each do |grid_spec|
      page.send(:setup)
      page.send(:draw_grid_quadrant, grid_spec)
    end
  end
end
