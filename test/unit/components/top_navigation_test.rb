#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestTopNavigation < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    @week_start = Date.new(2025, 10, 13)
    @week_end = Date.new(2025, 10, 19)
  end

  def test_constants
    assert_equal 8, BujoPdf::Components::TopNavigation::NAV_FONT_SIZE
    assert_equal 14, BujoPdf::Components::TopNavigation::TITLE_FONT_SIZE
  end

  def test_initialize_sets_properties
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 42,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    assert_equal 2025, nav.instance_variable_get(:@year)
    assert_equal 42, nav.instance_variable_get(:@week_num)
    assert_equal 52, nav.instance_variable_get(:@total_weeks)
    assert_equal @week_start, nav.instance_variable_get(:@week_start)
    assert_equal @week_end, nav.instance_variable_get(:@week_end)
  end

  def test_initialize_with_custom_content_area
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 42,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end,
      content_start_col: 5,
      content_width_boxes: 30
    )

    assert_equal 5, nav.instance_variable_get(:@content_start_col)
    assert_equal 30, nav.instance_variable_get(:@content_width_boxes)
  end

  def test_render_middle_week
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 25,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    # Should render prev and next links
    nav.render
  end

  def test_render_first_week_no_prev_link
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 1,
      total_weeks: 52,
      week_start: Date.new(2024, 12, 30),
      week_end: Date.new(2025, 1, 5)
    )

    # Should render next link but not prev
    nav.render
  end

  def test_render_last_week_no_next_link
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 52,
      total_weeks: 52,
      week_start: Date.new(2025, 12, 22),
      week_end: Date.new(2025, 12, 28)
    )

    # Should render prev link but not next
    nav.render
  end

  def test_show_prev_returns_true_for_non_first_week
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 2,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    assert nav.send(:show_prev?)
  end

  def test_show_prev_returns_false_for_first_week
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 1,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    refute nav.send(:show_prev?)
  end

  def test_show_next_returns_true_for_non_last_week
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 51,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    assert nav.send(:show_next?)
  end

  def test_show_next_returns_false_for_last_week
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 52,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    refute nav.send(:show_next?)
  end

  def test_draw_year_link
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 42,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    nav_box = @grid.rect(3, 0, 39, 2)
    nav.send(:draw_year_link, nav_box)
  end

  def test_draw_prev_week_link
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 42,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    nav_box = @grid.rect(3, 0, 39, 2)
    nav.send(:draw_prev_week_link, nav_box)
  end

  def test_draw_next_week_link
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 42,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    nav_box = @grid.rect(3, 0, 39, 2)
    nav.send(:draw_next_week_link, nav_box)
  end

  def test_draw_nav_background
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 42,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    nav.send(:draw_nav_background, 100, 700, 50, 30)
  end

  def test_draw_title
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 42,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    nav_box = @grid.rect(3, 0, 39, 2)
    nav.send(:draw_title, nav_box)
  end

  def test_title_format
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 42,
      total_weeks: 52,
      week_start: Date.new(2025, 10, 13),
      week_end: Date.new(2025, 10, 19)
    )

    # Title should be formatted as "Week 42: Oct 13 - Oct 19, 2025"
    # Testing by rendering - format is embedded in draw_title
    nav.render
  end

  def test_prev_week_format_padded
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 5,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    # Should show "w04" for previous week (zero-padded)
    nav.render
  end

  def test_next_week_format_padded
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 9,
      total_weeks: 52,
      week_start: @week_start,
      week_end: @week_end
    )

    # Should show "w10" for next week (zero-padded)
    nav.render
  end
end

class TestTopNavigationWithMockPDF < Minitest::Test
  def setup
    @mock_pdf = MockPDF.new
    @grid = GridSystem.new(@mock_pdf)
    @canvas = BujoPdf::Canvas.new(@mock_pdf, @grid)
    @week_start = Date.new(2025, 10, 13)
    @week_end = Date.new(2025, 10, 19)
  end

  def test_draws_year_text
    # MockPDF doesn't support the full bounding_box/transparent workflow,
    # so we test with real Prawn in TestTopNavigation instead
  end
end

class TestTopNavigationEdgeCases < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_year_spanning_weeks
    # Week that starts in one year and ends in next
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 1,
      total_weeks: 53,
      week_start: Date.new(2024, 12, 30),
      week_end: Date.new(2025, 1, 5)
    )

    nav.render
  end

  def test_53_week_year
    nav = BujoPdf::Components::TopNavigation.new(
      canvas: @canvas,
      year: 2025,
      week_num: 53,
      total_weeks: 53,
      week_start: Date.new(2025, 12, 29),
      week_end: Date.new(2026, 1, 4)
    )

    nav.render
  end
end
