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
        # Diagnostic: uncomment to show grid coordinates
        #Components::GridRuler.new(@pdf, @grid_system).render

        draw_header
        draw_two_column_layout
        draw_page_indicator
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
          @pdf.text 'Index', size: 18, style: :bold, align: :left, valign: :bottom
        end
      end

      # Draw the two-column layout with entry lines
      #
      # @return [void]
      def draw_two_column_layout
        col_width = (content_width - COLUMN_GAP) / 2
        line_height = 2  # 2 grid boxes per line

        # Starting entry number for this page
        base_entry = (@index_page_num - 1) * ENTRIES_PER_PAGE

        # Draw left column
        LINES_PER_COLUMN.times do |i|
          row = CONTENT_START_ROW + (i * line_height)
          entry_num = base_entry + i + 1
          draw_entry_line(LEFT_MARGIN, row, col_width, entry_num)
        end

        # Draw right column
        right_col_start = LEFT_MARGIN + col_width + COLUMN_GAP
        LINES_PER_COLUMN.times do |i|
          row = CONTENT_START_ROW + (i * line_height)
          entry_num = base_entry + LINES_PER_COLUMN + i + 1
          draw_entry_line(right_col_start, row, col_width, entry_num)
        end
      end

      # Draw a single entry line with number, ruled line, and page box
      #
      # @param col [Integer] Starting column
      # @param row [Integer] Grid row for this line
      # @param width [Integer] Column width in grid boxes
      # @param entry_num [Integer] Entry number to display
      # @return [void]
      def draw_entry_line(col, row, width, entry_num)
        # Number column (2 boxes wide), shifted up one box
        num_width = 2
        num_box = @grid_system.rect(col, row - 1, num_width, 2)

        @pdf.bounding_box([num_box[:x], num_box[:y]],
                          width: num_box[:width],
                          height: num_box[:height]) do
          @pdf.text entry_num.to_s,
                    size: 9,
                    color: '999999',
                    align: :right,
                    valign: :bottom
        end

        # Title area with ruled line
        title_start_col = col + num_width + 1
        page_box_width = 3
        title_end_col = col + width - page_box_width

        title_start_x = @grid_system.x(title_start_col)
        title_end_x = @grid_system.x(title_end_col)
        line_y = @grid_system.y(row + 2)  # Aligned to grid

        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.5
        @pdf.stroke_line [title_start_x, line_y], [title_end_x, line_y]

        # Page number box at end
        page_box = @grid_system.rect(title_end_col, row, page_box_width, 2)

        @pdf.stroke_color 'DDDDDD'
        @pdf.stroke_rectangle [page_box[:x], page_box[:y]],
                              page_box[:width],
                              page_box[:height]
      end

      # Draw page indicator at bottom
      #
      # @return [void]
      def draw_page_indicator
        indicator_box = @grid_system.rect(LEFT_MARGIN, 52, content_width, 2)

        @pdf.bounding_box([indicator_box[:x], indicator_box[:y]],
                          width: indicator_box[:width],
                          height: indicator_box[:height]) do
          @pdf.text "Index #{@index_page_num} of #{@index_page_count}",
                    size: 9,
                    color: '999999',
                    align: :center,
                    valign: :center
        end
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
