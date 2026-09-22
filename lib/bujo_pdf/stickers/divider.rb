# frozen_string_literal: true

require_relative 'base'
require_relative 'ornament'

module BujoPdf
  module Stickers
    # An ornamental rule with a gap in the middle to write a word in.
    #
    # The cartouche's cheap cousin, and the one likelier to be reached for
    # daily. A cartouche announces that a whole page is about something; this
    # only says that one thing ended and another began, which happens several
    # times on a page that is going well.
    #
    # The gap is the entire design. A rule with a word floating over it reads
    # as a correction; a rule that stops, leaves room, and starts again reads
    # as a heading.
    class Divider < Base
      WIDTH_BOXES = 24
      HEIGHT_BOXES = 2

      # Boxes of clear space in the middle. Six boxes is 3cm, which takes a
      # short word at handwriting size without the rule crowding it.
      GAP_BOXES = 6

      STYLES = {
        plain: 'plain',     # tapered rules, a lozenge at each inner end
        scroll: 'scroll'    # volutes turning back from the gap
      }.freeze

      include Ornament

      # @return [Array<Divider>]
      def self.all
        STYLES.keys.map { |style| new(style: style) }
      end

      attr_reader :style

      # @param style [Symbol] Key into {STYLES}
      def initialize(style: :plain)
        @style = style
        super(
          slug: "divider_#{STYLES.fetch(style)}",
          title: "Divider with title gap, #{STYLES.fetch(style)}",
          width_boxes: WIDTH_BOXES,
          height_boxes: HEIGHT_BOXES
        )
      end

      # Ornament again: a card here would draw a box around a gap whose whole
      # job is to be open.
      def backing_shape
        :none
      end

      # Where the writing goes: [col, cols] in boxes.
      #
      # @return [Array<Float>]
      def gap
        [(WIDTH_BOXES - GAP_BOXES) / 2.0, GAP_BOXES]
      end

      def draw(pdf)
        gap_start, gap_width = gap
        mid = height_pt / 2.0

        [[0, bx(gap_start), 1], [bx(gap_start + gap_width), width_pt, -1]].each do |from, to, side|
          # side is +1 for the left arm, so its inner end is at `to`.
          inner = side.positive? ? to : from
          polyline(pdf, [[from, mid], [to, mid]], width: Ornament::WEIGHTS[:scroll])
          draw_terminal(pdf, inner, mid, side)
        end
      end

      private

      def draw_terminal(pdf, x, mid, side)
        if style == :plain
          r = bx(0.28)
          pdf.fill_color Ornament::IRON
          pdf.fill_polygon([x, mid + r], [x - (side * r * 1.5), mid], [x, mid - r],
                           [x + (side * r * 1.5), mid])
          return
        end

        [1, -1].each do |vertical|
          volute(pdf,
                 x - (side * bx(0.60)), mid + (vertical * bx(0.42)),
                 inner_r: bx(0.07), outer_r: bx(0.48),
                 sweep: 330,
                 start_angle: vertical.positive? ? 250 : 110,
                 direction: side * vertical,
                 width: Ornament::WEIGHTS[:hair])
        end
        rivet(pdf, x, mid, 1.3)
      end
    end
  end
end
