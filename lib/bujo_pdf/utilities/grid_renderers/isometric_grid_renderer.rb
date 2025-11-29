# frozen_string_literal: true

require_relative 'base_grid_renderer'

module BujoPdf
  module Utilities
    module GridRenderers
      # Renderer for isometric grid pattern
      #
      # Draws an isometric grid composed of three sets of parallel lines at
      # 30°, 90°, and 150° from horizontal. This creates a 30-60-90° diamond
      # pattern useful for technical drawing, 3D object sketching, and game maps.
      #
      # The grid consists of equilateral triangles, making it ideal for
      # representing objects in isometric projection.
      #
      # @example Basic usage
      #   renderer = IsometricGridRenderer.new(pdf, 612, 792)
      #   renderer.render
      #
      # @example Custom line spacing and color
      #   renderer = IsometricGridRenderer.new(pdf, 612, 792,
      #     spacing: 15,
      #     line_color: 'DDDDDD',
      #     line_width: 0.3
      #   )
      #   renderer.render
      class IsometricGridRenderer < BaseGridRenderer
        # Angles for the three sets of parallel lines (in degrees)
        ANGLES = [30, 90, 150].freeze

        # Render the isometric grid pattern
        #
        # Draws three sets of parallel lines at 30°, 90°, and 150° angles.
        # Lines are spaced according to the @spacing value, measured
        # perpendicular to the line direction.
        #
        # @return [void]
        def render
          @pdf.stroke_color line_color
          @pdf.line_width line_width

          ANGLES.each do |angle|
            draw_parallel_lines(angle)
          end

          restore_colors
        end

        private

        # Draw a set of parallel lines at the specified angle
        #
        # @param angle [Float] Angle in degrees from horizontal (0° = right)
        # @return [void]
        def draw_parallel_lines(angle)
          angle_rad = angle * Math::PI / 180.0

          # For spacing perpendicular to the line direction
          # We need to adjust based on the angle
          perp_spacing = if angle == 90
                           @spacing
                         else
                           # For angled lines, spacing is measured perpendicular
                           # to the line direction
                           @spacing / Math.sin(60 * Math::PI / 180.0)
                         end

          # Calculate perpendicular direction (90° from line angle)
          perp_angle = angle_rad + Math::PI / 2

          # Calculate how many lines we need to cover the entire page
          # We need to extend beyond the page bounds in the perpendicular direction
          page_diagonal = Math.sqrt(@width**2 + @height**2)
          num_lines = (page_diagonal / perp_spacing * 2).ceil

          # Calculate starting position (extend beyond page to ensure full coverage)
          start_offset = -page_diagonal

          # Draw each parallel line
          num_lines.times do |i|
            offset = start_offset + (i * perp_spacing)

            # Calculate a point on this line (perpendicular offset from origin)
            px = offset * Math.cos(perp_angle)
            py = offset * Math.sin(perp_angle)

            # Calculate line endpoints extending far in both directions
            dx = Math.cos(angle_rad) * page_diagonal * 2
            dy = Math.sin(angle_rad) * page_diagonal * 2

            x1 = px - dx
            y1 = py - dy
            x2 = px + dx
            y2 = py + dy

            # Clip line to page bounds and draw if visible
            clipped = clip_line_to_bounds(x1, y1, x2, y2)
            if clipped
              @pdf.stroke do
                @pdf.line(*clipped)
              end
            end
          end
        end

        # Clip a line segment to page bounds using Cohen-Sutherland algorithm
        #
        # @param x1 [Float] Start point X coordinate
        # @param y1 [Float] Start point Y coordinate
        # @param x2 [Float] End point X coordinate
        # @param y2 [Float] End point Y coordinate
        # @return [Array<Array<Float>>, nil] Clipped line endpoints or nil if completely outside
        def clip_line_to_bounds(x1, y1, x2, y2)
          # Page bounds
          x_min = 0
          y_min = 0
          x_max = @width
          y_max = @height

          # Outcodes for Cohen-Sutherland
          left = 1
          right = 2
          bottom = 4
          top = 8

          compute_outcode = lambda do |x, y|
            code = 0
            code |= left if x < x_min
            code |= right if x > x_max
            code |= bottom if y < y_min
            code |= top if y > y_max
            code
          end

          outcode1 = compute_outcode.call(x1, y1)
          outcode2 = compute_outcode.call(x2, y2)

          loop do
            # Both points inside
            return [[x1, y1], [x2, y2]] if (outcode1 | outcode2).zero?

            # Both points on same outside side
            return nil if (outcode1 & outcode2) != 0

            # Pick a point outside the bounds
            outcode = outcode1.zero? ? outcode2 : outcode1

            # Find intersection point
            if (outcode & top) != 0
              x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1)
              y = y_max
            elsif (outcode & bottom) != 0
              x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1)
              y = y_min
            elsif (outcode & right) != 0
              y = y1 + (y2 - y1) * (x_max - x1) / (x2 - x1)
              x = x_max
            elsif (outcode & left) != 0
              y = y1 + (y2 - y1) * (x_min - x1) / (x2 - x1)
              x = x_min
            end

            # Update point and outcode
            if outcode == outcode1
              x1 = x
              y1 = y
              outcode1 = compute_outcode.call(x1, y1)
            else
              x2 = x
              y2 = y
              outcode2 = compute_outcode.call(x2, y2)
            end
          end
        end
      end
    end
  end
end
