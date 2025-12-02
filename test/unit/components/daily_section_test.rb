#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestDailySection < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    @week_start = Date.new(2025, 1, 6)  # Monday
  end

  def test_initialize_stores_required_params
    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 39,
      daily_rows: 9
    )

    # Should not raise and should be renderable
    section.render
  end

  def test_initialize_accepts_optional_params
    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 39,
      daily_rows: 9,
      line_count: 5,
      line_margin: 4,
      header_font_size: 10
    )

    section.render
  end

  def test_render_creates_week_grid
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    section = BujoPdf::Components::DailySection.new(
      canvas: canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,  # divisible by 7 for quantization
      daily_rows: 9
    )

    section.render

    # Should have drawn elements for 7 days
    # Each day column draws borders (stroke_rectangle) and text (text_box)
    assert mock_pdf.called?(:stroke_rectangle), "Expected day column borders"
    assert mock_pdf.called?(:text_box), "Expected day headers"
  end

  def test_render_draws_seven_day_columns
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    section = BujoPdf::Components::DailySection.new(
      canvas: canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9
    )

    section.render

    # Each day column should draw a border
    stroke_rect_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_rectangle }
    assert stroke_rect_calls.length >= 7, "Expected at least 7 day column borders"
  end

  def test_render_draws_day_headers
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    section = BujoPdf::Components::DailySection.new(
      canvas: canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9
    )

    section.render

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }
    text_contents = text_box_calls.map { |c| c[:args][0] }

    # Should include day abbreviations (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
    assert text_contents.include?('Mon'), "Expected Monday abbreviation"
    assert text_contents.include?('Tue'), "Expected Tuesday abbreviation"
    assert text_contents.include?('Wed'), "Expected Wednesday abbreviation"
    assert text_contents.include?('Thu'), "Expected Thursday abbreviation"
    assert text_contents.include?('Fri'), "Expected Friday abbreviation"
    assert text_contents.include?('Sat'), "Expected Saturday abbreviation"
    assert text_contents.include?('Sun'), "Expected Sunday abbreviation"
  end

  def test_render_draws_date_numbers
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    section = BujoPdf::Components::DailySection.new(
      canvas: canvas,
      week_start: @week_start,  # Jan 6, 2025
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9
    )

    section.render

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }
    text_contents = text_box_calls.map { |c| c[:args][0] }

    # Week of Jan 6: dates should be 1/6, 1/7, 1/8, 1/9, 1/10, 1/11, 1/12
    assert text_contents.include?('1/6'), "Expected date 1/6"
    assert text_contents.include?('1/7'), "Expected date 1/7"
    assert text_contents.include?('1/12'), "Expected date 1/12"
  end

  def test_render_shows_time_labels_on_monday_only
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    section = BujoPdf::Components::DailySection.new(
      canvas: canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9
    )

    section.render

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }
    text_contents = text_box_calls.map { |c| c[:args][0] }

    # Time labels should appear exactly once each (Monday only)
    assert_equal 1, text_contents.count('AM'), "AM label should appear once"
    assert_equal 1, text_contents.count('PM'), "PM label should appear once"
    assert_equal 1, text_contents.count('EVE'), "EVE label should appear once"
  end

  def test_render_draws_weekend_background
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    section = BujoPdf::Components::DailySection.new(
      canvas: canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9
    )

    section.render

    # Saturday and Sunday should have transparent backgrounds
    transparent_calls = mock_pdf.calls.select { |c| c[:method] == :transparent }
    assert transparent_calls.length >= 2, "Expected weekend background for Sat and Sun"
  end

  def test_render_draws_ruled_lines
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    section = BujoPdf::Components::DailySection.new(
      canvas: canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9,
      line_count: 4
    )

    section.render

    # Each day column should have 4 ruled lines
    stroke_line_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_line }
    assert stroke_line_calls.length >= 28, "Expected at least 28 lines (7 days * 4 lines)"
  end

  def test_render_with_real_prawn_document
    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 39,
      daily_rows: 9
    )

    # Should render without errors
    section.render

    assert_kind_of Prawn::Document, @pdf
  end

  def test_week_with_month_boundary
    # Week spanning December to January
    week_start = Date.new(2024, 12, 30)  # Monday Dec 30

    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9
    )

    # Should render without errors
    section.render
  end

  def test_different_content_width
    # Test with different width that's still divisible by 7
    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 0,
      content_start_row: 0,
      content_width_boxes: 42,  # 42/7 = 6 boxes per day
      daily_rows: 10
    )

    section.render
  end

  def test_non_quantized_width
    # Width not divisible by 7 - uses proportional spacing
    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 37,  # Not divisible by 7
      daily_rows: 9
    )

    section.render
  end
end

class TestDailySectionWithDateConfig < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    @week_start = Date.new(2025, 1, 6)
  end

  def test_render_with_date_config
    date_config = MockDateConfig.new

    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9,
      date_config: date_config
    )

    section.render
  end

  def test_render_without_date_config
    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9,
      date_config: nil
    )

    section.render
  end
end

class TestDailySectionWithEventStore < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    @week_start = Date.new(2025, 1, 6)
  end

  def test_render_with_event_store
    event_store = MockEventStore.new

    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9,
      event_store: event_store
    )

    section.render
  end

  def test_render_with_both_date_config_and_event_store
    date_config = MockDateConfig.new
    event_store = MockEventStore.new

    section = BujoPdf::Components::DailySection.new(
      canvas: @canvas,
      week_start: @week_start,
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 35,
      daily_rows: 9,
      date_config: date_config,
      event_store: event_store
    )

    section.render
  end
end
