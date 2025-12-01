#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestDayHeader < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
    @test_date = Date.new(2025, 1, 6)  # Monday
  end

  def test_defaults_constants
    defaults = BujoPdf::Components::DayHeader::DEFAULTS

    assert_equal :full, defaults[:format]
    assert_equal true, defaults[:show_day_name]
    assert_equal true, defaults[:show_date_number]
    assert_equal false, defaults[:show_month]
    assert_equal false, defaults[:weekend]
    assert_equal 10, defaults[:font_size]
    assert_nil defaults[:day_font_size]
    assert_nil defaults[:date_font_size]
    assert_equal 2, defaults[:header_padding]
    assert_equal :center, defaults[:align]
    assert_equal :top, defaults[:valign]
    assert_nil defaults[:weekend_bg_color]
    assert_nil defaults[:text_color]
  end

  def test_initialize_sets_properties
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date
    )

    # Should not raise and render
    header.render
  end

  def test_initialize_calculates_font_sizes
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      font_size: 12
    )

    # day_font_size defaults to font_size, date_font_size defaults to font_size - 1
    assert_equal 12, header.instance_variable_get(:@day_font_size)
    assert_equal 11, header.instance_variable_get(:@date_font_size)
  end

  def test_initialize_accepts_explicit_font_sizes
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      font_size: 12,
      day_font_size: 14,
      date_font_size: 8
    )

    assert_equal 14, header.instance_variable_get(:@day_font_size)
    assert_equal 8, header.instance_variable_get(:@date_font_size)
  end

  def test_render_with_full_format
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :full
    )

    # Should render Monday and 1/6
    header.render
  end

  def test_render_with_short_format
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :short
    )

    # Should render Mon and 1/6
    header.render
  end

  def test_render_with_abbrev_format
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :abbrev
    )

    # Should render M and 6
    header.render
  end

  def test_render_with_day_only_format
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :day_only
    )

    # Should render just Monday
    header.render
  end

  def test_render_with_date_only_format_no_month
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :date_only,
      show_month: false
    )

    # Should render just 6
    header.render
  end

  def test_render_with_date_only_format_with_month
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :date_only,
      show_month: true
    )

    # Should render 1/6
    header.render
  end

  def test_render_with_custom_format_day_name_only
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :custom,
      show_day_name: true,
      show_date_number: false
    )

    header.render
  end

  def test_render_with_custom_format_date_with_month
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :custom,
      show_day_name: false,
      show_date_number: true,
      show_month: true
    )

    header.render
  end

  def test_render_with_custom_format_date_without_month
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      format: :custom,
      show_day_name: false,
      show_date_number: true,
      show_month: false
    )

    header.render
  end

  def test_render_with_weekend_draws_background
    # Use real Prawn PDF for weekend background test (needs bounding_box block)
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: Date.new(2025, 1, 11),  # Saturday
      weekend: true
    )

    # Should complete without error
    header.render
  end

  def test_render_without_weekend_skips_background
    # Use real Prawn PDF (needs bounding_box block)
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      weekend: false
    )

    # Should complete without error
    header.render
  end

  def test_render_uses_custom_weekend_bg_color
    # Use real Prawn PDF (needs bounding_box block)
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: Date.new(2025, 1, 11),  # Saturday
      weekend: true,
      weekend_bg_color: 'FFEEEE'
    )

    # Should complete without error
    header.render
    # Verifying color was used would require PDF inspection
  end

  def test_render_uses_custom_text_color
    # Use real Prawn PDF (needs bounding_box block)
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      text_color: '333333'
    )

    # Should complete without error
    header.render
    # Verifying color was used would require PDF inspection
  end

  def test_render_with_custom_alignment
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      align: :left,
      valign: :center
    )

    header.render
  end

  def test_render_with_custom_padding
    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: @test_date,
      header_padding: 5
    )

    header.render
  end
end

class TestDayHeaderFormats < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  def test_all_days_of_week
    # Test rendering headers for each day of the week
    (0..6).each do |day_offset|
      date = Date.new(2025, 1, 6) + day_offset  # Monday through Sunday

      header = BujoPdf::Components::DayHeader.new(
        canvas: @canvas,
        col: 5, row: 10, width: 5, height: 1.5,
        date: date,
        format: :full
      )

      header.render
    end
  end

  def test_various_months
    # Test rendering headers for different months
    [1, 6, 12].each do |month|
      date = Date.new(2025, month, 15)

      header = BujoPdf::Components::DayHeader.new(
        canvas: @canvas,
        col: 5, row: 10, width: 5, height: 1.5,
        date: date,
        format: :date_only,
        show_month: true
      )

      header.render
    end
  end

  def test_single_digit_dates
    # Test date 1-9
    date = Date.new(2025, 1, 5)

    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: date,
      format: :short
    )

    header.render
  end

  def test_double_digit_dates
    # Test date 10-31
    date = Date.new(2025, 1, 25)

    header = BujoPdf::Components::DayHeader.new(
      canvas: @canvas,
      col: 5, row: 10, width: 5, height: 1.5,
      date: date,
      format: :short
    )

    header.render
  end
end
