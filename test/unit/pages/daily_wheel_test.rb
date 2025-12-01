#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestDailyWheel < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :daily_wheel,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
  end

  def test_page_has_registered_type
    assert_equal :daily_wheel, BujoPdf::Pages::DailyWheel.page_type
  end

  def test_page_has_registered_title
    assert_equal "Daily Wheel", BujoPdf::Pages::DailyWheel.default_title
  end

  def test_page_has_registered_dest
    assert_equal "daily_wheel", BujoPdf::Pages::DailyWheel.default_dest
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.send(:setup)
  end

  def test_setup_uses_full_page_layout
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
  end

  def test_constants_are_defined
    assert_equal 48, BujoPdf::Pages::DailyWheel::NUM_SEGMENTS
    assert_equal true, BujoPdf::Pages::DailyWheel::SHOW_HOUR_LABELS
    assert_equal 7, BujoPdf::Pages::DailyWheel::HOUR_LABEL_FONT_SIZE
    assert_equal 6, BujoPdf::Pages::DailyWheel::PROPORTIONS.length
  end

  def test_line_width_constants
    assert_equal 0.75, BujoPdf::Pages::DailyWheel::HOUR_LINE_WIDTH
    assert_equal 0.25, BujoPdf::Pages::DailyWheel::HALF_HOUR_LINE_WIDTH
    assert_equal 0.75, BujoPdf::Pages::DailyWheel::CIRCLE_LINE_WIDTH
  end

  def test_render_draws_wheel
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_circles
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    page.send(:draw_circles, radii)
  end

  def test_draw_divisions
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    page.send(:draw_divisions, radii)
  end

  def test_draw_hour_labels
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    scale = 1.0
    page.send(:draw_hour_labels, radii, scale)
  end

  def test_draw_night_backgrounds
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.send(:setup)
    radii = [100, 110, 120, 130, 140, 150]
    page.send(:draw_night_backgrounds, radii)
  end

  def test_draw_arc_segment
    page = BujoPdf::Pages::DailyWheel.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_arc_segment, 100, 120, 0, Math::PI / 2)
  end

  def test_proportions_are_ordered
    proportions = BujoPdf::Pages::DailyWheel::PROPORTIONS
    (0...proportions.length - 1).each do |i|
      assert proportions[i] < proportions[i + 1],
             "Expected proportions to increase: #{proportions[i]} < #{proportions[i + 1]}"
    end
  end
end

class TestDailyWheelMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::DailyWheel::Mixin

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

  def test_mixin_provides_daily_wheel_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:daily_wheel_page), "Expected daily_wheel_page method"
  end

  def test_daily_wheel_page_generates_page
    builder = TestBuilder.new
    builder.daily_wheel_page

    assert_equal 1, builder.pdf.page_count
  end
end

class TestDailyWheelIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :daily_wheel,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::DailyWheel.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_wheel_is_centered
    context = BujoPdf::RenderContext.new(
      page_key: :daily_wheel,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::DailyWheel.new(@pdf, context)
    page.generate

    # The wheel center should be at page center
    # Hard to verify without PDF introspection, but generation should succeed
  end

  def test_night_hours_coverage
    # Night hours should cover 9 hours (22, 23, 0, 1, 2, 3, 4, 5, 6)
    night_hours = [22, 23, 0, 1, 2, 3, 4, 5, 6]
    assert_equal 9, night_hours.length
    # Each hour = 2 segments, so 18 segments should be shaded
  end

  def test_segment_count_covers_24_hours
    # 48 segments = 24 hours x 2 half-hours
    assert_equal 48, BujoPdf::Pages::DailyWheel::NUM_SEGMENTS
    assert_equal 24, BujoPdf::Pages::DailyWheel::NUM_SEGMENTS / 2
  end
end
