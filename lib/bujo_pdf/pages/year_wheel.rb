# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Year Wheel page - circular calendar with 365 radial divisions.
    #
    # This page renders a circular nature calendar wheel with:
    # - 4 concentric circles defining bands
    # - 365 radial divisions (one per day of the year)
    # - Lines extend in bands between circles (with one band left empty)
    # - Month markers with labels at the start of each month
    #
    # The wheel is centered on the page and sized to fit within the content area.
    #
    # Example:
    #   page = YearWheel.new(pdf, { year: 2025 })
    #   page.generate
    class YearWheel < Base
      # Configuration constants
      NUM_DAYS = 365

      # Month abbreviations
      MONTH_LABELS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

      # Day of year (0-indexed) when each month starts (non-leap year)
      MONTH_START_DAYS = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334].freeze

      # All radii as proportions (0.0 to 1.0) relative to max radius
      # Circle 5 is at proportion 360/380 of max radius
      CIRCLE_5_PROP = 360.0 / 380.0
      CIRCLE_BAND_WIDTH = 5.0 / 380.0    # Gap between circles 1-5
      OUTER_EXTENSION = 80.0 / 380.0     # How far lines extend beyond circle 5
      MONTH_LINE_INWARD = 8.0 / 380.0    # How far month lines extend inward from circle 1
      MONTH_LABEL_OFFSET = 18.0 / 380.0  # Distance inward from circle 1 to month label center

      PROPORTIONS = [
        CIRCLE_5_PROP - (4 * CIRCLE_BAND_WIDTH),  # Circle 1 (innermost)
        CIRCLE_5_PROP - (3 * CIRCLE_BAND_WIDTH),  # Circle 2
        CIRCLE_5_PROP - (2 * CIRCLE_BAND_WIDTH),  # Circle 3
        CIRCLE_5_PROP - (1 * CIRCLE_BAND_WIDTH),  # Circle 4
        CIRCLE_5_PROP,                             # Circle 5
        CIRCLE_5_PROP + OUTER_EXTENSION            # Outer extent (for division lines)
      ].freeze

      # Line widths
      DIVISION_LINE_WIDTH = 0.25
      CIRCLE_LINE_WIDTH = 0.75
      MONTH_LINE_WIDTH = 0.75

      # Font sizes
      MONTH_LABEL_FONT_SIZE = 8

      # Set up the named destination for this page.
      def setup
        set_destination('year_wheel')
        use_layout :full_page
      end

      # Render the year wheel on the page.
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
          draw_circles(radii)
          draw_divisions(radii)
          draw_month_markers(radii, scale)
        end
      end

      private

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

      # Draw the 365 radial divisions.
      #
      # @param radii [Array<Float>] Array of radii in points
      def draw_divisions(radii)
        @pdf.stroke_color Styling::Colors.TEXT_GRAY
        @pdf.line_width DIVISION_LINE_WIDTH

        angle_step = (2 * Math::PI) / NUM_DAYS
        start_angle = -Math::PI / 2.0  # Start from top

        NUM_DAYS.times do |day|
          angle = start_angle + (day * angle_step)
          cos_a = Math.cos(angle)
          sin_a = Math.sin(angle)

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

      # Draw month markers and labels.
      #
      # @param radii [Array<Float>] Array of radii in points
      # @param scale [Float] Scale factor for converting proportions to points
      def draw_month_markers(radii, scale)
        angle_step = (2 * Math::PI) / NUM_DAYS
        start_angle = -Math::PI / 2.0  # Start from top (Jan 1)

        inner_radius = radii[0]
        line_end_radius = inner_radius - (MONTH_LINE_INWARD * scale)
        label_radius = inner_radius - (MONTH_LABEL_OFFSET * scale)

        @pdf.stroke_color Styling::Colors.SECTION_HEADERS
        @pdf.line_width MONTH_LINE_WIDTH
        @pdf.fill_color Styling::Colors.TEXT_GRAY

        box_size = 24

        12.times do |month|
          day = MONTH_START_DAYS[month]
          # Subtract to go clockwise
          angle = start_angle - (day * angle_step)
          cos_a = Math.cos(angle)
          sin_a = Math.sin(angle)

          # Draw line from circle 1 inward
          @pdf.stroke_line(
            [cos_a * inner_radius, sin_a * inner_radius],
            [cos_a * line_end_radius, sin_a * line_end_radius]
          )

          # Draw month label
          label_x = cos_a * label_radius
          label_y = sin_a * label_radius

          @pdf.text_box MONTH_LABELS[month],
                        at: [label_x - (box_size / 2), label_y + (box_size / 2)],
                        width: box_size,
                        height: box_size,
                        align: :center,
                        valign: :center,
                        size: MONTH_LABEL_FONT_SIZE,
                        overflow: :shrink_to_fit
        end
      end
    end
  end
end
