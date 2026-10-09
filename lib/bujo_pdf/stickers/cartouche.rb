# frozen_string_literal: true

require_relative 'base'
require_relative 'ornament'

module BujoPdf
  module Stickers
    # A horizontal ironwork frame with a clear band across the middle.
    #
    # The rosette's sibling, and probably the more useful of the two: titles
    # are horizontal, so this is the doily you can actually write a phrase in.
    # A cartouche is historically "an unrolled scroll with an oval centre and
    # pierced curled edges", which is exactly the job - scrollwork that exists
    # only to frame a name.
    class Cartouche < Base
      WIDTH_BOXES = 24
      HEIGHT_BOXES = 7

      # The clear band, in boxes from the sticker's edges.
      WELL_LEFT = 5
      WELL_RIGHT = 5
      WELL_TOP = 2
      WELL_BOTTOM = 2

      # Two dressings of the same frame.
      STYLES = {
        scroll: 'scroll',   # volutes running out to both ends
        leaf:   'leaf'      # lance-and-tendril, lighter
      }.freeze

      include Ornament

      # @return [Array<Cartouche>]
      def self.all
        STYLES.keys.map { |style| new(style: style) }
      end

      attr_reader :style

      # @param style [Symbol] Key into {STYLES}
      def initialize(style: :scroll)
        @style = style
        super(
          slug: "cartouche_#{STYLES.fetch(style)}",
          title: "Cartouche, #{STYLES.fetch(style)}",
          width_boxes: WIDTH_BOXES,
          height_boxes: HEIGHT_BOXES
        )
      end

      # Same reason as the rosette: the page showing through is the design.
      def backing_shape
        :none
      end

      def draw(pdf)
        draw_well(pdf)
        draw_ends(pdf)
        draw_finials(pdf)
      end

      private

      # The title band: a double-ruled tablet with bowed ends, so it reads as
      # a cast plate rather than a text box.
      def draw_well(pdf)
        left = bx(WELL_LEFT)
        right = bx(WIDTH_BOXES - WELL_RIGHT)
        top = by(WELL_TOP)
        bottom = by(HEIGHT_BOXES - WELL_BOTTOM)
        bow = bx(0.55)

        [[Ornament::WEIGHTS[:bar], 0.0], [Ornament::WEIGHTS[:hair], 2.0]].each do |width, inset|
          l = left + inset
          r = right - inset
          t = top - inset
          b = bottom + inset

          polyline(pdf, [[l, t], [r, t]], width: width)
          polyline(pdf, [[l, b], [r, b]], width: width)
          # Ends bow outward, which is what makes it a tablet and not a box.
          arc_stroke(pdf, [l, t], [l, b], bow: bow - inset, width: width)
          arc_stroke(pdf, [r, b], [r, t], bow: bow - inset, width: width)
        end
      end

      # Scrollwork running off each end of the well, mirrored left to right.
      def draw_ends(pdf)
        mid = height_pt / 2.0

        [[bx(WELL_LEFT), -1], [bx(WIDTH_BOXES - WELL_RIGHT), 1]].each do |anchor, side|
          case style
          when :scroll then draw_scroll_end(pdf, anchor, mid, side)
          else draw_leaf_end(pdf, anchor, mid, side)
          end
        end
      end

      def draw_scroll_end(pdf, anchor, mid, side)
        reach = bx(4.2)
        tip = anchor + (side * reach)

        # The spine, tapering to a point rather than stopping dead.
        polyline(pdf, [[anchor, mid], [tip, mid]], width: Ornament::WEIGHTS[:bar])

        # A big volute close in to the well and a smaller one beyond it. One
        # pair on its own reads as two stray commas; the second pair, half the
        # size, is what makes the run look like it is unrolling.
        [[0.34, 1.25, Ornament::WEIGHTS[:bar]],
         [0.74, 0.70, Ornament::WEIGHTS[:scroll]]].each do |along, radius, weight|
          [1, -1].each do |vertical|
            volute(pdf,
                   anchor + (side * reach * along), mid + (vertical * bx(radius * 0.62)),
                   inner_r: bx(0.10),
                   outer_r: bx(radius * 0.62),
                   sweep: 330,
                   start_angle: vertical.positive? ? 250 : 110,
                   direction: side * vertical,
                   width: weight)
          end
        end

        rivet(pdf, tip, mid, Ornament::WEIGHTS[:rim] * 0.85)
      end

      def draw_leaf_end(pdf, anchor, mid, side)
        reach = bx(4.2)

        # A symmetrical leaf with a dot at its centre reads as an eye, which
        # is the one thing this must not do. Two offset leaves of different
        # lengths, veined instead of dotted, read as foliage.
        [[1, 1.0, 1.05], [-1, 0.72, 0.72]].each do |vertical, length, half|
          tip = [anchor + (side * reach * length), mid + (vertical * bx(0.55))]
          lance(pdf, [anchor, mid], tip, half_width: bx(half), belly: 0.34,
                                         width: Ornament::WEIGHTS[:bar])
          # The vein: a single stroke down the middle of the leaf.
          arc_stroke(pdf, [anchor, mid], tip,
                     bow: vertical * bx(0.20), width: Ornament::WEIGHTS[:hair])
        end

        volute(pdf, anchor + (side * bx(0.75)), mid - bx(0.95),
               inner_r: bx(0.06), outer_r: bx(0.48),
               sweep: 320, start_angle: side.positive? ? 120 : 60,
               direction: -side, width: Ornament::WEIGHTS[:scroll])
      end

      # Small marks top and bottom centre. Without them the frame is
      # left-right symmetric only, and reads as unfinished at the waist.
      def draw_finials(pdf)
        cx = width_pt / 2.0
        span = bx(0.9)

        [[by(WELL_TOP), 1], [by(HEIGHT_BOXES - WELL_BOTTOM), -1]].each do |edge, direction|
          lance(pdf,
                [cx, edge],
                [cx, edge + (direction * span)],
                half_width: bx(0.34), belly: 0.45,
                width: Ornament::WEIGHTS[:scroll])
        end
      end
    end
  end
end
