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
      register_page :future_log,
        title: "Future Log",
        dest: "future_log_%{_n}"

      # Mixin providing future_log_page and future_log_pages verbs for document builders.
      module Mixin
        include MixinSupport

        # Generate a single future log page.
        #
        # @param num [Integer] Which future log page (1, 2, etc.)
        # @param total [Integer, nil] Total future log pages (defaults to num)
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def future_log_page(num:, total: nil)
          count = total || num
          start_month = (num - 1) * 6 + 1  # Page 1 = months 1-6, Page 2 = months 7-12

          define_page(dest: "future_log_#{num}", title: 'Future Log', type: :future_log,
                      future_log_page: num, future_log_page_count: count,
                      future_log_start_month: start_month) do |ctx|
            FutureLog.new(@pdf, ctx).generate
          end
        end

        # Generate multiple future log pages.
        #
        # Uses page_set DSL to automatically populate context.set with
        # page position and label information.
        #
        # @param count [Integer] Number of future log pages (default: 2)
        # @return [Array<PageRef>, nil] Array of PageRefs during define phase
        def future_log_pages(count: 2)
          page_set(count, "Future Log %page of %total") do
            future_log_page(num: @current_page_set_index + 1, total: count)
          end
        end
      end

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
        # Get page position from context.set (page_set DSL) or legacy context
        @future_log_page = context.set? ? context.set.page : (context[:future_log_page] || 1)
        @future_log_page_count = context.set? ? context.set.total : (context[:future_log_page_count] || 2)
        @start_month = context[:future_log_start_month] || ((@future_log_page - 1) * MONTHS_PER_PAGE + 1)
        @year = context[:year]

        # Set named destination for this page
        set_destination("future_log_#{@future_log_page}")

        use_layout :full_page
      end

      def render
        # Diagnostic: uncomment to show grid coordinates
        # Components::GridRuler.new(@pdf, @grid_system).render
        draw_header
        draw_two_column_layout
        draw_set_label(col: LEFT_MARGIN, width: content_width)
      end

      private

      # Draw the page header
      #
      # @return [void]
      def draw_header
        first_month = Date::MONTHNAMES[@start_month]
        last_month = Date::MONTHNAMES[@start_month + MONTHS_PER_PAGE - 1]
        h2(LEFT_MARGIN, HEADER_ROW, "Future Log: #{first_month} - #{last_month} #{@year}")
      end

      # Draw the two-column layout with 3 months per column
      #
      # @return [void]
      def draw_two_column_layout
        month_cells = @grid.divide_grid(
          col: LEFT_MARGIN, row: CONTENT_START_ROW,
          width: content_width, height: 50,
          cols: 2, rows: MONTHS_PER_COLUMN,
          col_gap: COLUMN_GAP, order: :down
        )

        month_cells.each_with_index do |cell, i|
          draw_month_section(@start_month + i, cell.col, cell.row, cell.width, cell.height)
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
        left, right = @grid.divide_columns(col: col, width: width, count: 2, gap: ENTRY_COLUMN_GAP)

        # Draw entry lines starting 2 rows below the header
        row = start_row + 2
        draw_entry_lines(left.col, row, left.width, height - 2)
        draw_entry_lines(right.col, row, right.width, height - 2)
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
      # @param col [Integer] Starting column
      # @param start_row [Integer] Starting row for lines
      # @param width [Integer] Width in grid boxes
      # @param row_count [Integer] Number of rows available
      # @return [void]
      def draw_entry_lines(col, start_row, width, row_count)
        ruled_lines(col, start_row, width, row_count)
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
