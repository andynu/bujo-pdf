# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/styling'

module SubComponent
  # WeekColumn renders a single day column in the weekly view
  #
  # This component displays:
  # - Day header with day name and date
  # - Weekend background styling (optional)
  # - Ruled lines for note-taking
  # - Time period labels (AM/PM/EVE) for Monday
  #
  # @example Basic usage
  #   column = SubComponent::WeekColumn.new(pdf, grid_system,
  #     date: Date.new(2025, 1, 6),
  #     day_name: "Monday",
  #     show_time_labels: true
  #   )
  #   column.render_at(5, 10, 5.57, 9)
  #
  # @example Weekend column
  #   column = SubComponent::WeekColumn.new(pdf, grid_system,
  #     date: Date.new(2025, 1, 11),
  #     day_name: "Saturday",
  #     weekend: true
  #   )
  #   column.render_at(30, 10, 5.57, 9)
  class WeekColumn < Base
    # Default configuration values
    DEFAULTS = {
      line_count: 4,
      header_height: 30,
      header_padding: 2,
      lines_start: 35,
      lines_padding: 40,
      line_margin: 3,
      day_header_font_size: 9,
      day_date_font_size: 8,
      time_label_font_size: 6,
      border_color: Styling::Colors::BORDERS,
      weekend_bg_color: Styling::Colors::WEEKEND_BG,
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
        draw_ruled_lines(box[:width], box[:height])
        draw_time_labels(box[:width], box[:height]) if option(:show_time_labels, DEFAULTS[:show_time_labels])
      end
    end

    private

    # Draw subtle weekend background
    def draw_weekend_background(width, height)
      @pdf.fill_color option(:weekend_bg_color, DEFAULTS[:weekend_bg_color])
      @pdf.fill_rectangle [0, height], width, height
      @pdf.fill_color '000000'
    end

    # Draw column border
    def draw_border(width, height)
      @pdf.stroke_color option(:border_color, DEFAULTS[:border_color])
      @pdf.stroke_bounds
      @pdf.stroke_color '000000'
    end

    # Draw day header with day name and date
    def draw_header(date, day_name, width, height)
      header_padding = option(:header_padding, DEFAULTS[:header_padding])
      header_height = option(:header_height, DEFAULTS[:header_height])
      date_font_size = option(:day_date_font_size, DEFAULTS[:day_date_font_size])

      header_text = if date
        "#{day_name}\n#{date.strftime('%-m/%-d')}"
      else
        day_name
      end

      @pdf.font "Helvetica-Bold", size: option(:day_header_font_size, DEFAULTS[:day_header_font_size])
      @pdf.text_box header_text,
                   at: [header_padding, height - header_padding],
                   width: width - (header_padding * 2),
                   height: header_height,
                   align: :center,
                   size: date_font_size
    end

    # Draw evenly-spaced ruled lines for notes
    def draw_ruled_lines(width, height)
      line_count = option(:line_count, DEFAULTS[:line_count])
      lines_start = option(:lines_start, DEFAULTS[:lines_start])
      lines_padding = option(:lines_padding, DEFAULTS[:lines_padding])
      line_margin = option(:line_margin, DEFAULTS[:line_margin])
      border_color = option(:border_color, DEFAULTS[:border_color])

      line_start_y = height - lines_start
      available_space = height - lines_padding
      line_spacing = available_space / line_count.to_f

      line_count.to_i.times do |line_num|
        y_pos = line_start_y - (line_num * line_spacing)
        @pdf.stroke_color border_color
        @pdf.stroke_horizontal_line line_margin, width - line_margin, at: y_pos
        @pdf.stroke_color '000000'
      end

      # Store line_spacing and line_start_y for time labels
      @line_spacing = line_spacing
      @line_start_y = line_start_y
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
      @pdf.fill_color '000000'
    end
  end
end
