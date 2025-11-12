# frozen_string_literal: true

require_relative '../styling'

module BujoPdf
  module Utilities
    module GridRenderers
      # Abstract base class for all grid renderers
      #
      # Grid renderers provide different background grid patterns for planner pages,
      # such as dot grids, isometric grids, perspective grids, and hexagon grids.
      #
      # Each renderer implements a specific grid pattern while maintaining a common
      # interface for configuration and rendering.
      #
      # All concrete renderers must implement the #render method.
      #
      # @abstract Subclass and override {#render} to implement a grid pattern
      #
      # @example Creating a custom grid renderer
      #   class MyGridRenderer < BaseGridRenderer
      #     def render
      #       # Draw custom grid pattern using @pdf, @width, @height
      #     end
      #   end
      #
      #   renderer = MyGridRenderer.new(pdf, 612, 792)
      #   renderer.render
      class BaseGridRenderer
        attr_reader :pdf, :width, :height, :spacing, :options

        # Initialize a new grid renderer
        #
        # @param pdf [Prawn::Document] The Prawn PDF document instance
        # @param width [Float] Width of area to fill with grid (in points)
        # @param height [Float] Height of area to fill with grid (in points)
        # @param options [Hash] Additional rendering options
        # @option options [Float] :spacing Base spacing between grid elements (default: 14.17pt = 5mm)
        # @option options [String] :line_color 6-digit hex color for grid lines (default: 'CCCCCC')
        # @option options [Float] :line_width Width of grid lines in points (default: 0.25)
        # @option options [String] :fill_color 6-digit hex color for filled elements (default: 'CCCCCC')
        def initialize(pdf, width, height, options = {})
          @pdf = pdf
          @width = width
          @height = height
          @spacing = options.fetch(:spacing, Styling::Grid::DOT_SPACING)
          @options = options
        end

        # Render the grid pattern
        #
        # This method must be implemented by concrete renderer classes.
        # It should draw the appropriate grid pattern using the PDF object
        # and the configured dimensions and spacing.
        #
        # @raise [NotImplementedError] if not overridden by subclass
        # @return [void]
        def render
          raise NotImplementedError, "#{self.class} must implement #render"
        end

        protected

        # Get line color from options or default
        #
        # @return [String] 6-digit hex color code
        def line_color
          @options.fetch(:line_color, Styling::Colors::DOT_GRID)
        end

        # Get line width from options or default
        #
        # @return [Float] Line width in points
        def line_width
          @options.fetch(:line_width, 0.25)
        end

        # Get fill color from options or default
        #
        # @return [String] 6-digit hex color code
        def fill_color
          @options.fetch(:fill_color, Styling::Colors::DOT_GRID)
        end

        # Calculate how many grid columns fit in the given width
        #
        # @return [Integer] Number of columns
        def cols
          (@width / @spacing).floor
        end

        # Calculate how many grid rows fit in the given height
        #
        # @return [Integer] Number of rows
        def rows
          (@height / @spacing).floor
        end

        # Restore default colors after rendering
        #
        # Call this at the end of render() to reset colors to black
        #
        # @return [void]
        def restore_colors
          @pdf.fill_color Styling::Colors::TEXT_BLACK
          @pdf.stroke_color Styling::Colors::TEXT_BLACK
        end
      end
    end
  end
end
