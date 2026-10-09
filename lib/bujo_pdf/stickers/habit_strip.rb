# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Stickers
    # A week of habit checkboxes: named rows down the left, seven day columns.
    #
    # Deliberately unlabelled beyond the weekday initials. The planner's
    # tracker page failed partly because it *named* what to track, which makes
    # a template into someone else's idea; leaving the rows blank makes it
    # yours at the moment you place it.
    class HabitStrip < Base
      DAYS = %w[M T W T F S S].freeze
      LABEL_COLS = 5    # width of the habit-name column
      HEADER_ROWS = 1
      DEFAULT_ROWS = 5  # habit rows

      # @return [Array<HabitStrip>]
      def self.all
        [new]
      end

      attr_reader :rows

      # @param rows [Integer] Number of habit rows
      def initialize(rows: DEFAULT_ROWS)
        @rows = rows
        super(
          slug: "habit_strip_#{rows}",
          title: "Habit strip, #{rows} rows x 7 days",
          width_boxes: LABEL_COLS + DAYS.length,
          height_boxes: HEADER_ROWS + rows
        )
      end

      def draw(pdf)
        draw_day_headers(pdf)
        draw_name_rules(pdf)
        draw_checkboxes(pdf)
      end

      private

      def draw_day_headers(pdf)
        DAYS.each_with_index do |day, i|
          label(pdf, LABEL_COLS + i, 0, day,
                cols: 1, rows: HEADER_ROWS, size: 6, align: :center, style: :bold)
        end
      end

      # A rule under each habit name, so the column works as a writing line.
      def draw_name_rules(pdf)
        rows.times do |r|
          rule(pdf, 0, LABEL_COLS - 0.4, HEADER_ROWS + r + 1)
        end
      end

      def draw_checkboxes(pdf)
        inset = 0.15
        rows.times do |r|
          DAYS.length.times do |c|
            frame(pdf,
                  LABEL_COLS + c + inset,
                  HEADER_ROWS + r + inset,
                  1 - (inset * 2), 1 - (inset * 2),
                  radius: 1)
          end
        end
      end
    end
  end
end
