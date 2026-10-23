#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestDaylightBands < Minitest::Test
  include Styling::Colors

  START_COL = 2
  START_ROW = 12

  def render(week_start)
    pdf = MockPDF.new
    grid = GridSystem.new(pdf)
    BujoPdf::Components::DaylightBands.new(
      canvas: BujoPdf::Canvas.new(pdf, grid),
      week_start: week_start,
      col: START_COL, row: START_ROW, width: 40
    ).render
    [pdf, grid]
  end

  # [color, x, top, width, height] for every filled rectangle, in draw order
  def fills(pdf)
    color = nil
    pdf.calls.filter_map do |call|
      color = call[:args][0] if call[:method] == :fill_color
      next unless call[:method] == :fill_rectangle

      (x, top), width, height = call[:args]
      [color, x, top, width, height]
    end
  end

  # Hour (6..21) whose 2-row block contains a y coordinate
  def hour_at(grid, y)
    6 + ((grid.y(START_ROW) - y) / grid.height(2)).floor
  end

  def test_midsummer_shades_only_the_last_two_evening_hours
    pdf, grid = render(Date.new(2026, 6, 15))
    shaded = fills(pdf)

    refute_empty shaded
    hours = shaded.map { |_, _, top, _, height| hour_at(grid, top - (height / 2)) }.uniq.sort
    assert_equal [20, 21], hours
    assert(shaded.all? { |color, *| [color_night_bg, color_twilight_bg].include?(color) })
  end

  def test_midwinter_six_oclock_block_is_night_then_twilight
    pdf, grid = render(Date.new(2026, 12, 14))
    six = fills(pdf).select { |_, _, top, _, h| hour_at(grid, top - (h / 2)) == 6 }

    assert_equal [color_night_bg, color_twilight_bg] * 7, six.map(&:first), 'dawn is near 6:35'
    six.each_slice(2) do |(_, _, night_top, *), _|
      assert_in_delta grid.y(START_ROW), night_top, 1.0
    end
  end

  def test_midwinter_morning_twilight_sits_at_the_top_of_the_seven_oclock_block
    pdf, grid = render(Date.new(2026, 12, 14))
    seven = fills(pdf).select { |_, _, top, _, h| hour_at(grid, top - (h / 2)) == 7 }

    assert_equal 7, seven.size, 'one morning twilight sliver per day'
    seven.each do |color, _, top, _, height|
      assert_equal color_twilight_bg, color
      assert_in_delta grid.y(START_ROW + 2), top, 1.0
      assert_operator height, :<, grid.height(2) / 3, 'sunrise is near 7:10'
    end
  end

  def test_midsummer_six_oclock_block_is_blank
    pdf, grid = render(Date.new(2026, 6, 15))

    assert(fills(pdf).none? { |_, _, top, _, h| hour_at(grid, top - (h / 2)) == 6 })
  end

  def test_midwinter_evening_is_night_from_five_onward
    pdf, grid = render(Date.new(2026, 12, 14))
    by_hour = fills(pdf).group_by { |_, _, top, _, h| hour_at(grid, top - (h / 2)) }

    (17..21).each do |hour|
      assert(by_hour.fetch(hour).any? { |color, *| color == color_night_bg }, "night at #{hour}:00")
    end
    assert_nil by_hour[12]
  end

  def test_each_day_uses_its_own_column
    pdf, grid = render(Date.new(2026, 12, 14))
    xs = fills(pdf).map { |_, x, *| x.round(1) }.uniq.sort

    assert_equal 7, xs.size
    assert_in_delta grid.x(START_COL), xs.first, 1.0
  end

  def test_hour_labels_appear_once_in_the_monday_column
    pdf, grid = render(Date.new(2026, 6, 15))
    labels = pdf.calls.select { |c| c[:method] == :text_box }

    assert_equal %w[6 7 8 9 10 11 12 1 2 3 4 5 6 7 8 9], labels.map { |c| c[:args][0] }
    labels.each do |call|
      assert_operator call[:kwargs][:at][0], :<, grid.x(START_COL + 2)
    end
  end
end
