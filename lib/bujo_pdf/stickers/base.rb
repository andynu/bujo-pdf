# frozen_string_literal: true

require_relative '../utilities/styling'

module BujoPdf
  # Stickers are standalone widgets exported as transparent PNGs for import
  # into a note-taking app's sticker library.
  #
  # They exist because of a structural limit in Noteshelf and GoodNotes: an
  # imported PDF is the page *background*, and the lasso tool only selects
  # annotations created inside the app. Anything the planner draws is scenery -
  # it cannot be picked up, duplicated or moved. The only way to hand the user
  # a reusable widget is to ship it as an image the app treats as an
  # annotation, which means a PNG in the sticker library.
  #
  # A corollary shapes what belongs here: a widget is sticker-ready exactly
  # when it holds no opinion about the size of the page it sits on. Patterns
  # that encode a page-scale construction (a perspective grid's vanishing
  # point, a lined page's margin rule) degrade into noise when shrunk.
  module Stickers
    # Base class for a single sticker.
    #
    # Subclasses declare their size in grid boxes and draw into a Prawn
    # document whose page is exactly that size, so the page edge crops any
    # overflow for free. Sizing in grid boxes rather than points is what lets
    # a placed sticker line up with the planner's dot grid: dropped at 100%,
    # a 10-box-wide patch spans exactly ten dots.
    class Base
      include Styling::Colors

      # Points per grid box, matching the planner's dot spacing.
      BOX = Styling::Grid::DOT_SPACING

      # Default ink for sticker line work. Deliberately neutral so a sticker
      # reads the same on every theme - it is placed by the user, and we have
      # no way to know what is underneath it.
      DEFAULT_LINE_COLOR = 'AAAAAA'
      DEFAULT_LINE_WIDTH = 0.4

      attr_reader :slug, :title, :width_boxes, :height_boxes

      # @param slug [String] Filename stem, snake_case
      # @param title [String] Human-readable name
      # @param width_boxes [Integer, Float] Width in grid boxes
      # @param height_boxes [Integer, Float] Height in grid boxes
      def initialize(slug:, title:, width_boxes:, height_boxes:)
        @slug = slug
        @title = title
        @width_boxes = width_boxes
        @height_boxes = height_boxes
      end

      # @return [Float] Width in points
      def width_pt
        width_boxes * BOX
      end

      # @return [Float] Height in points
      def height_pt
        height_boxes * BOX
      end

      # @return [String] e.g. "10x10"
      def size_label
        "#{fmt(width_boxes)}x#{fmt(height_boxes)}"
      end

      # @return [String] Filename stem including size
      def filename
        "#{slug}_#{size_label}"
      end

      # Shape of the card this sticker wants when backed.
      #
      # A round widget on a square card reads as a sticker of the wrong shape,
      # so a sticker gets to say what outline suits it.
      #
      # @return [Symbol] :rect or :circle
      def backing_shape
        :rect
      end

      # Draw the sticker.
      #
      # The document's page is exactly {#width_pt} x {#height_pt} with no
      # margin, so the drawing origin is the sticker's bottom-left corner.
      #
      # @param pdf [Prawn::Document]
      # @return [void]
      def draw(pdf)
        raise NotImplementedError, "#{self.class} must implement #draw"
      end

      protected

      # Horizontal position of a box column, from the left edge.
      #
      # @param boxes [Integer, Float]
      # @return [Float] points
      def bx(boxes)
        boxes * BOX
      end

      # Vertical position of a box row, measured from the *top* edge.
      #
      # Mirrors the planner's grid convention (row 0 at the top) so widget
      # layout code reads the same as page layout code, even though Prawn's
      # own origin is bottom-left.
      #
      # @param boxes [Integer, Float]
      # @return [Float] points
      def by(boxes)
        height_pt - (boxes * BOX)
      end

      # A horizontal rule spanning the given box columns.
      def rule(pdf, from_col, to_col, row, width: DEFAULT_LINE_WIDTH, color: DEFAULT_LINE_COLOR)
        pdf.stroke_color color
        pdf.line_width width
        pdf.stroke_line([bx(from_col), by(row)], [bx(to_col), by(row)])
      end

      # A vertical rule spanning the given box rows.
      def vrule(pdf, col, from_row, to_row, width: DEFAULT_LINE_WIDTH, color: DEFAULT_LINE_COLOR)
        pdf.stroke_color color
        pdf.line_width width
        pdf.stroke_line([bx(col), by(from_row)], [bx(col), by(to_row)])
      end

      # An unfilled rectangle in box coordinates.
      def frame(pdf, col, row, cols, rows, width: DEFAULT_LINE_WIDTH, color: DEFAULT_LINE_COLOR, radius: nil)
        pdf.stroke_color color
        pdf.line_width width
        if radius
          pdf.stroke_rounded_rectangle([bx(col), by(row)], bx(cols), bx(rows), radius)
        else
          pdf.stroke_rectangle([bx(col), by(row)], bx(cols), bx(rows))
        end
      end

      # Small text placed in box coordinates.
      def label(pdf, col, row, text, size: 7, cols: 4, rows: 1,
                align: :left, valign: :center, style: :normal, color: '777777')
        pdf.fill_color color
        pdf.font('Helvetica', style: style) do
          pdf.text_box text,
                       at: [bx(col), by(row)],
                       width: bx(cols),
                       height: bx(rows),
                       size: size,
                       align: align,
                       valign: valign,
                       overflow: :shrink_to_fit
        end
      end

      private

      def fmt(value)
        value == value.to_i ? value.to_i.to_s : value.to_s
      end
    end
  end
end
