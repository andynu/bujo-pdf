# frozen_string_literal: true

require_relative 'base'
require_relative 'ornament'

module BujoPdf
  module Stickers
    # The small marks a book uses to say "this passage is over".
    #
    # Typography has always had punctuation for the end of a thought that is
    # larger than a sentence and smaller than a chapter - the fleuron, the
    # asterism, the dinkus, the tombstone at the end of a proof. A planner
    # page has exactly that problem several times a day and no mark for it.
    #
    # These are the cheapest stickers in the pack and probably the most
    # placed, for the same reason a full stop is the most typed character.
    class Colophon < Base
      MARKS = {
        fleuron: { width: 3, height: 3, title: 'fleuron' },
        asterism: { width: 3, height: 3, title: 'asterism' },
        dinkus: { width: 4, height: 1, title: 'dinkus' },
        tombstone: { width: 2, height: 2, title: 'tombstone' },
        swash: { width: 8, height: 2, title: 'swash rule' }
      }.freeze

      include Ornament

      # @return [Array<Colophon>]
      def self.all
        MARKS.keys.map { |mark| new(mark: mark) }
      end

      attr_reader :mark

      # @param mark [Symbol] Key into {MARKS}
      def initialize(mark:)
        spec = MARKS.fetch(mark)
        @mark = mark
        super(
          slug: "colophon_#{mark}",
          title: "Colophon mark, #{spec[:title]}",
          width_boxes: spec[:width],
          height_boxes: spec[:height]
        )
      end

      # Punctuation, not an object. Nothing here is big enough to card.
      def backing_shape
        :none
      end

      def draw(pdf)
        send(:"draw_#{mark}", pdf)
      end

      private

      # A leaf on a curling stem - the printer's flower.
      def draw_fleuron(pdf)
        cx = width_pt / 2.0
        cy = height_pt / 2.0
        reach = bx(0.95)

        lance(pdf, [cx, cy - reach], [cx, cy + reach],
              half_width: bx(0.46), belly: 0.40, width: Ornament::WEIGHTS[:scroll])

        [1, -1].each do |side|
          volute(pdf, cx + (side * bx(0.62)), cy - bx(0.30),
                 inner_r: bx(0.05), outer_r: bx(0.40),
                 sweep: 320, start_angle: side.positive? ? 150 : 30,
                 direction: side, width: Ornament::WEIGHTS[:hair])
        end
      end

      # Three asterisks in a triangle - the traditional section break.
      def draw_asterism(pdf)
        cx = width_pt / 2.0
        cy = height_pt / 2.0
        spread = bx(0.62)

        [[cx, cy + spread], [cx - spread, cy - (spread * 0.72)], [cx + spread, cy - (spread * 0.72)]]
          .each { |x, y| draw_asterisk(pdf, x, y, bx(0.28)) }
      end

      def draw_asterisk(pdf, x, y, radius)
        pdf.stroke_color Ornament::IRON
        pdf.line_width Ornament::WEIGHTS[:scroll]
        3.times do |i|
          angle = (i * 60 + 90) * Math::PI / 180.0
          dx = Math.cos(angle) * radius
          dy = Math.sin(angle) * radius
          pdf.stroke_line([x - dx, y - dy], [x + dx, y + dy])
        end
      end

      # Three dots. The quietest break there is.
      def draw_dinkus(pdf)
        cy = height_pt / 2.0
        [0.25, 0.5, 0.75].each { |t| rivet(pdf, width_pt * t, cy, 1.1) }
      end

      # The end-of-proof lozenge.
      def draw_tombstone(pdf)
        cx = width_pt / 2.0
        cy = height_pt / 2.0
        r = bx(0.42)

        pdf.fill_color Ornament::IRON
        pdf.fill_polygon([cx, cy + r], [cx + r, cy], [cx, cy - r], [cx - r, cy])
      end

      # A rule that curls at both ends, for breaking a page without a gap.
      def draw_swash(pdf)
        cy = height_pt / 2.0
        inset = bx(1.1)

        polyline(pdf, [[inset, cy], [width_pt - inset, cy]], width: Ornament::WEIGHTS[:scroll])

        [[inset, -1], [width_pt - inset, 1]].each do |x, side|
          volute(pdf, x - (side * bx(0.44)), cy,
                 inner_r: bx(0.06), outer_r: bx(0.44),
                 sweep: 330, start_angle: side.positive? ? 0 : 180,
                 direction: side, width: Ornament::WEIGHTS[:scroll])
        end

        rivet(pdf, width_pt / 2.0, cy, 1.0)
      end
    end
  end
end
