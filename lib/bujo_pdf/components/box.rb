# frozen_string_literal: true

require_relative '../utilities/styling'

module BujoPdf
  module Components
    # Box renders a rectangle at grid coordinates.
    #
    # Supports stroked borders, filled backgrounds, rounded corners,
    # and transparency. A flexible primitive for building UI elements.
    #
    # Example usage in a page:
    #   box(2, 5, 10, 3)                           # Simple stroked box
    #   box(2, 5, 10, 3, fill: 'EEEEEE')           # Filled box
    #   box(2, 5, 10, 3, radius: 2)                # Rounded corners
    #   box(2, 5, 10, 3, stroke: nil, fill: 'FF0000', opacity: 0.1)
    #
    class Box
      # Mixin providing the box verb for pages and components
      module Mixin
        # Render a box at grid coordinates
        #
        # @param col [Integer] Starting column (left edge)
        # @param row [Integer] Starting row (top edge)
        # @param width [Integer] Width in grid boxes
        # @param height [Integer] Height in grid boxes
        # @param stroke [String, nil] Border color (nil for no border)
        # @param stroke_width [Float] Border width in points (default: 0.5)
        # @param fill [String, nil] Fill color (nil for no fill)
        # @param radius [Float] Corner radius in points (default: 0 for square)
        # @param opacity [Float] Opacity 0.0-1.0 (default: 1.0)
        # @return [void]
        def box(col, row, width, height, stroke: 'CCCCCC', stroke_width: 0.5, fill: nil, radius: 0, opacity: 1.0)
          Box.new(
            pdf: @pdf,
            grid: @grid,
            col: col,
            row: row,
            width: width,
            height: height,
            stroke: stroke,
            stroke_width: stroke_width,
            fill: fill,
            radius: radius,
            opacity: opacity
          ).render
        end
      end

      # Initialize a new Box component
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param grid [GridSystem] The grid system for coordinate conversion
      # @param col [Integer] Starting column (left edge)
      # @param row [Integer] Starting row (top edge)
      # @param width [Integer] Width in grid boxes
      # @param height [Integer] Height in grid boxes
      # @param stroke [String, nil] Border color (nil for no border)
      # @param stroke_width [Float] Border width in points
      # @param fill [String, nil] Fill color (nil for no fill)
      # @param radius [Float] Corner radius in points
      # @param opacity [Float] Opacity 0.0-1.0
      def initialize(pdf:, grid:, col:, row:, width:, height:,
                     stroke: 'CCCCCC', stroke_width: 0.5, fill: nil, radius: 0, opacity: 1.0)
        @pdf = pdf
        @grid = grid
        @col = col
        @row = row
        @width = width
        @height = height
        @stroke = stroke
        @stroke_width = stroke_width
        @fill = fill
        @radius = radius
        @opacity = opacity
      end

      # Render the box
      #
      # @return [void]
      def render
        x = @grid.x(@col)
        y = @grid.y(@row)
        w = @grid.width(@width)
        h = @grid.height(@height)

        wrap_opacity do
          draw_fill(x, y, w, h) if @fill
          draw_stroke(x, y, w, h) if @stroke
        end

        # Restore defaults
        @pdf.stroke_color '000000'
        @pdf.fill_color '000000'
        @pdf.line_width 0.5
      end

      private

      def wrap_opacity(&block)
        if @opacity < 1.0
          @pdf.transparent(@opacity, &block)
        else
          yield
        end
      end

      def draw_fill(x, y, w, h)
        @pdf.fill_color @fill
        if @radius > 0
          @pdf.fill_rounded_rectangle([x, y], w, h, @radius)
        else
          @pdf.fill_rectangle([x, y], w, h)
        end
      end

      def draw_stroke(x, y, w, h)
        @pdf.stroke_color @stroke
        @pdf.line_width @stroke_width
        if @radius > 0
          @pdf.stroke_rounded_rectangle([x, y], w, h, @radius)
        else
          @pdf.stroke_rectangle([x, y], w, h)
        end
      end
    end
  end
end
