# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # Two or three overlapping circles.
    #
    # The one analytical shape that survived, and it survived on the fidelity
    # argument rather than the repetition one: nothing here is tedious, but
    # two circles of visibly equal size with a clean overlap cannot be drawn
    # freehand, and a Venn with unequal circles reads as a claim about the
    # sets rather than an accident of the drawing.
    class Venn < Base
      # Circle radius and centre separation, in boxes. Separation is 1.2x the
      # radius, which is the classic proportion - enough overlap to write in,
      # not so much that the outer lunes vanish.
      RADIUS = 5
      SEPARATION = 6

      LINE_WIDTH = 0.7
      LINE_COLOR = '8C8C8C'

      COUNTS = [2, 3].freeze

      # @return [Array<Venn>]
      def self.all
        COUNTS.map { |count| new(circles: count) }
      end

      attr_reader :circles

      # @param circles [Integer] 2 or 3
      def initialize(circles: 2)
        raise ArgumentError, "Venn supports #{COUNTS.join(' or ')} circles" unless COUNTS.include?(circles)

        @circles = circles
        super(
          slug: "venn_#{circles}",
          title: "Venn, #{circles} circles",
          width_boxes: SEPARATION + (RADIUS * 2),
          height_boxes: circles == 2 ? RADIUS * 2 : SEPARATION + (RADIUS * 2)
        )
      end

      def draw(pdf)
        pdf.stroke_color LINE_COLOR
        pdf.line_width LINE_WIDTH
        centres.each { |centre| pdf.stroke_circle centre, bx(RADIUS) }
      end

      # Centres in points, bottom-left origin.
      #
      # @return [Array<Array<Float>>]
      def centres
        cx = width_pt / 2.0
        cy = height_pt / 2.0
        half = bx(SEPARATION) / 2.0

        return [[cx - half, cy], [cx + half, cy]] if circles == 2

        # Equilateral: two along the bottom, one above, all the same distance
        # apart, then centred in whatever whole-box page that needs.
        rise = bx(SEPARATION) * Math.sqrt(3) / 2.0
        base = cy - (rise / 2.0)
        [[cx - half, base], [cx + half, base], [cx, base + rise]]
      end
    end
  end
end
