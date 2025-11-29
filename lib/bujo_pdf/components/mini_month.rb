# frozen_string_literal: true

require_relative '../utilities/styling'
require_relative '../utilities/date_calculator'
require_relative 'h1'

module BujoPdf
  module Components
    # MiniMonth renders a compact monthly calendar.
    #
    # Renders a month title, weekday headers (M T W T F S S), and day numbers
    # in a grid. Columns are proportionally divided across the width, so any
    # width works (not just multiples of 7).
    #
    # Layout (in grid boxes):
    # - Row 0: Month title (1 box)
    # - Row 1: Weekday headers (1 box)
    # - Rows 2-7: Calendar days (6 boxes, some months need all 6)
    #
    # Total height: 8 boxes
    #
    # Example usage in a page:
    #   mini_month(2, 5, 21, month: 1, year: 2025)
    #   mini_month(2, 5, 20, month: 3, year: 2025, align: :left)
    #
    class MiniMonth
      include H1::Mixin
      include Styling::Colors

      # Standard height for a mini month (title + headers + 6 calendar rows)
      HEIGHT_BOXES = 8

      # Mixin providing the mini_month verb for pages and components
      module Mixin
        # Render a mini month calendar at a grid position
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Starting row (top edge)
        # @param width [Integer] Width in grid boxes
        # @param month [Integer] Month number (1-12)
        # @param year [Integer] Year
        # @param align [Symbol] Title alignment :left, :center, :right (default: :center)
        # @param show_links [Boolean] Add clickable links to weekly pages (default: true)
        # @param show_weekend_bg [Boolean] Show weekend background shading (default: true)
        # @return [void]
        def mini_month(col, row, width, month:, year:, align: :center, show_links: true, show_weekend_bg: true)
          MiniMonth.new(
            pdf: @pdf,
            grid: @grid,
            col: col,
            row: row,
            width: width,
            month: month,
            year: year,
            align: align,
            show_links: show_links,
            show_weekend_bg: show_weekend_bg
          ).render
        end
      end

      # Initialize a new MiniMonth component
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param grid [GridSystem] The grid system for coordinate conversion
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top edge)
      # @param width [Integer] Width in grid boxes
      # @param month [Integer] Month number (1-12)
      # @param year [Integer] Year
      # @param align [Symbol] Title alignment
      # @param show_links [Boolean] Add clickable links
      # @param show_weekend_bg [Boolean] Show weekend background
      def initialize(pdf:, grid:, col:, row:, width:, month:, year:, align: :center, show_links: true, show_weekend_bg: true)
        @pdf = pdf
        @grid = grid
        @col = col
        @row = row
        @width = width
        @month = month
        @year = year
        @align = align
        @show_links = show_links
        @show_weekend_bg = show_weekend_bg

        # Calculate proportional column width in points
        @col_width_pt = @grid.width(@width) / 7.0
      end

      # Render the mini month calendar
      #
      # @return [void]
      def render
        draw_title
        draw_weekday_headers
        draw_weekend_backgrounds if @show_weekend_bg
        draw_day_numbers
      end

      private

      # Draw the month title
      def draw_title
        h1(@col, @row, Date::MONTHNAMES[@month], width: @width, align: @align)
      end

      # Draw weekday headers (M T W T F S S)
      def draw_weekday_headers
        headers_row = @row + 1
        day_names = %w[M T W T F S S]

        @pdf.font 'Helvetica', size: 7
        @pdf.fill_color Styling::Colors.TEXT_BLACK

        day_names.each_with_index do |day, i|
          cell_x = col_x(i)
          @pdf.text_box day,
                        at: [cell_x, @grid.y(headers_row)],
                        width: @col_width_pt,
                        height: @grid.height(1),
                        align: :center,
                        valign: :center
        end
      end

      # Draw weekend background shading
      def draw_weekend_backgrounds
        first_day = Date.new(@year, @month, 1)
        last_day = Date.new(@year, @month, -1)
        start_col_offset = (first_day.wday + 6) % 7 # Monday-based

        headers_row = @row + 1

        1.upto(last_day.day) do |day|
          date = Date.new(@year, @month, day)
          next unless date.saturday? || date.sunday?

          day_row = (start_col_offset + day - 1) / 7
          day_col = (start_col_offset + day - 1) % 7

          cal_row = headers_row + 1 + day_row
          cell_x = col_x(day_col)
          cell_y = @grid.y(cal_row)

          @pdf.fill_color Styling::Colors.WEEKEND_BG
          @pdf.transparent(0.1) do
            @pdf.fill_rectangle [cell_x, cell_y], @col_width_pt, @grid.height(1)
          end
        end

        @pdf.fill_color Styling::Colors.TEXT_BLACK
      end

      # Draw day numbers and optional links
      def draw_day_numbers
        first_day = Date.new(@year, @month, 1)
        last_day = Date.new(@year, @month, -1)
        start_col_offset = (first_day.wday + 6) % 7 # Monday-based

        headers_row = @row + 1
        current_row = 0
        current_col = start_col_offset

        @pdf.font 'Helvetica', size: 7
        @pdf.fill_color Styling::Colors.TEXT_BLACK

        1.upto(last_day.day) do |day|
          cal_row = headers_row + 1 + current_row
          cell_x = col_x(current_col)
          cell_y = @grid.y(cal_row)

          @pdf.text_box day.to_s,
                        at: [cell_x, cell_y],
                        width: @col_width_pt,
                        height: @grid.height(1),
                        align: :center,
                        valign: :center

          if @show_links
            date = Date.new(@year, @month, day)
            week_num = Utilities::DateCalculator.week_number_for_date(@year, date)
            link_bottom = cell_y - @grid.height(1)
            @pdf.link_annotation(
              [cell_x, link_bottom, cell_x + @col_width_pt, cell_y],
              Dest: "week_#{week_num}",
              Border: [0, 0, 0]
            )
          end

          current_col += 1
          if current_col >= 7
            current_col = 0
            current_row += 1
          end
        end
      end

      # Calculate x position for a column (0-6)
      #
      # @param col_index [Integer] Column index (0-6)
      # @return [Float] X position in points
      def col_x(col_index)
        @grid.x(@col) + (col_index * @col_width_pt)
      end
    end
  end
end
