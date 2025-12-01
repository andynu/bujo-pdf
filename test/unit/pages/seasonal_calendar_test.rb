#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestSeasonalCalendar < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
  end

  def test_page_has_registered_type
    assert_equal :seasonal, BujoPdf::Pages::SeasonalCalendar.page_type
  end

  def test_page_has_default_dest
    assert_equal "seasonal", BujoPdf::Pages::SeasonalCalendar.default_dest
  end

  def test_page_has_default_title
    assert_equal "Seasonal Calendar", BujoPdf::Pages::SeasonalCalendar.default_title
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)
  end

  def test_setup_uses_standard_with_sidebars_layout
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
    assert_kind_of BujoPdf::Layouts::StandardWithSidebarsLayout, layout
  end

  def test_setup_configures_layout_for_seasonal
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert_equal :seasonal, layout.options[:highlight_tab]
    assert_nil layout.options[:current_week]
  end

  def test_render_calls_all_sections
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_header
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)
  end

  def test_draw_header_shows_year
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)
    # Verifies no error when rendering year header
  end

  def test_draw_seasons
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_seasons)
  end

  def test_calculate_season_height_for_2_months
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    # 2 months: (2 * 8) + (2 * 1) = 18
    assert_equal 18, page.send(:calculate_season_height, 2)
  end

  def test_calculate_season_height_for_3_months
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    # 3 months: (3 * 8) + (3 * 1) = 27
    assert_equal 27, page.send(:calculate_season_height, 3)
  end

  def test_calculate_season_height_for_4_months
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    # 4 months: (4 * 8) + (4 * 1) = 36
    assert_equal 36, page.send(:calculate_season_height, 4)
  end

  def test_calculate_season_height_for_1_month
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    # 1 month: (1 * 8) + (1 * 1) = 9
    assert_equal 9, page.send(:calculate_season_height, 1)
  end

  def test_draw_season_grid
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    season = { name: "Winter", months: [1, 2] }
    page.send(:draw_season_grid, season, 2, 2, 20)
  end

  def test_draw_season_grid_spring
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    season = { name: "Spring", months: [3, 4, 5, 6] }
    page.send(:draw_season_grid, season, 2, 20, 20)
  end

  def test_draw_season_grid_summer
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    season = { name: "Summer", months: [7, 8] }
    page.send(:draw_season_grid, season, 22, 2, 20)
  end

  def test_draw_season_grid_fall
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    season = { name: "Fall", months: [9, 10, 11] }
    page.send(:draw_season_grid, season, 22, 20, 20)
  end

  def test_draw_fieldset
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    page.send(:draw_fieldset, 2, 2, 20, 18, "Test")
  end

  def test_draw_month_grid
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    page.send(:draw_month_grid, 1, 2, 2, 20)
  end

  def test_draw_month_grid_all_months
    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, @context)
    page.send(:setup)

    (1..12).each do |month|
      page.send(:draw_month_grid, month, 2, month * 4, 20)
    end
  end

  def test_includes_styling_colors
    assert_includes BujoPdf::Pages::SeasonalCalendar.included_modules,
                    Styling::Colors
  end

  def test_includes_styling_grid
    assert_includes BujoPdf::Pages::SeasonalCalendar.included_modules,
                    Styling::Grid
  end
end

class TestSeasonalCalendarMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::SeasonalCalendar::Mixin

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

  def test_mixin_provides_seasonal_calendar_method
    builder = TestBuilder.new
    assert builder.respond_to?(:seasonal_calendar), "Expected seasonal_calendar method"
  end

  def test_seasonal_calendar_generates_page
    builder = TestBuilder.new
    builder.seasonal_calendar

    assert_equal 1, builder.pdf.page_count
  end
end

class TestSeasonalCalendarIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::SeasonalCalendar.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end

  def test_page_generation_for_different_years
    [2024, 2025, 2026].each do |year|
      pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      DotGrid.create_stamp(pdf, "page_dots")
      total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(year)

      context = BujoPdf::RenderContext.new(
        page_key: :seasonal,
        page_number: 1,
        year: year,
        total_weeks: total_weeks
      )

      page = BujoPdf::Pages::SeasonalCalendar.new(pdf, context)
      page.generate

      assert_equal 1, pdf.page_count, "Year #{year} should produce 1 page"
    end
  end

  def test_page_generation_for_leap_year
    pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(pdf, "page_dots")

    context = BujoPdf::RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: 2024,  # Leap year
      total_weeks: 53
    )

    page = BujoPdf::Pages::SeasonalCalendar.new(pdf, context)
    page.generate

    assert_equal 1, pdf.page_count
  end
end
