# frozen_string_literal: true

require_relative 'base_grid_renderer'

module BujoPdf
  module Utilities
    module GridRenderers
      # Renderer for perspective grid pattern
      #
      # Draws a perspective grid with horizontal lines and converging lines
      # toward vanishing points. Supports 1-point, 2-point, and 3-point
      # perspective configurations.
      #
      # Useful for architectural drawings, scene design, and spatial planning.
      #
      # @example Basic 2-point perspective (default)
      #   renderer = PerspectiveGridRenderer.new(pdf, 612, 792)
      #   renderer.render
      #
      # @example 1-point perspective with center vanishing point
      #   renderer = PerspectiveGridRenderer.new(pdf, 612, 792,
      #     num_points: 1,
      #     vanishing_points: [[306, 396]]  # Center of page
      #   )
      #   renderer.render
      #
      # @example Custom 2-point perspective
      #   renderer = PerspectiveGridRenderer.new(pdf, 612, 792,
      #     num_points: 2,
      #     horizon_y: 400,
      #     vanishing_points: [[-1224, 400], [1836, 400]]
      #   )
      #   renderer.render
      class PerspectiveGridRenderer < BaseGridRenderer
        # Initialize a new perspective grid renderer
        #
        # @param pdf [Prawn::Document] The Prawn PDF document instance
        # @param width [Float] Width of area to fill with grid (in points)
        # @param height [Float] Height of area to fill with grid (in points)
        # @param options [Hash] Additional rendering options
        # @option options [Integer] :num_points Number of vanishing points (1, 2, or 3)
        # @option options [Float] :horizon_y Y-coordinate of horizon line
        # @option options [Array<Array<Float>>] :vanishing_points Array of [x, y] coordinates
        # @option options [Float] :spacing Spacing for horizontal grid lines
        # @option options [Integer] :num_converging Number of converging lines per vanishing point
        def initialize(pdf, width, height, options = {})
          super
          @num_points = options.fetch(:num_points, 2)
          @horizon_y = options.fetch(:horizon_y, height / 2.0)
          @vanishing_points = options.fetch(:vanishing_points, default_vanishing_points)
          @num_converging = options.fetch(:num_converging, 12)
        end

        # Render the perspective grid pattern
        #
        # Draws horizontal lines and converging lines to vanishing points.
        #
        # @return [void]
        def render
          @pdf.stroke_color line_color
          @pdf.line_width line_width

          # Draw horizontal grid lines
          draw_horizontal_lines

          # Draw horizon line (slightly bolder)
          @pdf.line_width(line_width * 1.5)
          @pdf.stroke do
            @pdf.line [0, @horizon_y], [@width, @horizon_y]
          end
          @pdf.line_width(line_width)

          # Draw converging lines to vanishing points
          @vanishing_points.each do |vp|
            draw_converging_lines(vp)
          end

          restore_colors
        end

        private

        # Get default vanishing points based on configuration
        #
        # @return [Array<Array<Float>>] Array of [x, y] vanishing point coordinates
        def default_vanishing_points
          case @num_points
          when 1
            # Center vanishing point
            [[@width / 2.0, @horizon_y]]
          when 2
            # Left and right vanishing points (off page for natural perspective)
            [[-@width * 2, @horizon_y], [@width * 3, @horizon_y]]
          when 3
            # Left, right, and vertical vanishing points
            [
              [-@width * 2, @horizon_y],
              [@width * 3, @horizon_y],
              [@width / 2.0, -@height * 2]  # Below page for upward perspective
            ]
          else
            raise ArgumentError, "num_points must be 1, 2, or 3"
          end
        end

        # Draw horizontal grid lines
        #
        # @return [void]
        def draw_horizontal_lines
          # Number of lines above and below horizon
          num_lines_above = (@horizon_y / @spacing).ceil
          num_lines_below = ((@height - @horizon_y) / @spacing).ceil

          # Draw lines above horizon
          num_lines_above.times do |i|
            y = @horizon_y + ((i + 1) * @spacing)
            next if y > @height

            @pdf.stroke do
              @pdf.line [0, y], [@width, y]
            end
          end

          # Draw lines below horizon
          num_lines_below.times do |i|
            y = @horizon_y - ((i + 1) * @spacing)
            next if y < 0

            @pdf.stroke do
              @pdf.line [0, y], [@width, y]
            end
          end
        end

        # Draw converging lines to a vanishing point
        #
        # @param vp [Array<Float>] Vanishing point [x, y] coordinates
        # @return [void]
        def draw_converging_lines(vp)
          vp_x, vp_y = vp

          # Determine if vanishing point is on horizon (standard) or vertical (3-point)
          is_vertical = (vp_y - @horizon_y).abs > @height / 4

          if is_vertical
            # For vertical vanishing points, draw lines from bottom edge
            draw_vertical_converging_lines(vp_x, vp_y)
          else
            # For horizon vanishing points, draw lines from vertical edges
            draw_horizon_converging_lines(vp_x, vp_y)
          end
        end

        # Draw converging lines to a horizon vanishing point
        #
        # Lines emanate from left/right edges of the page toward the vanishing point.
        #
        # @param vp_x [Float] Vanishing point X coordinate
        # @param vp_y [Float] Vanishing point Y coordinate
        # @return [void]
        def draw_horizon_converging_lines(vp_x, vp_y)
          # Determine which edge to start from
          edge_x = vp_x < @width / 2.0 ? @width : 0
          edge_points = []

          # Create evenly spaced points along the opposite edge
          @num_converging.times do |i|
            y = (i + 1) * (@height / (@num_converging + 1.0))
            edge_points << [edge_x, y]
          end

          # Draw lines from edge points to vanishing point
          edge_points.each do |point|
            # Clip line to page bounds
            clipped = clip_line_to_bounds(point[0], point[1], vp_x, vp_y)
            if clipped
              @pdf.stroke do
                @pdf.line(*clipped)
              end
            end
          end
        end

        # Draw converging lines to a vertical vanishing point (3-point perspective)
        #
        # Lines emanate from bottom edge toward the vanishing point.
        #
        # @param vp_x [Float] Vanishing point X coordinate
        # @param vp_y [Float] Vanishing point Y coordinate
        # @return [void]
        def draw_vertical_converging_lines(vp_x, vp_y)
          edge_y = vp_y < @height / 2.0 ? @height : 0
          edge_points = []

          # Create evenly spaced points along horizontal edge
          @num_converging.times do |i|
            x = (i + 1) * (@width / (@num_converging + 1.0))
            edge_points << [x, edge_y]
          end

          # Draw lines from edge points to vanishing point
          edge_points.each do |point|
            clipped = clip_line_to_bounds(point[0], point[1], vp_x, vp_y)
            if clipped
              @pdf.stroke do
                @pdf.line(*clipped)
              end
            end
          end
        end

        # Clip a line segment to page bounds
        #
        # Simplified clipping: just check if endpoints are within bounds,
        # and clamp them to page bounds if needed.
        #
        # @param x1 [Float] Start point X coordinate
        # @param y1 [Float] Start point Y coordinate
        # @param x2 [Float] End point X coordinate
        # @param y2 [Float] End point Y coordinate
        # @return [Array<Array<Float>>, nil] Clipped line endpoints or nil if completely outside
        def clip_line_to_bounds(x1, y1, x2, y2)
          # Simple clipping: find intersections with page bounds
          # For a line from (x1,y1) to (x2,y2), clip to rectangle [0, 0, width, height]

          dx = x2 - x1
          dy = y2 - y1

          # Calculate t values for intersections with each edge
          t_min = 0.0
          t_max = 1.0

          # Left edge (x = 0)
          if dx != 0
            t = -x1 / dx.to_f
            if dx < 0
              t_max = [t_max, t].min if t > 0
            else
              t_min = [t_min, t].max if t < 1
            end
          elsif x1 < 0
            return nil
          end

          # Right edge (x = width)
          if dx != 0
            t = (@width - x1) / dx.to_f
            if dx > 0
              t_max = [t_max, t].min if t > 0
            else
              t_min = [t_min, t].max if t < 1
            end
          elsif x1 > @width
            return nil
          end

          # Bottom edge (y = 0)
          if dy != 0
            t = -y1 / dy.to_f
            if dy < 0
              t_max = [t_max, t].min if t > 0
            else
              t_min = [t_min, t].max if t < 1
            end
          elsif y1 < 0
            return nil
          end

          # Top edge (y = height)
          if dy != 0
            t = (@height - y1) / dy.to_f
            if dy > 0
              t_max = [t_max, t].min if t > 0
            else
              t_min = [t_min, t].max if t < 1
            end
          elsif y1 > @height
            return nil
          end

          return nil if t_min > t_max

          # Calculate clipped endpoints
          cx1 = x1 + t_min * dx
          cy1 = y1 + t_min * dy
          cx2 = x1 + t_max * dx
          cy2 = y1 + t_max * dy

          [[cx1, cy1], [cx2, cy2]]
        end
      end
    end
  end
end
