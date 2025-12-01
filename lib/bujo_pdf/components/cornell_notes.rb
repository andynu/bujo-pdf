# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative '../utilities/grid_rect'
require_relative 'box'
require_relative 'text'

module BujoPdf
  module Components
    # CornellNotes component for weekly pages.
    #
    # Renders the Cornell notes section with three areas:
    #   - Cues/Questions column (left, 25% width)
    #   - Notes column (right, 75% width)
    #   - Summary section (bottom, full width)
    #
    # Each section has:
    #   - Border
    #   - Header label
    #   - Content area
    #
    # Example usage:
    #   canvas = Canvas.new(pdf, grid)
    #   notes = CornellNotes.new(
    #     canvas: canvas,
    #     bounds: GridRect.new(2, 11, 40, 44),
    #     cues_cols: 10,
    #     summary_rows: 9
    #   )
    #   notes.render
    class CornellNotes < Component
      include Styling::Colors
      include Box::Mixin
      include Text::Mixin

      LABEL_FONT_SIZE = 8

      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param bounds [GridRect] Bounding rectangle for the entire component
      # @param cues_cols [Integer] Width of cues column in grid boxes
      # @param summary_rows [Integer] Height of summary section in grid boxes
      def initialize(canvas:, bounds:, cues_cols:, summary_rows:)
        super(canvas: canvas)

        # Derive dimensions from bounds
        notes_cols = bounds.width - cues_cols
        notes_main_rows = bounds.height - summary_rows

        # Pre-compute section rectangles
        @cues_rect = GridRect.new(bounds.col, bounds.row, cues_cols, notes_main_rows)
        @notes_rect = GridRect.new(bounds.col + cues_cols, bounds.row, notes_cols, notes_main_rows)
        @summary_rect = GridRect.new(bounds.col, bounds.row + notes_main_rows, bounds.width, summary_rows)
      end

      def render
        draw_labeled_section(*@cues_rect, "Cues/Questions")
        draw_labeled_section(*@notes_rect, "Notes")
        draw_labeled_section(*@summary_rect, "Summary")
      end

      private

      # Draw a labeled section with border and header.
      #
      # @param col [Integer] Starting grid column
      # @param row [Integer] Starting grid row
      # @param width_boxes [Integer] Width in grid boxes
      # @param height_boxes [Integer] Height in grid boxes
      # @param label [String] Section label text
      # @param label_size [Integer] Font size for label (optional)
      # @return [void]
      def draw_labeled_section(col, row, width_boxes, height_boxes, label, label_size: LABEL_FONT_SIZE)
        box(col, row, width_boxes, height_boxes, stroke: Styling::Colors.BORDERS)
        text(col, row, label,
             size: label_size,
             style: :bold,
             align: :center,
             width: width_boxes,
             color: Styling::Colors.SECTION_HEADERS)
      end
    end
  end
end
