# frozen_string_literal: true

require_relative 'base_grid_renderer'

module BujoPdf
  module Utilities
    module GridRenderers
      # Renderer for hexagon grid pattern
      #
      # Draws a tessellating pattern of regular hexagons. Supports both
      # flat-top and pointy-top orientations.
      #
      # Useful for game maps (hex-based strategy games), organic patterns,
      # chemistry diagrams (benzene rings), and geometric design.
      #
      # @example Basic flat-top hexagon grid (default)
      #   renderer = HexagonGridRenderer.new(pdf, 612, 792)
      #   renderer.render
      #
      # @example Pointy-top hexagons with custom size
      #   renderer = HexagonGridRenderer.new(pdf, 612, 792,
      #     spacing: 20,
      #     orientation: :pointy_top,
      #     line_color: 'AAAAAA'
      #   )
      #   renderer.render
      class HexagonGridRenderer < BaseGridRenderer
        # Initialize a new hexagon grid renderer
        #
        # @param pdf [Prawn::Document] The Prawn PDF document instance
        # @param width [Float] Width of area to fill with hexagons (in points)
        # @param height [Float] Height of area to fill with hexagons (in points)
        # @param options [Hash] Additional rendering options
        # @option options [Float] :spacing Edge-to-edge distance (default: 14.17pt = 5mm)
        # @option options [Symbol] :orientation :flat_top or :pointy_top (default: :flat_top)
        def initialize(pdf, width, height, options = {})
          super
          @orientation = options.fetch(:orientation, :flat_top)
        end

        # Render the hexagon grid pattern
        #
        # Calculates hexagon tessellation and draws each hexagon.
        #
        # @return [void]
        def render
          @pdf.stroke_color line_color
          @pdf.line_width line_width

          if @orientation == :flat_top
            render_flat_top_hexagons
          else
            render_pointy_top_hexagons
          end

          restore_colors
        end

        private

        # Render flat-top hexagons (flat edge on top)
        #
        # @return [void]
        def render_flat_top_hexagons
          # For flat-top hexagons where @spacing is the edge length (side):
          # - hex_width (vertex to vertex) = spacing * 2
          # - hex_height (edge to edge) = spacing * sqrt(3)
          # - horizontal_spacing (center to center, same row) = spacing * 1.5
          # - vertical_spacing (center to center, same column) = spacing * sqrt(3)
          hex_width = @spacing * 2
          hex_height = @spacing * Math.sqrt(3)

          # Center-to-center spacing for proper edge-to-edge tessellation
          horizontal_spacing = @spacing * 1.5
          vertical_spacing = hex_height

          # Calculate grid dimensions (with extra rows/cols for coverage)
          cols = (@width / horizontal_spacing).ceil + 2
          rows = (@height / vertical_spacing).ceil + 2

          # Draw hexagons
          cols.times do |col|
            rows.times do |row|
              # Offset odd columns vertically for tessellation (brick pattern)
              y_offset = col.odd? ? vertical_spacing / 2.0 : 0
              center_x = col * horizontal_spacing
              center_y = (row * vertical_spacing) + y_offset

              # Only draw if hexagon is at least partially visible
              if hexagon_visible?(center_x, center_y, hex_width, hex_height)
                draw_hexagon(center_x, center_y, @spacing, :flat_top)
              end
            end
          end
        end

        # Render pointy-top hexagons (pointy vertex on top)
        #
        # @return [void]
        def render_pointy_top_hexagons
          # For pointy-top hexagons where @spacing is the edge length (side):
          # - hex_width (edge to edge) = spacing * sqrt(3)
          # - hex_height (vertex to vertex) = spacing * 2
          # - horizontal_spacing (center to center) = spacing * sqrt(3)
          # - vertical_spacing (center to center) = spacing * 1.5
          hex_width = @spacing * Math.sqrt(3)
          hex_height = @spacing * 2

          # Center-to-center spacing for proper edge-to-edge tessellation
          horizontal_spacing = hex_width
          vertical_spacing = @spacing * 1.5

          # Calculate grid dimensions (with extra rows/cols for coverage)
          cols = (@width / horizontal_spacing).ceil + 2
          rows = (@height / vertical_spacing).ceil + 2

          # Draw hexagons
          rows.times do |row|
            cols.times do |col|
              # Offset odd rows by half horizontal spacing for tessellation
              x_offset = row.odd? ? horizontal_spacing / 2.0 : 0
              center_x = (col * horizontal_spacing) + x_offset
              center_y = row * vertical_spacing

              # Only draw if hexagon is at least partially visible
              if hexagon_visible?(center_x, center_y, hex_width, hex_height)
                draw_hexagon(center_x, center_y, @spacing, :pointy_top)
              end
            end
          end
        end

        # Check if a hexagon is at least partially visible within page bounds
        #
        # @param cx [Float] Hexagon center X coordinate
        # @param cy [Float] Hexagon center Y coordinate
        # @param width [Float] Hexagon width
        # @param height [Float] Hexagon height
        # @return [Boolean] true if hexagon should be drawn
        def hexagon_visible?(cx, cy, width, height)
          # Simple bounding box check
          left = cx - width / 2.0
          right = cx + width / 2.0
          bottom = cy - height / 2.0
          top = cy + height / 2.0

          # Check if bounding box intersects page bounds
          !(right < 0 || left > @width || top < 0 || bottom > @height)
        end

        # Draw a single hexagon at the specified center point
        #
        # @param cx [Float] Center X coordinate
        # @param cy [Float] Center Y coordinate
        # @param edge_length [Float] Length of each edge of the hexagon
        # @param orientation [Symbol] :flat_top or :pointy_top
        # @return [void]
        def draw_hexagon(cx, cy, edge_length, orientation)
          # For a regular hexagon, circumradius (center to vertex) equals edge length
          radius = edge_length

          # Calculate six vertices
          vertices = 6.times.map do |i|
            # Starting angle depends on orientation
            # flat_top: first vertex at 0° (right), edges are horizontal top/bottom
            # pointy_top: first vertex at 30°, vertices are at top/bottom
            angle_offset = orientation == :flat_top ? 0 : 30
            angle = angle_offset + (i * 60)
            angle_rad = angle * Math::PI / 180.0

            [
              cx + radius * Math.cos(angle_rad),
              cy + radius * Math.sin(angle_rad)
            ]
          end

          # Draw hexagon as a closed polygon
          @pdf.stroke do
            @pdf.polygon(*vertices)
          end
        end
      end
    end
  end
end
