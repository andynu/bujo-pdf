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

      def initialize(pdf, grid_system, **options)
        super
        validate_options
      end

      def render
        draw_cues_section
        draw_notes_section
        draw_summary_section
      end

      private

      def validate_options
        required_keys = [:content_start_col, :notes_start_row, :cues_cols,
                        :notes_cols, :notes_main_rows, :summary_rows]
        missing_keys = required_keys - context.keys

        unless missing_keys.empty?
          raise ArgumentError, "CornellNotes requires: #{missing_keys.join(', ')}"
        end
      end

      def draw_cues_section
        cues_box = @grid.rect(
          context[:content_start_col],
          context[:notes_start_row],
          context[:cues_cols],
          context[:notes_main_rows]
        )

        @pdf.bounding_box([cues_box[:x], cues_box[:y]],
                         width: cues_box[:width],
                         height: cues_box[:height]) do
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'
          @pdf.font "Helvetica-Bold", size: HEADER_FONT_SIZE
          @pdf.move_down HEADER_PADDING
          @pdf.fill_color COLOR_SECTION_HEADERS
          @pdf.text "Cues/Questions", align: :center, size: LABEL_FONT_SIZE
          @pdf.fill_color '000000'
        end
      end

      def draw_notes_section
        notes_box = @grid.rect(
          context[:content_start_col] + context[:cues_cols],
          context[:notes_start_row],
          context[:notes_cols],
          context[:notes_main_rows]
        )

        @pdf.bounding_box([notes_box[:x], notes_box[:y]],
                         width: notes_box[:width],
                         height: notes_box[:height]) do
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'
          @pdf.font "Helvetica-Bold", size: HEADER_FONT_SIZE
          @pdf.move_down HEADER_PADDING
          @pdf.fill_color COLOR_SECTION_HEADERS
          @pdf.text "Notes", align: :center, size: LABEL_FONT_SIZE
          @pdf.fill_color '000000'
        end
      end

      def draw_summary_section
        summary_box = @grid.rect(
          context[:content_start_col],
          context[:notes_start_row] + context[:notes_main_rows],
          context[:cues_cols] + context[:notes_cols],
          context[:summary_rows]
        )

        @pdf.bounding_box([summary_box[:x], summary_box[:y]],
                         width: summary_box[:width],
                         height: summary_box[:height]) do
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_bounds
          @pdf.stroke_color '000000'
          @pdf.font "Helvetica-Bold", size: LABEL_FONT_SIZE
          @pdf.move_down HEADER_PADDING
          @pdf.fill_color COLOR_SECTION_HEADERS
          @pdf.text "Summary", align: :center
          @pdf.fill_color '000000'
        end
      end
    end
  end
end
