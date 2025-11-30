# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Example tracker spread demonstrating creative grid usage.
    #
    # This page shows how the dot grid can be used for various tracking
    # purposes like habit tracking, mood tracking, sleep logs, etc.
    # It demonstrates possibilities without prescribing structure.
    #
    # Design philosophy: "Show, don't prescribe"
    # - Display example tracker layouts
    # - Provide inspiration, not requirements
    # - Let users design their own trackers
    #
    # Example:
    #   page = TrackerExample.new(pdf, context)
    #   page.generate
    class TrackerExample < Base
      register_page :tracker_example,
        title: "Tracker Ideas",
        dest: "tracker_example"

      # Mixin providing tracker_example_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the tracker example page.
        #
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def tracker_example_page
          define_page(dest: 'tracker_example', title: 'Tracker Ideas', type: :template) do |ctx|
            TrackerExample.new(@pdf, ctx).generate
          end
        end
      end

      def setup
        set_destination("tracker_example")
        use_layout :full_page
      end

      def render
        draw_header
        draw_habit_tracker_example
        draw_mood_tracker_example
        draw_footer_note
      end

      private

      # Draw the page header
      #
      # @return [void]
      def draw_header
        header_box = @grid_system.rect(2, 1, 39, 3)

        @pdf.bounding_box([header_box[:x], header_box[:y]],
                          width: header_box[:width],
                          height: header_box[:height]) do
          @pdf.text "Tracker Ideas",
                    size: 18,
                    style: :bold,
                    align: :left,
                    valign: :center
        end

        subtitle_box = @grid_system.rect(2, 4, 39, 2)
        @pdf.bounding_box([subtitle_box[:x], subtitle_box[:y]],
                          width: subtitle_box[:width],
                          height: subtitle_box[:height]) do
          @pdf.text "Examples to spark your creativity - adapt these to your needs",
                    size: 10,
                    style: :italic,
                    color: '666666',
                    align: :left,
                    valign: :top
        end
      end

      # Draw example habit tracker
      #
      # @return [void]
      def draw_habit_tracker_example
        start_row = 8

        # Section label
        label_box = @grid_system.rect(2, start_row, 39, 2)
        @pdf.bounding_box([label_box[:x], label_box[:y]],
                          width: label_box[:width],
                          height: label_box[:height]) do
          @pdf.text "Habit Tracker",
                    size: 12,
                    style: :bold,
                    align: :left,
                    valign: :bottom
        end

        # Draw mini grid example
        grid_start_row = start_row + 3
        days = 31
        habits = ["Exercise", "Read", "Meditate", "Journal", "Water"]

        # Column headers (days 1-31)
        draw_day_headers(10, grid_start_row, days)

        # Habit rows
        habits.each_with_index do |habit, index|
          row = grid_start_row + 2 + index
          draw_habit_row(habit, row, days)
        end
      end

      # Draw day number headers
      #
      # @param start_col [Integer] Starting column
      # @param row [Integer] Row for headers
      # @param count [Integer] Number of days
      # @return [void]
      def draw_day_headers(start_col, row, count)
        cell_width = 1
        [1, 7, 14, 21, 28, 31].each do |day|
          next if day > count

          col = start_col + (day - 1) * cell_width
          x = @grid_system.x(col)
          y = @grid_system.y(row)

          @pdf.text_box day.to_s,
                        at: [x, y],
                        width: @grid_system.width(cell_width),
                        height: @grid_system.height(1),
                        size: 7,
                        color: '999999',
                        align: :center,
                        valign: :center
        end
      end

      # Draw a single habit row with boxes
      #
      # @param habit [String] Habit name
      # @param row [Integer] Grid row
      # @param days [Integer] Number of day boxes
      # @return [void]
      def draw_habit_row(habit, row, days)
        # Habit label
        label_x = @grid_system.x(2)
        label_y = @grid_system.y(row)
        @pdf.text_box habit,
                      at: [label_x, label_y],
                      width: @grid_system.width(7),
                      height: @grid_system.height(1),
                      size: 8,
                      color: '666666',
                      align: :right,
                      valign: :center

        # Draw small boxes for each day
        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.25

        days.times do |i|
          col = 10 + i
          box_x = @grid_system.x(col)
          box_y = @grid_system.y(row)
          box_size = @grid_system.width(0.8)

          @pdf.stroke_rectangle [box_x + 1, box_y - 2], box_size, box_size
        end

        @pdf.stroke_color '000000'
      end

      # Draw example mood tracker
      #
      # @return [void]
      def draw_mood_tracker_example
        start_row = 24

        # Section label
        label_box = @grid_system.rect(2, start_row, 39, 2)
        @pdf.bounding_box([label_box[:x], label_box[:y]],
                          width: label_box[:width],
                          height: label_box[:height]) do
          @pdf.text "Mood / Energy Log",
                    size: 12,
                    style: :bold,
                    align: :left,
                    valign: :bottom
        end

        # Description
        desc_box = @grid_system.rect(2, start_row + 2, 39, 2)
        @pdf.bounding_box([desc_box[:x], desc_box[:y]],
                          width: desc_box[:width],
                          height: desc_box[:height]) do
          @pdf.text "Rate daily (1-5) or use symbols: ++ + = - --",
                    size: 9,
                    style: :italic,
                    color: '999999',
                    align: :left,
                    valign: :top
        end

        # Draw simple weekly grid example
        grid_start_row = start_row + 5
        draw_weekly_mood_grid(grid_start_row)

        # Other ideas section
        draw_other_ideas(start_row + 15)
      end

      # Draw a weekly mood/energy grid
      #
      # @param start_row [Integer] Starting row
      # @return [void]
      def draw_weekly_mood_grid(start_row)
        days = %w[Mon Tue Wed Thu Fri Sat Sun]
        metrics = ["Mood", "Energy", "Sleep (hrs)"]

        # Day headers
        days.each_with_index do |day, i|
          col = 10 + (i * 4)
          x = @grid_system.x(col)
          y = @grid_system.y(start_row)

          @pdf.text_box day,
                        at: [x, y],
                        width: @grid_system.width(4),
                        height: @grid_system.height(1),
                        size: 8,
                        color: '666666',
                        align: :center,
                        valign: :center
        end

        # Metric rows
        metrics.each_with_index do |metric, mi|
          row = start_row + 2 + (mi * 2)

          # Label
          @pdf.text_box metric,
                        at: [@grid_system.x(2), @grid_system.y(row)],
                        width: @grid_system.width(7),
                        height: @grid_system.height(2),
                        size: 8,
                        color: '666666',
                        align: :right,
                        valign: :center

          # Day cells
          @pdf.stroke_color 'DDDDDD'
          @pdf.line_width 0.5

          7.times do |di|
            col = 10 + (di * 4)
            box = @grid_system.rect(col, row, 3, 2)
            @pdf.stroke_rectangle [box[:x], box[:y]], box[:width], box[:height]
          end

          @pdf.stroke_color '000000'
        end
      end

      # Draw other tracker ideas
      #
      # @param start_row [Integer] Starting row
      # @return [void]
      def draw_other_ideas(start_row)
        label_box = @grid_system.rect(2, start_row, 39, 2)
        @pdf.bounding_box([label_box[:x], label_box[:y]],
                          width: label_box[:width],
                          height: label_box[:height]) do
          @pdf.text "More Ideas",
                    size: 12,
                    style: :bold,
                    align: :left,
                    valign: :bottom
        end

        ideas = [
          "Water intake (glasses per day)",
          "Gratitude (3 things daily)",
          "Expense tracking (categories)",
          "Reading log (pages/books)",
          "Exercise types and duration",
          "Project progress (milestones)"
        ]

        ideas.each_with_index do |idea, i|
          row = start_row + 3 + i
          col = i < 3 ? 2 : 22  # Two columns
          row = row - 3 if i >= 3

          @pdf.text_box "- #{idea}",
                        at: [@grid_system.x(col), @grid_system.y(row)],
                        width: @grid_system.width(18),
                        height: @grid_system.height(1),
                        size: 9,
                        color: '666666',
                        align: :left,
                        valign: :center
        end
      end

      # Draw footer note
      #
      # @return [void]
      def draw_footer_note
        footer_box = @grid_system.rect(2, 50, 39, 3)

        @pdf.bounding_box([footer_box[:x], footer_box[:y]],
                          width: footer_box[:width],
                          height: footer_box[:height]) do
          @pdf.text "Create your own! Use the dot grid as a canvas for any tracking system that works for you.",
                    size: 10,
                    style: :italic,
                    color: '999999',
                    align: :center,
                    valign: :center
        end
      end
    end
  end
end
