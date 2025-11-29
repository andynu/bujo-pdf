# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Future log page for capturing events beyond the current planning horizon.
    #
    # Classic bullet journal technique: 12-month spread with minimal structure.
    # Each page shows 6 months in a two-column layout (3 months per column).
    # Users write future events here and migrate them to weekly pages when
    # the time comes.
    #
    # Design:
    # - 12-month spread across 2 pages (6 months per page, 2 columns)
    # - Month headers with simple dividers
    # - Ruled lines for writing entries
    # - Minimal structure to allow flexible use
    #
    # Example:
    #   context = RenderContext.new(
    #     page_key: :future_log_1,
    #     future_log_page: 1,          # Which page of the spread (1 or 2)
    #     future_log_start_month: 1,   # First month on this page (1 = Jan)
    #     year: 2025
    #   )
    #   page = FutureLog.new(pdf, context)
    #   page.generate
    class FutureLog < Base
      # Number of months per page (2 columns x 3 rows)
      MONTHS_PER_PAGE = 6

      # Layout constants
      LEFT_MARGIN = 2
      RIGHT_MARGIN = 41
      COLUMN_GAP = 1        # Gap between month columns in grid boxes
      ENTRY_COLUMN_GAP = 1  # Gap between entry line columns within a month
      HEADER_ROW = 1
      CONTENT_START_ROW = 4
      MONTHS_PER_COLUMN = 3

      def setup
        @future_log_page = context[:future_log_page] || 1
        @start_month = context[:future_log_start_month] || ((@future_log_page - 1) * MONTHS_PER_PAGE + 1)
        @year = context[:year]

        # Set named destination for this page
        set_destination("future_log_#{@future_log_page}")

        use_layout :full_page
      end

      def render
        # Diagnostic: uncomment to show grid coordinates
        #Components::GridRuler.new(@pdf, @grid_system).render
        draw_header
        draw_two_column_layout
      end

      private

      # Draw the page header
      #
      # @return [void]
      def draw_header
        header_box = @grid_system.rect(LEFT_MARGIN, HEADER_ROW, content_width, 2)

        @pdf.bounding_box([header_box[:x], header_box[:y]],
                          width: header_box[:width],
                          height: header_box[:height]) do
          # Show which months are on this page
          first_month = Date::MONTHNAMES[@start_month]
          last_month = Date::MONTHNAMES[@start_month + MONTHS_PER_PAGE - 1]
          @pdf.text "Future Log: #{first_month} - #{last_month} #{@year}",
                    size: 14,
                    style: :bold,
                    align: :left,
                    valign: :bottom
        end
      end

      # Draw the two-column layout with 3 months per column
      #
      # @return [void]
      def draw_two_column_layout
        # Calculate column dimensions
        col_width = (content_width - COLUMN_GAP) / 2

        # Available height for month sections (rows 4-53 = 50 rows)
        available_rows = 50
        section_height = available_rows / MONTHS_PER_COLUMN  # ~16 rows per month

        # Draw left column (first 3 months)
        MONTHS_PER_COLUMN.times do |i|
          month_num = @start_month + i
          row = CONTENT_START_ROW + (i * section_height)
          draw_month_section(month_num, LEFT_MARGIN, row, col_width, section_height)
        end

        # Draw right column (next 3 months)
        right_col_start = LEFT_MARGIN + col_width + COLUMN_GAP
        MONTHS_PER_COLUMN.times do |i|
          month_num = @start_month + MONTHS_PER_COLUMN + i
          row = CONTENT_START_ROW + (i * section_height)
          draw_month_section(month_num, right_col_start, row, col_width, section_height)
        end
      end

      # Draw a single month section
      #
      # Each month has two columns of entry lines within its allocated space.
      #
      # @param month_num [Integer] Month number (1-12)
      # @param col [Integer] Starting column for this section
      # @param start_row [Integer] Starting row for this section
      # @param width [Integer] Width in grid boxes
      # @param height [Integer] Section height in grid boxes
      # @return [void]
      def draw_month_section(month_num, col, start_row, width, height)
        draw_month_header(month_num, col, start_row, width)

        # Split the month width into two columns of entry lines
        entry_col_width = (width - ENTRY_COLUMN_GAP) / 2
        entry_col1 = col
        entry_col2 = col + entry_col_width + ENTRY_COLUMN_GAP

        # Draw entry lines starting 2 rows below the header
        row = start_row + 2
        draw_entry_lines(entry_col1, row, entry_col_width, height - 2)
        draw_entry_lines(entry_col2, row, entry_col_width, height - 2)
      end

      # Draw month header with divider line
      #
      # @param month_num [Integer] Month number (1-12)
      # @param col [Integer] Starting column
      # @param row [Integer] Row for the header
      # @param width [Integer] Width in grid boxes
      # @return [void]
      def draw_month_header(month_num, col, row, width)
        header_box = @grid_system.rect(col, row, width, 2)

        # Month name
        @pdf.bounding_box([header_box[:x], header_box[:y]],
                          width: header_box[:width],
                          height: header_box[:height]) do
          month_name = Date::MONTHNAMES[month_num]
          @pdf.text month_name.upcase,
                    size: 11,
                    style: :bold,
                    color: '666666',
                    align: :left,
                    valign: :bottom
        end

        # Divider line under header
        line_y = @grid_system.y(row + 2)
        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 1.0
        @pdf.stroke_line [@grid_system.x(col), line_y], [@grid_system.x(col + width), line_y]
        @pdf.line_width 0.5
      end

      # Draw ruled entry lines for a section
      #
      # Lines are quantized to the dot grid - each line sits exactly on a grid row,
      # providing consistent spacing that aligns with the 5mm dot pattern.
      #
      # @param col [Integer] Starting column
      # @param start_row [Integer] Starting row for lines
      # @param width [Integer] Width in grid boxes
      # @param row_count [Integer] Number of rows available
      # @return [void]
      def draw_entry_lines(col, start_row, width, row_count)
        @pdf.stroke_color 'E5E5E5'
        @pdf.line_width 0.5

        # Draw one line per grid row, aligned exactly with grid positions
        row_count.times do |i|
          row = start_row + i
          line_y = @grid_system.y(row + 1)  # Bottom of the row, aligned to grid

          @pdf.stroke_line [@grid_system.x(col), line_y], [@grid_system.x(col + width), line_y]
        end

        @pdf.stroke_color '000000'
      end

      # Calculate content width (usable area between margins)
      #
      # @return [Integer] Width in grid boxes
      def content_width
        RIGHT_MARGIN - LEFT_MARGIN
      end
    end
  end
end
