# frozen_string_literal: true

require_relative 'base'
require_relative 'ornament'

module BujoPdf
  module Stickers
    # An engraved ring: interlaced hypotrochoid curves around an open centre.
    #
    # The other way to make a doily. Where the rosette is forged - heavy bars,
    # discrete motifs, visible joins - this is engraved: one continuous line
    # that never repeats a join, the pattern on banknotes, share certificates
    # and watch dials. The two read as different centuries, which is why both
    # ship.
    #
    # It also costs almost nothing. A rosette needs a motif drawn by hand; a
    # guilloche needs three numbers. The curve a point on a small circle
    # traces while that circle rolls inside a large one does all the work, and
    # has since geometric lathes in the 1700s.
    class Guilloche < Base
      DEFAULT_SIZE_BOXES = 14

      # Ring radius and rolling-circle radius, in arbitrary units - only their
      # ratio matters. The lobe count is fixed_r / gcd(fixed_r, rolling_r).
      PATTERNS = {
        9 => { fixed: 9, rolling: 2 },
        13 => { fixed: 13, rolling: 2 }
      }.freeze

      # How far the tracing point sits from the rolling circle's centre, as a
      # fraction of (fixed - rolling). This is the only band control: at 0 the
      # curve is a plain circle, and as it approaches 1 the open middle closes
      # up entirely.
      OFFSET = 0.38

      # Copies of the curve, each rotated by a third of a lobe. One pass reads
      # as a wavy circle; three interlace into a band.
      PHASES = 3

      SAMPLES = 720

      include Ornament

      # @param size [Integer] Diameter in grid boxes
      # @return [Array<Guilloche>]
      def self.all(size: DEFAULT_SIZE_BOXES)
        PATTERNS.keys.map { |lobes| new(lobes: lobes, size: size) }
      end

      attr_reader :lobes

      # @param lobes [Integer] Key into {PATTERNS}. Below about nine the
      #   curve steps far enough per lobe to cross the band as a chord,
      #   which reads as a tangle rather than as engraving.
      # @param size [Integer] Diameter in grid boxes
      def initialize(lobes: 9, size: DEFAULT_SIZE_BOXES)
        @spec = PATTERNS.fetch(lobes)
        @lobes = lobes
        super(
          slug: "guilloche_#{lobes}",
          title: "Guilloche ring, #{lobes} lobes",
          width_boxes: size,
          height_boxes: size
        )
      end

      # Engraving, like ornament: the page through the middle is the point.
      def backing_shape
        :none
      end

      # Radius of the open middle, in points. Exposed because it is the whole
      # question for this sticker - anything smaller than a couple of boxes is
      # a decoration rather than a place to write.
      #
      # @return [Float]
      def core_radius
        outer_radius * (1.0 - OFFSET) / (1.0 + OFFSET)
      end

      # @return [Float] points
      def outer_radius
        ([width_pt, height_pt].min / 2.0) - Ornament::WEIGHTS[:rim]
      end

      def draw(pdf)
        cx = width_pt / 2.0
        cy = height_pt / 2.0

        draw_rim(pdf, cx, cy)
        PHASES.times do |phase|
          rotation = (360.0 / lobes / PHASES) * phase
          pdf.rotate(rotation, origin: [cx, cy]) do
            polyline(pdf, curve_points(cx, cy), width: Ornament::WEIGHTS[:hair])
          end
        end
      end

      private

      def draw_rim(pdf, cx, cy)
        pdf.stroke_color Ornament::IRON
        pdf.line_width Ornament::WEIGHTS[:bar]
        pdf.stroke_circle [cx, cy], outer_radius
        pdf.line_width Ornament::WEIGHTS[:hair]
        pdf.stroke_circle [cx, cy], core_radius
      end

      # The hypotrochoid itself.
      #
      # The curve closes after rolling/gcd turns, so sampling that whole
      # interval draws every lobe exactly once and joins back to the start.
      def curve_points(cx, cy)
        fixed = @spec[:fixed].to_f
        rolling = @spec[:rolling].to_f
        base = fixed - rolling
        offset = base * OFFSET
        scale = outer_radius / (base + offset)
        turns = rolling / @spec[:rolling].gcd(@spec[:fixed])
        span = 2 * Math::PI * turns

        (0..SAMPLES).map do |i|
          t = span * i / SAMPLES.to_f
          ratio = base / rolling
          x = (base * Math.cos(t)) + (offset * Math.cos(ratio * t))
          y = (base * Math.sin(t)) - (offset * Math.sin(ratio * t))
          [cx + (x * scale), cy + (y * scale)]
        end
      end
    end
  end
end
