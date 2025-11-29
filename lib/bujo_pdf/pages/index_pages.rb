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
    # - Clean numbered lines for writing entries
    # - Page number indicator at bottom
    # - Named destinations for each index page (index_1, index_2, etc.)
    #
    # Example:
    #   context = RenderContext.new(
    #     page_key: :index,
    #     index_page_num: 1,        # Which index page (1, 2, 3...)
    #     index_page_count: 4       # Total index pages
    #   )
    #   page = IndexPage.new(pdf, context)
    #   page.generate
    class IndexPage < Base
      # Number of entry lines per page
      LINES_PER_PAGE = 25

      # Setup with full page layout (no sidebars for index)
      def setup
        @index_page_num = context[:index_page_num] || 1
        @index_page_count = context[:index_page_count] || 4

        # Set named destination for this index page
        set_destination("index_#{@index_page_num}")

        use_layout :full_page
      end

      # Render the index page with numbered lines
      def render
        draw_header
        draw_entry_lines
        draw_page_indicator
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
          @pdf.text 'Index', size: 18, style: :bold, align: :left, valign: :bottom
        end
      end

      # Draw numbered entry lines for TOC entries
      #
      # @return [void]
      def draw_entry_lines
        # Start below header
        start_row = 5
        line_height = 2  # 2 grid boxes per line

        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.5

        LINES_PER_PAGE.times do |i|
          row = start_row + (i * line_height)
          line_num = ((@index_page_num - 1) * LINES_PER_PAGE) + i + 1

          draw_entry_line(row, line_num)
        end

        @pdf.stroke_color '000000'
      end

      # Draw a single entry line with number and ruled line
      #
      # @param row [Integer] Grid row for this line
      # @param line_num [Integer] Line number to display
      # @return [void]
      def draw_entry_line(row, line_num)
        # Number column (3 boxes wide)
        num_box = @grid_system.rect(2, row, 3, 2)

        @pdf.bounding_box([num_box[:x], num_box[:y]],
                          width: num_box[:width],
                          height: num_box[:height]) do
          @pdf.text line_num.to_s.rjust(3),
                    size: 9,
                    color: '999999',
                    align: :right,
                    valign: :bottom
        end

        # Title area with ruled line (32 boxes)
        title_start_x = @grid_system.x(6)
        title_end_x = @grid_system.x(38)
        line_y = @grid_system.y(row + 2) + 3  # Slightly above bottom of box

        @pdf.stroke_line [title_start_x, line_y], [title_end_x, line_y]

        # Page number area (3 boxes at end)
        page_box = @grid_system.rect(39, row, 3, 2)

        # Draw a small box for page number
        @pdf.stroke_color 'DDDDDD'
        @pdf.stroke_rectangle [page_box[:x], page_box[:y]],
                              page_box[:width],
                              page_box[:height]
        @pdf.stroke_color 'CCCCCC'
      end

      # Draw page indicator at bottom
      #
      # @return [void]
      def draw_page_indicator
        indicator_box = @grid_system.rect(2, 52, 39, 2)

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
    end
  end
end
