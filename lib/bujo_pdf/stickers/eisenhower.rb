# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # An Eisenhower matrix: urgency across, importance down.
    #
    # The free-floating counterpart to the hour axis. It carries its own axis
    # labels and has no opinion about what is underneath it, so it reads
    # correctly dropped anywhere at any rotation-free position - which is the
    # property that makes a widget survive placement by hand.
    class Eisenhower < Base
      LABEL_BAND = 2   # boxes reserved on the top and left for axis labels
      QUADRANT = 6     # boxes per quadrant edge

      COLUMN_LABELS = %w[URGENT [NOT\ URGENT]].freeze
      ROW_LABELS = ['IMPORTANT', '[NOT IMPORTANT]'].freeze

      # @return [Array<Eisenhower>]
      def self.all
        [new]
      end

      def initialize
        super(
          slug: 'eisenhower',
          title: 'Eisenhower matrix',
          width_boxes: LABEL_BAND + (QUADRANT * 2),
          height_boxes: LABEL_BAND + (QUADRANT * 2)
        )
      end

      def draw(pdf)
        draw_labels(pdf)
        draw_quadrants(pdf)
      end

      private

      def draw_labels(pdf)
        COLUMN_LABELS.each_with_index do |text, i|
          label(pdf, LABEL_BAND + (i * QUADRANT), 0, text,
                cols: QUADRANT, rows: LABEL_BAND, size: 6,
                align: :center, style: :bold)
        end

        # Rotated so they read up the side. Horizontal text would have to fit
        # "NOT IMPORTANT" into a two-box band and would wrap mid-word; rotating
        # trades the band's width for the quadrant's height, which is ample.
        ROW_LABELS.each_with_index do |text, i|
          draw_rotated_label(pdf, text, LABEL_BAND + (i * QUADRANT))
        end
      end

      def draw_rotated_label(pdf, text, row)
        cx = bx(LABEL_BAND / 2.0)
        cy = by(row + (QUADRANT / 2.0))

        pdf.rotate(90, origin: [cx, cy]) do
          pdf.fill_color '777777'
          pdf.font('Helvetica', style: :bold) do
            pdf.text_box text,
                         at: [cx - bx(QUADRANT / 2.0), cy + bx(LABEL_BAND / 2.0)],
                         width: bx(QUADRANT),
                         height: bx(LABEL_BAND),
                         size: 6,
                         align: :center,
                         valign: :center,
                         overflow: :shrink_to_fit
          end
        end
      end

      # Drawn as four separate rounded cells rather than a divided square:
      # separate cells give each quadrant a closed edge to write inside, and
      # the gaps read as a matrix without needing heavier axis rules.
      def draw_quadrants(pdf)
        2.times do |row|
          2.times do |col|
            frame(pdf,
                  LABEL_BAND + (col * QUADRANT),
                  LABEL_BAND + (row * QUADRANT),
                  QUADRANT, QUADRANT, radius: 3)
          end
        end
      end
    end
  end
end
