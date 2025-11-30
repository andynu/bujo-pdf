# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative '../utilities/date_calculator'
require_relative 'h1'
require_relative 'week_grid'

module BujoPdf
  module Components
    # MiniMonth renders a compact monthly calendar using WeekGrid for column layout.
    #
    # Renders a month title, weekday headers (M T W T F S S), and day numbers
    # in a grid. Uses WeekGrid for consistent column widths with optional
    # quantization for grid alignment.
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
    class MiniMonth < Component
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
        # @param quantize [Boolean] Use grid-aligned column widths when width divisible by 7 (default: true)
        # @return [void]
        def mini_month(col, row, width, month:, year:, align: :center, show_links: true, show_weekend_bg: true, quantize: true)
          c = @canvas || Canvas.new(@pdf, @grid)
          MiniMonth.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            month: month,
            year: year,
            align: align,
            show_links: show_links,
            show_weekend_bg: show_weekend_bg,
            quantize: quantize
          ).render
        end
      end

      # Initialize a new MiniMonth component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top edge)
      # @param width [Integer] Width in grid boxes
      # @param month [Integer] Month number (1-12)
      # @param year [Integer] Year
      # @param align [Symbol] Title alignment
      # @param show_links [Boolean] Add clickable links
      # @param show_weekend_bg [Boolean] Show weekend background
      # @param quantize [Boolean] Use grid-aligned column widths
      def initialize(canvas:, col:, row:, width:, month:, year:, align: :center, show_links: true, show_weekend_bg: true, quantize: true)
        super(canvas: canvas)
        @col = col
        @row = row
        @width = width
        @month = month
        @year = year
        @align = align
        @show_links = show_links
        @show_weekend_bg = show_weekend_bg
        @quantize = quantize

        # Create WeekGrid for column layout (used for headers row position)
        # The WeekGrid handles quantization: grid-aligned widths when divisible by 7
        @week_grid = WeekGrid.from_grid(
          canvas: @canvas,
          col: @col,
          row: @row + 1, # Headers are at row + 1 (after title)
          width_boxes: @width,
          height_boxes: 1,
          quantize: @quantize,
          show_headers: false # We'll draw our own headers with custom font size
        )
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

      # Draw weekday headers (M T W T F S S) using WeekGrid's each_cell pattern
      def draw_weekday_headers
        day_names = %w[M T W T F S S]

        pdf.font 'Helvetica', size: 7
        pdf.fill_color Styling::Colors.TEXT_BLACK

        @week_grid.each_cell do |day_index, cell_rect|
          pdf.text_box day_names[day_index],
                        at: [cell_rect[:x], cell_rect[:y]],
                        width: cell_rect[:width],
                        height: grid.height(1),
                        align: :center,
                        valign: :center
        end
      end

      # Draw weekend background shading using WeekGrid's cell_rect for column positioning
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
          cell_rect = @week_grid.cell_rect(day_col)
          cell_y = grid.y(cal_row)

          pdf.fill_color Styling::Colors.WEEKEND_BG
          pdf.transparent(0.1) do
            pdf.fill_rectangle [cell_rect[:x], cell_y], cell_rect[:width], grid.height(1)
          end
        end

        pdf.fill_color Styling::Colors.TEXT_BLACK
      end

      # Draw day numbers and optional links using WeekGrid's cell_rect for column positioning
      def draw_day_numbers
        first_day = Date.new(@year, @month, 1)
        last_day = Date.new(@year, @month, -1)
        start_col_offset = (first_day.wday + 6) % 7 # Monday-based

        headers_row = @row + 1
        current_row = 0
        current_col = start_col_offset

        pdf.font 'Helvetica', size: 7
        pdf.fill_color Styling::Colors.TEXT_BLACK

        1.upto(last_day.day) do |day|
          cal_row = headers_row + 1 + current_row
          cell_rect = @week_grid.cell_rect(current_col)
          cell_y = grid.y(cal_row)

          pdf.text_box day.to_s,
                        at: [cell_rect[:x], cell_y],
                        width: cell_rect[:width],
                        height: grid.height(1),
                        align: :center,
                        valign: :center

          if @show_links
            date = Date.new(@year, @month, day)
            week_num = Utilities::DateCalculator.week_number_for_date(@year, date)
            link_bottom = cell_y - grid.height(1)
            pdf.link_annotation(
              [cell_rect[:x], link_bottom, cell_rect[:x] + cell_rect[:width], cell_y],
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
    end
  end
end
