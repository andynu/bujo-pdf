#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'digest'

class TestPerspectiveGridRenderer < Minitest::Test
  WIDTH = 612.0
  HEIGHT = 792.0

  # Records drawing operations, running stroke blocks so their lines are seen.
  class Recorder
    attr_reader :ops

    def initialize = @ops = []
    def stroke = yield
    def line(from, to) = @ops << [:line, from.map { |v| v.round(3) }, to.map { |v| v.round(3) }]
    def rectangle(point, width, height) = @ops << [:rect, point.map { |v| v.round(3) }, width.round(3), height.round(3)]
    def dash(*args, **kwargs) = @ops << [:dash, args, kwargs]
    def undash = @ops << [:undash]
    def method_missing(*) = self
    def respond_to_missing?(*) = true

    def lines = @ops.select { |op| op.first == :line }.map { |_, from, to| [from, to] }
  end

  def test_one_point_output_unchanged
    recorder = render(:perspective, num_points: 1, draw_guide_rectangles: true, num_converging: 24, line_width: 0.35)

    # Captured from the renderer before the 2-point options were added
    assert_equal '74fc36fec43d079d8736cdaf7ecbb798aac384912773e0dc251784098e035575',
                 Digest::SHA256.hexdigest(recorder.ops.inspect)
  end

  def test_two_point_draws_no_horizontal_lines_besides_the_horizon
    horizon = (HEIGHT * 0.55).round(3)
    horizontals = two_point.lines.select { |from, to| from[1] == to[1] }

    assert_equal [horizon], horizontals.map { |from, _| from[1] }.uniq
  end

  def test_two_point_draws_vertical_guides_every_two_boxes
    verticals = two_point.lines.select { |from, to| from[0] == to[0] }.map { |from, _| from[0] }.sort

    two_boxes = Styling::Grid::DOT_SPACING * 2
    assert_equal (1..(WIDTH / two_boxes).floor).map { |i| (i * two_boxes).round(3) }, verticals
  end

  def test_two_point_rays_start_at_each_edge_vanishing_point
    horizon = (HEIGHT * 0.55).round(3)
    rays = two_point.lines.reject { |from, to| from[1] == to[1] || from[0] == to[0] }
    from_left = rays.count { |from, to| [from, to].include?([0.0, horizon]) }
    from_right = rays.count { |from, to| [from, to].include?([WIDTH, horizon]) }

    # 4.5 degree steps across +/-81 degrees, minus the horizontal ray
    assert_equal 36, from_left
    assert_equal 36, from_right
  end

  private

  def two_point
    @two_point ||= render(:perspective_2)
  end

  def render(type, **options)
    recorder = Recorder.new
    BujoPdf::Utilities::GridFactory.create(type, recorder, WIDTH, HEIGHT, **options).render
    recorder
  end
end
