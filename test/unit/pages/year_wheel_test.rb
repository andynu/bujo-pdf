#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestYearWheel < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :year_wheel,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
  end

  def test_page_has_registered_type
    assert_equal :year_wheel, BujoPdf::Pages::YearWheel.page_type
  end

  def test_page_has_registered_title
    assert_equal "Year Wheel", BujoPdf::Pages::YearWheel.default_title
  end

  def test_page_has_registered_dest
    assert_equal "year_wheel", BujoPdf::Pages::YearWheel.default_dest
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)

    # Destination should be set (year_wheel)
    # Can't easily verify without PDF introspection
  end

  def test_setup_uses_full_page_layout
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
  end

  def test_render_draws_wheel
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)

    # Should render without error
  end

  def test_constants_are_defined
    assert_equal 365, BujoPdf::Pages::YearWheel::NUM_DAYS
    assert_equal 12, BujoPdf::Pages::YearWheel::MONTH_LABELS.length
    assert_equal 12, BujoPdf::Pages::YearWheel::MONTH_START_DAYS.length
    assert_equal 182, BujoPdf::Pages::YearWheel::TOP_OFFSET_DAYS
    assert_equal 6, BujoPdf::Pages::YearWheel::PROPORTIONS.length
  end

  def test_month_labels
    labels = BujoPdf::Pages::YearWheel::MONTH_LABELS
    assert_equal "Jan", labels[0]
    assert_equal "Dec", labels[11]
  end

  def test_month_start_days
    days = BujoPdf::Pages::YearWheel::MONTH_START_DAYS
    assert_equal 0, days[0]    # January starts at day 0
    assert_equal 31, days[1]   # February starts at day 31
    assert_equal 59, days[2]   # March starts at day 59 (31+28)
    assert_equal 334, days[11] # December starts at day 334
  end

  def test_draw_circles
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    page.send(:draw_circles, radii)

    # Should draw circles without error
  end

  def test_draw_divisions
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    page.send(:draw_divisions, radii)

    # Should draw divisions without error
  end

  def test_draw_month_markers
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    scale = 1.0
    page.send(:draw_month_markers, radii, scale)

    # Should draw month markers without error
  end

  def test_draw_week_markers
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    page.send(:draw_week_markers, radii)

    # Should draw week markers without error
  end

  def test_draw_weekend_backgrounds
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    page.send(:draw_weekend_backgrounds, radii)

    # Should draw weekend backgrounds without error
  end

  def test_draw_arc_segment
    page = BujoPdf::Pages::YearWheel.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_arc_segment, 100, 120, 0, Math::PI / 2)

    # Should draw arc segment without error
  end

  def test_with_different_year
    context_2024 = BujoPdf::RenderContext.new(
      page_key: :year_wheel,
      page_number: 1,
      year: 2024,
      total_weeks: 52
    )

    page = BujoPdf::Pages::YearWheel.new(@pdf, context_2024)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_with_leap_year
    # 2024 is a leap year (366 days)
    context_leap = BujoPdf::RenderContext.new(
      page_key: :year_wheel,
      page_number: 1,
      year: 2024,
      total_weeks: 52
    )

    page = BujoPdf::Pages::YearWheel.new(@pdf, context_leap)
    page.generate

    # Should generate without error even for leap year
    assert_equal 1, @pdf.page_count
  end
end

class TestYearWheelMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::YearWheel::Mixin

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

  def test_mixin_provides_year_wheel_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:year_wheel_page), "Expected year_wheel_page method"
  end

  def test_year_wheel_page_generates_page
    builder = TestBuilder.new
    builder.year_wheel_page

    assert_equal 1, builder.pdf.page_count
  end
end

class TestYearWheelIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :year_wheel,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::YearWheel.new(@pdf, context)
    page.generate

    # PDF should be valid and have content
    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_wheel_is_centered
    context = BujoPdf::RenderContext.new(
      page_key: :year_wheel,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::YearWheel.new(@pdf, context)
    page.generate

    # The wheel center should be at page center
    # Page dimensions: 612 x 792 (letter size)
    # Center: 306, 396
    # Hard to verify without PDF introspection, but generation should succeed
  end

  def test_proportions_are_ordered
    proportions = BujoPdf::Pages::YearWheel::PROPORTIONS
    # Each proportion should be greater than the previous (circles expand outward)
    (0...proportions.length - 1).each do |i|
      assert proportions[i] < proportions[i + 1],
             "Expected proportions to increase: #{proportions[i]} < #{proportions[i + 1]}"
    end
  end
end
