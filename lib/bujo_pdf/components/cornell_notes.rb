# frozen_string_literal: true

require_relative '../component'

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
    #   notes = CornellNotes.new(pdf, grid_system,
    #     content_start_col: 3,
    #     notes_start_row: 11,
    #     cues_cols: 10,
    #     notes_cols: 29,
    #     notes_main_rows: 35,
    #     summary_rows: 9
    #   )
    #   notes.render
    class CornellNotes < Component
      COLOR_BORDERS = 'E5E5E5'
      COLOR_SECTION_HEADERS = 'AAAAAA'
      HEADER_FONT_SIZE = 10
      LABEL_FONT_SIZE = 8
      HEADER_PADDING = 5

      def render
        draw_cues_section
        draw_notes_section
        draw_summary_section
      end

      private

      def validate_configuration
        require_options(:content_start_col, :notes_start_row, :cues_cols,
                       :notes_cols, :notes_main_rows, :summary_rows)
      end

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
        section_box = @grid.rect(col, row, width_boxes, height_boxes)

        @pdf.bounding_box([section_box[:x], section_box[:y]],
                         width: section_box[:width],
                         height: section_box[:height]) do
          with_stroke_color(COLOR_BORDERS) do
            @pdf.stroke_bounds
          end

          with_font("Helvetica-Bold", HEADER_FONT_SIZE) do
            @pdf.move_down HEADER_PADDING
            with_fill_color(COLOR_SECTION_HEADERS) do
              @pdf.text label, align: :center, size: label_size
            end
          end
        end
      end

      def draw_cues_section
        draw_labeled_section(
          context[:content_start_col],
          context[:notes_start_row],
          context[:cues_cols],
          context[:notes_main_rows],
          "Cues/Questions"
        )
      end

      def draw_notes_section
        draw_labeled_section(
          context[:content_start_col] + context[:cues_cols],
          context[:notes_start_row],
          context[:notes_cols],
          context[:notes_main_rows],
          "Notes"
        )
      end

      def draw_summary_section
        draw_labeled_section(
          context[:content_start_col],
          context[:notes_start_row] + context[:notes_main_rows],
          context[:cues_cols] + context[:notes_cols],
          context[:summary_rows],
          "Summary"
        )
      end
    end
  end
end
