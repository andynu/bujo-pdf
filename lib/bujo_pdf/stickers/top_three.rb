# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # Three numbered lines with checkboxes.
    #
    # The smallest widget in the pack, and the one whose value is least about
    # drawing effort - three lines are easy to rule by hand. It earns its
    # place by being a *commitment device*: a box with exactly three slots
    # refuses a fourth in a way a blank area never does.
    class TopThree < Base
      COUNT = 3
      TITLE = 'TOP 3'
      TITLE_ROWS = 1.5
      ROW_HEIGHT = 1.5
      DEFAULT_WIDTH_BOXES = 12

      # @return [Array<TopThree>]
      def self.all
        [new]
      end

      # @param width [Integer] Width in grid boxes
      def initialize(width: DEFAULT_WIDTH_BOXES)
        super(
          slug: 'top_three',
          title: 'Top three',
          width_boxes: width,
          height_boxes: TITLE_ROWS + (COUNT * ROW_HEIGHT)
        )
      end

      def draw(pdf)
        label(pdf, 0, 0, TITLE,
              cols: width_boxes, rows: TITLE_ROWS, size: 7,
              align: :left, style: :bold, color: '888888')

        COUNT.times do |i|
          row = TITLE_ROWS + (i * ROW_HEIGHT)
          draw_checkbox(pdf, row)
          rule(pdf, 1.6, width_boxes, row + ROW_HEIGHT - 0.3)
        end
      end

      private

      def draw_checkbox(pdf, row)
        frame(pdf, 0.1, row + 0.2, 1, 1, radius: 1)
      end
    end
  end
end
