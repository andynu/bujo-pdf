# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Future log page for capturing events beyond the current planning horizon.
    #
    # Classic bullet journal technique: 6-month spread with minimal structure.
    # Each page shows 3 months with headers and ruled lines for entries.
    # Users write future events here and migrate them to weekly pages when
    # the time comes.
    #
    # Design:
    # - 6-month spread across 2 pages (3 months per page)
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
      # Number of months per page
      MONTHS_PER_PAGE = 3

      # Number of entry lines per month section
      LINES_PER_MONTH = 14

      def setup
        @future_log_page = context[:future_log_page] || 1
        @start_month = context[:future_log_start_month] || ((@future_log_page - 1) * MONTHS_PER_PAGE + 1)
        @year = context[:year]

        # Set named destination for this page
        set_destination("future_log_#{@future_log_page}")

        use_layout :full_page
      end

      def render
        draw_header
        draw_month_sections
      end

      private

      # Draw the page header
      #
      # @return [void]
      def draw_header
        header_box = @grid_system.rect(2, 1, 39, 3)

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

      # Draw all month sections
      #
      # @return [void]
      def draw_month_sections
        # Calculate available height for months
        start_row = 5
        section_height = 16  # boxes per month section
        spacing = 1          # boxes between sections

        MONTHS_PER_PAGE.times do |i|
          month_num = @start_month + i
          row = start_row + (i * (section_height + spacing))
          draw_month_section(month_num, row, section_height)
        end
      end

      # Draw a single month section
      #
      # @param month_num [Integer] Month number (1-12)
      # @param start_row [Integer] Starting row for this section
      # @param height [Integer] Section height in grid boxes
      # @return [void]
      def draw_month_section(month_num, start_row, height)
        # Month header
        draw_month_header(month_num, start_row)

        # Entry lines below header
        draw_entry_lines(start_row + 2, height - 2)
      end

      # Draw month header with divider line
      #
      # @param month_num [Integer] Month number (1-12)
      # @param row [Integer] Row for the header
      # @return [void]
      def draw_month_header(month_num, row)
        header_box = @grid_system.rect(2, row, 39, 2)

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
        @pdf.stroke_line [@grid_system.x(2), line_y], [@grid_system.x(41), line_y]
        @pdf.line_width 0.5
      end

      # Draw ruled entry lines for a section
      #
      # @param start_row [Integer] Starting row for lines
      # @param row_count [Integer] Number of rows available
      # @return [void]
      def draw_entry_lines(start_row, row_count)
        line_height = 1  # 1 grid box per line

        @pdf.stroke_color 'E5E5E5'
        @pdf.line_width 0.5

        num_lines = row_count
        num_lines.times do |i|
          row = start_row + (i * line_height)
          line_y = @grid_system.y(row + 1) + 3  # Position line

          @pdf.stroke_line [@grid_system.x(2), line_y], [@grid_system.x(41), line_y]
        end

        @pdf.stroke_color '000000'
      end
    end
  end
end
