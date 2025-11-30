# frozen_string_literal: true

module BujoPdf
  module Components
    # SubComponentBase is the abstract base class for position-based components
    #
    # Sub-components are low-level, reusable UI elements that can be positioned
    # anywhere on the page using grid coordinates. They encapsulate common rendering
    # patterns and provide a consistent interface for layout and styling.
    #
    # All sub-components must implement the {#render_at} method.
    #
    # @example Creating a custom sub-component
    #   class MyComponent < BujoPdf::Components::SubComponentBase
    #     def render_at(col, row, width_boxes, height_boxes)
    #       in_grid_box(col, row, width_boxes, height_boxes) do
    #         pdf.text "Hello from #{col}, #{row}"
    #       end
    #     end
    #   end
    #
    # @example Using a sub-component
    #   component = MyComponent.new(pdf, grid_system, color: 'FF0000')
    #   component.render_at(5, 10, 20, 15)  # Render at grid position (5, 10)
    class SubComponentBase
      # @return [Prawn::Document] The PDF document instance
      attr_reader :pdf

      # @return [GridSystem] The grid system for coordinate conversion
      attr_reader :grid

      # @return [Hash] Component configuration options
      attr_reader :options

      # Initialize a new sub-component
      #
      # @param pdf [Prawn::Document] The Prawn PDF document instance
      # @param grid_system [GridSystem] The grid system for coordinate conversion
      # @param options [Hash] Configuration options for the component
      def initialize(pdf, grid_system, **options)
        @pdf = pdf
        @grid = grid_system
        @options = options
      end

      # Render the component at a specific grid position
      #
      # This method must be implemented by all sub-component classes.
      #
      # @param col [Integer, Float] Starting column in grid coordinates
      # @param row [Integer, Float] Starting row in grid coordinates
      # @param width_boxes [Integer, Float] Width in grid boxes
      # @param height_boxes [Integer, Float] Height in grid boxes
      # @raise [NotImplementedError] If not implemented by subclass
      # @return [void]
      def render_at(col, row, width_boxes, height_boxes)
        raise NotImplementedError, "#{self.class.name} must implement #render_at"
      end

      protected

      # Create a bounding box at the specified grid position and execute a block
      #
      # This is a convenience helper for simple components that just need a
      # bounding box at a grid position. The block is executed within the
      # bounding box's local coordinate system.
      #
      # @param col [Integer, Float] Starting column in grid coordinates
      # @param row [Integer, Float] Starting row in grid coordinates
      # @param width_boxes [Integer, Float] Width in grid boxes
      # @param height_boxes [Integer, Float] Height in grid boxes
      # @yield Block to execute within the bounding box
      # @return [void]
      #
      # @example Draw text in a grid box
      #   in_grid_box(5, 10, 20, 5) do
      #     pdf.text "Hello", align: :center
      #   end
      def in_grid_box(col, row, width_boxes, height_boxes, &block)
        box = @grid.rect(col, row, width_boxes, height_boxes)
        @pdf.bounding_box([box[:x], box[:y]],
                          width: box[:width],
                          height: box[:height],
                          &block)
      end

      # Create a ComponentContext for local coordinate system operations
      #
      # ComponentContext provides local grid helpers and proportional division
      # within a bounded region. This is useful for complex layouts that need
      # both grid quantization (alignment) and proportional division (equal spacing).
      #
      # @param col [Integer, Float] Starting column in grid coordinates
      # @param row [Integer, Float] Starting row in grid coordinates
      # @param width_boxes [Integer, Float] Width in grid boxes
      # @param height_boxes [Integer, Float] Height in grid boxes
      # @yield [context] Block to execute within the component context
      # @yieldparam context [ComponentContext] The component context instance
      # @return [void]
      #
      # @example Using ComponentContext for hybrid layout
      #   with_context(5, 10, 20, 15) do |ctx|
      #     # Use proportional division
      #     col_width = ctx.divide_width(7)
      #
      #     # Use grid quantization
      #     header_height = ctx.grid_height(1.5)
      #
      #     # Draw content using local coordinates
      #     ctx.text_box "Header", at: [0, ctx.height_pt],
      #                  width: ctx.width_pt, height: header_height
      #   end
      def with_context(col, row, width_boxes, height_boxes, &block)
        require_relative '../dsl/runtime/component_context'

        box = @grid.rect(col, row, width_boxes, height_boxes)
        ComponentContext.new(@pdf, box[:x], box[:y], box[:width], box[:height], &block)
      end

      # Get a configuration option with optional default value
      #
      # Automatically resolves theme colors when default is nil and key matches
      # known color option names (border_color, text_color, weekend_bg_color, etc.)
      #
      # @param key [Symbol] The option key
      # @param default [Object] Default value if option not set
      # @return [Object] The option value or default
      #
      # @example
      #   def render_at(col, row, width_boxes, height_boxes)
      #     color = option(:color, 'CCCCCC')
      #     pdf.fill_color color
      #   end
      def option(key, default = nil)
        value = @options.fetch(key, default)

        # If value is nil and it's a color option, use themed default
        if value.nil?
          value = themed_color_default(key)
        end

        value
      end

      private

      # Get themed default color for common color option keys
      # @param key [Symbol] The option key
      # @return [String, nil] The themed color or nil if not a color option
      def themed_color_default(key)
        require_relative '../utilities/styling'

        case key
        when :border_color
          Styling::Colors.BORDERS
        when :text_color
          Styling::Colors.TEXT_BLACK
        when :weekend_bg_color
          Styling::Colors.WEEKEND_BG
        when :header_color
          Styling::Colors.SECTION_HEADERS
        when :line_color
          Styling::Colors.BORDERS
        else
          nil
        end
      end
    end
  end
end
