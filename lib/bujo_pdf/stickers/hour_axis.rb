# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # A vertical hour axis: labelled times down the left, a spine, and a rule
    # at each hour reaching across the widget.
    #
    # This is the alignment-sensitive member of the pack. Unlike a grid patch
    # or a quadrant, it is meant to sit *beside* something - a day column, a
    # block of notes - and it looks wrong if its hour rules do not line up
    # with the page's dot grid. One hour is exactly one grid box, so dropped
    # at 100% every rule lands on a dot row.
    class HourAxis < Base
      DEFAULT_START_HOUR = 7   # 7am
      DEFAULT_END_HOUR = 21    # 9pm
      # Width of the time column. Labels are right-aligned against the spine,
      # so any slack here becomes dead space on the left edge; "12p" at 6pt is
      # only ~11pt wide, and two boxes left far more room than it needed.
      LABEL_COLS = 1.5
      DEFAULT_WIDTH_BOXES = 6

      # @return [Array<HourAxis>]
      def self.all
        [new]
      end

      attr_reader :start_hour, :end_hour

      # @param start_hour [Integer] First hour shown, 24h clock
      # @param end_hour [Integer] Last hour shown, 24h clock
      # @param width [Integer] Total width in grid boxes
      def initialize(start_hour: DEFAULT_START_HOUR, end_hour: DEFAULT_END_HOUR,
                     width: DEFAULT_WIDTH_BOXES)
        @start_hour = start_hour
        @end_hour = end_hour
        super(
          slug: "hour_axis_#{start_hour}_#{end_hour}",
          title: "Hour axis, #{clock(start_hour)}-#{clock(end_hour)}",
          width_boxes: width,
          height_boxes: end_hour - start_hour
        )
      end

      def draw(pdf)
        # Spine between the labels and the writing area.
        vrule(pdf, LABEL_COLS, 0, height_boxes, width: 0.6)

        # One box per hour *slot*. There is one more rule than slot, because
        # the last rule closes the final hour rather than opening a new one,
        # and each label names the slot beneath it.
        (0..height_boxes).each { |row| rule(pdf, LABEL_COLS, width_boxes, row) }

        height_boxes.times do |i|
          label(pdf, 0, i, clock(start_hour + i),
                cols: LABEL_COLS - 0.25, rows: 1, size: 6,
                align: :right, valign: :top)
        end
      end

      def self.clock(hour)
        suffix = hour < 12 ? 'a' : 'p'
        display = hour % 12
        display = 12 if display.zero?
        "#{display}#{suffix}"
      end

      private

      def clock(hour)
        self.class.clock(hour)
      end
    end
  end
end
