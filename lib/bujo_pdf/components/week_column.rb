# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative 'box'
require_relative 'hline'
require_relative 'text'

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
    #   canvas = Canvas.new(pdf, grid)
    #   column = BujoPdf::Components::WeekColumn.new(
    #     canvas: canvas,
    #     col: 5, row: 10, width: 5.57, height: 9,
    #     date: Date.new(2025, 1, 6),
    #     day_name: "Monday",
    #     show_time_labels: true
    #   )
    #   column.render
    #
    # @example Weekend column
    #   column = BujoPdf::Components::WeekColumn.new(
    #     canvas: canvas,
    #     col: 30, row: 10, width: 5.57, height: 9,
    #     date: Date.new(2025, 1, 11),
    #     day_name: "Saturday",
    #     weekend: true
    #   )
    #   column.render
    class WeekColumn < Component
      include Box::Mixin
      include HLine::Mixin
      include Text::Mixin

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

      def initialize(canvas:, col:, row:, width:, height:,
                     date: nil, day_name: nil,
                     line_count: DEFAULTS[:line_count],
                     header_height_boxes: DEFAULTS[:header_height_boxes],
                     line_margin: DEFAULTS[:line_margin],
                     day_header_font_size: DEFAULTS[:day_header_font_size],
                     day_date_font_size: DEFAULTS[:day_date_font_size],
                     time_label_font_size: DEFAULTS[:time_label_font_size],
                     header_color: DEFAULTS[:header_color],
                     border_color: DEFAULTS[:border_color],
                     weekend_bg_color: DEFAULTS[:weekend_bg_color],
                     show_time_labels: DEFAULTS[:show_time_labels],
                     weekend: DEFAULTS[:weekend],
                     date_config: nil, event_store: nil,
                     header_height: nil, header_padding: nil, lines_start: nil,
                     lines_padding: nil)
        super(canvas: canvas)
        @col = col
        @row = row
        @width_boxes = width
        @height_boxes = height
        @date = date
        @day_name = day_name || date&.strftime('%A')
        @line_count = line_count
        @header_height_boxes = header_height_boxes
        @line_margin = line_margin
        @day_header_font_size = day_header_font_size
        @day_date_font_size = day_date_font_size
        @time_label_font_size = time_label_font_size
        @header_color = header_color
        @border_color = border_color
        @weekend_bg_color = weekend_bg_color
        @show_time_labels = show_time_labels
        @weekend = weekend
        @date_config = date_config
        @event_store = event_store

        raise ArgumentError, "date or day_name required" unless @date || @day_name
      end

      def render
        draw_weekend_background if @weekend
        draw_border
        draw_header(@date, @day_name)
        draw_date_label(@date) if @date_config || @event_store
        draw_ruled_lines
        draw_time_labels if @show_time_labels
      end

      private

      def effective_header_color
        @header_color || Styling::Colors.SECTION_HEADERS
      end

      def effective_border_color
        @border_color || Styling::Colors.BORDERS
      end

      def effective_weekend_bg_color
        @weekend_bg_color || Styling::Colors.WEEKEND_BG
      end

      # Draw subtle weekend background
      def draw_weekend_background
        box(@col, @row, @width_boxes, @height_boxes,
            fill: effective_weekend_bg_color, stroke: nil, opacity: 0.1)
      end

      # Draw column border
      def draw_border
        box(@col, @row, @width_boxes, @height_boxes,
            stroke: effective_border_color, fill: nil)
      end

      # Draw day header with day name and date
      # Header is 1 box high with:
      # - Three-letter weekday in gray on top left (slight inset)
      # - Month/day centered
      def draw_header(date, day_name)
        # Small inset from column edges (0.2 boxes ~ 3pt)
        inset = 0.2

        # Three-letter weekday abbreviation in gray, top left with inset
        short_day = day_name[0..2] if day_name
        if short_day
          # Left portion of column, grid-aligned with inset
          text(@col + inset, @row, short_day,
               size: @day_header_font_size,
               color: effective_header_color,
               align: :left,
               width: @width_boxes.ceil.to_i,
               height: @header_height_boxes)
        end

        # Month/day centered in full column width (no inset for centered text)
        if date
          date_str = date.strftime('%-m/%-d')
          text(@col, @row, date_str,
               size: @day_header_font_size,
               align: :center,
               width: @width_boxes.ceil.to_i,
               height: @header_height_boxes)
        end
      end

      # Draw ruled lines that divide content into 2-box-high rows
      # Lines start at the bottom edge of the 1-box header
      def draw_ruled_lines
        # Lines are positioned at grid rows below the header
        # Each section is 2 boxes high, lines are at bottom of header + 2n boxes

        # Calculate line margin in grid boxes (approximate from pixels)
        margin_boxes = @line_margin.to_f / grid.width(1)
        line_width = @width_boxes - (margin_boxes * 2)

        # First line is at the bottom of the header row
        first_line_row = @row + @header_height_boxes

        # Draw lines every 2 boxes
        @line_count.to_i.times do |line_num|
          line_row = first_line_row + (line_num * 2)
          hline(@col + margin_boxes, line_row, line_width, color: effective_border_color)
        end

        # Store row info for time labels
        @first_line_row = first_line_row
      end

      # Draw time period labels (AM/PM/EVE) for Monday column
      def draw_time_labels
        return unless @first_line_row

        # Same inset as header text (0.2 boxes ~ 3pt)
        inset = 0.2
        labels = ['AM', 'PM', 'EVE']

        labels.each_with_index do |label, idx|
          # Each section is 2 boxes high, label goes at top of each section
          section_row = @first_line_row + (idx * 2)
          text(@col + inset, section_row, label,
               size: @time_label_font_size,
               color: effective_border_color,
               align: :left,
               width: 2,
               height: 1)
        end
      end

      # Draw highlighted date label below day header
      # Label appears directly below the 1-box header if date is highlighted
      # Supports both date_config highlights and calendar events
      #
      # Note: Uses raw PDF calls for text because it needs overflow: :shrink_to_fit
      # which the text verb doesn't support yet.
      def draw_date_label(date)
        return unless date

        # Try date_config first (takes priority)
        highlighted_date = @date_config&.date_for_day(date)

        # If no date_config entry, try calendar events
        calendar_events = []
        if !highlighted_date && @event_store
          calendar_events = @event_store.events_for_date(date, limit: 1)
          return if calendar_events.empty?
        end

        return unless highlighted_date || !calendar_events.empty?

        # Label box positioned 1 box below header (grid-aligned)
        # Label is 0.85 boxes high
        label_height_boxes = 0.85
        label_row = @row + @header_height_boxes + 1  # Skip 1 box after header

        label_height = grid.height(label_height_boxes)
        label_y = grid.y(label_row)

        # Horizontal padding (2pt on each side)
        h_padding = 2
        width = grid.width(@width_boxes)

        # Determine colors and label text based on source
        if highlighted_date
          # From date_config
          category_style = @date_config.category_style(highlighted_date.category)
          priority_style = @date_config.priority_style(highlighted_date.priority)
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
        label_x = grid.x(@col) + h_padding
        pdf.fill_color bg_color
        pdf.fill_rectangle [label_x, label_y], width - (h_padding * 2), label_height
        pdf.fill_color '000000'

        # Text (with small vertical and horizontal padding)
        v_padding = 1
        text_h_padding = 2

        pdf.font('Helvetica-Bold') if bold

        pdf.fill_color text_color
        pdf.text_box label_text,
                      at: [label_x + text_h_padding, label_y - v_padding],
                      width: width - (h_padding * 2) - (text_h_padding * 2),
                      height: label_height - (v_padding * 2),
                      size: 7,
                      align: :center,
                      valign: :center,
                      overflow: :shrink_to_fit

        pdf.fill_color '000000'
        pdf.font('Helvetica')  # Reset font
      end
    end
  end
end
