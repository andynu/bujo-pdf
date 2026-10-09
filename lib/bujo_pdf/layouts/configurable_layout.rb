# frozen_string_literal: true

require_relative 'base_layout'
require_relative 'chrome_spec'

module BujoPdf
  module Layouts
    # ConfigurableLayout provides a flexible, config-driven layout.
    #
    # Instead of creating separate layout classes for each sidebar combination
    # (StandardWithSidebarsLayout, DailyWithSidebarsLayout, etc.), ConfigurableLayout
    # accepts a ChromeSpec that defines which sidebars to render and where.
    #
    # This is the recommended layout for new pages. The hardcoded layout classes
    # are maintained for backward compatibility.
    #
    # Layout behavior is entirely controlled by the chrome_spec:
    # - No chrome_spec or empty ChromeSpec: Full page (equivalent to FullPageLayout)
    # - ChromeSpec with sidebars: Renders configured sidebars, calculates content area
    #
    # @example Full page layout (no sidebars)
    #   layout = ConfigurableLayout.new(pdf, grid)
    #   layout.content_area  # => { col: 0, row: 0, width_boxes: 43, height_boxes: 55 }
    #
    # @example Standard weekly layout
    #   spec = ChromeSpec.new(
    #     left: :week_sidebar,
    #     right: { component: :tab_sidebar, top_tabs: [...] }
    #   )
    #   layout = ConfigurableLayout.new(pdf, grid, chrome_spec: spec)
    #
    # @example Daily layout
    #   spec = ChromeSpec.new(
    #     left: :month_sidebar,
    #     right: { component: :tab_sidebar, top_tabs: [...] }
    #   )
    #   layout = ConfigurableLayout.new(pdf, grid, chrome_spec: spec)
    #
    # @see ChromeSpec for chrome region configuration
    # @see BaseLayout for inherited behavior
    class ConfigurableLayout < BaseLayout
      # Initialize a new ConfigurableLayout.
      #
      # @param pdf [Prawn::Document] PDF document to render into
      # @param grid_system [Utilities::GridSystem] Grid system for positioning
      # @param chrome_spec [ChromeSpec, nil] Chrome configuration (nil for full page)
      # @param options [Hash] Additional layout options passed to sidebars
      def initialize(pdf, grid_system, chrome_spec: nil, **options)
        # Use empty ChromeSpec if none provided (full page behavior)
        effective_spec = chrome_spec || ChromeSpec.new
        super(pdf, grid_system, chrome_spec: effective_spec, **options)
      end

      # Get the content area specification.
      #
      # Content area is always calculated from the ChromeSpec. Since we
      # guarantee a ChromeSpec is present (defaulting to empty), this
      # never raises NotImplementedError.
      #
      # @return [Hash] Content area with :col, :row, :width_boxes, :height_boxes
      #
      # @example Full page (no chrome)
      #   { col: 0, row: 0, width_boxes: 43, height_boxes: 55 }
      #
      # @example With standard sidebars
      #   { col: 2, row: 0, width_boxes: 40, height_boxes: 55 }
      def content_area
        @chrome_spec.content_area(PAGE_WIDTH_BOXES, PAGE_HEIGHT_BOXES)
      end

      # Render chrome regions before page content.
      #
      # Delegates to BaseLayout's render_before which iterates through
      # active regions and renders each configured sidebar.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_before(page)
        super
      end

      # Render chrome regions after page content.
      #
      # Currently a no-op. Can be extended for overlays or borders.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_after(page)
        super
      end
    end
  end
end
