# frozen_string_literal: true

module BujoPdf
  module Layouts
    # Abstract base class for all layout types.
    #
    # Layouts define the structure of a page by specifying:
    # - Content area boundaries (where page-specific content goes)
    # - Layout components to render (sidebars, navigation, backgrounds)
    # - Lifecycle hooks for rendering before/after page content
    #
    # Subclasses must implement:
    # - content_area: Return content area specification
    #
    # Subclasses may optionally override:
    # - render_before(page): Render layout components before page content
    # - render_after(page): Render layout components after page content
    #
    # @abstract Subclasses must implement {#content_area}
    #
    # @example Creating a custom layout
    #   class MyLayout < BaseLayout
    #     def content_area
    #       { col: 5, row: 5, width_boxes: 33, height_boxes: 45 }
    #     end
    #
    #     def render_before(page)
    #       # Draw sidebars, backgrounds, etc.
    #     end
    #   end
    #
    # @example Using a layout in a page
    #   class MyPage < Pages::Base
    #     def setup
    #       use_layout :my_layout, option1: value1
    #     end
    #   end
    class BaseLayout
      attr_reader :pdf, :grid_system, :options

      # Initialize a new layout instance.
      #
      # @param pdf [Prawn::Document] PDF document to render into
      # @param grid_system [Utilities::GridSystem] Grid system for positioning
      # @param options [Hash] Layout-specific options
      def initialize(pdf, grid_system, **options)
        @pdf = pdf
        @grid_system = grid_system
        @options = options
      end

      # Get the content area specification.
      #
      # Returns a hash with grid coordinates defining where page content
      # should be positioned. The content area excludes sidebars and other
      # layout chrome elements.
      #
      # @abstract Subclasses must implement this method
      # @raise [NotImplementedError] if not implemented by subclass
      # @return [Hash] Content area with keys :col, :row, :width_boxes, :height_boxes
      #
      # @example Full page content area
      #   { col: 0, row: 0, width_boxes: 43, height_boxes: 55 }
      #
      # @example Content area with sidebars
      #   { col: 3, row: 0, width_boxes: 39, height_boxes: 55 }
      def content_area
        raise NotImplementedError, "#{self.class} must implement #content_area"
      end

      # Render layout components before page content.
      #
      # This method is called after the page background (dot grid) is drawn
      # but before the page's render method is called. Use this to draw
      # sidebars, navigation chrome, or other layout elements that should
      # appear behind the page content.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_before(page)
        # Default: no-op, subclasses can override
      end

      # Render layout components after page content.
      #
      # This method is called after the page's render method completes.
      # Use this to draw overlays, borders, or other elements that should
      # appear on top of the page content.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [void]
      def render_after(page)
        # Default: no-op, subclasses can override
      end

      protected

      # Helper to access page context.
      #
      # Provides access to the RenderContext from the page, which contains
      # contextual information like year, week number, etc.
      #
      # @param page [Pages::Base] The page being rendered
      # @return [RenderContext] The page's render context
      def page_context(page)
        page.context
      end
    end
  end
end
