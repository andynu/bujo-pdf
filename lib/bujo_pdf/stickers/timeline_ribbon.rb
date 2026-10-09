# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # An undated horizontal week: seven segments with a lane to draw across.
    #
    # The complement to the hour axis - that one is a day seen vertically,
    # this is a week seen horizontally. Left undated so it can describe any
    # seven-day stretch, including one that does not start on a Monday.
    class TimelineRibbon < Base
      SEGMENTS = 7
      SEGMENT_COLS = 2
      HEIGHT_ROWS = 3
      LANE_TOP = 0.5      # lane sits inside the height so ticks have room
      LANE_BOTTOM = 2.5
      TICK_ROWS = 0.4

      # @return [Array<TimelineRibbon>]
      def self.all
        [new]
      end

      def initialize
        super(
          slug: 'timeline_ribbon',
          title: "Timeline ribbon, #{SEGMENTS} segments",
          width_boxes: SEGMENTS * SEGMENT_COLS,
          height_boxes: HEIGHT_ROWS
        )
      end

      def draw(pdf)
        # The lane itself: an open channel to draw a span across.
        rule(pdf, 0, width_boxes, LANE_TOP, width: 0.6)
        rule(pdf, 0, width_boxes, LANE_BOTTOM, width: 0.6)

        # Dividers are ticks hanging off the rails rather than lines crossing
        # the lane, so a span drawn through the ribbon is not chopped into
        # segments by its own scale.
        (0..SEGMENTS).each do |i|
          col = i * SEGMENT_COLS
          ends = i.zero? || i == SEGMENTS

          if ends
            vrule(pdf, col, LANE_TOP, LANE_BOTTOM, width: 0.6)
          else
            vrule(pdf, col, LANE_TOP - TICK_ROWS, LANE_TOP, width: 0.4)
            vrule(pdf, col, LANE_BOTTOM, LANE_BOTTOM + TICK_ROWS, width: 0.4)
          end
        end
      end
    end
  end
end
