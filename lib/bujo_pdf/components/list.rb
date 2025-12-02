# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative 'ruled_lines'
require_relative 'hline'
require_relative 'box'
require_relative 'text'

module BujoPdf
  module Components
    # List renders rows with optional numbers, markers, dividers, and page boxes.
    #
    # This is a visual component for drawing list-like structures. The caller
    # decides the semantic meaning (todo list, index, etc.). The component
    # just draws the visual elements:
    #
    #   [optional number] [optional marker] [line area] [optional page box]
    #
    # Each slot is independent and composable:
    # - (number, marker, line) - numbered checklist
    # - (number, line, page_box) - index/TOC entry
    # - (marker, line) - simple todo
    # - (line) - just ruled lines for writing
    #
    # Example usage:
    #   # Simple todo list with bullets
    #   List.new(canvas: c, col: 5, row: 10, width: 20, rows: 8, marker: :bullet)
    #
    #   # Index entry with numbers and page box
    #   List.new(canvas: c, col: 2, row: 4, width: 18, rows: 25,
    #            show_numbers: true, show_page_box: true, row_height: 2)
    #
    #   # Numbered checklist
    #   List.new(canvas: c, col: 5, row: 10, width: 20, rows: 8,
    #            show_numbers: true, marker: :checkbox)
    #
    class List < Component
      include RuledLines::Mixin
      include HLine::Mixin
      include Box::Mixin
      include Text::Mixin

      # Marker sizes in points
      BULLET_RADIUS = 2.0
      CHECKBOX_SIZE = 8.0
      CIRCLE_RADIUS = 4.0

      # Column widths in grid boxes
      NUMBER_COLUMN_WIDTH = 2
      MARKER_COLUMN_WIDTH = 1
      PAGE_BOX_WIDTH = 3

      # Mixin providing the list verb for pages and components
      module Mixin
        # Render a list with optional numbers, markers, dividers, and page boxes
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Starting row (top of first line)
        # @param width [Integer] Width in grid boxes
        # @param rows [Integer] Number of rows/entries
        # @param show_numbers [Boolean] Show entry numbers (default: false)
        # @param start_num [Integer] First entry number when show_numbers is true (default: 1)
        # @param marker [Symbol] Marker style :none, :bullet, :checkbox, or :circle (default: :none)
        # @param divider [Symbol] Row divider style :none, :solid, or :dashed (default: :none)
        # @param show_page_box [Boolean] Show page number box at end (default: false)
        # @param row_height [Integer] Height of each row in grid boxes (default: 1)
        # @param divider_color [String, nil] Hex color for dividers (default: theme BORDERS)
        # @param number_color [String, nil] Hex color for numbers (default: '999999')
        # @param marker_color [String, nil] Hex color for markers (default: theme TEXT_BLACK)
        # @param line_color [String, nil] Hex color for ruled lines (default: 'CCCCCC')
        # @return [void]
        def list(col, row, width, rows:, show_numbers: false, start_num: 1,
                 marker: :none, divider: :none, show_page_box: false, row_height: 1,
                 divider_color: nil, number_color: nil, marker_color: nil, line_color: nil)
          c = @canvas || Canvas.new(@pdf, @grid)
          List.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            rows: rows,
            show_numbers: show_numbers,
            start_num: start_num,
            marker: marker,
            divider: divider,
            show_page_box: show_page_box,
            row_height: row_height,
            divider_color: divider_color,
            number_color: number_color,
            marker_color: marker_color,
            line_color: line_color
          ).render
        end
      end

      # Initialize a new List component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top of first line)
      # @param width [Integer] Width in grid boxes
      # @param rows [Integer] Number of rows/entries
      # @param show_numbers [Boolean] Show entry numbers
      # @param start_num [Integer] First entry number
      # @param marker [Symbol] Marker style :none, :bullet, :checkbox, or :circle
      # @param divider [Symbol] Divider style :none, :solid, or :dashed
      # @param show_page_box [Boolean] Show page number box
      # @param row_height [Integer] Height of each row in grid boxes
      # @param divider_color [String, nil] Hex color for dividers
      # @param number_color [String, nil] Hex color for numbers
      # @param marker_color [String, nil] Hex color for markers
      # @param line_color [String, nil] Hex color for ruled lines
      def initialize(canvas:, col:, row:, width:, rows:,
                     show_numbers: false, start_num: 1,
                     marker: :none, divider: :none, show_page_box: false, row_height: 1,
                     divider_color: nil, number_color: nil, marker_color: nil, line_color: nil)
        super(canvas: canvas)
        @col = col
        @row = row
        @width = width
        @rows = rows
        @show_numbers = show_numbers
        @start_num = start_num
        @marker = marker
        @divider = divider
        @show_page_box = show_page_box
        @row_height = row_height
        @divider_color = divider_color
        @number_color = number_color
        @marker_color = marker_color
        @line_color = line_color

        validate_parameters
      end

      # Render the list
      #
      # @return [void]
      def render
        draw_dividers if @divider != :none
        @rows.times { |i| draw_row(i) }
      end

      # Get the bounding rectangle for a specific row
      #
      # @param row_index [Integer] Row index (0-based)
      # @return [Hash] Rectangle with :x, :y, :width, :height keys in points
      def row_rect(row_index)
        validate_row_index(row_index)
        grid.rect(@col, @row + (row_index * @row_height), @width, @row_height)
      end

      # Get the text/content area rectangle (excluding number, marker, page_box columns)
      #
      # @param row_index [Integer] Row index (0-based)
      # @return [Hash] Rectangle with :x, :y, :width, :height keys in points
      def content_rect(row_index)
        validate_row_index(row_index)
        content_col = @col + left_columns_width
        content_width = @width - left_columns_width - right_columns_width
        grid.rect(content_col, @row + (row_index * @row_height), content_width, @row_height)
      end

      # Total height of the list in points
      #
      # @return [Float] Height in points
      def height
        @rows * @row_height * Styling::Grid::DOT_SPACING
      end

      private

      def validate_parameters
        raise ArgumentError, 'canvas is required' if @canvas.nil?
        raise ArgumentError, 'width must be positive' if @width <= 0
        raise ArgumentError, 'rows must be positive' if @rows <= 0
        raise ArgumentError, 'marker must be :none, :bullet, :checkbox, or :circle' unless %i[none bullet checkbox circle].include?(@marker)
        raise ArgumentError, 'divider must be :none, :solid, or :dashed' unless %i[none solid dashed].include?(@divider)
        raise ArgumentError, 'row_height must be positive' if @row_height <= 0
      end

      def validate_row_index(row_index)
        raise ArgumentError, "row_index must be 0-#{@rows - 1}, got #{row_index}" unless (0...@rows).cover?(row_index)
      end

      # Draw a single row with all its elements
      def draw_row(row_index)
        entry_row = @row + (row_index * @row_height)
        current_col = @col

        if @show_numbers
          draw_number(current_col, entry_row, @start_num + row_index)
          current_col += NUMBER_COLUMN_WIDTH + 1  # +1 gap after number
        end

        if @marker != :none
          draw_marker(current_col, entry_row)
          current_col += MARKER_COLUMN_WIDTH
        end

        # Draw ruled line from current position to page box (or end)
        line_end_col = @show_page_box ? @col + @width - PAGE_BOX_WIDTH : @col + @width
        line_width = line_end_col - current_col

        # Line sits at the bottom of the row
        hline(current_col, entry_row + @row_height, line_width, color: effective_line_color) if line_width > 0

        draw_page_box(entry_row) if @show_page_box
      end

      # Draw entry number (right-aligned in its column)
      def draw_number(col, row, num)
        # Position at bottom of row area for better visual alignment
        text_row = row + @row_height - 1
        text(col, text_row, num.to_s,
             size: 9,
             color: effective_number_color,
             align: :right,
             width: NUMBER_COLUMN_WIDTH,
             height: 1)
      end

      # Draw marker (bullet, checkbox, or circle)
      def draw_marker(col, row)
        # Center in the marker column, vertically centered in row
        marker_center_x = grid.x(col) + (Styling::Grid::DOT_SPACING / 2)
        marker_center_y = grid.y(row) - (@row_height * Styling::Grid::DOT_SPACING / 2)

        pdf.save_graphics_state do
          pdf.fill_color(effective_marker_color)
          pdf.stroke_color(effective_marker_color)

          case @marker
          when :bullet
            pdf.fill_circle([marker_center_x, marker_center_y], BULLET_RADIUS)
          when :checkbox
            half = CHECKBOX_SIZE / 2
            pdf.line_width = 0.5
            pdf.stroke_rectangle([marker_center_x - half, marker_center_y + half], CHECKBOX_SIZE, CHECKBOX_SIZE)
          when :circle
            pdf.line_width = 0.5
            pdf.stroke_circle([marker_center_x, marker_center_y], CIRCLE_RADIUS)
          end
        end
      end

      # Draw page number box at the end of the row
      def draw_page_box(row)
        box_col = @col + @width - PAGE_BOX_WIDTH
        box(box_col, row, PAGE_BOX_WIDTH, @row_height,
            stroke: 'DDDDDD', fill: nil, radius: 0)
      end

      # Draw dividers between rows
      def draw_dividers
        return if @rows <= 1

        divider_count = @rows - 1
        divider_col = @col + left_columns_width
        divider_width = @width - left_columns_width - right_columns_width
        dash_pattern = @divider == :dashed ? [3, 2] : nil

        pdf.stroke_color effective_divider_color
        pdf.line_width 0.5
        pdf.dash(dash_pattern[0], space: dash_pattern[1]) if dash_pattern

        # Draw dividers at the bottom of each row (except last)
        divider_count.times do |i|
          divider_row = @row + ((i + 1) * @row_height)
          y = grid.y(divider_row)
          x_start = grid.x(divider_col)
          x_end = grid.x(divider_col + divider_width)
          pdf.stroke_line [x_start, y], [x_end, y]
        end

        # Restore defaults
        pdf.undash if dash_pattern
        pdf.stroke_color '000000'
        pdf.line_width 0.5
      end

      # Width of left columns (number + marker) in grid boxes
      def left_columns_width
        width = 0
        width += NUMBER_COLUMN_WIDTH + 1 if @show_numbers  # +1 gap
        width += MARKER_COLUMN_WIDTH if @marker != :none
        width
      end

      # Width of right columns (page box) in grid boxes
      def right_columns_width
        @show_page_box ? PAGE_BOX_WIDTH : 0
      end

      def effective_divider_color
        @divider_color || Styling::Colors.BORDERS
      end

      def effective_number_color
        @number_color || '999999'
      end

      def effective_marker_color
        @marker_color || Styling::Colors.TEXT_BLACK
      end

      def effective_line_color
        @line_color || 'CCCCCC'
      end
    end
  end
end
