# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # A rubber stamp: a framed word that passes judgement on whatever it lands
    # on.
    #
    # Every other widget in this pack is a container you commit to *before*
    # writing. A stamp is the opposite - it is applied afterwards, to something
    # that already exists, and it asks nothing of you but the verdict you had
    # anyway. That is the lowest-ritual thing a sticker can be, which is why
    # this is the one family that fits a present-tense user without
    # qualification.
    #
    # It is also the only family that deliberately breaks the pack's neutral
    # grey. Every other sticker sits *under* handwriting and stays quiet so it
    # works on any theme. A stamp sits *over* handwriting, and a stamp that
    # whispers is not a stamp.
    class Stamp < Base
      # Stamp inks. Both are muted - this is an ink pad, not a highlighter.
      INKS = {
        oxide: '9C4636',     # the classic stamp red, dulled toward rust
        charcoal: '44464A'   # archival, for marks about provenance
      }.freeze

      # The vocabulary, grouped by what the stamp actually asserts.
      #
      # The group picks the default ink, which is a semantic choice rather
      # than a decorative one: verdicts, prompts and states are assertions and
      # should be loud, while provenance marks are library stamps and should
      # be quiet. The other ink for every word is still available behind
      # --all, the same way the dot grid patch is.
      GROUPS = {
        verdict:    { ink: :oxide,    words: ['SUCCESS', 'FAILED', 'WORKED', "DIDN'T WORK"] },
        provenance: { ink: :charcoal, words: %w[DRAFT VERIFIED REFERENCE] + ['PERMANENT RECORD'] },
        generative: { ink: :oxide,    words: %w[IDEA HYPOTHESIS QUESTION] },
        status:     { ink: :oxide,    words: %w[BLOCKED WAITING REVISIT ABANDONED SHIPPED] }
      }.freeze

      HEIGHT_BOXES = 2
      BLANK_WIDTH_BOXES = 10

      FONT_SIZE = 9
      # Letter spacing is most of the stamp look, and the only lever available
      # while the pack ships no font of its own: built-in Helvetica-Bold set
      # tight reads as a button label, set loose it reads as stamped.
      TRACKING = 1.6

      FRAME_WIDTH = 1.2
      INNER_FRAME_WIDTH = 0.4
      INNER_INSET = 1.8       # points between the two frame rules
      SIDE_PADDING = 0.72     # boxes of clear space each side of the word

      class << self
        # The stamp pack.
        #
        # @param all [Boolean] Also emit every word in its non-default ink
        # @return [Array<Stamp>]
        def all(all: false)
          stamps = GROUPS.each_value.flat_map do |spec|
            inks = all ? INKS.keys : [spec[:ink]]
            spec[:words].flat_map { |word| inks.map { |ink| new(text: word, ink: ink) } }
          end

          # A blank frame ships in both inks regardless: the word is yours, so
          # we cannot know which register it belongs in.
          stamps + INKS.keys.map { |ink| new(text: nil, ink: ink) }
        end

        # A shared document used only to measure text.
        #
        # A stamp has to know its own width at construction time, before any
        # real document exists, and guessing from character counts puts
        # "SHIPPED" and "QUESTION" on different box widths for no visible
        # reason. Measuring is exact and costs one throwaway document.
        #
        # @return [Prawn::Document]
        def measurer
          @measurer ||= Prawn::Document.new
        end

        # @return [Float] points
        def text_width(text)
          doc = measurer
          measured = nil
          # Prawn's font block returns the font, not the block's value.
          doc.font('Helvetica', style: :bold) { measured = doc.width_of(text, size: FONT_SIZE) }
          measured + (TRACKING * text.length)
        end
      end

      attr_reader :text, :ink

      # @param text [String, nil] The word, in caps; nil for a blank frame
      # @param ink [Symbol] Key into {INKS}
      def initialize(text:, ink: :oxide)
        @text = text
        @ink = ink
        super(
          slug: "stamp_#{text ? slugify(text) : 'blank'}_#{ink}",
          title: "Stamp: #{text || '(blank)'}, #{ink}",
          width_boxes: self.class.width_boxes_for(text),
          height_boxes: HEIGHT_BOXES
        )
      end

      # Width in whole boxes that fits the word plus its padding.
      #
      # @return [Integer]
      def self.width_boxes_for(text)
        return BLANK_WIDTH_BOXES if text.nil?

        needed = text_width(text) + (SIDE_PADDING * 2 * BOX)
        [(needed / BOX).ceil, 5].max
      end

      # A stamp is ink on the page, not an object sitting on it. Backing one
      # would turn a mark into a label.
      def backing_shape
        :none
      end

      # @return [String] the hex colour this stamp prints in
      def color
        INKS.fetch(ink)
      end

      def draw(pdf)
        draw_frame(pdf)
        draw_word(pdf) if text
      end

      private

      def draw_frame(pdf)
        pdf.stroke_color color

        inset = FRAME_WIDTH / 2.0
        pdf.line_width FRAME_WIDTH
        pdf.stroke_rectangle(
          [inset, height_pt - inset],
          width_pt - (inset * 2),
          height_pt - (inset * 2)
        )

        inner = inset + INNER_INSET
        pdf.line_width INNER_FRAME_WIDTH
        pdf.stroke_rectangle(
          [inner, height_pt - inner],
          width_pt - (inner * 2),
          height_pt - (inner * 2)
        )
      end

      def draw_word(pdf)
        pdf.fill_color color
        pdf.font('Helvetica', style: :bold) do
          pdf.character_spacing(TRACKING) do
            # Tracking adds a trailing gap after the last letter, which
            # centring then counts as ink. Nudging right by half of it puts
            # the letters themselves back on the centre line.
            pdf.text_box text,
                         at: [TRACKING / 2.0, height_pt],
                         width: width_pt,
                         height: height_pt,
                         size: FONT_SIZE,
                         align: :center,
                         valign: :center,
                         overflow: :shrink_to_fit
          end
        end
      end

      def slugify(value)
        value.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')
      end
    end
  end
end
