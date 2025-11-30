# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/styling'

module BujoPdf
  module Pages
    # Reference and calibration page with grid measurements.
    #
    # This page displays diagnostic information about the grid system,
    # including dimensions, centimeter markings, and reference lines.
    # Useful for calibrating digital note-taking apps and understanding
    # the coordinate system.
    #
    # Features:
    #   - Dot grid background
    #   - Diagnostic grid overlay with coordinates
    #   - Center cross and division lines (halves, thirds)
    #   - Circle reference
    #   - Centimeter markings along edges
    #   - Page and grid dimension information
    #
    # Example:
    #   page = ReferenceCalibration.new(pdf, { year: 2025 })
    #   page.generate
    class ReferenceCalibration < Base
      include Styling::Grid

      # Mixin providing reference_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the reference/calibration page.
        #
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def reference_page
          define_page(dest: 'reference', title: 'Calibration & Reference', type: :template) do |ctx|
            ReferenceCalibration.new(@pdf, ctx).generate
          end
        end
      end

      def setup
        set_destination('reference')
        use_layout :full_page  # Explicit: no sidebars for reference page
      end

      def render
        draw_dot_grid
        # Always show diagnostic grid on reference page
        Diagnostics.draw_grid(@pdf, @grid_system, enabled: true, label_every: 5)
        draw_calibration_elements
      end

      private

      def draw_calibration_elements
        draw_center_cross
        draw_division_lines
        draw_reference_circle
        draw_centimeter_markings
        draw_measurements_info
      end

      # Draw very faint X through center
      def draw_center_cross
        @pdf.stroke_color 'EEEEEE'
        @pdf.stroke do
          @pdf.line [0, 0], [PAGE_WIDTH, PAGE_HEIGHT]
          @pdf.line [0, PAGE_HEIGHT], [PAGE_WIDTH, 0]
        end
      end

      # Draw faint solid lines for halves and dotted lines for thirds
      def draw_division_lines
        center_x = PAGE_WIDTH / 2.0
        center_y = PAGE_HEIGHT / 2.0
        third_x = PAGE_WIDTH / 3.0
        third_y = PAGE_HEIGHT / 3.0

        # Solid lines for halves
        @pdf.stroke_color 'EEEEEE'
        @pdf.stroke do
          @pdf.horizontal_line 0, PAGE_WIDTH, at: center_y
          @pdf.vertical_line 0, PAGE_HEIGHT, at: center_x
        end

        # Dotted lines for thirds
        @pdf.stroke_color 'CCCCCC'
        @pdf.dash(2, space: 3)
        @pdf.stroke do
          @pdf.vertical_line 0, PAGE_HEIGHT, at: third_x
          @pdf.vertical_line 0, PAGE_HEIGHT, at: third_x * 2
          @pdf.horizontal_line 0, PAGE_WIDTH, at: third_y
          @pdf.horizontal_line 0, PAGE_WIDTH, at: third_y * 2
        end
        @pdf.undash
      end

      # Draw circle with radius = 1/4 page width
      def draw_reference_circle
        center_x = PAGE_WIDTH / 2.0
        center_y = PAGE_HEIGHT / 2.0
        circle_radius = PAGE_WIDTH / 4.0

        @pdf.stroke_color 'CCCCCC'
        @pdf.stroke do
          @pdf.circle [center_x, center_y], circle_radius
        end
      end

      # Draw centimeter markings along top and left edges
      def draw_centimeter_markings
        cm_in_points = 28.35  # 1 cm ≈ 28.35 points

        @pdf.fill_color '888888'
        @pdf.font "Helvetica", size: 6

        # Top horizontal centimeter markings
        num_cm_horizontal = (PAGE_WIDTH / cm_in_points).floor
        (0..num_cm_horizontal).each do |cm|
          x = cm * cm_in_points
          @pdf.stroke_color 'AAAAAA'
          @pdf.stroke_line [x, PAGE_HEIGHT - 5], [x, PAGE_HEIGHT - 15]
          @pdf.text_box cm.to_s,
                        at: [x - 5, PAGE_HEIGHT - 2],
                        width: 10,
                        height: 8,
                        size: 5,
                        align: :center
        end

        # Left vertical centimeter markings
        num_cm_vertical = (PAGE_HEIGHT / cm_in_points).floor
        (0..num_cm_vertical).each do |cm|
          y = cm * cm_in_points
          @pdf.stroke_color 'AAAAAA'
          @pdf.stroke_line [5, y], [15, y]
          @pdf.text_box cm.to_s,
                        at: [2, y - 2],
                        width: 10,
                        height: 8,
                        size: 5
        end
      end

      # Display page dimensions and grid box counts
      def draw_measurements_info
        cm_in_points = 28.35
        boxes_per_width = (PAGE_WIDTH / DOT_SPACING).floor
        boxes_per_height = (PAGE_HEIGHT / DOT_SPACING).floor
        center_x = PAGE_WIDTH / 2.0
        center_y = PAGE_HEIGHT / 2.0

        @pdf.fill_color '000000'
        @pdf.font "Helvetica", size: 8

        measurements = [
          "Page: #{PAGE_WIDTH}pt × #{PAGE_HEIGHT}pt",
          "Page: #{(PAGE_WIDTH / cm_in_points).round(1)}cm × #{(PAGE_HEIGHT / cm_in_points).round(1)}cm",
          "",
          "Dot Grid Boxes:",
          "  Full: #{boxes_per_width} × #{boxes_per_height}",
          "  Half: #{(boxes_per_width/2).round} × #{(boxes_per_height/2).round}",
          "  Third: #{(boxes_per_width/3).round} × #{(boxes_per_height/3).round}",
          "  Quarter: #{(boxes_per_width/4).round} × #{(boxes_per_height/4).round}"
        ]

        y_pos = center_y + 50
        measurements.each do |text|
          @pdf.text_box text,
                        at: [center_x - 80, y_pos],
                        width: 160,
                        height: 15,
                        size: 8,
                        align: :center
          y_pos -= 12
        end
      end
    end
  end
end
