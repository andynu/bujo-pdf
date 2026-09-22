# frozen_string_literal: true

require_relative 'base'
require_relative 'stamp'

module BujoPdf
  module Stickers
    # A circular stamp: a word curved around the rim, a clear centre to date.
    #
    # The roundel is the form officialdom reserves for things that have been
    # *entered into a record* rather than merely judged, which is why it reads
    # differently from the rectangular stamps even carrying the same word. It
    # is also the one stamp with somewhere to write: the middle is left open
    # with two rules across it, so the mark can carry a date.
    class Postmark < Base
      SIZE_BOXES = 12

      # Words that suit a roundel. A rectangle can say ABANDONED; a roundel
      # cannot, because the form implies filing rather than judgement.
      WORDS = {
        'PERMANENT RECORD' => :charcoal,
        'RECEIVED' => :charcoal,
        'ENTERED' => :oxide
      }.freeze

      FONT_SIZE = 7.5
      RIM_WIDTH = 1.3
      TRACK_WIDTH = 0.5
      RULE_WIDTH = 0.4

      # Inner edge of the lettering band, as a fraction of the outer radius.
      # Everything inside it is the open middle where the date goes.
      TRACK_INNER = 0.70

      # @return [Array<Postmark>]
      def self.all
        WORDS.map { |word, ink| new(text: word, ink: ink) } + [new(text: nil, ink: :charcoal)]
      end

      attr_reader :text, :ink

      # @param text [String, nil] Rim lettering; nil leaves the rim plain
      # @param ink [Symbol] Key into {Stamp::INKS}
      def initialize(text:, ink: :charcoal, size: SIZE_BOXES)
        @text = text
        @ink = ink
        super(
          slug: "postmark_#{text ? text.downcase.gsub(/[^a-z0-9]+/, '_') : 'blank'}_#{ink}",
          title: "Postmark: #{text || '(blank)'}, #{ink}",
          width_boxes: size,
          height_boxes: size
        )
      end

      # Ink on the page, like the rectangular stamps.
      def backing_shape
        :none
      end

      # @return [String]
      def color
        Stamp::INKS.fetch(ink)
      end

      def draw(pdf)
        cx = width_pt / 2.0
        cy = height_pt / 2.0
        outer = [cx, cy].min - (RIM_WIDTH / 2.0)

        draw_rings(pdf, cx, cy, outer)
        draw_date_rules(pdf, cx, cy, outer)
        return unless text

        draw_rim_text(pdf, cx, cy, outer)
        draw_foot(pdf, cx, cy, outer)
      end

      private

      def draw_rings(pdf, cx, cy, outer)
        pdf.stroke_color color

        pdf.line_width RIM_WIDTH
        pdf.stroke_circle [cx, cy], outer

        pdf.line_width TRACK_WIDTH
        pdf.stroke_circle [cx, cy], outer * TRACK_INNER
      end

      # Three dots at the foot of the lettering band.
      #
      # Rim text occupies the top of the ring and nothing occupies the bottom,
      # which leaves a roundel looking like it lost half its printing. Real
      # postmarks fill that arc with stars or a second line; three dots are
      # the version that says nothing, which is what we want when we do not
      # know what the stamp is being used for.
      def draw_foot(pdf, cx, cy, outer)
        radius = outer * ((1.0 + TRACK_INNER) / 2.0)
        pdf.fill_color color
        [-20, 0, 20].each do |deg|
          angle = ((270 + deg) * Math::PI) / 180.0
          pdf.fill_circle [cx + (Math.cos(angle) * radius), cy + (Math.sin(angle) * radius)], 1.1
        end
      end

      # Two rules across the open middle. Without them the centre reads as a
      # hole; with them it reads as a field waiting for a date.
      def draw_date_rules(pdf, cx, cy, outer)
        core = outer * TRACK_INNER
        pdf.stroke_color color
        pdf.line_width RULE_WIDTH

        [0.34, -0.34].each do |offset|
          dy = core * offset
          half = Math.sqrt((core * core) - (dy * dy)) * 0.82
          pdf.stroke_line([cx - half, cy + dy], [cx + half, cy + dy])
        end
      end

      # Letters set around the top of the rim, each rotated to stand upright
      # on the circle.
      #
      # Every glyph is advanced by its own width rather than by an even share
      # of the arc, so an I takes less of the circle than a W - the same
      # reason proportional type exists, applied to a curve.
      def draw_rim_text(pdf, cx, cy, outer)
        radius = outer * ((1.0 + TRACK_INNER) / 2.0)
        chars = text.chars
        widths = nil
        pdf.font('Helvetica', style: :bold) do
          widths = chars.map { |ch| pdf.width_of(ch, size: FONT_SIZE) + Stamp::TRACKING }
        end

        # Arc length -> angle. Sum first so the run can be centred on twelve
        # o'clock before any of it is drawn.
        total_deg = widths.sum / radius * 180.0 / Math::PI
        cursor = total_deg / 2.0

        pdf.fill_color color
        pdf.font('Helvetica', style: :bold) do
          chars.each_with_index do |ch, i|
            step = widths[i] / radius * 180.0 / Math::PI
            # Positive rotation is counter-clockwise, so walking the cursor
            # down lays the word out left to right.
            angle = cursor - (step / 2.0)
            cursor -= step

            pdf.rotate(angle, origin: [cx, cy]) do
              pdf.draw_text(ch, at: [cx - (widths[i] / 2.0), cy + radius - FONT_SIZE], size: FONT_SIZE)
            end
          end
        end
      end
    end
  end
end
