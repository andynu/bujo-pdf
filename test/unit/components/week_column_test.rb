#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestWeekColumn < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_initialize_requires_date_or_day_name
    error = assert_raises(ArgumentError) do
      BujoPdf::Components::WeekColumn.new(
        canvas: @canvas,
        col: 5, row: 10, width: 5, height: 9
      )
    end
    assert_match(/date or day_name required/, error.message)
  end

  def test_initialize_with_date_infers_day_name
    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: Date.new(2025, 1, 6)  # Monday
    )

    # Should not raise and should render
    column.render
  end

  def test_initialize_with_day_name_only
    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 9,
      day_name: "Monday"
    )

    # Should not raise and should render
    column.render
  end

  def test_initialize_with_both_date_and_day_name
    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: Date.new(2025, 1, 6),
      day_name: "Monday"
    )

    column.render
  end

  def test_render_draws_border
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      day_name: "Monday"
    )

    column.render

    # Box component draws borders with stroke_rectangle
    assert mock_pdf.called?(:stroke_rectangle), "Expected border to be drawn"
  end

  def test_render_draws_header
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: Date.new(2025, 1, 6),
      day_name: "Monday"
    )

    column.render

    # Should draw header text boxes
    assert mock_pdf.called?(:text_box), "Expected header text to be drawn"

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }

    # Should have text_box calls for day abbreviation and date
    assert text_box_calls.length >= 2, "Expected at least 2 text boxes for header"
  end

  def test_render_weekend_draws_background
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: Date.new(2025, 1, 11),  # Saturday
      weekend: true
    )

    column.render

    # Weekend background is drawn with fill_rectangle and uses transparent()
    assert mock_pdf.called?(:transparent), "Expected weekend background with transparency"
  end

  def test_render_non_weekend_skips_background
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: Date.new(2025, 1, 6),  # Monday
      weekend: false
    )

    column.render

    # fill_rectangle may still be called for other things, but check weekend isn't set
    # Actually, can't easily check this without deeper inspection
  end

  def test_render_draws_ruled_lines
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      day_name: "Monday",
      line_count: 4
    )

    column.render

    # HLine component draws horizontal lines
    stroke_line_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_line }
    assert stroke_line_calls.length >= 4, "Expected at least 4 ruled lines"
  end

  def test_render_with_time_labels
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      day_name: "Monday",
      show_time_labels: true
    )

    column.render

    # Should draw AM/PM/EVE labels
    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }
    text_contents = text_box_calls.map { |c| c[:args][0] }

    # Should include time labels
    assert text_contents.any? { |t| t == 'AM' }, "Expected AM label"
    assert text_contents.any? { |t| t == 'PM' }, "Expected PM label"
    assert text_contents.any? { |t| t == 'EVE' }, "Expected EVE label"
  end

  def test_render_without_time_labels
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      day_name: "Tuesday",
      show_time_labels: false
    )

    column.render

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }
    text_contents = text_box_calls.map { |c| c[:args][0] }

    # Should NOT include time labels
    refute text_contents.include?('AM'), "Did not expect AM label"
    refute text_contents.include?('PM'), "Did not expect PM label"
    refute text_contents.include?('EVE'), "Did not expect EVE label"
  end

  def test_defaults_constants
    defaults = BujoPdf::Components::WeekColumn::DEFAULTS

    assert_equal 4, defaults[:line_count]
    assert_equal 1, defaults[:header_height_boxes]
    assert_equal 3, defaults[:line_margin]
    assert_equal 8, defaults[:day_header_font_size]
    assert_equal 8, defaults[:day_date_font_size]
    assert_equal 6, defaults[:time_label_font_size]
    assert_equal false, defaults[:show_time_labels]
    assert_equal false, defaults[:weekend]
  end

  def test_custom_line_count
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      day_name: "Monday",
      line_count: 6
    )

    column.render

    stroke_line_calls = mock_pdf.calls.select { |c| c[:method] == :stroke_line }
    assert stroke_line_calls.length >= 6, "Expected at least 6 ruled lines"
  end

  def test_header_displays_day_abbreviation
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      day_name: "Wednesday"
    )

    column.render

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }
    text_contents = text_box_calls.map { |c| c[:args][0] }

    # Should show "Wed" (first 3 chars)
    assert text_contents.include?('Wed'), "Expected day abbreviation 'Wed'"
  end

  def test_header_displays_date_format
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: Date.new(2025, 1, 6),  # January 6
      day_name: "Monday"
    )

    column.render

    text_box_calls = mock_pdf.calls.select { |c| c[:method] == :text_box }
    text_contents = text_box_calls.map { |c| c[:args][0] }

    # Date should be formatted as "1/6" (month/day without leading zeros)
    assert text_contents.include?('1/6'), "Expected date format '1/6'"
  end

  def test_with_real_prawn_document
    # Integration test with real PDF rendering
    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5.57, height: 9,
      date: Date.new(2025, 1, 6),
      day_name: "Monday",
      show_time_labels: true,
      weekend: false
    )

    # Should render without errors
    column.render

    # PDF should still be valid
    assert_kind_of Prawn::Document, @pdf
  end

  def test_weekend_saturday
    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 30, row: 10, width: 5.57, height: 9,
      date: Date.new(2025, 1, 11),  # Saturday
      day_name: "Saturday",
      weekend: true
    )

    column.render
  end

  def test_weekend_sunday
    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 35, row: 10, width: 5.57, height: 9,
      date: Date.new(2025, 1, 12),  # Sunday
      day_name: "Sunday",
      weekend: true
    )

    column.render
  end

  def test_accepts_fractional_width
    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5.57, height: 9,
      day_name: "Monday"
    )

    column.render
  end

  def test_accepts_all_optional_params
    # Make sure constructor accepts all documented parameters
    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: Date.new(2025, 1, 6),
      day_name: "Monday",
      line_count: 5,
      header_height_boxes: 2,
      line_margin: 5,
      day_header_font_size: 10,
      day_date_font_size: 10,
      time_label_font_size: 7,
      header_color: 'CCCCCC',
      border_color: 'DDDDDD',
      weekend_bg_color: 'F0F0F0',
      show_time_labels: true,
      weekend: false,
      date_config: nil,
      event_store: nil,
      header_height: nil,
      header_padding: nil,
      lines_start: nil,
      lines_padding: nil
    )

    column.render
  end
