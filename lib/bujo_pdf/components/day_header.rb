# frozen_string_literal: true

require_relative 'sub_component_base'
require_relative '../utilities/styling'

module BujoPdf
  module Components
    # DayHeader renders a single day header cell with date information
    #
    # This component displays day name and/or date number in various formats.
    # Useful for weekly pages, calendar views, and daily sections.
    #
    # @example Full day header
    #   header = BujoPdf::Components::DayHeader.new(pdf, grid_system,
    #     date: Date.new(2025, 1, 6),
    #     format: :full,
    #     weekend: false
    #   )
    #   header.render_at(5, 10, 5, 1.5)
    #
    # @example Short format
    #   header = BujoPdf::Components::DayHeader.new(pdf, grid_system,
    #     date: Date.new(2025, 1, 11),
    #     format: :short,
    #     weekend: true
    #   )
    #   header.render_at(30, 10, 5, 1.5)
    class DayHeader < SubComponentBase
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

      # Render the day header at the specified grid position
      #
      # @param col [Float] Starting column in grid coordinates
      # @param row [Float] Starting row in grid coordinates
      # @param width_boxes [Float] Width in grid boxes
      # @param height_boxes [Float] Height in grid boxes
      def render_at(col, row, width_boxes, height_boxes)
        date = option(:date)
        raise ArgumentError, "date required" unless date

        in_grid_box(col, row, width_boxes, height_boxes) do
          box = @grid.rect(col, row, width_boxes, height_boxes)
          draw_background(box[:width], box[:height]) if option(:weekend, DEFAULTS[:weekend])
          draw_header(date, box[:width], box[:height])
        end
      end

      private

      # Draw weekend background
      def draw_background(width, height)
        @pdf.fill_color option(:weekend_bg_color, DEFAULTS[:weekend_bg_color])
        @pdf.fill_rectangle [0, height], width, height
        @pdf.fill_color Styling::Colors.TEXT_BLACK
      end

      # Draw day header text
      def draw_header(date, width, height)
        format = option(:format, DEFAULTS[:format])
        show_day_name = option(:show_day_name, DEFAULTS[:show_day_name])
        show_date_number = option(:show_date_number, DEFAULTS[:show_date_number])
        show_month = option(:show_month, DEFAULTS[:show_month])
        font_size = option(:font_size, DEFAULTS[:font_size])
        day_font_size = option(:day_font_size) || font_size
        date_font_size = option(:date_font_size) || (font_size - 1)
        header_padding = option(:header_padding, DEFAULTS[:header_padding])
        align = option(:align, DEFAULTS[:align])
        valign = option(:valign, DEFAULTS[:valign])
        text_color = option(:text_color, DEFAULTS[:text_color])

        # Format header text based on format option
        header_text = case format
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
          if show_month
            date.strftime('%-m/%-d')
          else
            date.strftime('%-d')
          end
        else
          # Custom format: build from show_* options
          parts = []
          parts << date.strftime('%A') if show_day_name
          if show_date_number
            parts << (show_month ? date.strftime('%-m/%-d') : date.strftime('%-d'))
          end
          parts.join("\n")
        end

        # Draw text
        @pdf.font "Helvetica-Bold", size: day_font_size
        @pdf.fill_color text_color
        @pdf.text_box header_text,
                     at: [header_padding, height - header_padding],
                     width: width - (header_padding * 2),
                     height: height - (header_padding * 2),
                     align: align,
                     valign: valign,
                     size: date_font_size

        @pdf.fill_color Styling::Colors.TEXT_BLACK
      end
    end
  end
end
