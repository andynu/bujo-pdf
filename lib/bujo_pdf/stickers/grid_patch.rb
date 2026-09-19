# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/grid_renderers/base_grid_renderer'
require_relative '../utilities/grid_renderers/dot_grid_renderer'
require_relative '../utilities/grid_renderers/graph_grid_renderer'
require_relative '../utilities/grid_renderers/lined_grid_renderer'
require_relative '../utilities/grid_renderers/isometric_grid_renderer'
require_relative '../utilities/grid_renderers/hexagon_grid_renderer'

module BujoPdf
  module Stickers
    # A small square of one of the planner's grid patterns.
    #
    # The grid renderers already take an arbitrary (width, height) with
    # configurable spacing, so a patch is the existing renderer pointed at a
    # smaller rectangle - no new drawing code.
    #
    # Two of the six planner grid types are deliberately absent:
    #
    # - *perspective* encodes a vanishing point sized for a full page. Shrink
    #   the frame and the construction does not shrink with it, so a patch is
    #   a scribble of lines converging somewhere off-sticker. A perspective
    #   grid needs a large field to mean anything.
    # - *dot* is available but off by default: every planner page already
    #   draws a dot grid beneath its content, so a dot patch usually puts dots
    #   on dots. It earns its place only over something opaque.
    class GridPatch < Base
      DEFAULT_SIZE_BOXES = 10

      # Grid types offered as patches, in the order they are generated.
      # :default flags the ones included unless everything is requested.
      TYPES = {
        graph: {
          title: 'Graph grid',
          renderer: Utilities::GridRenderers::GraphGridRenderer,
          default: true
        },
        lined: {
          title: 'Lined',
          renderer: Utilities::GridRenderers::LinedGridRenderer,
          default: true,
          # The lined page draws a red margin rule, which is a page feature -
          # it makes no sense partway through a patch dropped mid-notes.
          options: { show_margin: false }
        },
        isometric: {
          title: 'Isometric grid',
          renderer: Utilities::GridRenderers::IsometricGridRenderer,
          default: true
        },
        hexagon: {
          title: 'Hexagon grid',
          renderer: Utilities::GridRenderers::HexagonGridRenderer,
          default: true
        },
        dot: {
          title: 'Dot grid',
          renderer: Utilities::GridRenderers::DotGridRenderer,
          default: false
        }
      }.freeze

      # Build the grid patches for a sticker pack.
      #
      # @param size [Integer, Float] Patch edge length in grid boxes
      # @param all [Boolean] Include patches that are off by default
      # @return [Array<GridPatch>]
      def self.all(size: DEFAULT_SIZE_BOXES, all: false)
        TYPES.filter_map do |type, spec|
          next unless all || spec[:default]

          new(type: type, size: size)
        end
      end

      attr_reader :type

      # @param type [Symbol] Key into {TYPES}
      # @param size [Integer, Float] Patch edge length in grid boxes
      def initialize(type:, size: DEFAULT_SIZE_BOXES)
        spec = TYPES.fetch(type) { raise ArgumentError, "Unknown grid type: #{type}" }
        @type = type
        @spec = spec
        super(
          slug: "grid_#{type}",
          title: spec[:title],
          width_boxes: size,
          height_boxes: size
        )
      end

      def draw(pdf)
        options = {
          spacing: BOX,
          line_color: DEFAULT_LINE_COLOR,
          line_width: DEFAULT_LINE_WIDTH,
          fill_color: DEFAULT_LINE_COLOR
        }.merge(@spec[:options] || {})

        # Hexagons tile past the frame they are given; the page edge crops
        # them, which is simply what a cropped honeycomb looks like.
        @spec[:renderer].new(pdf, width_pt, height_pt, options).render
      end
    end
  end
end
