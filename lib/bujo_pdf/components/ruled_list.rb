# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative 'hline'
require_relative 'box'

module BujoPdf
  module Components
    # RuledList renders numbered entry lines for index/TOC pages.
    #
    # Each line has:
    # - Entry number (right-aligned, muted color)
    # - Ruled line for writing entry title
    # - Optional page number box at the end
    #
    # Lines are spaced 2 grid rows apart to give room for handwriting.
    #
    # Example usage in a page:
    #   ruled_list(2, 4, 18, entries: 25, start_num: 1)
    #   ruled_list(2, 4, 18, entries: 25, start_num: 1, show_page_box: false)
    #
    class RuledList < Component
      include HLine::Mixin
      include Box::Mixin

      # Height of each entry line in grid boxes
      LINE_HEIGHT = 2

      # Width of entry number column in grid boxes
      NUM_WIDTH = 2

      # Width of page number box in grid boxes
      PAGE_BOX_WIDTH = 3

      # Mixin providing the ruled_list verb for pages and components
      module Mixin
        # Render a ruled list with numbered entries
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Starting row (top of first line)
        # @param width [Integer] Width in grid boxes
        # @param entries [Integer] Number of entry lines to draw
        # @param start_num [Integer] First entry number (default: 1)
        # @param show_page_box [Boolean] Show page number box at end (default: true)
        # @param line_color [String] Color for ruled lines (default: 'CCCCCC')
        # @param num_color [String] Color for entry numbers (default: '999999')
        # @return [void]
        def ruled_list(col, row, width, entries:, start_num: 1, show_page_box: true, line_color: 'CCCCCC', num_color: '999999')
          c = @canvas || Canvas.new(@pdf, @grid)
          RuledList.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            entries: entries,
            start_num: start_num,
            show_page_box: show_page_box,
            line_color: line_color,
            num_color: num_color
          ).render
        end
      end

      # Initialize a new RuledList component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top of first line)
      # @param width [Integer] Width in grid boxes
      # @param entries [Integer] Number of entry lines
      # @param start_num [Integer] First entry number
      # @param show_page_box [Boolean] Show page number box
      # @param line_color [String] Ruled line color
      # @param num_color [String] Entry number color
      def initialize(canvas:, col:, row:, width:, entries:, start_num: 1, show_page_box: true, line_color: 'CCCCCC', num_color: '999999')
        super(canvas: canvas)
        @col = col
        @row = row
        @width = width
        @entries = entries
        @start_num = start_num
        @show_page_box = show_page_box
        @line_color = line_color
        @num_color = num_color
      end

      # Render the ruled list
      #
      # @return [void]
      def render
        @entries.times do |i|
          entry_row = @row + (i * LINE_HEIGHT)
          entry_num = @start_num + i
          draw_entry_line(entry_row, entry_num)
        end
      end

      private

      # Draw a single entry line
      #
      # @param row [Integer] Grid row for this entry
      # @param entry_num [Integer] Entry number to display
      # @return [void]
      def draw_entry_line(row, entry_num)
        draw_entry_number(row, entry_num)
        draw_ruled_line(row)
        draw_page_box(row) if @show_page_box
      end

      # Draw the entry number (right-aligned in its column)
      #
      # @param row [Integer] Grid row
      # @param entry_num [Integer] Number to display
      # @return [void]
      def draw_entry_number(row, entry_num)
        num_rect = grid.rect(@col, row - 1, NUM_WIDTH, LINE_HEIGHT)

        pdf.bounding_box([num_rect[:x], num_rect[:y]],
                          width: num_rect[:width],
                          height: num_rect[:height]) do
          pdf.text entry_num.to_s,
                    size: 9,
                    color: @num_color,
                    align: :right,
                    valign: :bottom
        end
      end

      # Draw the ruled line for the entry title
      #
      # @param row [Integer] Grid row
      # @return [void]
      def draw_ruled_line(row)
        line_start_col = @col + NUM_WIDTH + 1
        line_end_col = @show_page_box ? @col + @width - PAGE_BOX_WIDTH : @col + @width
        line_width = line_end_col - line_start_col

        # Line sits at the bottom of the entry area (row + LINE_HEIGHT)
        hline(line_start_col, row + LINE_HEIGHT, line_width, color: @line_color)
      end

      # Draw the page number box at the end
      #
      # @param row [Integer] Grid row
      # @return [void]
      def draw_page_box(row)
        box_col = @col + @width - PAGE_BOX_WIDTH
        box(@col + @width - PAGE_BOX_WIDTH, row, PAGE_BOX_WIDTH, LINE_HEIGHT,
            stroke: 'DDDDDD', fill: nil, radius: 0)
      end
    end
  end
end
