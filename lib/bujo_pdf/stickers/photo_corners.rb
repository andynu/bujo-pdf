# frozen_string_literal: true

require_relative 'base'
require_relative 'backed'

module BujoPdf
  module Stickers
    # Chamfered corners: the drawing is tucked in behind them.
    #
    # Two readings of the same triangle, and both are wanted. In :dark it is a
    # gummed photo corner, the thing in an album. In :paper it is the page
    # itself - a slit cut in the sheet with the corner of something slid
    # under it.
    #
    # The slit reading is approximate by construction. It only works if the
    # triangle matches the paper behind it, and a sticker cannot know what it
    # will land on, so :paper uses the pack's card colour and accepts being
    # close rather than exact on any theme but the light one.
    class PhotoCorners < Base
      CORNER_BOXES = 3

      # The area the four-corner set frames.
      SET_WIDTH = 16
      SET_HEIGHT = 12

      INKS = {
        dark: { fill: '4A4640', edge: '2E2B27', title: 'dark' },
        paper: { fill: Backed::CARD_COLOR, edge: Backed::BORDER_COLOR, title: 'paper' }
      }.freeze

      EDGE_WIDTH = 0.4

      # Both inks, each as a single corner and as a set of four.
      #
      # The set is the low-friction version - place once, draw inside. The
      # single corner is the flexible one, because the size of the thing being
      # tucked in is not ours to decide.
      #
      # @return [Array<PhotoCorners>]
      def self.all
        INKS.keys.flat_map do |ink|
          [new(ink: ink, layout: :single), new(ink: ink, layout: :set)]
        end
      end

      attr_reader :ink, :layout

      # @param ink [Symbol] Key into {INKS}
      # @param layout [Symbol] :single or :set
      def initialize(ink: :dark, layout: :set)
        spec = INKS.fetch(ink)
        @ink = ink
        @layout = layout
        single = layout == :single
        super(
          slug: "photo_corner#{single ? '' : 's'}_#{spec[:title]}",
          title: "Photo corner#{single ? '' : 's (set of four)'}, #{spec[:title]}",
          width_boxes: single ? CORNER_BOXES : SET_WIDTH,
          height_boxes: single ? CORNER_BOXES : SET_HEIGHT
        )
      end

      # A corner is a thing laid over the page. Backing one would put a card
      # behind the very gap it is meant to be holding something in.
      def backing_shape
        :none
      end

      def draw(pdf)
        if layout == :single
          draw_corner(pdf, 0, 0, 1, 1)
        else
          draw_corner(pdf, 0, 0, 1, 1)
          draw_corner(pdf, width_boxes, 0, -1, 1)
          draw_corner(pdf, 0, height_boxes, 1, -1)
          draw_corner(pdf, width_boxes, height_boxes, -1, -1)
        end
      end

      private

      # One right triangle, its square angle at (col, row) and its hypotenuse
      # facing inward.
      #
      # @param sx [Integer] +1 to build rightward, -1 leftward
      # @param sy [Integer] +1 to build downward from the top, -1 upward
      def draw_corner(pdf, col, row, sx, sy)
        spec = INKS.fetch(ink)
        size = CORNER_BOXES

        square = [bx(col), by(row)]
        along = [bx(col + (sx * size)), by(row)]
        down = [bx(col), by(row + (sy * size))]

        pdf.fill_color spec[:fill]
        pdf.fill_polygon(square, along, down)

        pdf.stroke_color spec[:edge]
        pdf.line_width EDGE_WIDTH
        pdf.stroke_line(along, down)
      end
    end
  end
end
