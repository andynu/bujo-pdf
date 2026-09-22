# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # An adhesive index flag: a small opaque tab that points at something.
    #
    # The expressive answer to a problem the analytical widgets kept failing.
    # A bracket or an arrow says "these lines belong together", which is a
    # structural claim you have to work out before you can make it. A flag
    # says "here", which you already know.
    #
    # Left pointing right, because that is how they are drawn; a note app
    # rotates a sticker freely, so one shape covers every direction.
    class FlagTag < Base
      WIDTH_BOXES = 4
      HEIGHT_BOXES = 2

      # Muted enough to sit on a planner page without shouting over the
      # handwriting it is pointing at.
      COLORS = {
        clay: { fill: 'C08063', edge: '9A6047', title: 'clay' },
        sage: { fill: '93A382', edge: '6F7E60', title: 'sage' },
        slate: { fill: '7E8FA3', edge: '5E6C7E', title: 'slate' }
      }.freeze

      SHAPES = {
        pennant: 'pennant',   # a triangular point
        tab: 'tab',           # a plain rounded tab
        notch: 'notch'        # a ribbon end, cut inward
      }.freeze

      EDGE_WIDTH = 0.5
      CORNER_RADIUS = 1.5
      # The adhesive end of a real index flag is clear film. Lightening the
      # left third is what separates a flag from a coloured rectangle.
      GRIP_BOXES = 1.3
      GRIP_ALPHA = 0.45

      # @return [Array<FlagTag>]
      def self.all
        SHAPES.keys.flat_map do |shape|
          COLORS.keys.map { |color| new(shape: shape, color: color) }
        end
      end

      attr_reader :shape, :color_name

      # @param shape [Symbol] Key into {SHAPES}
      # @param color [Symbol] Key into {COLORS}
      def initialize(shape: :pennant, color: :clay)
        @shape = shape
        @color_name = color
        super(
          slug: "flag_#{SHAPES.fetch(shape)}_#{COLORS.fetch(color)[:title]}",
          title: "Flag tag, #{SHAPES.fetch(shape)}, #{COLORS.fetch(color)[:title]}",
          width_boxes: WIDTH_BOXES,
          height_boxes: HEIGHT_BOXES
        )
      end

      # An object lying on the page, already opaque. A card would just put a
      # second, larger rectangle behind it.
      def backing_shape
        :none
      end

      # @return [Hash]
      def palette
        COLORS.fetch(color_name)
      end

      def draw(pdf)
        pdf.fill_color palette[:fill]
        pdf.stroke_color palette[:edge]
        pdf.line_width EDGE_WIDTH

        case shape
        when :tab then draw_tab(pdf)
        else draw_polygon_flag(pdf)
        end

        draw_grip(pdf)
      end

      private

      def draw_tab(pdf)
        inset = EDGE_WIDTH / 2.0
        pdf.fill_and_stroke_rounded_rectangle(
          [inset, height_pt - inset],
          width_pt - (inset * 2),
          height_pt - (inset * 2),
          CORNER_RADIUS
        )
      end

      def draw_polygon_flag(pdf)
        inset = EDGE_WIDTH / 2.0
        top = height_pt - inset
        bottom = inset
        left = inset
        right = width_pt - inset
        mid = height_pt / 2.0
        cut = bx(0.9)

        points =
          if shape == :pennant
            [[left, top], [right - cut, top], [right, mid], [right - cut, bottom], [left, bottom]]
          else
            [[left, top], [right, top], [right - cut, mid], [right, bottom], [left, bottom]]
          end

        pdf.fill_and_stroke_polygon(*points)
      end

      # The clear adhesive end, faked by laying a pale wash over the left of
      # whatever shape was just drawn.
      def draw_grip(pdf)
        pdf.transparent(GRIP_ALPHA) do
          pdf.fill_color 'FFFFFF'
          pdf.fill_rectangle([EDGE_WIDTH, height_pt - EDGE_WIDTH],
                             bx(GRIP_BOXES), height_pt - (EDGE_WIDTH * 2))
        end
      end
    end
  end
end
