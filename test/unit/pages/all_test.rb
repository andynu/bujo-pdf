#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestPagesAll < Minitest::Test
  # Test class that includes Pages::All
  class TestBuilder
    include BujoPdf::Pages::All

    attr_reader :pdf, :year, :date_config, :event_store, :total_pages

    def initialize(year = 2025)
      @year = year
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @date_config = nil
      @event_store = nil
      @total_pages = 100
      @first_page_used = false
      DotGrid.create_stamp(@pdf, "page_dots")
    end
  end

  def test_includes_mixin_support
    builder = TestBuilder.new
    assert builder.respond_to?(:start_new_page, true), "Expected MixinSupport#start_new_page"
    assert builder.respond_to?(:build_context, true), "Expected MixinSupport#build_context"
    assert builder.respond_to?(:define_page, true), "Expected MixinSupport#define_page"
    assert builder.respond_to?(:page_set, true), "Expected MixinSupport#page_set"
  end

  def test_includes_seasonal_calendar_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:seasonal_calendar), "Expected SeasonalCalendar#seasonal_calendar"
  end

  def test_includes_year_at_glance_events_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:year_events_page), "Expected YearAtGlanceEvents#year_events_page"
  end

  def test_includes_year_at_glance_highlights_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:year_highlights_page), "Expected YearAtGlanceHighlights#year_highlights_page"
  end

  def test_includes_multi_year_overview_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:multi_year_page), "Expected MultiYearOverview#multi_year_page"
  end

  def test_includes_index_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:index_page), "Expected IndexPage#index_page"
  end

  def test_includes_future_log_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:future_log_page), "Expected FutureLog#future_log_page"
  end

  def test_includes_weekly_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:weekly_page), "Expected WeeklyPage#weekly_page"
  end

  def test_includes_monthly_review_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:monthly_review_page), "Expected MonthlyReview#monthly_review_page"
  end

  def test_includes_quarterly_planning_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:quarterly_planning_page), "Expected QuarterlyPlanning#quarterly_planning_page"
  end

  def test_includes_collection_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:collection_page), "Expected CollectionPage#collection_page"
  end

  def test_includes_grid_showcase_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:grid_showcase_page), "Expected GridShowcase#grid_showcase_page"
  end

  def test_includes_grids_overview_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:grids_overview_page), "Expected GridsOverview#grids_overview_page"
  end

  def test_includes_dot_grid_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:dot_grid_page), "Expected Grids::DotGridPage#dot_grid_page"
  end

  def test_includes_graph_grid_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:graph_grid_page), "Expected Grids::GraphGridPage#graph_grid_page"
  end

  def test_includes_lined_grid_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:lined_grid_page), "Expected Grids::LinedGridPage#lined_grid_page"
  end

  def test_includes_isometric_grid_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:isometric_grid_page), "Expected Grids::IsometricGridPage#isometric_grid_page"
  end

  def test_includes_perspective_grid_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:perspective_grid_page), "Expected Grids::PerspectiveGridPage#perspective_grid_page"
  end

  def test_includes_hexagon_grid_page_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:hexagon_grid_page), "Expected Grids::HexagonGridPage#hexagon_grid_page"
  end

  def test_includes_tracker_example_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:tracker_example_page), "Expected TrackerExample#tracker_example_page"
  end

  def test_includes_reference_calibration_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:reference_page), "Expected ReferenceCalibration#reference_page"
  end

  def test_includes_daily_wheel_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:daily_wheel_page), "Expected DailyWheel#daily_wheel_page"
  end

  def test_includes_year_wheel_mixin
    builder = TestBuilder.new
    assert builder.respond_to?(:year_wheel_page), "Expected YearWheel#year_wheel_page"
  end

  def test_includes_composite_verbs
    builder = TestBuilder.new
    assert builder.respond_to?(:grid_pages), "Expected CompositeVerbs#grid_pages"
    assert builder.respond_to?(:template_pages), "Expected CompositeVerbs#template_pages"
  end
end

class TestCompositeVerbs < Minitest::Test
  class MockBuilder
    include BujoPdf::Pages::All

    attr_reader :pdf, :year, :date_config, :event_store, :total_pages
    attr_accessor :pages_called

    def initialize
      @year = 2025
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @date_config = nil
      @event_store = nil
      @total_pages = 100
      @first_page_used = false
      @pages_called = []
      DotGrid.create_stamp(@pdf, "page_dots")
    end

    # Override grid page methods to track calls
    def grid_showcase_page
      @pages_called << :grid_showcase_page
    end

    def grids_overview_page
      @pages_called << :grids_overview_page
    end

    def dot_grid_page
      @pages_called << :dot_grid_page
    end

    def graph_grid_page
      @pages_called << :graph_grid_page
    end

    def lined_grid_page
      @pages_called << :lined_grid_page
    end

    def isometric_grid_page
      @pages_called << :isometric_grid_page
    end

    def perspective_grid_page
      @pages_called << :perspective_grid_page
    end

    def hexagon_grid_page
      @pages_called << :hexagon_grid_page
    end

    def tracker_example_page
      @pages_called << :tracker_example_page
    end

    def reference_page
      @pages_called << :reference_page
    end

    def daily_wheel_page
      @pages_called << :daily_wheel_page
    end

    def year_wheel_page
      @pages_called << :year_wheel_page
    end
  end

  def test_grid_pages_calls_all_grid_page_methods
    builder = MockBuilder.new
    builder.grid_pages

    expected = [
      :grid_showcase_page,
      :grids_overview_page,
      :dot_grid_page,
      :graph_grid_page,
      :lined_grid_page,
      :isometric_grid_page,
      :perspective_grid_page,
      :hexagon_grid_page
    ]

    assert_equal expected, builder.pages_called
  end

  def test_template_pages_calls_all_template_page_methods
    builder = MockBuilder.new
    builder.template_pages

    expected = [
      :tracker_example_page,
      :reference_page,
      :daily_wheel_page,
      :year_wheel_page
    ]

    assert_equal expected, builder.pages_called
  end
end

class TestPagesAllIntegration < Minitest::Test
  class IntegrationBuilder
    include BujoPdf::Pages::All

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

  def test_can_generate_seasonal_calendar
    builder = IntegrationBuilder.new
    builder.seasonal_calendar
    assert builder.pdf.page_count >= 1
  end

  def test_can_generate_index_page
    builder = IntegrationBuilder.new
    builder.index_page(num: 1)
    assert builder.pdf.page_count >= 1
  end

  def test_can_generate_weekly_page
    builder = IntegrationBuilder.new
    builder.weekly_page(week: 1)
    assert builder.pdf.page_count >= 1
  end
end
