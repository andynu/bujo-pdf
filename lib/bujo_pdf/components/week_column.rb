# frozen_string_literal: true

require_relative 'sub_component_base'
require_relative '../utilities/styling'

module BujoPdf
  module Components
    # WeekColumn renders a single day column in the weekly view
    #
    # This component displays:
    # - 1-box-high header with three-letter weekday (gray, top-left) and date (centered)
    # - Weekend background styling (optional)
    # - Four ruled lines dividing the column into 2-box-high sections
    # - Time period labels (AM/PM/EVE) for Monday
    #
    # @example Basic usage
    #   column = BujoPdf::Components::WeekColumn.new(pdf, grid_system,
    #     date: Date.new(2025, 1, 6),
    #     day_name: "Monday",
    #     show_time_labels: true
    #   )
    #   column.render_at(5, 10, 5.57, 9)
    #
    # @example Weekend column
    #   column = BujoPdf::Components::WeekColumn.new(pdf, grid_system,
    #     date: Date.new(2025, 1, 11),
    #     day_name: "Saturday",
    #     weekend: true
    #   )
    #   column.render_at(30, 10, 5.57, 9)
    class WeekColumn < SubComponentBase
      # Default configuration values
      DEFAULTS = {
        line_count: 4,
        header_height_boxes: 1, # Header is 1 box high
        line_margin: 3,
        day_header_font_size: 8,
        day_date_font_size: 8,
        time_label_font_size: 6,
        header_color: nil,        # Will use Styling::Colors.SECTION_HEADERS if nil
        border_color: nil,        # Will use Styling::Colors.BORDERS if nil
        weekend_bg_color: nil,    # Will use Styling::Colors.WEEKEND_BG if nil
        show_time_labels: false,
        weekend: false
      }.freeze

      # Render the week column at the specified grid position
      #
      # @param col [Float] Starting column in grid coordinates
      # @param row [Float] Starting row in grid coordinates
      # @param width_boxes [Float] Width in grid boxes
      # @param height_boxes [Float] Height in grid boxes
      def render_at(col, row, width_boxes, height_boxes)
        date = option(:date)
        day_name = option(:day_name) || date&.strftime('%A')

        raise ArgumentError, "date or day_name required" unless date || day_name

        in_grid_box(col, row, width_boxes, height_boxes) do
          box = @grid.rect(col, row, width_boxes, height_boxes)
          draw_weekend_background(box[:width], box[:height]) if option(:weekend, DEFAULTS[:weekend])
          draw_border(box[:width], box[:height])
          draw_header(date, day_name, box[:width], box[:height])
          draw_date_label(date, box[:width], box[:height]) if option(:date_config) || option(:event_store)
          draw_ruled_lines(box[:width], box[:height])
          draw_time_labels(box[:width], box[:height]) if option(:show_time_labels, DEFAULTS[:show_time_labels])
        end
      end

      private

      # Draw subtle weekend background
      def draw_weekend_background(width, height)
        @pdf.fill_color option(:weekend_bg_color, DEFAULTS[:weekend_bg_color])
        @pdf.transparent(0.1) do
          @pdf.fill_rectangle [0, height], width, height
        end
        @pdf.fill_color Styling::Colors.TEXT_BLACK
      end

      # Draw column border
      def draw_border(width, height)
        @pdf.stroke_color option(:border_color, DEFAULTS[:border_color])
        @pdf.stroke_bounds
        @pdf.stroke_color Styling::Colors.TEXT_BLACK
      end

      # Draw day header with day name and date
      # Header is 1 box high with:
      # - Three-letter weekday in gray on top left
      # - Month/day centered
      def draw_header(date, day_name, width, height)
        header_height_boxes = option(:header_height_boxes, DEFAULTS[:header_height_boxes])
        header_height = @grid.height(header_height_boxes)
        header_color = option(:header_color, DEFAULTS[:header_color])
        font_size = option(:day_header_font_size, DEFAULTS[:day_header_font_size])

        # Three-letter weekday abbreviation in gray, top left
        short_day = day_name[0..2] if day_name
        if short_day
          @pdf.fill_color header_color
          @pdf.font "Helvetica", size: font_size
          @pdf.text_box short_day,
                       at: [2, height - 2],
                       width: width / 2,
                       height: header_height,
                       align: :left,
                       valign: :top
          @pdf.fill_color Styling::Colors.TEXT_BLACK
        end

        # Month/day centered
        if date
          date_str = date.strftime('%-m/%-d')
          @pdf.font "Helvetica", size: font_size
          @pdf.text_box date_str,
                       at: [0, height - 2],
                       width: width,
                       height: header_height,
                       align: :center,
                       valign: :top
        end
      end

      # Draw ruled lines that divide content into 2-box-high rows
      # Lines start at the bottom edge of the 1-box header
      def draw_ruled_lines(width, height)
        line_count = option(:line_count, DEFAULTS[:line_count])
        line_margin = option(:line_margin, DEFAULTS[:line_margin])
        border_color = option(:border_color, DEFAULTS[:border_color])
        header_height_boxes = option(:header_height_boxes, DEFAULTS[:header_height_boxes])

        # Calculate line spacing (2 boxes per section)
        box_height = @grid.height(1)
        section_height = box_height * 2 # Each section is 2 boxes high
        header_height = @grid.height(header_height_boxes)

        # Lines start at bottom of header
        first_line_y = height - header_height

        # Draw lines every 2 boxes, starting from bottom of header
        line_count.to_i.times do |line_num|
          y_pos = first_line_y - (line_num * section_height)
          @pdf.stroke_color border_color
          @pdf.stroke_horizontal_line line_margin, width - line_margin, at: y_pos
          @pdf.stroke_color Styling::Colors.TEXT_BLACK
        end

        # Store spacing info for time labels
        @line_spacing = section_height
        @line_start_y = first_line_y
      end

      # Draw time period labels (AM/PM/EVE) for Monday column
      def draw_time_labels(_width, _height)
        return unless @line_start_y && @line_spacing

        labels = ['AM', 'PM', 'EVE']
        label_font_size = option(:time_label_font_size, DEFAULTS[:time_label_font_size])
        border_color = option(:border_color, DEFAULTS[:border_color])

        @pdf.fill_color border_color
        @pdf.font "Helvetica", size: label_font_size

        labels.each_with_index do |label, idx|
          region_y = @line_start_y - (idx * @line_spacing) - 2
          @pdf.text_box label,
                       at: [3, region_y],
                       width: 20,
                       height: 10,
                       size: label_font_size
        end
        @pdf.fill_color Styling::Colors.TEXT_BLACK
      end

      # Draw highlighted date label below day header
      # Label appears directly below the 1-box header if date is highlighted
      # Supports both date_config highlights and calendar events
      def draw_date_label(date, width, height)
        return unless date

        # Check both date_config and event_store
        date_config = option(:date_config)
        event_store = option(:event_store)

        # Try date_config first (takes priority)
        highlighted_date = date_config&.date_for_day(date)

        # If no date_config entry, try calendar events
        calendar_events = []
        if !highlighted_date && event_store
          calendar_events = event_store.events_for_date(date, limit: 1)
          return if calendar_events.empty?
        end

        return unless highlighted_date || !calendar_events.empty?

        # Label box positioned 1 box below header (grid-aligned)
        # Label is 0.85 boxes high
        header_height_boxes = option(:header_height_boxes, DEFAULTS[:header_height_boxes])
        label_height_boxes = 0.85
        label_start_row = header_height_boxes + 1  # Skip 1 box after header

        label_height = @grid.height(label_height_boxes)
        label_y = height - @grid.height(label_start_row)

        # Horizontal padding (2pt on each side)
        h_padding = 2

        # Determine colors and label text based on source
        if highlighted_date
          # From date_config
          category_style = date_config.category_style(highlighted_date.category)
          priority_style = date_config.priority_style(highlighted_date.priority)
          bg_color = category_style['color']
          text_color = category_style['text_color']
          label_text = highlighted_date.label
          bold = priority_style['bold']
        else
          # From calendar events
          event = calendar_events.first
          bg_color = event.color || 'E5E5E5'
          text_color = '333333'
          label_text = event.display_label(include_icon: true)
          bold = false
        end

        # Background
        @pdf.fill_color bg_color
        @pdf.fill_rectangle [h_padding, label_y + label_height], width - (h_padding * 2), label_height
        @pdf.fill_color '000000'

        # Text (with small vertical and horizontal padding)
        v_padding = 1
        text_h_padding = 2

        @pdf.font('Helvetica-Bold') if bold

        @pdf.fill_color text_color
        @pdf.text_box label_text,
                      at: [h_padding + text_h_padding, label_y + label_height - v_padding],
                      width: width - (h_padding * 2) - (text_h_padding * 2),
                      height: label_height - (v_padding * 2),
                      size: 7,
                      align: :center,
                      valign: :center,
                      overflow: :shrink_to_fit

        @pdf.fill_color '000000'
        @pdf.font('Helvetica')  # Reset font
      end
    end
  end
end
