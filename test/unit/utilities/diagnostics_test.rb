#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestDiagnostics < Minitest::Test
  def setup
    @pdf = MockPDF.new
    @grid = GridSystem.new(@pdf)
  end

  def test_draw_grid_when_disabled_does_nothing
    Diagnostics.draw_grid(@pdf, @grid, enabled: false)

    assert_equal 0, @pdf.calls.length
  end

  def test_draw_grid_when_enabled_draws_dots_at_intersections
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 10)

    # Should call fill_circle for every grid intersection
    # Grid is 43 cols x 55 rows = (43+1) * (55+1) = 44 * 56 = 2464 intersections
    fill_circle_calls = @pdf.calls.count { |c| c[:method] == :fill_circle }
    assert_equal (43 + 1) * (55 + 1), fill_circle_calls
  end

  def test_draw_grid_sets_diagnostic_red_fill_color_for_dots
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 10)

    # First fill_color call should be diagnostic red for dots
    fill_color_calls = @pdf.calls.select { |c| c[:method] == :fill_color }
    assert fill_color_calls.length >= 1
    assert_equal Styling::Colors.DIAGNOSTIC_RED, fill_color_calls[0][:args][0]
  end

  def test_draw_grid_draws_dashed_grid_lines
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 5)

    # Should call dash to set line style
    assert @pdf.called?(:dash)
    dash_call = @pdf.last_call(:dash)
    assert_equal 1, dash_call[:args][0]
    assert_equal({ space: 2 }, dash_call[:kwargs])

    # Should call undash at the end
    assert @pdf.called?(:undash)
  end

  def test_draw_grid_draws_vertical_lines_at_intervals
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 5)

    stroke_line_calls = @pdf.calls.select { |c| c[:method] == :stroke_line }

    # With 43 cols and label_every: 5, vertical lines at 0, 5, 10, 15, 20, 25, 30, 35, 40, 43
    # That's (0..43).step(5) = [0, 5, 10, 15, 20, 25, 30, 35, 40] = 9 vertical lines
    # Plus horizontal lines at (0..55).step(5) = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55] = 12 lines
    # Total = 9 + 12 = 21 lines
    assert_equal 21, stroke_line_calls.length
  end

  def test_draw_grid_draws_coordinate_labels
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 10)

    text_box_calls = @pdf.calls.select { |c| c[:method] == :text_box }

    # With label_every: 10 on a 43x55 grid:
    # Columns: 0, 10, 20, 30, 40 = 5 columns
    # Rows: 0, 10, 20, 30, 40, 50 = 6 rows
    # Total labels: 5 * 6 = 30
    assert_equal 30, text_box_calls.length
  end

  def test_draw_grid_label_format
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 43)

    text_box_calls = @pdf.calls.select { |c| c[:method] == :text_box }

    # With label_every: 43, only column 0 and 43 shown
    # First label should be (0,0)
    first_label = text_box_calls.first[:args][0]
    assert_equal '(0,0)', first_label
  end

  def test_draw_grid_draws_white_background_for_labels
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 10)

    fill_rectangle_calls = @pdf.calls.select { |c| c[:method] == :fill_rectangle }

    # Each label has a background rectangle
    # 5 cols * 6 rows = 30 labels = 30 rectangles
    assert_equal 30, fill_rectangle_calls.length
  end

  def test_draw_grid_resets_colors_to_defaults
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 10)

    fill_color_calls = @pdf.calls.select { |c| c[:method] == :fill_color }
    stroke_color_calls = @pdf.calls.select { |c| c[:method] == :stroke_color }

    # Last fill_color and stroke_color should reset to TEXT_BLACK
    assert_equal Styling::Colors.TEXT_BLACK, fill_color_calls.last[:args][0]
    assert_equal Styling::Colors.TEXT_BLACK, stroke_color_calls.last[:args][0]
  end

  def test_draw_grid_sets_line_width
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 10)

    line_width_calls = @pdf.calls.select { |c| c[:method] == :line_width }

    # Sets line width to 0.25 for grid lines, then 1 to reset
    assert line_width_calls.length >= 2
    assert_equal 0.25, line_width_calls.first[:args][0]
    assert_equal 1, line_width_calls.last[:args][0]
  end

  def test_draw_grid_sets_font_for_labels
    Diagnostics.draw_grid(@pdf, @grid, enabled: true, label_every: 10)

    font_calls = @pdf.calls.select { |c| c[:method] == :font }

    assert font_calls.length >= 1
    assert_equal 'Helvetica', font_calls.first[:args][0]
    assert_equal({ size: 6 }, font_calls.first[:kwargs])
  end

  def test_draw_grid_default_label_every_is_five
    Diagnostics.draw_grid(@pdf, @grid, enabled: true)

    stroke_line_calls = @pdf.calls.select { |c| c[:method] == :stroke_line }

    # Default label_every: 5
    # Vertical lines: (0..43).step(5) = 9 lines
    # Horizontal lines: (0..55).step(5) = 12 lines
    # Total: 21 lines
    assert_equal 21, stroke_line_calls.length
  end

  def test_draw_grid_enabled_by_default
    # When enabled not specified, defaults to true
    Diagnostics.draw_grid(@pdf, @grid)

    assert @pdf.calls.length > 0
    assert @pdf.called?(:fill_circle)
  end
end
