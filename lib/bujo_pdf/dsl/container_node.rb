# frozen_string_literal: true

require_relative 'layout_node'

module BujoPdf
  module DSL
    # ContainerNode is a layout node that arranges children in a direction.
    #
    # This is the primary building block for layouts. Children can be arranged:
    # - :vertical (default) - stacked top to bottom
    # - :horizontal - arranged left to right
    #
    # Space distribution:
    # 1. Fixed-size children get their requested size
    # 2. Remaining space is distributed among flex children by weight
    # 3. If flex children don't divide evenly, extra boxes go to the last child
    #
    # @example Vertical stack with flex
    #   container = ContainerNode.new(direction: :vertical)
    #   container.add_child(SectionNode.new(height: 10))
    #   container.add_child(SectionNode.new(flex: 1))
    #   container.add_child(SectionNode.new(height: 5))
    #
    # @example Horizontal columns
    #   container = ContainerNode.new(direction: :horizontal)
    #   container.add_child(SectionNode.new(width: 3))   # sidebar
    #   container.add_child(SectionNode.new(flex: 1))    # content
    #   container.add_child(SectionNode.new(width: 1))   # right margin
    #
    class ContainerNode < LayoutNode
      attr_reader :direction, :gap

      # Initialize a new container node.
      #
      # @param direction [Symbol] Layout direction (:vertical or :horizontal)
      # @param gap [Numeric] Space between children in grid boxes (default: 0)
      # @param kwargs [Hash] Additional constraints passed to LayoutNode
      def initialize(direction: :vertical, gap: 0, **kwargs)
        super(**kwargs)
        @direction = direction
        @gap = gap
      end

      # Compute bounding boxes for this container and all children.
      #
      # The algorithm:
      # 1. Calculate total fixed space consumed by fixed-size children and gaps
      # 2. Distribute remaining space to flex children by weight
      # 3. Position each child sequentially in the layout direction
      #
      # @param col [Numeric] Starting column
      # @param row [Numeric] Starting row
      # @param width [Numeric] Available width
      # @param height [Numeric] Available height
      # @return [Hash] Computed bounds for this container
      def compute_bounds(col:, row:, width:, height:)
        # First, compute our own bounds
        @computed_bounds = super

        return @computed_bounds if @children.empty?

        # Use our computed bounds for child layout
        available_width = @computed_bounds[:width]
        available_height = @computed_bounds[:height]
        start_col = @computed_bounds[:col]
        start_row = @computed_bounds[:row]

        if @direction == :vertical
          compute_vertical_layout(start_col, start_row, available_width, available_height)
        else
          compute_horizontal_layout(start_col, start_row, available_width, available_height)
        end

        @computed_bounds
      end

      private

      # Compute layout for vertical (top-to-bottom) direction.
      #
      # @param start_col [Numeric] Starting column
      # @param start_row [Numeric] Starting row
      # @param width [Numeric] Available width
      # @param height [Numeric] Available height
      def compute_vertical_layout(start_col, start_row, width, height)
        # Calculate total gap space
        total_gap = @gap * (@children.length - 1)

        # Calculate fixed space and collect flex children
        fixed_space = 0
        flex_total = 0

        @children.each do |child|
          if child.fixed_height?
            fixed_space += child.constraints[:height]
          elsif child.flex?
            flex_total += child.flex_weight
          else
            # Child with no height or flex takes no space initially
            # (will be zero height unless we decide on a default behavior)
          end
        end

        # Available space for flex children
        flex_space = height - fixed_space - total_gap
        flex_space = [flex_space, 0].max  # Don't go negative

        # Track position
        current_row = start_row

        @children.each_with_index do |child, index|
          # Determine child height
          child_height = if child.fixed_height?
            child.constraints[:height]
          elsif child.flex? && flex_total > 0
            # Proportional distribution with quantization
            proportion = child.flex_weight.to_f / flex_total
            base_height = (flex_space * proportion).floor

            # For the last flex child, give it all remaining space
            # to avoid fractional boxes
            if last_flex_child?(child, index)
              remaining = height - (current_row - start_row) - total_remaining_gap(index)
              remaining - fixed_space_after(index)
            else
              base_height
            end
          else
            0
          end

          # Compute child bounds
          child.compute_bounds(
            col: start_col,
            row: current_row,
            width: width,
            height: child_height
          )

          # Move to next position
          current_row += child_height
          current_row += @gap if index < @children.length - 1
        end
      end

      # Compute layout for horizontal (left-to-right) direction.
      #
      # @param start_col [Numeric] Starting column
      # @param start_row [Numeric] Starting row
      # @param width [Numeric] Available width
      # @param height [Numeric] Available height
      def compute_horizontal_layout(start_col, start_row, width, height)
        # Calculate total gap space
        total_gap = @gap * (@children.length - 1)

        # Calculate fixed space and collect flex children
        fixed_space = 0
        flex_total = 0

        @children.each do |child|
          if child.fixed_width?
            fixed_space += child.constraints[:width]
          elsif child.flex?
            flex_total += child.flex_weight
          end
        end

        # Available space for flex children
        flex_space = width - fixed_space - total_gap
        flex_space = [flex_space, 0].max

        # Track position
        current_col = start_col

        @children.each_with_index do |child, index|
          # Determine child width
          child_width = if child.fixed_width?
            child.constraints[:width]
          elsif child.flex? && flex_total > 0
            proportion = child.flex_weight.to_f / flex_total
            base_width = (flex_space * proportion).floor

            # For the last flex child, give it all remaining space
            if last_flex_child?(child, index)
              remaining = width - (current_col - start_col) - total_remaining_gap(index)
              remaining - fixed_space_after_horizontal(index)
            else
              base_width
            end
          else
            0
          end

          # Compute child bounds
          child.compute_bounds(
            col: current_col,
            row: start_row,
            width: child_width,
            height: height
          )

          # Move to next position
          current_col += child_width
          current_col += @gap if index < @children.length - 1
        end
      end

      # Check if this is the last flex child.
      #
      # @param child [LayoutNode] The current child
      # @param current_index [Integer] Current position in children array
      # @return [Boolean] true if this is the last flex child
      def last_flex_child?(child, current_index)
        return false unless child.flex?

        # Check if any later children are also flex
        ((current_index + 1)...@children.length).each do |i|
          return false if @children[i].flex?
        end
        true
      end

      # Calculate remaining gap space from current position.
      #
      # @param current_index [Integer] Current position
      # @return [Numeric] Total remaining gap space
      def total_remaining_gap(current_index)
        remaining_count = @children.length - current_index - 1
        @gap * remaining_count
      end

      # Calculate fixed space after current position (vertical).
      #
      # @param current_index [Integer] Current position
      # @return [Numeric] Total fixed height after this position
      def fixed_space_after(current_index)
        total = 0
        ((current_index + 1)...@children.length).each do |i|
          child = @children[i]
          total += child.constraints[:height] if child.fixed_height?
        end
        total
      end

      # Calculate fixed space after current position (horizontal).
      #
      # @param current_index [Integer] Current position
      # @return [Numeric] Total fixed width after this position
      def fixed_space_after_horizontal(current_index)
        total = 0
        ((current_index + 1)...@children.length).each do |i|
          child = @children[i]
          total += child.constraints[:width] if child.fixed_width?
        end
        total
      end
    end
  end
end
