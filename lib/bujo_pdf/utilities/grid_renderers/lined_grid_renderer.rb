# frozen_string_literal: true

require_relative 'base_grid_renderer'

module BujoPdf
  module Utilities
    module GridRenderers
      # Renderer for ruled lines (lined paper) pattern
      #
      # Draws horizontal lines at regular intervals, plus an optional
      # left margin line in a different color. This creates a pattern
      # similar to traditional notebook paper.
      #
      # @example Basic usage
      #   renderer = LinedGridRenderer.new(pdf, 612, 792)
      #   renderer.render
      #
      # @example Custom options
      #   renderer = LinedGridRenderer.new(pdf, 612, 792,
      #     line_spacing_boxes: 2,  # Lines every 2 boxes (~10mm)
      #     margin_col: 3,          # Left margin at column 3
      #     margin_color: 'FFCCCC', # Pink margin line
      #     show_margin: true
      #   )
      #   renderer.render
      class LinedGridRenderer < BaseGridRenderer
        DEFAULT_LINE_SPACING_BOXES = 2  # Lines every 2 boxes (~10mm)
        DEFAULT_MARGIN_COL = 3          # Left margin at column 3

        # Initialize a new lined grid renderer
        #
        # @param pdf [Prawn::Document] The Prawn PDF document instance
        # @param width [Float] Width of area to fill with lines (in points)
        # @param height [Float] Height of area to fill with lines (in points)
        # @param options [Hash] Additional rendering options
        # @option options [Integer] :line_spacing_boxes Number of grid boxes between lines (default: 2)
        # @option options [Integer] :margin_col Column for left margin line (default: 3)
        # @option options [String] :margin_color 6-digit hex color for margin (default: 'FFCCCC')
        # @option options [Boolean] :show_margin Whether to draw margin line (default: true)
        # @option options [Integer] :start_row Row to start lines from (default: 0)
        def initialize(pdf, width, height, options = {})
          super
          @line_spacing_boxes = options.fetch(:line_spacing_boxes, DEFAULT_LINE_SPACING_BOXES)
          @margin_col = options.fetch(:margin_col, DEFAULT_MARGIN_COL)
          @margin_color = options.fetch(:margin_color, 'FFCCCC')
          @show_margin = options.fetch(:show_margin, true)
          @start_row = options.fetch(:start_row, 0)
        end

        # Render the ruled lines pattern
        #
        # Draws horizontal lines every line_spacing_boxes grid positions,
        # plus an optional vertical margin line on the left.
        #
        # @return [void]
        def render
          draw_ruled_lines
          draw_margin_line if @show_margin
          restore_colors
        end

        private

        # Draw horizontal ruled lines
        #
        # @return [void]
        def draw_ruled_lines
          @pdf.stroke_color line_color
          @pdf.line_width line_width

          # Draw lines every line_spacing_boxes from start_row to end
          (@start_row..rows).step(@line_spacing_boxes).each do |row|
            y = @height - (row * @spacing)
            @pdf.line [0, y], [@width, y]
          end

          @pdf.stroke
        end

        # Draw left margin line
        #
        # @return [void]
        def draw_margin_line
          @pdf.stroke_color @margin_color
          @pdf.line_width 0.5

          x = @margin_col * @spacing
          @pdf.line [x, 0], [x, @height]

          @pdf.stroke
        end
      end
    end
  end
end
