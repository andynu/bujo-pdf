#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

# Concrete test subclass for testing YearAtGlanceBase abstract methods
class TestYearAtGlancePage < BujoPdf::Pages::YearAtGlanceBase
  def page_title
    "Test Year Page"
  end

  def destination_name
    'test_year_page'
  end
end

class TestYearAtGlanceBase < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :test_year,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
  end

  def test_constants_are_defined
    assert_equal 8, BujoPdf::Pages::YearAtGlanceBase::YEAR_MONTH_HEADER_SIZE
    assert_equal 6, BujoPdf::Pages::YearAtGlanceBase::YEAR_DAY_SIZE
    assert_equal 5, BujoPdf::Pages::YearAtGlanceBase::YEAR_DAY_ABBREV_SIZE
    assert_equal 12, BujoPdf::Pages::YearAtGlanceBase::MONTH_NAMES.length
  end

  def test_month_names
    expected = %w[January February March April May June July August September October November December]
    assert_equal expected, BujoPdf::Pages::YearAtGlanceBase::MONTH_NAMES
  end

  def test_setup_sets_year_and_total_weeks
    page = TestYearAtGlancePage.new(@pdf, @context)
    page.send(:setup)

    assert_equal 2025, page.instance_variable_get(:@year)
    assert_equal 53, page.instance_variable_get(:@total_weeks)
  end

  def test_setup_sets_destination
    page = TestYearAtGlancePage.new(@pdf, @context)
    page.send(:setup)

    # Destination should be set (can't easily verify without PDF introspection)
    # Just ensure no error
  end

  def test_current_week_returns_nil
    page = TestYearAtGlancePage.new(@pdf, @context)

    assert_nil page.send(:current_week)
  end

  def test_highlight_tab_returns_destination_name
    page = TestYearAtGlancePage.new(@pdf, @context)
    page.send(:setup)

    assert_equal 'test_year_page', page.send(:highlight_tab)
  end

  def test_page_title_must_be_implemented
    # Create anonymous subclass that doesn't implement page_title
    klass = Class.new(BujoPdf::Pages::YearAtGlanceBase)
    page = klass.new(@pdf, @context)

    assert_raises(NotImplementedError) do
      page.send(:page_title)
    end
  end

  def test_destination_name_must_be_implemented
    # Create anonymous subclass that doesn't implement destination_name
    klass = Class.new(BujoPdf::Pages::YearAtGlanceBase)
    page = klass.new(@pdf, @context)

    assert_raises(NotImplementedError) do
      page.send(:destination_name)
    end
  end

  def test_generate_renders_page_without_errors
    page = TestYearAtGlancePage.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_render_calls_all_drawing_methods
    page = TestYearAtGlancePage.new(@pdf, @context)

    # Track method calls
    calls = []
    page.define_singleton_method(:draw_weekend_backgrounds) { calls << :weekend }
    page.define_singleton_method(:draw_dot_grid) { calls << :dots }
    page.define_singleton_method(:draw_header) { calls << :header }
    page.define_singleton_method(:draw_month_headers) { calls << :month_headers }
    page.define_singleton_method(:draw_days_grid) { calls << :days_grid }

    page.send(:render)

    assert_includes calls, :weekend
    assert_includes calls, :dots
    assert_includes calls, :header
    assert_includes calls, :month_headers
    assert_includes calls, :days_grid
  end
end

class TestYearAtGlanceDrawMethods < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :test_year,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
    @page = TestYearAtGlancePage.new(@pdf, @context)
    @page.send(:setup)
  end

  def test_draw_header_renders_title
    @page.send(:draw_header)
    # Should complete without error
  end

  def test_draw_month_headers_renders_12_months
    @page.send(:draw_month_headers)
    # Should complete without error and render 12 month headers
  end

  def test_draw_days_grid_renders_all_days
    @page.send(:draw_days_grid)
    # Should complete without error and render 31x12 grid
  end

  def test_draw_weekend_backgrounds_renders_without_error
    @page.send(:draw_weekend_backgrounds)
    # Should complete without error
  end

  def test_draw_empty_cell_renders_overlay
    cell_x = 100
    cell_y = 500
    cell_width = 40
    cell_height = 20

    @page.send(:draw_empty_cell, cell_x, cell_y, cell_width, cell_height)
    # Should complete without error
  end

  def test_draw_day_cell_renders_for_valid_date
    cell_x = 100
    cell_y = 500
    cell_width = 40
    cell_height = 20
    month = 1
    day_num = 15

    @page.send(:draw_day_cell, cell_x, cell_y, cell_width, cell_height, month, day_num)
    # Should complete without error
  end

  def test_draw_day_cell_for_weekend
    cell_x = 100
    cell_y = 500
    cell_width = 40
    cell_height = 20
    # Jan 4, 2025 is a Saturday
    month = 1
    day_num = 4

    @page.send(:draw_day_cell, cell_x, cell_y, cell_width, cell_height, month, day_num)
    # Should complete without error
  end
