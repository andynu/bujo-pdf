#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'pdf-reader'

class TestWeeklyPage < Minitest::Test
  include Styling::Colors

  def content_stream(week_num)
    pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(pdf, 'page_dots')
    context = BujoPdf::RenderContext.new(
      page_key: :"week_#{week_num}", page_number: 1,
      year: 2026, total_weeks: 53, week_num: week_num
    )
    BujoPdf::Pages::WeeklyPage.new(pdf, context).generate
    PDF::Reader.new(StringIO.new(pdf.render)).page(1).raw_content
  end

  def fill_op(hex)
    rgb = hex.scan(/../).map { |pair| format('%.5f', pair.to_i(16) / 255.0).sub(/0+\z/, '').sub(/\.\z/, '.0') }
    "#{rgb.join(' ')} scn"
  end

  def test_night_bands_are_drawn_before_any_dot_grid
    raw = content_stream(51) # mid December: long evenings

    night = raw.index(fill_op(color_night_bg))
    dots = raw.index('Do')

    refute_nil night, 'expected night tint on a December week'
    assert_operator night, :<, dots
  end
end
