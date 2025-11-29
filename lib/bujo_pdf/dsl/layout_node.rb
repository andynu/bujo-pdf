# frozen_string_literal: true

module BujoPdf
  module DSL
    # LayoutNode is the base class for all nodes in the layout tree.
    #
    # Each node represents a rectangular region on the page. Nodes can contain
    # children, and the layout algorithm computes bounding boxes by distributing
    # available space according to constraints (fixed sizes, flex weights, etc.).
    #
    # The coordinate system uses grid units (not points) to preserve alignment
    # with the 5mm dot grid. The 43x55 grid is the central mental model.
    #
    # Constraints:
    #   - width/height: Fixed size in grid boxes
    #   - flex: Proportional share of remaining space
    #   - min_width/min_height: Minimum size constraints
    #   - max_width/max_height: Maximum size constraints
    #
    # @example Basic usage
    #   root = ContainerNode.new(direction: :vertical)
    #   root.add_child(SectionNode.new(height: 10))
    #   root.add_child(SectionNode.new(flex: 1))
    #   root.compute_bounds(col: 0, row: 0, width: 43, height: 55)
    #
    class LayoutNode
      attr_reader :children, :constraints, :computed_bounds, :name

      # Initialize a new layout node.
      #
      # @param name [Symbol, nil] Optional name for referencing this node
      # @param constraints [Hash] Size and position constraints
      # @option constraints [Numeric] :width Fixed width in grid boxes
      # @option constraints [Numeric] :height Fixed height in grid boxes
      # @option constraints [Numeric] :flex Flex weight for distributing space
      # @option constraints [Numeric] :min_width Minimum width
      # @option constraints [Numeric] :min_height Minimum height
      # @option constraints [Numeric] :max_width Maximum width
      # @option constraints [Numeric] :max_height Maximum height
      def initialize(name: nil, **constraints)
        @name = name
        @constraints = constraints
        @children = []
        @computed_bounds = nil
      end

      # Add a child node.
      #
      # @param child [LayoutNode] The child node to add
      # @return [LayoutNode] The child node (for chaining)
      def add_child(child)
        @children << child
        child
      end

      # Check if this node has a fixed width.
      #
      # @return [Boolean] true if width is specified
      def fixed_width?
        @constraints.key?(:width)
      end

      # Check if this node has a fixed height.
      #
      # @return [Boolean] true if height is specified
      def fixed_height?
        @constraints.key?(:height)
      end

      # Check if this node uses flex layout.
      #
      # @return [Boolean] true if flex is specified
      def flex?
        @constraints.key?(:flex)
      end

      # Get the flex weight.
      #
      # @return [Numeric] The flex weight, or 0 if not a flex node
      def flex_weight
        @constraints[:flex] || 0
      end

      # Compute bounding boxes for this node and all descendants.
      #
      # This method is the core of the layout algorithm. It takes an available
      # rectangle and computes where this node (and its children) should be
      # positioned and sized.
      #
      # The default implementation assigns the full available space to this
      # node. Subclasses override to implement specific layout behaviors
      # (columns, rows, etc.).
      #
      # @param col [Numeric] Starting column in grid coordinates
      # @param row [Numeric] Starting row in grid coordinates
      # @param width [Numeric] Available width in grid boxes
      # @param height [Numeric] Available height in grid boxes
      # @return [Hash] Computed bounds { col:, row:, width:, height: }
      def compute_bounds(col:, row:, width:, height:)
        # Apply fixed dimensions if specified
        actual_width = @constraints[:width] || width
        actual_height = @constraints[:height] || height

        # Apply min/max constraints
        actual_width = apply_min_max(actual_width, :width)
        actual_height = apply_min_max(actual_height, :height)

        @computed_bounds = {
          col: col,
          row: row,
          width: actual_width,
          height: actual_height
        }
      end

      # Find a descendant node by name.
      #
      # @param target_name [Symbol] The name to search for
      # @return [LayoutNode, nil] The found node, or nil
      def find(target_name)
        return self if @name == target_name

        @children.each do |child|
          result = child.find(target_name)
          return result if result
        end
        nil
      end

      # Iterate over this node and all descendants.
      #
      # @yield [LayoutNode] Each node in the tree
      # @return [Enumerator] If no block given
      def each(&block)
        return enum_for(:each) unless block_given?

        yield self
        @children.each { |child| child.each(&block) }
      end

      # Get a human-readable representation of this node.
      #
      # @return [String] Debug representation
      def inspect
        "#<#{self.class.name.split('::').last} name=#{@name.inspect} constraints=#{@constraints} bounds=#{@computed_bounds}>"
      end

      protected

      # Apply min/max constraints to a dimension.
      #
      # @param value [Numeric] The computed value
      # @param dimension [Symbol] :width or :height
      # @return [Numeric] The constrained value
      def apply_min_max(value, dimension)
        min_key = :"min_#{dimension}"
        max_key = :"max_#{dimension}"

        value = [@constraints[min_key], value].compact.max
        value = [@constraints[max_key], value].compact.min
        value
      end

      # Quantize a value to whole grid boxes when possible.
      #
      # This is used to keep columns/rows aligned with the dot grid.
      # When division doesn't work out evenly, we give the extra space
      # to the last item rather than using fractional boxes.
      #
      # @param value [Numeric] The value to quantize
      # @return [Integer] The quantized value
      def quantize(value)
        value.floor
      end
    end
  end
end
