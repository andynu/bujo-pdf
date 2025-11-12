# frozen_string_literal: true

require_relative '../utilities/styling'
require_relative '../utilities/grid_system'
require_relative '../utilities/dot_grid'
require_relative '../utilities/diagnostics'

module BujoPdf
  module Pages
    # Abstract base class for all page types in the planner.
    #
    # This class defines a standard lifecycle for page generation using the
    # Template Method pattern. Subclasses implement specific rendering logic
    # by overriding the hook methods: setup, render, and finalize.
    #
    # Lifecycle:
    #   1. initialize(pdf, context) - Create page with PDF object and context
    #   2. setup - Prepare page-specific state and calculations
    #   3. render - Draw the actual page content
    #   4. finalize - Post-render tasks (links, bookmarks, etc.)
    #
    # Example:
    #   class MyPage < Base
    #     def render
    #       draw_dot_grid
    #       @pdf.text "Hello World"
    #     end
    #   end
    #
    #   page = MyPage.new(pdf, { year: 2025 })
    #   page.generate
    class Base
      attr_reader :pdf, :context, :grid_system

      # Initialize a new page instance.
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [Hash] Rendering context (year, week_num, etc.)
      def initialize(pdf, context)
        @pdf = pdf
        @context = context
        @grid_system = BujoPdf::Utilities::GridSystem.new(pdf)
        @components = []
      end

      # Generate the page (template method).
      #
      # This method orchestrates the page generation lifecycle. Subclasses
      # should NOT override this method. Instead, override the hook methods:
      # setup, render, and finalize.
      #
      # @return [void]
      def generate
        setup
        render
        finalize
      end

      protected

      # Hook: Prepare page-specific state and calculations.
      #
      # Override this method to set up any state needed for rendering,
      # such as calculating positions, preparing data structures, or
      # setting named destinations.
      #
      # @return [void]
      def setup
        # Default: no-op, subclasses can override
      end

      # Hook: Draw the actual page content.
      #
      # This method MUST be implemented by subclasses. This is where the
      # actual page rendering logic goes.
      #
      # @raise [NotImplementedError] if not overridden by subclass
      # @return [void]
      def render
        raise NotImplementedError, "#{self.class} must implement #render"
      end

      # Hook: Post-render tasks.
      #
      # Override this method to perform tasks after the main rendering is
      # complete, such as adding link annotations or updating bookmarks.
      #
      # @return [void]
      def finalize
        # Default: no-op, subclasses can override
      end

      # Add a component to be rendered.
      #
      # Components are rendered in the order they are added, during the
      # render_components call.
      #
      # @param component [Object] A component with a #render method
      # @return [void]
      def add_component(component)
        @components << component
      end

      # Render all added components.
      #
      # Call this method in your render implementation to render all
      # components that have been added via add_component.
      #
      # @return [void]
      def render_components
        @components.each(&:render)
      end

      # Set a named destination for this page.
      #
      # Named destinations allow internal links to jump to specific pages.
      # The destination is set at the top of the current page.
      #
      # @param name [String] The destination name (e.g., 'week_1')
      # @return [void]
      def set_destination(name)
        @pdf.add_dest(name, @pdf.dest_xyz(0, @pdf.bounds.top))
      end

      # Helper to access styling utilities.
      #
      # @return [Module] The Styling utilities module
      def styling
        BujoPdf::Utilities::Styling
      end

      # Draw dot grid across the entire page.
      #
      # This is a convenience method that delegates to the DotGrid utility.
      #
      # @param width [Numeric, nil] Width to draw dots (defaults to page width)
      # @param height [Numeric, nil] Height to draw dots (defaults to page height)
      # @return [void]
      def draw_dot_grid(width = nil, height = nil)
        width ||= @pdf.bounds.width
        height ||= @pdf.bounds.height
        BujoPdf::Utilities::DotGrid.draw(@pdf, width, height)
      end

      # Draw diagnostic grid overlay for layout debugging.
      #
      # This is a convenience method that delegates to the Diagnostics utility.
      #
      # @param label_every [Integer] Show labels every N grid lines
      # @return [void]
      def draw_diagnostic_grid(label_every: 5)
        BujoPdf::Utilities::Diagnostics.draw_grid(@pdf, label_every: label_every)
      end
    end
  end
end
