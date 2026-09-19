# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # Wraps a sticker in an opaque card so it reads as a physical sticker.
    #
    # A transparent sticker lets the planner's dot grid show through, which
    # makes it look like an overlay rather than a thing sitting on the page.
    # A card gives the widget its own surface: the grid stops at the edge and
    # the content inside belongs to the sticker.
    #
    # The card is content plus a half-box gutter on every side, so a 10x10
    # patch becomes an 11x11 sticker - still whole boxes, so it still lands on
    # the grid when placed at 100%.
    #
    # Note what the backing costs and buys. Alignment of the *content* to the
    # page grid stops mattering, because the card hides the grid underneath;
    # only the card's own placement matters now. That makes the card a good
    # trade for free-floating widgets and a questionable one for the hour
    # axis, whose whole purpose is to line up with something beside it.
    class Backed < Base
      GUTTER_BOXES = 0.5
      CORNER_RADIUS_BOXES = 0.5

      # A warm near-white: reads as a card on the light and earth themes
      # without the glare of pure white.
      CARD_COLOR = 'FDFCFA'
      BORDER_COLOR = 'D5D0C6'
      BEVEL_COLOR = 'FFFFFF'
      BEVEL_SHADE = 'C9C3B7'

      BEVEL_INSET = 1.0     # points
      BEVEL_ALPHA = 0.9

      # Wrap each of the given stickers in a card.
      #
      # @param stickers [Array<Base>]
      # @return [Array<Backed>]
      def self.wrap(stickers)
        stickers.map { |sticker| new(sticker: sticker) }
      end

      attr_reader :inner, :gutter

      # @param sticker [Base] The widget to sit on the card
      # @param gutter [Float] Padding around the content, in grid boxes
      def initialize(sticker:, gutter: GUTTER_BOXES)
        @inner = sticker
        @gutter = gutter
        super(
          slug: "#{sticker.slug}_card",
          title: "#{sticker.title} (card)",
          width_boxes: sticker.width_boxes + (gutter * 2),
          height_boxes: sticker.height_boxes + (gutter * 2)
        )
      end

      def draw(pdf)
        draw_face(pdf)
        draw_content(pdf)
        draw_bevel(pdf)
        draw_border(pdf)
      end

      private

      def radius
        bx(CORNER_RADIUS_BOXES)
      end

      # The opaque surface. This is the part that stops the page's dot grid.
      #
      # The card fills the page exactly, with no cast shadow. An offset drop
      # shadow would leave a strip of transparent page along two edges, which
      # reads as a misaligned crop once the sticker is placed on a busy page.
      # The bevel below supplies the raised look without that gap.
      def draw_face(pdf)
        pdf.fill_color CARD_COLOR
        pdf.fill_rounded_rectangle([0, height_pt], width_pt, height_pt, radius)
      end

      # Draw the widget inside a clipping path matching the content area.
      #
      # Some patterns tile past the frame they are given - the hexagon grid
      # relies on being cropped rather than stopping on its own - so without a
      # clip they bleed into the gutter and out through the rounded corners,
      # where nothing can paint over them because that area has to stay
      # transparent.
      #
      # Prawn exposes no clip helper, but the PDF operator is available: build
      # the path with #rectangle, then "W n" to intersect the clip region and
      # end the path without painting it.
      def draw_content(pdf)
        pdf.save_graphics_state
        pdf.rectangle([bx(gutter), height_pt - bx(gutter)],
                      inner.width_pt, inner.height_pt)
        pdf.add_content('W n')
        pdf.translate(bx(gutter), bx(gutter)) { inner.draw(pdf) }
        pdf.restore_graphics_state
      end

      # A light lip on the inside edge, plus a faint shade just inside it, to
      # suggest thickness without a cast shadow.
      def draw_bevel(pdf)
        pdf.transparent(BEVEL_ALPHA) do
          pdf.stroke_color BEVEL_COLOR
          pdf.line_width 1.4
          pdf.stroke_rounded_rectangle(
            [BEVEL_INSET, height_pt - BEVEL_INSET],
            width_pt - (BEVEL_INSET * 2),
            height_pt - (BEVEL_INSET * 2),
            [radius - BEVEL_INSET, 0].max
          )
        end

        pdf.transparent(0.35) do
          pdf.stroke_color BEVEL_SHADE
          pdf.line_width 0.5
          pdf.stroke_rounded_rectangle(
            [BEVEL_INSET * 2, height_pt - (BEVEL_INSET * 2)],
            width_pt - (BEVEL_INSET * 4),
            height_pt - (BEVEL_INSET * 4),
            [radius - (BEVEL_INSET * 2), 0].max
          )
        end
      end

      def draw_border(pdf)
        pdf.stroke_color BORDER_COLOR
        pdf.line_width 0.7
        pdf.stroke_rounded_rectangle([0, height_pt], width_pt, height_pt, radius)
      end
    end
  end
end
