# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
require_relative '../utilities/sun_times'
require_relative 'text'

module BujoPdf
  module Components
    # DaylightBands turns a weekly page's notes area into an optional hour
    # planner: one block per hour per day, tinted where the hour falls in
    # night or civil twilight, with hour numbers once down the Monday column.
    #
    # The tints are drawn as solid fills and must go down before the dot grid
    # so the dots stay on top. They are meant to be barely visible, well below
    # any contrast guideline; raising them makes the notes area look shaded.
    #
    # Example usage:
    #   DaylightBands.new(canvas: canvas, week_start: Date.new(2026, 12, 14),
    #                     col: 2, row: 12, width: 40).render
    class DaylightBands < Component
      include Styling::Colors
      include Text::Mixin

      FIRST_HOUR = 7
      LAST_HOUR = 21
      ROWS_PER_HOUR = 2
      GAP = 0.5           # points between neighbouring hour blocks
      LABEL_FONT_SIZE = 6
      LABEL_INSET = 0.2   # grid boxes, matching WeekColumn's text inset

      def initialize(canvas:, week_start:, col:, row:, width:)
        super(canvas: canvas)
        @week_start = week_start
        @col = col
        @row = row
        @width = width
      end

      def render
        draw_bands
        draw_hour_labels
      end

      private

      def hours
        (FIRST_HOUR..LAST_HOUR)
      end

      def draw_bands
        # Same quantized columns as the daily section above
        week_grid = grid.week_grid(@col, @row, @width, hours.size * ROWS_PER_HOUR,
                                   quantize: true, show_headers: false)

        week_grid.each_cell do |day_index, cell|
          sun = Utilities::SunTimes.for(@week_start + day_index)
          hours.each_with_index do |hour, index|
            draw_hour_block(sun, hour, index, cell[:x] + GAP, cell[:width] - (2 * GAP))
          end
        end
      end

      def draw_hour_block(sun, hour, index, x, width)
        block_top = grid.y(@row + (index * ROWS_PER_HOUR))
        points_per_minute = grid.height(ROWS_PER_HOUR) / 60.0
        start = hour * 60

        sun.shaded_spans(start, start + 60).each do |phase, from, to|
          top = [block_top - ((from - start) * points_per_minute), block_top - GAP].min
          bottom = [block_top - ((to - start) * points_per_minute), block_top - grid.height(ROWS_PER_HOUR) + GAP].max
          next if top <= bottom

          with_fill_color(phase == :night ? color_night_bg : color_twilight_bg) do
            pdf.fill_rectangle([x, top], width, top - bottom)
          end
        end
      end

      def draw_hour_labels
        hours.each_with_index do |hour, index|
          text(@col + LABEL_INSET, @row + (index * ROWS_PER_HOUR), (((hour - 1) % 12) + 1).to_s,
               size: LABEL_FONT_SIZE,
               color: color_borders,
               align: :left,
               width: 2,
               height: 1)
        end
      end
    end
  end
end
