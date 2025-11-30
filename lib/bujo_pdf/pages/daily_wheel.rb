# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Daily Wheel page - circular clock with 48 half-hour divisions.
    #
    # This page renders a circular time wheel with:
    # - 4 concentric circles defining bands
    # - 48 radial divisions (24 hours × 2 half-hours)
    # - Bold lines on hour marks, lighter lines on half-hour marks
    # - Lines extend in bands between circles (with one band left empty)
    # - Optional hour labels around the outside
    #
    # The wheel is centered on the page and sized to fit within the content area.
    #
    # Example:
    #   page = DailyWheel.new(pdf, { year: 2025 })
    #   page.generate
    class DailyWheel < Base
      # Mixin providing daily_wheel_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the daily wheel page.
        #
        # @return [void]
        def daily_wheel_page
          start_new_page
          context = build_context(page_key: :daily_wheel)
          DailyWheel.new(@pdf, context).generate
        end
      end

      # Configuration constants
      NUM_SEGMENTS = 48  # 24 hours × 2 half-hours
      SHOW_HOUR_LABELS = true  # Set to false to hide hour labels
      HOUR_LABEL_FONT_SIZE = 7

      # All radii as proportions (0.0 to 1.0) relative to max radius
      # Circle 5 is at proportion 360/380 of max radius
      CIRCLE_5_PROP = 360.0 / 380.0
      CIRCLE_BAND_WIDTH = 5.0 / 380.0    # Gap between circles 1-5
      OUTER_EXTENSION = 80.0 / 380.0     # How far lines extend beyond circle 5
      LABEL_OFFSET = 12.0 / 380.0        # Distance from outer extent to label center

      PROPORTIONS = [
        CIRCLE_5_PROP - (4 * CIRCLE_BAND_WIDTH),  # Circle 1 (innermost)
        CIRCLE_5_PROP - (3 * CIRCLE_BAND_WIDTH),  # Circle 2
        CIRCLE_5_PROP - (2 * CIRCLE_BAND_WIDTH),  # Circle 3
        CIRCLE_5_PROP - (1 * CIRCLE_BAND_WIDTH),  # Circle 4
        CIRCLE_5_PROP,                             # Circle 5
        CIRCLE_5_PROP + OUTER_EXTENSION            # Outer extent (for division lines)
      ].freeze

      # Line widths
      HOUR_LINE_WIDTH = 0.75
      HALF_HOUR_LINE_WIDTH = 0.25
      CIRCLE_LINE_WIDTH = 0.75

      # Set up the named destination for this page.
      def setup
        set_destination('daily_wheel')
        use_layout :full_page
      end

      # Render the daily wheel on the page.
      def render
        draw_dot_grid

        # Calculate center and scale
        center_x = Styling::Grid::PAGE_WIDTH / 2.0
        center_y = Styling::Grid::PAGE_HEIGHT / 2.0

        # Calculate scale to fit snugly (limited by width since 8.5" < 11")
        margin = @grid_system.width(2)  # 2 grid boxes margin
        usable_width = Styling::Grid::PAGE_WIDTH - (2 * margin)
        max_proportion = PROPORTIONS.max
        max_radius = usable_width / 2.0
        scale = max_radius / max_proportion

        # Convert proportions to actual radii
        radii = PROPORTIONS.map { |p| p * scale }

        # Draw wheel using Prawn's translate for centered coordinates
        @pdf.translate(center_x, center_y) do
          draw_night_backgrounds(radii)
          draw_circles(radii)
          draw_divisions(radii)
          draw_hour_labels(radii, scale) if SHOW_HOUR_LABELS
        end
      end

      private

      # Draw shaded backgrounds for night hours (10 PM to 7 AM).
      #
      # @param radii [Array<Float>] Array of radii in points
      def draw_night_backgrounds(radii)
        angle_step = (2 * Math::PI) / NUM_SEGMENTS
        start_angle = -Math::PI / 2.0

        inner_r = radii[2]  # Circle 3
        outer_r = radii[3]  # Circle 4

        @pdf.fill_color Styling::Colors.WEEKEND_BG

        # Night hours: 22, 23, 0, 1, 2, 3, 4, 5, 6 (10 PM to 7 AM)
        night_hours = [22, 23, 0, 1, 2, 3, 4, 5, 6]

        @pdf.transparent(0.2) do  # 20% opacity
          night_hours.each do |hour|
            # Each hour has 2 segments (on the hour and half past)
            2.times do |half|
              segment = (hour * 2) + half

              # Subtract to go clockwise
              angle1 = start_angle - (segment * angle_step)
              angle2 = start_angle - ((segment + 1) * angle_step)

              draw_arc_segment(inner_r, outer_r, angle1, angle2)
            end
          end
        end
      end

      # Draw a filled arc segment between two radii and two angles.
      #
      # @param inner_r [Float] Inner radius
      # @param outer_r [Float] Outer radius
      # @param angle1 [Float] Starting angle (radians)
      # @param angle2 [Float] Ending angle (radians)
      def draw_arc_segment(inner_r, outer_r, angle1, angle2)
        steps = 8  # Smoothness of arc

        @pdf.save_graphics_state
        @pdf.move_to(Math.cos(angle1) * outer_r, Math.sin(angle1) * outer_r)

        # Outer arc (from angle1 to angle2)
        steps.times do |i|
          t = (i + 1).to_f / steps
          a = angle1 + (angle2 - angle1) * t
          @pdf.line_to(Math.cos(a) * outer_r, Math.sin(a) * outer_r)
        end

        # Line to inner radius
        @pdf.line_to(Math.cos(angle2) * inner_r, Math.sin(angle2) * inner_r)

        # Inner arc (from angle2 back to angle1)
        steps.times do |i|
          t = (i + 1).to_f / steps
          a = angle2 + (angle1 - angle2) * t
          @pdf.line_to(Math.cos(a) * inner_r, Math.sin(a) * inner_r)
        end

        @pdf.fill
        @pdf.restore_graphics_state
      end

      # Draw the 4 concentric circles.
      #
      # @param radii [Array<Float>] Array of radii in points
      def draw_circles(radii)
        @pdf.stroke_color Styling::Colors.SECTION_HEADERS
        @pdf.line_width CIRCLE_LINE_WIDTH

        # Draw only circles 1-4 (indices 0-3)
        4.times do |i|
          @pdf.stroke_circle [0, 0], radii[i]
        end
      end

      # Draw the 48 radial divisions.
      #
      # @param radii [Array<Float>] Array of radii in points
      def draw_divisions(radii)
        @pdf.stroke_color Styling::Colors.TEXT_GRAY

        angle_step = (2 * Math::PI) / NUM_SEGMENTS
        start_angle = -Math::PI / 2.0  # Start from top (12 o'clock)

        NUM_SEGMENTS.times do |segment|
          angle = start_angle + (segment * angle_step)
          cos_a = Math.cos(angle)
          sin_a = Math.sin(angle)

          # Determine if this is an hour mark (every 2nd segment) or half-hour
          is_hour = (segment % 2).zero?
          @pdf.line_width is_hour ? HOUR_LINE_WIDTH : HALF_HOUR_LINE_WIDTH

          # Band 1: between circle 1 and circle 2 (indices 0-1)
          @pdf.stroke_line(
            [cos_a * radii[0], sin_a * radii[0]],
            [cos_a * radii[1], sin_a * radii[1]]
          )

          # Band 2: between circle 2 and 3 - NO DIVISIONS (intentionally empty)

          # Band 3: between circle 3 and circle 4 (indices 2-3)
          @pdf.stroke_line(
            [cos_a * radii[2], sin_a * radii[2]],
            [cos_a * radii[3], sin_a * radii[3]]
          )

          # Band 4: between circle 4 and circle 5 (indices 3-4)
          @pdf.stroke_line(
            [cos_a * radii[3], sin_a * radii[3]],
            [cos_a * radii[4], sin_a * radii[4]]
          )

          # Band 5: between circle 5 and outer extent (indices 4-5)
          @pdf.stroke_line(
            [cos_a * radii[4], sin_a * radii[4]],
            [cos_a * radii[5], sin_a * radii[5]]
          )
        end
      end

      # Draw hour labels around the outside of the wheel.
      #
      # @param radii [Array<Float>] Array of radii in points
      # @param scale [Float] Scale factor for converting proportions to points
      def draw_hour_labels(radii, scale)
        @pdf.fill_color Styling::Colors.TEXT_GRAY

        label_radius = radii[5] + (LABEL_OFFSET * scale)
        angle_step = (2 * Math::PI) / 24  # One label per hour
        start_angle = -Math::PI / 2.0  # Start from top (12 o'clock position = 0)

        # Text box dimensions for centering
        box_size = 20

        24.times do |hour|
          # Subtract to go clockwise (standard clock direction)
          angle = start_angle - (hour * angle_step)
          x = Math.cos(angle) * label_radius
          y = Math.sin(angle) * label_radius

          # Use text_box for proper centering
          @pdf.text_box hour.to_s,
                        at: [x - (box_size / 2), y + (box_size / 2)],
                        width: box_size,
                        height: box_size,
                        align: :center,
                        valign: :center,
                        size: HOUR_LABEL_FONT_SIZE,
                        overflow: :shrink_to_fit
        end
      end
    end
  end
end