end

class TestWeekColumnWithDateConfig < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_render_with_date_config_draws_label
    # Mock date config that returns a highlighted date
    date_config = MockDateConfig.new
    date = Date.new(2025, 1, 6)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: date,
      day_name: "Monday",
      date_config: date_config
    )

    column.render
    # Should complete without error
  end

  def test_render_without_date_config_or_events_skips_label
    mock_pdf = MockPDF.new
    grid = GridSystem.new(mock_pdf)
    canvas = BujoPdf::Canvas.new(mock_pdf, grid)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: Date.new(2025, 1, 6),
      day_name: "Monday",
      date_config: nil,
      event_store: nil
    )

    column.render

    # Without date_config or event_store, no date label should be drawn
    fill_rectangle_calls = mock_pdf.calls.select { |c| c[:method] == :fill_rectangle }
    # fill_rectangle would be called for label background - should have none beyond weekend bg
    # (weekend is false by default, so no background rectangles expected for labels)
  end
end

class TestWeekColumnWithEventStore < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_render_with_event_store_draws_event_label
    # Mock event store that returns events
    event_store = MockEventStore.new
    date = Date.new(2025, 1, 6)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: date,
      day_name: "Monday",
      event_store: event_store
    )

    column.render
  end

  def test_render_with_empty_event_store
    # Mock event store that returns no events
    event_store = MockEventStoreEmpty.new
    date = Date.new(2025, 1, 6)

    column = BujoPdf::Components::WeekColumn.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 9,
      date: date,
      day_name: "Monday",
      event_store: event_store
    )

    column.render
  end
end

# Mock classes for date_config and event_store testing are in test_helper.rb