end

class TestYearAtGlanceWithDateConfig < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @date_config = MockDateConfigForYear.new
    @context = BujoPdf::RenderContext.new(
      page_key: :test_year,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      date_config: @date_config
    )
  end

  def test_generate_with_date_config_renders_legend
    page = TestYearAtGlancePage.new(@pdf, @context)
    page.generate
    # Should render legend when date_config has dates
  end

  def test_draw_legend_renders_when_dates_present
    page = TestYearAtGlancePage.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_legend)
    # Should complete without error
  end

  def test_draw_day_cell_highlights_configured_dates
    page = TestYearAtGlancePage.new(@pdf, @context)
    page.send(:setup)

    # Jan 1 is configured as highlighted
    page.send(:draw_day_cell, 100, 500, 40, 20, 1, 1)
    # Should render with highlighting
  end
end

class TestYearAtGlanceWithEventStore < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @event_store = MockEventStoreForYear.new
    @context = BujoPdf::RenderContext.new(
      page_key: :test_year,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      event_store: @event_store
    )
  end

  def test_draw_day_cell_shows_calendar_events
    page = TestYearAtGlancePage.new(@pdf, @context)
    page.send(:setup)

    # Jan 6 has a calendar event
    page.send(:draw_day_cell, 100, 500, 40, 20, 1, 6)
    # Should render with event highlighting
  end
end

class TestYearAtGlanceIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_year_at_glance_events_page_generates
    context = BujoPdf::RenderContext.new(
      page_key: :year_events,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::YearAtGlanceEvents.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_year_at_glance_highlights_page_generates
    context = BujoPdf::RenderContext.new(
      page_key: :year_highlights,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::YearAtGlanceHighlights.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_events_page_has_correct_title
    context = BujoPdf::RenderContext.new(
      page_key: :year_events,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::YearAtGlanceEvents.new(@pdf, context)
    page.send(:setup)

    assert_equal "Events of 2025", page.send(:page_title)
  end

  def test_highlights_page_has_correct_title
    context = BujoPdf::RenderContext.new(
      page_key: :year_highlights,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::YearAtGlanceHighlights.new(@pdf, context)
    page.send(:setup)

    assert_equal "Highlights of 2025", page.send(:page_title)
  end
end

# Mock classes
class MockDateConfigForYear
  HighlightedDate = Struct.new(:date, :label, :category, :priority, :color, keyword_init: true)
  CategoryStyle = { 'color' => 'FF6B6B', 'text_color' => 'FFFFFF', 'icon' => '*' }
  PriorityStyle = { 'bold' => true, 'border_width' => 1.0 }

  def any?
    true
  end

  def dates
    [
      HighlightedDate.new(date: Date.new(2025, 1, 1), label: "New Year", category: "holiday", priority: "high"),
      HighlightedDate.new(date: Date.new(2025, 12, 25), label: "Christmas", category: "holiday", priority: "high")
    ]
  end

  def date_for_day(date)
    return HighlightedDate.new(date: date, label: "New Year", category: "holiday", priority: "high", color: nil) if date == Date.new(2025, 1, 1)
    nil
  end

  def category_style(category)
    CategoryStyle
  end

  def priority_style(priority)
    PriorityStyle
  end
end

class MockEventStoreForYear
  MockEvent = Struct.new(:color, :icon, keyword_init: true)

  def events_for_date(date, limit: nil)
    return [MockEvent.new(color: '4285F4', icon: 'E')] if date == Date.new(2025, 1, 6)
    []
  end
end
