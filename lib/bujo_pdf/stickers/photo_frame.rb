# frozen_string_literal: true

require_relative 'base'
require_relative 'backed'

module BujoPdf
  module Stickers
    # An instant-film frame: an opaque border with a clear window to draw in.
    #
    # The only sticker in the pack that improves what you put *inside* it. A
    # doodle on a planner page is a doodle; the same doodle with a white
    # border and a caption strip under it is a photograph of something, and
    # gets treated as worth keeping. That is a real effect and it costs four
    # filled rectangles.
    #
    # The border has to be painted rather than left transparent, because the
    # whole illusion is that the page does *not* show through the surround.
    # That is also why this sticker refuses a card: the card would fill the
    # window too.
    class PhotoFrame < Base
      # Border widths in boxes. The deep bottom edge is the caption strip, and
      # it is the single feature that makes the shape read as instant film
      # rather than as a picture frame.
      SIDE = 1.5
      TOP = 1.5
      CAPTION = 4.5

      FORMATS = {
        portrait: { width: 16, height: 20, title: 'portrait' },
        wide: { width: 22, height: 16, title: 'wide' }
      }.freeze

      FACE_COLOR = Backed::CARD_COLOR
      EDGE_COLOR = Backed::BORDER_COLOR
      WINDOW_COLOR = 'C8C2B6'

      EDGE_WIDTH = 0.5
      WINDOW_WIDTH = 0.4
      CORNER_RADIUS = 2.0

      # @return [Array<PhotoFrame>]
      def self.all
        FORMATS.keys.map { |format| new(format: format) }
      end

      attr_reader :format

      # @param format [Symbol] Key into {FORMATS}
      def initialize(format: :portrait)
        spec = FORMATS.fetch(format)
        @format = format
        super(
          slug: "photo_frame_#{spec[:title]}",
          title: "Photo frame, #{spec[:title]}",
          width_boxes: spec[:width],
          height_boxes: spec[:height]
        )
      end

      # The frame paints its own surround; a card would paint the window shut.
      def backing_shape
        :none
      end

      # The drawable area, in boxes: [col, row, cols, rows] from the top left.
      #
      # @return [Array<Float>]
      def window
        [SIDE, TOP, width_boxes - (SIDE * 2), height_boxes - TOP - CAPTION]
      end

      def draw(pdf)
        col, row, cols, rows = window

        draw_face(pdf)
        draw_border_edge(pdf)

        # Punch the window back out of the painted face.
        pdf.fill_color FACE_COLOR
        pdf.stroke_color WINDOW_COLOR
        pdf.line_width WINDOW_WIDTH
        clear_window(pdf, col, row, cols, rows)
      end

      private

      # Paint the surround as four strips rather than one rectangle with a
      # hole. Prawn has no compound-path fill, and four rectangles are exact.
      def draw_face(pdf)
        col, row, cols, rows = window
        pdf.fill_color FACE_COLOR

        pdf.fill_rectangle([0, height_pt], width_pt, bx(row))                       # top
        pdf.fill_rectangle([0, by(row + rows)], width_pt, bx(CAPTION))              # caption
        pdf.fill_rectangle([0, by(row)], bx(col), bx(rows))                         # left
        pdf.fill_rectangle([bx(col + cols), by(row)], bx(SIDE), bx(rows))           # right
      end

      def draw_border_edge(pdf)
        pdf.stroke_color EDGE_COLOR
        pdf.line_width EDGE_WIDTH
        inset = EDGE_WIDTH / 2.0
        pdf.stroke_rounded_rectangle(
          [inset, height_pt - inset],
          width_pt - (inset * 2),
          height_pt - (inset * 2),
          CORNER_RADIUS
        )
      end

      # A hairline around the window sells the edge of the print. Without it
      # the transparent area reads as a hole in the sticker.
      def clear_window(pdf, col, row, cols, rows)
        pdf.stroke_rectangle([bx(col), by(row)], bx(cols), bx(rows))
      end
    end
  end
end
