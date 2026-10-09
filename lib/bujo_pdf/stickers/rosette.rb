# frozen_string_literal: true

require_relative 'base'
require_relative 'ornament'

module BujoPdf
  module Stickers
    # An ironwork rosette with an open centre: a medallion to write a title in.
    #
    # This is the pack's first purely expressive sticker. It organises nothing
    # and tracks nothing - it declares that the page under it is about
    # something, and it pays off the moment it is placed rather than later if
    # some imposed structure turns out to have been right.
    #
    # The construction is one motif repeated around a centre, which is also
    # how the real thing is made: a cast rosette is a single pattern pulled
    # from one mould and set in a ring.
    class Rosette < Base
      DEFAULT_SIZE_BOXES = 14

      # Fraction of the radius left clear in the middle. Below about a third
      # the hole stops being a place to write and becomes a design feature.
      CORE = 0.38

      # The two moulds.
      #
      # :lance is leaf-and-point work - lighter, closer to a Gothic quatrefoil.
      # :scroll is bar-and-volute - heavier, closer to a gate.
      MOTIFS = {
        lance: { petals: 12, title: 'lance' },
        scroll: { petals: 8, title: 'scroll' }
      }.freeze

      include Ornament

      # @param size [Integer] Diameter in grid boxes
      # @return [Array<Rosette>]
      def self.all(size: DEFAULT_SIZE_BOXES)
        MOTIFS.keys.map { |motif| new(motif: motif, size: size) }
      end

      attr_reader :motif, :petals

      # @param motif [Symbol] Key into {MOTIFS}
      # @param size [Integer] Diameter in grid boxes
      def initialize(motif: :lance, size: DEFAULT_SIZE_BOXES)
        spec = MOTIFS.fetch(motif)
        @motif = motif
        @petals = spec[:petals]
        super(
          slug: "rosette_#{spec[:title]}",
          title: "Rosette, #{spec[:title]} (#{spec[:petals]} petals)",
          width_boxes: size,
          height_boxes: size
        )
      end

      # Ornament is defined by what shows through it. A card behind a rosette
      # fills the negative space that makes it ornament rather than a doodle.
      def backing_shape
        :none
      end

      def draw(pdf)
        cx = width_pt / 2.0
        cy = height_pt / 2.0
        outer = [cx, cy].min - (Ornament::WEIGHTS[:rim] / 2.0)
        inner = outer * CORE

        draw_rings(pdf, cx, cy, outer, inner)
        radial_repeat(pdf, cx, cy, petals) do
          case motif
          when :lance then draw_lance_motif(pdf, cx, cy, inner, outer)
          else draw_scroll_motif(pdf, cx, cy, inner, outer)
          end
        end
      end

      private

      def draw_rings(pdf, cx, cy, outer, inner)
        pdf.stroke_color Ornament::IRON

        pdf.line_width Ornament::WEIGHTS[:rim]
        pdf.stroke_circle [cx, cy], outer

        # A second hairline just inside the rim is the trick that makes a
        # plain circle read as a moulded edge rather than a drawn one.
        pdf.line_width Ornament::WEIGHTS[:hair]
        pdf.stroke_circle [cx, cy], outer - (Ornament::WEIGHTS[:rim] * 1.6)

        pdf.line_width Ornament::WEIGHTS[:bar]
        pdf.stroke_circle [cx, cy], inner
      end

      # A pointed leaf spanning the band, with a tendril curling off its base
      # and a berry where it meets the rim.
      def draw_lance_motif(pdf, cx, cy, inner, outer)
        span = outer - inner
        base = [cx, cy + inner]
        tip = [cx, cy + outer - (span * 0.04)]
        half = (2 * Math::PI * ((inner + outer) / 2.0) / petals) * 0.34

        lance(pdf, base, tip, half_width: half, belly: 0.42)

        [1, -1].each do |side|
          arc_stroke(pdf,
                     [cx, cy + inner + (span * 0.06)],
                     [cx + (side * half * 1.15), cy + inner + (span * 0.46)],
                     bow: side * half * 0.55,
                     width: Ornament::WEIGHTS[:scroll])
        end

        rivet(pdf, cx, cy + inner + (span * 0.08), Ornament::WEIGHTS[:bar] * 0.8)
      end

      # A radial bar with a pair of volutes curling off it - the standard
      # gate panel, shrunk.
      def draw_scroll_motif(pdf, cx, cy, inner, outer)
        span = outer - inner
        polyline(pdf,
                 [[cx, cy + inner], [cx, cy + outer]],
                 width: Ornament::WEIGHTS[:bar])

        [1, -1].each do |side|
          volute(pdf,
                 cx + (side * span * 0.26), cy + inner + (span * 0.46),
                 inner_r: span * 0.06,
                 outer_r: span * 0.40,
                 sweep: 290,
                 start_angle: side.positive? ? 170 : 10,
                 direction: side,
                 width: Ornament::WEIGHTS[:bar])
        end

        # Tie each volute back to the bar. Unattached curls read as two
        # separate marks that happen to be adjacent; a stem makes the cell one
        # forged piece, which is the whole difference between scrollwork and
        # scribble.
        [1, -1].each do |side|
          arc_stroke(pdf,
                     [cx, cy + inner + (span * 0.12)],
                     [cx + (side * span * 0.20), cy + inner + (span * 0.40)],
                     bow: side * span * 0.07,
                     width: Ornament::WEIGHTS[:scroll])
        end

        rivet(pdf, cx, cy + inner + (span * 0.10), Ornament::WEIGHTS[:scroll] * 1.3)
        rivet(pdf, cx, cy + outer - (span * 0.08), Ornament::WEIGHTS[:bar])
      end
    end
  end
end
