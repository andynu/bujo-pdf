# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # A circle divided by radial ticks, with an open centre.
    #
    # Not a pie: the division lines are drawn only in a band inside the rim,
    # so the middle stays clear to write in. This is the geometry the planner's
    # DailyWheel page already uses - concentric rings packed near the edge with
    # spokes crossing only the outer bands - generalised so the segment count
    # and how far the ticks reach inward become parameters.
    #
    # Extracting it here is what makes it usable. As a page it sat at the back
    # of the book, unreachable and (being background rather than annotation)
    # impossible to pick up. As a sticker it can be dropped wherever the
    # thought occurs.
    #
    # @example A clock face with ticks reaching a third of the way in
    #   RadialDivider.new(segments: 12, depth: 0.33)
    class RadialDivider < Base
      DEFAULT_SIZE_BOXES = 10

      # How far ticks reach inward, as a fraction of the radius.
      #
      # :rim matches the DailyWheel page - a narrow band of ticks that reads
      # as a graduated edge. :deep reaches a third of the way in, which makes
      # a stronger ring and leaves room to write between the spokes rather
      # than only in the dead centre.
      DEPTHS = { rim: 0.08, deep: 0.33 }.freeze

      # Segment counts worth generating, with what each reads as.
      SEGMENTS = {
        12 => 'clock face or months',
        24 => 'hours'
      }.freeze

      MAJOR_TICK_WIDTH = 0.7
      MINOR_TICK_WIDTH = 0.3
      CIRCLE_WIDTH = 0.6

      # Build the radial dividers for a sticker pack: every segment count at
      # every depth, so the user can find out which they reach for.
      #
      # @param size [Integer, Float] Diameter in grid boxes
      # @return [Array<RadialDivider>]
      def self.all(size: DEFAULT_SIZE_BOXES)
        SEGMENTS.keys.flat_map do |segments|
          DEPTHS.keys.map { |depth| new(segments: segments, depth: depth, size: size) }
        end
      end

      attr_reader :segments, :depth_name

      # @param segments [Integer] Number of divisions around the circle
      # @param depth [Symbol, Float] Key into {DEPTHS}, or a raw fraction
      # @param size [Integer, Float] Diameter in grid boxes
      def initialize(segments:, depth: :deep, size: DEFAULT_SIZE_BOXES)
        @segments = segments
        @depth_name = depth.is_a?(Symbol) ? depth : :custom
        @depth = depth.is_a?(Symbol) ? DEPTHS.fetch(depth) : depth
        super(
          slug: "radial_#{segments}_#{@depth_name}",
          title: "Radial divider, #{segments} segments (#{@depth_name})",
          width_boxes: size,
          height_boxes: size
        )
      end

      # A ring belongs on a disc, not a rounded square.
      def backing_shape
        :circle
      end

      def draw(pdf)
        cx = width_pt / 2.0
        cy = height_pt / 2.0
        # Inset by the widest stroke so the rim is not clipped by the page edge.
        outer = [cx, cy].min - MAJOR_TICK_WIDTH
        inner = outer * (1.0 - @depth)

        pdf.stroke_color DEFAULT_LINE_COLOR

        draw_rings(pdf, cx, cy, outer, inner)
        draw_ticks(pdf, cx, cy, outer, inner)
      end

      private

      # The rim, plus an inner ring closing the tick band into a track.
      def draw_rings(pdf, cx, cy, outer, inner)
        pdf.line_width CIRCLE_WIDTH
        pdf.stroke_circle [cx, cy], outer
        pdf.stroke_circle [cx, cy], inner
      end

      # Spokes crossing only the band between the two rings.
      #
      # Every quarter turn is drawn heavier, which gives the eye somewhere to
      # land without adding numerals - a sticker has no idea what it is going
      # to be used to measure, so labelling it would be a guess.
      def draw_ticks(pdf, cx, cy, outer, inner)
        step = (2 * Math::PI) / segments
        quarter = segments / 4.0

        segments.times do |i|
          angle = (-Math::PI / 2.0) + (i * step)
          cos_a = Math.cos(angle)
          sin_a = Math.sin(angle)

          major = quarter.positive? && (i % quarter).zero?
          pdf.line_width major ? MAJOR_TICK_WIDTH : MINOR_TICK_WIDTH

          pdf.stroke_line(
            [cx + (cos_a * inner), cy + (sin_a * inner)],
            [cx + (cos_a * outer), cy + (sin_a * outer)]
          )
        end
      end
    end
  end
end
