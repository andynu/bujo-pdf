# frozen_string_literal: true

module BujoPdf
  module Stickers
    # Drawing vocabulary for the ornamental stickers.
    #
    # The ornament in this pack is *generated*, not traced: a rosette is one
    # motif repeated around a centre, a cartouche is one volute mirrored four
    # ways. That means the whole family needs exactly two primitives - a
    # spiral and a pointed leaf - plus a way to repeat them. Everything else
    # is parameters.
    #
    # Weight is what separates ironwork from wire. A single hairline repeated
    # twelve times reads as a spirograph; the same construction with a heavy
    # rim, medium bars and fine scroll tails reads as something forged. Hence
    # {WEIGHTS} rather than one line width.
    module Ornament
      # Stroke widths, heaviest first. Ironwork is legible because its parts
      # are visibly different thicknesses.
      WEIGHTS = {
        rim: 1.5,     # the outer ring or frame - the structural member
        bar: 0.9,     # ribs and major motif outlines
        scroll: 0.5,  # tails, tendrils, fill work
        hair: 0.3     # the finest detail
      }.freeze

      # A warm dark grey. Ornament is meant to be looked at rather than
      # written over, so it carries more weight than the pack's default
      # hairline grey, and it leans warm so it sits on the earth theme.
      IRON = '7A756C'

      # Repeat a block around a centre point.
      #
      # Prawn's rotate does the trigonometry, so a motif only ever has to be
      # drawn once, at twelve o'clock, in ordinary coordinates.
      #
      # @param count [Integer] Number of repeats
      # @yield [index] Draws one motif in its unrotated position
      def radial_repeat(pdf, cx, cy, count)
        step = 360.0 / count
        count.times do |i|
          pdf.rotate(i * step, origin: [cx, cy]) { yield i }
        end
      end

      # An Archimedean spiral, stroked as a sampled polyline.
      #
      # This is the volute - the rolled-up end of a scroll, and the single
      # most recognisable gesture in wrought iron. Sampling beats beziers
      # here: a spiral needs no control-point fitting, and at sticker scale
      # 6 degrees per segment is already smoother than the paper.
      #
      # @param inner_r [Float] Radius at the tight end
      # @param outer_r [Float] Radius at the open end
      # @param sweep [Float] Total turn in degrees
      # @param start_angle [Float] Where the tight end points, in degrees
      def volute(pdf, cx, cy, inner_r:, outer_r:, sweep: 400, start_angle: 0,
                 width: WEIGHTS[:scroll], color: IRON, direction: 1)
        steps = [(sweep / 6.0).ceil, 8].max
        points = (0..steps).map do |i|
          t = i / steps.to_f
          angle = ((start_angle + (direction * sweep * t)) * Math::PI) / 180.0
          r = inner_r + ((outer_r - inner_r) * t)
          [cx + (Math.cos(angle) * r), cy + (Math.sin(angle) * r)]
        end
        polyline(pdf, points, width: width, color: color)
      end

      # A pointed leaf: two mirrored bezier flanks from a base to a tip.
      #
      # The belly parameter is what stops it looking like an almond. Pushing
      # the widest point back toward the base (belly < 0.5) gives the
      # lance-and-tail silhouette that cast iron uses; centring it gives a
      # symmetrical petal.
      #
      # @param belly [Float] Where the leaf is widest, 0 at base, 1 at tip
      # @param half_width [Float] Half the leaf's widest span, in points
      def lance(pdf, base, tip, half_width:, belly: 0.4,
                width: WEIGHTS[:bar], color: IRON)
        dx = tip[0] - base[0]
        dy = tip[1] - base[1]
        length = Math.sqrt((dx * dx) + (dy * dy))
        return if length.zero?

        ux = dx / length
        uy = dy / length
        # 1.33 is the standard bezier fudge: a control point that far out
        # puts the curve itself at roughly half_width.
        bulge = half_width * 1.33

        pdf.stroke_color color
        pdf.line_width width
        [1, -1].each do |side|
          nx = -uy * bulge * side
          ny = ux * bulge * side
          c1 = [base[0] + (ux * length * belly) + nx, base[1] + (uy * length * belly) + ny]
          c2 = [tip[0] - (ux * length * 0.35) + nx, tip[1] - (uy * length * 0.35) + ny]
          pdf.stroke_curve(base, tip, bounds: [c1, c2])
        end
      end

      # A single bezier arc, given as two control offsets along and across.
      def arc_stroke(pdf, from, to, bow:, width: WEIGHTS[:scroll], color: IRON)
        dx = to[0] - from[0]
        dy = to[1] - from[1]
        length = Math.sqrt((dx * dx) + (dy * dy))
        return if length.zero?

        nx = -dy / length * bow
        ny = dx / length * bow
        c1 = [from[0] + (dx * 0.25) + nx, from[1] + (dy * 0.25) + ny]
        c2 = [from[0] + (dx * 0.75) + nx, from[1] + (dy * 0.75) + ny]

        pdf.stroke_color color
        pdf.line_width width
        pdf.stroke_curve(from, to, bounds: [c1, c2])
      end

      # A filled dot. Cast iron is full of these - rivets, bosses, berries -
      # and they are what keeps a repeated motif from reading as a diagram.
      def rivet(pdf, x, y, radius, color: IRON)
        pdf.fill_color color
        pdf.fill_circle [x, y], radius
      end

      # Stroke a run of points as a single open path.
      def polyline(pdf, points, width: WEIGHTS[:scroll], color: IRON)
        return if points.length < 2

        pdf.stroke_color color
        pdf.line_width width
        pdf.stroke do
          pdf.move_to(points.first)
          points.drop(1).each { |p| pdf.line_to(p) }
        end
      end
    end
  end
end
