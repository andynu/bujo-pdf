# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'

module BujoPdf
  module Components
    # DayHeader renders a single day header cell with date information
    #
    # This component displays day name and/or date number in various formats.
    # Useful for weekly pages, calendar views, and daily sections.
    #
    # @example Full day header
    #   canvas = Canvas.new(pdf, grid)
    #   header = BujoPdf::Components::DayHeader.new(
    #     canvas: canvas,
    #     col: 5, row: 10, width: 5, height: 1.5,
    #     date: Date.new(2025, 1, 6),
    #     format: :full,
    #     weekend: false
    #   )
    #   header.render
    #
    # @example Short format
    #   header = BujoPdf::Components::DayHeader.new(
    #     canvas: canvas,
    #     col: 30, row: 10, width: 5, height: 1.5,
    #     date: Date.new(2025, 1, 11),
    #     format: :short,
    #     weekend: true
    #   )
    #   header.render
    class DayHeader < Component
      # Default configuration values
      DEFAULTS = {
        format: :full,                # :full, :short, :abbrev, :day_only, :date_only
        show_day_name: true,
        show_date_number: true,
        show_month: false,
        weekend: false,
        font_size: 10,
        day_font_size: nil,           # If nil, uses font_size
        date_font_size: nil,          # If nil, uses font_size - 1
        header_padding: 2,
        align: :center,
        valign: :top,
        weekend_bg_color: nil,        # Will use Styling::Colors.WEEKEND_BG if nil
        text_color: nil               # Will use Styling::Colors.TEXT_BLACK if nil
      }.freeze

      def initialize(canvas:, col:, row:, width:, height:, date:,
                     format: DEFAULTS[:format],
                     show_day_name: DEFAULTS[:show_day_name],
                     show_date_number: DEFAULTS[:show_date_number],
                     show_month: DEFAULTS[:show_month],
                     weekend: DEFAULTS[:weekend],
                     font_size: DEFAULTS[:font_size],
                     day_font_size: DEFAULTS[:day_font_size],
                     date_font_size: DEFAULTS[:date_font_size],
                     header_padding: DEFAULTS[:header_padding],
                     align: DEFAULTS[:align],
                     valign: DEFAULTS[:valign],
                     weekend_bg_color: DEFAULTS[:weekend_bg_color],
                     text_color: DEFAULTS[:text_color])
        super(canvas: canvas)
        @col = col
        @row = row
        @width_boxes = width
        @height_boxes = height
        @date = date
        @format = format
        @show_day_name = show_day_name
        @show_date_number = show_date_number
        @show_month = show_month
        @weekend = weekend
        @font_size = font_size
        @day_font_size = day_font_size || font_size
        @date_font_size = date_font_size || (font_size - 1)
        @header_padding = header_padding
        @align = align
        @valign = valign
        @weekend_bg_color = weekend_bg_color
        @text_color = text_color
      end

      def render
        box = grid.rect(@col, @row, @width_boxes, @height_boxes)

        pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
          draw_background(box[:width], box[:height]) if @weekend
          draw_header(@date, box[:width], box[:height])
        end
      end

      private

      # Draw weekend background
      def draw_background(width, height)
        pdf.fill_color @weekend_bg_color || Styling::Colors.WEEKEND_BG
        pdf.fill_rectangle [0, height], width, height
        pdf.fill_color Styling::Colors.TEXT_BLACK
      end

      # Draw day header text
      def draw_header(date, width, height)
        # Format header text based on format option
        header_text = case @format
        when :full
          day_name = date.strftime('%A')
          date_str = date.strftime('%-m/%-d')
          "#{day_name}\n#{date_str}"
        when :short
          day_name = date.strftime('%a')  # Mon, Tue, etc.
          date_str = date.strftime('%-m/%-d')
          "#{day_name}\n#{date_str}"
        when :abbrev
          day_name = date.strftime('%a')[0]  # M, T, W, etc.
          date_str = date.strftime('%-d')
          "#{day_name}\n#{date_str}"
        when :day_only
          date.strftime('%A')
        when :date_only
          if @show_month
            date.strftime('%-m/%-d')
          else
            date.strftime('%-d')
          end
        else
          # Custom format: build from show_* options
          parts = []
          parts << date.strftime('%A') if @show_day_name
          if @show_date_number
            parts << (@show_month ? date.strftime('%-m/%-d') : date.strftime('%-d'))
          end
          parts.join("\n")
        end

        # Draw text
        pdf.font "Helvetica-Bold", size: @day_font_size
        pdf.fill_color @text_color || Styling::Colors.TEXT_BLACK
        pdf.text_box header_text,
                     at: [@header_padding, height - @header_padding],
                     width: width - (@header_padding * 2),
                     height: height - (@header_padding * 2),
                     align: @align,
                     valign: @valign,
                     size: @date_font_size

        pdf.fill_color Styling::Colors.TEXT_BLACK
      end
    end
  end
end
