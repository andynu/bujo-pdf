# frozen_string_literal: true

require_relative 'grid_renderers/base_grid_renderer'
require_relative 'grid_renderers/dot_grid_renderer'

module BujoPdf
  module Utilities
    # Factory for creating grid renderer instances
    #
    # The GridFactory provides a centralized way to instantiate different
    # grid renderer types based on a symbol identifier. This allows for
    # easy extensibility and consistent configuration across the application.
    #
    # Supported grid types:
    # - :dots - Standard dot grid (default)
    # - :isometric - Isometric grid with 30-60-90° triangles
    # - :perspective - Perspective grid with vanishing points
    # - :hexagon - Tessellating hexagon grid
    #
    # @example Creating a dot grid renderer
    #   renderer = GridFactory.create(:dots, pdf, 612, 792)
    #   renderer.render
    #
    # @example Creating an isometric grid with custom options
    #   renderer = GridFactory.create(:isometric, pdf, 612, 792,
    #     spacing: 15,
    #     line_color: 'DDDDDD'
    #   )
    #   renderer.render
    module GridFactory
      # Create a grid renderer of the specified type
      #
      # @param type [Symbol] Grid type identifier
      # @param pdf [Prawn::Document] The Prawn PDF document instance
      # @param width [Float] Width of area to fill with grid (in points)
      # @param height [Float] Height of area to fill with grid (in points)
      # @param options [Hash] Rendering options passed to the renderer
      #
      # @return [BaseGridRenderer] An instance of the appropriate renderer class
      #
      # @raise [ArgumentError] if type is not a supported grid type
      #
      # @example
      #   renderer = GridFactory.create(:dots, pdf, 612, 792)
      #   renderer = GridFactory.create(:isometric, pdf, 612, 792, spacing: 15)
      #   renderer = GridFactory.create(:hexagon, pdf, 612, 792, orientation: :flat_top)
      def self.create(type, pdf, width, height, **options)
        case type
        when :dots
          require_relative 'grid_renderers/dot_grid_renderer'
          GridRenderers::DotGridRenderer.new(pdf, width, height, options)
        when :isometric
          require_relative 'grid_renderers/isometric_grid_renderer'
          GridRenderers::IsometricGridRenderer.new(pdf, width, height, options)
        when :perspective
          require_relative 'grid_renderers/perspective_grid_renderer'
          GridRenderers::PerspectiveGridRenderer.new(pdf, width, height, options)
        when :hexagon
          require_relative 'grid_renderers/hexagon_grid_renderer'
          GridRenderers::HexagonGridRenderer.new(pdf, width, height, options)
        else
          raise ArgumentError, "Unknown grid type: #{type}. " \
                               "Supported types: :dots, :isometric, :perspective, :hexagon"
        end
      end

      # Get list of all supported grid types
      #
      # @return [Array<Symbol>] Array of supported grid type symbols
      def self.supported_types
        [:dots, :isometric, :perspective, :hexagon]
      end

      # Check if a grid type is supported
      #
      # @param type [Symbol] Grid type identifier to check
      # @return [Boolean] true if supported, false otherwise
      def self.supported?(type)
        supported_types.include?(type)
      end
    end
  end
end
