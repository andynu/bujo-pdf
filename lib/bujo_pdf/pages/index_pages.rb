# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Index page for building a custom table of contents.
    #
    # Classic bullet journal technique: numbered lines where users can write
    # their own page references and hyperlink entries. Each index page has
    # a named destination so TOC entries can link to specific index pages.
    #
    # Design:
    # - Two-column layout with numbered lines
    # - Page number boxes for each entry
    # - Named destinations for each index page (index_1, index_2)
    # - 2 pages total covering entries 1-100
    #
    # Example:
    #   context = RenderContext.new(
    #     page_key: :index,
    #     index_page_num: 1,        # Which index page (1 or 2)
    #     index_page_count: 2       # Total index pages
    #   )
    #   page = IndexPage.new(pdf, context)
    #   page.generate
    class IndexPage < Base
      # Layout constants
      LEFT_MARGIN = 2
      RIGHT_MARGIN = 41
      COLUMN_GAP = 1
      HEADER_ROW = 1
      CONTENT_START_ROW = 4

      # Number of entry lines per column
      LINES_PER_COLUMN = 25

      # Entries per page (2 columns)
      ENTRIES_PER_PAGE = LINES_PER_COLUMN * 2

      # Setup with full page layout (no sidebars for index)
      def setup
        @index_page_num = context[:index_page_num] || 1
        @index_page_count = context[:index_page_count] || 2

        # Set named destination for this index page
        set_destination("index_#{@index_page_num}")

        use_layout :full_page
      end

      # Render the index page with numbered lines in two columns
      def render
        draw_header
        draw_two_column_layout
        draw_column_divider
        @grid.redraw_dots(col: 0, row: 0, width: @grid.cols, height: @grid.rows)
        # Footer drawn after dots so text appears clean
        draw_page_indicator
      end

      private

      # Draw the page header
      #
      # @return [void]
      def draw_header
        h2(LEFT_MARGIN, HEADER_ROW, 'Index')
      end

      # Draw the two-column layout with entry lines using RuledList
      #
      # @return [void]
      def draw_two_column_layout
        left, right = @grid.divide_columns(col: LEFT_MARGIN, width: content_width, count: 2, gap: COLUMN_GAP)

        # Starting entry number for this page
        base_entry = (@index_page_num - 1) * ENTRIES_PER_PAGE

        # Draw left column
        ruled_list(left.col, CONTENT_START_ROW, left.width,
                   entries: LINES_PER_COLUMN,
                   start_num: base_entry + 1)

        # Draw right column
        ruled_list(right.col, CONTENT_START_ROW, right.width,
                   entries: LINES_PER_COLUMN,
                   start_num: base_entry + LINES_PER_COLUMN + 1)
      end

      # Draw vertical divider between columns
      #
      # @return [void]
      def draw_column_divider
        left, _right = @grid.divide_columns(col: LEFT_MARGIN, width: content_width, count: 2, gap: COLUMN_GAP)
        divider_col = left.col + left.width
        divider_height = LINES_PER_COLUMN * 2  # 2 rows per entry

        vline(divider_col, CONTENT_START_ROW, divider_height, color: 'E5E5E5')
      end

      # Draw page indicator at bottom (last row)
      #
      # @return [void]
      def draw_page_indicator
        text(LEFT_MARGIN, 54, "Index #{@index_page_num} of #{@index_page_count}",
             size: 9,
             color: '999999',
             width: content_width,
             align: :center,
             position: :subscript)
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
