# frozen_string_literal: true

module BujoPdf
  module Layouts
    # Represents chrome configuration for a layout.
    #
    # ChromeSpec defines which sidebars/chrome components appear on each edge
    # of a page. It supports multiple configuration styles for flexibility:
    #
    # - nil: No chrome on this edge
    # - Symbol: Lookup component from registry (e.g., :week_sidebar)
    # - Hash: Component with options (e.g., { component: :week_sidebar, year: 2025 })
    # - Proc: Inline definition for custom chrome
    #
    # The content area is automatically calculated by subtracting active
    # chrome regions from the full page dimensions.
    #
    # @example Creating a ChromeSpec with sidebars
    #   spec = ChromeSpec.new(
    #     left: :week_sidebar,
    #     right: { component: :nav_tabs, highlight: :seasonal }
    #   )
    #   spec.active_regions  # => { left: :week_sidebar, right: { ... } }
    #   spec.content_area(43, 55)  # => { col: 2, row: 0, width_boxes: 40, height_boxes: 55 }
    #
    # @example Full page (no chrome)
    #   spec = ChromeSpec.new
    #   spec.active_regions  # => {}
    #   spec.content_area(43, 55)  # => { col: 0, row: 0, width_boxes: 43, height_boxes: 55 }
    #
    # @example Using a Proc for dynamic chrome
    #   spec = ChromeSpec.new(
    #     left: ->(canvas, page) { canvas.week_sidebar(page.context[:year]) }
    #   )
    class ChromeSpec
      # Default widths for chrome regions in grid boxes
      DEFAULT_WIDTHS = {
        left: 2,
        right: 1,
        top: 0,
        bottom: 0
      }.freeze

      attr_reader :left, :right, :top, :bottom

      # Initialize a new ChromeSpec.
      #
      # @param left [nil, Symbol, Hash, Proc] Left sidebar configuration
      # @param right [nil, Symbol, Hash, Proc] Right sidebar configuration
      # @param top [nil, Symbol, Hash, Proc] Top chrome configuration
      # @param bottom [nil, Symbol, Hash, Proc] Bottom chrome configuration
      def initialize(left: nil, right: nil, top: nil, bottom: nil)
        @left = left
        @right = right
        @top = top
        @bottom = bottom
      end

      # Get all active (non-nil) chrome regions.
      #
      # @return [Hash] Hash of active regions with their configurations
      #
      # @example
      #   spec = ChromeSpec.new(left: :week_sidebar, right: :nav_tabs)
      #   spec.active_regions  # => { left: :week_sidebar, right: :nav_tabs }
      def active_regions
        {
          left: @left,
          right: @right,
          top: @top,
          bottom: @bottom
        }.compact
      end

      # Check if a specific region is active.
      #
      # @param region [Symbol] Region to check (:left, :right, :top, :bottom)
      # @return [Boolean] True if region has chrome configured
      def region_active?(region)
        send(region).present? if respond_to?(region)
      rescue
        false
      end

      # Calculate the content area given page dimensions.
      #
      # The content area is the region available for page content after
      # accounting for active chrome regions. Each active region reduces
      # the available space based on its configured or default width.
      #
      # @param page_width [Integer] Total page width in grid boxes (default: 43)
      # @param page_height [Integer] Total page height in grid boxes (default: 55)
      # @return [Hash] Content area with :col, :row, :width_boxes, :height_boxes
      #
      # @example Full page (no chrome)
      #   spec = ChromeSpec.new
      #   spec.content_area(43, 55)
      #   # => { col: 0, row: 0, width_boxes: 43, height_boxes: 55 }
      #
      # @example With left and right sidebars
      #   spec = ChromeSpec.new(left: :week_sidebar, right: :nav_tabs)
      #   spec.content_area(43, 55)
      #   # => { col: 2, row: 0, width_boxes: 40, height_boxes: 55 }
      def content_area(page_width = 43, page_height = 55)
        left_width = region_width(:left)
        right_width = region_width(:right)
        top_height = region_width(:top)
        bottom_height = region_width(:bottom)

        {
          col: left_width,
          row: top_height,
          width_boxes: page_width - left_width - right_width,
          height_boxes: page_height - top_height - bottom_height
        }
      end

      # Get the width/height of a chrome region.
      #
      # If the region is configured with a Hash containing :width or :height,
      # that value is used. Otherwise, the default width for the region is used.
      #
      # @param region [Symbol] Region to get width for
      # @return [Integer] Width/height in grid boxes (0 if region is nil)
      def region_width(region)
        config = send(region)
        return 0 if config.nil?

        # If config is a Hash with explicit width/height, use it
        if config.is_a?(Hash)
          # For left/right, use :width; for top/bottom, use :height
          size_key = [:left, :right].include?(region) ? :width : :height
          return config[size_key] if config.key?(size_key)
        end

        # Otherwise use default
        DEFAULT_WIDTHS.fetch(region, 0)
      end

      # Create a new ChromeSpec with updated regions.
      #
      # Returns a new instance with the specified changes, leaving
      # unspecified regions unchanged from the original.
      #
      # @param changes [Hash] Regions to update
      # @return [ChromeSpec] New instance with changes applied
      #
      # @example Add a right sidebar
      #   spec = ChromeSpec.new(left: :week_sidebar)
      #   new_spec = spec.with(right: :nav_tabs)
      #   new_spec.active_regions  # => { left: :week_sidebar, right: :nav_tabs }
      def with(**changes)
        ChromeSpec.new(
          left: changes.fetch(:left, @left),
          right: changes.fetch(:right, @right),
          top: changes.fetch(:top, @top),
          bottom: changes.fetch(:bottom, @bottom)
        )
      end

      # Check equality with another ChromeSpec.
      #
      # @param other [ChromeSpec] Another ChromeSpec to compare
      # @return [Boolean] True if all regions are equal
      def ==(other)
        return false unless other.is_a?(ChromeSpec)

        @left == other.left &&
          @right == other.right &&
          @top == other.top &&
          @bottom == other.bottom
      end

      alias eql? ==

      # Generate hash code for use in Hash keys.
      #
      # @return [Integer] Hash code
      def hash
        [@left, @right, @top, @bottom].hash
      end

      # String representation for debugging.
      #
      # @return [String] Human-readable representation
      def inspect
        regions = active_regions.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
        "#<ChromeSpec #{regions.empty? ? '(full page)' : regions}>"
      end
    end
  end
end
