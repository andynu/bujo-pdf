# frozen_string_literal: true

require_relative '../utilities/grid_rect'

module BujoPdf
  module Components
    # Stack places slots one after another along an axis, in whole grid boxes.
    #
    # A vertical stack (the column verb) splits its area into rows top to
    # bottom; a horizontal stack (the row verb) splits it into columns left to
    # right. Each slot declares its size in boxes, or :fill to share whatever
    # the fixed slots and gaps leave over. Every slot spans the full cross axis.
    #
    # Slots are collected first and laid out afterwards, so a :fill slot can sit
    # anywhere in the stack. Pages are fixed, not flowed: a stack that does not
    # fit its area raises instead of continuing elsewhere.
    #
    # Example usage in a page:
    #   column(2, 4, 38, 49, gap: 1) do |c|
    #     c.slot(13) { |cell| fieldset(cell, legend: 'Tasks') }
    #     c.slot(:fill) { |cell| fieldset(cell, legend: 'Notes') }
    #     c.slot(8) { |cell| fieldset(cell, legend: 'Events') }
    #   end
    #
    class Stack
      AXES = %i[vertical horizontal].freeze

      # Mixin providing the column and row verbs for pages
      #
      # Include via Components::All in Pages::Base
      module Mixin
        # Stack slots top to bottom
        #
        # @param col [Integer, GridRect] Starting column (left edge), or a GridRect for the whole area
        # @param row [Integer] Starting row (top edge)
        # @param width [Integer] Width in grid boxes
        # @param height [Integer] Height in grid boxes
        # @param gap [Integer] Rows between slots (default: 0)
        # @yieldparam stack [Stack] Declare slots with stack.slot(size) { |cell| ... }
        # @return [Array<GridRect>] Each slot's cell, in declaration order
        # @raise [ArgumentError] if the slots do not fit the area
        def column(col, row = nil, width = nil, height = nil, gap: 0, &block)
          Stack.build(GridRect.from(col, row, width, height), :vertical, gap, &block)
        end

        # Stack slots left to right
        #
        # @param (see #column)
        # @param gap [Integer] Columns between slots (default: 0)
        # @yieldparam (see #column)
        # @return (see #column)
        # @raise (see #column)
        def row(col, row = nil, width = nil, height = nil, gap: 0, &block)
          Stack.build(GridRect.from(col, row, width, height), :horizontal, gap, &block)
        end
      end

      # Yield a new stack for slot declarations, then render it.
      #
      # @return [Array<GridRect>]
      def self.build(area, axis, gap)
        stack = new(area, axis: axis, gap: gap)
        yield stack
        stack.render
      end

      # @param area [GridRect] Region to divide
      # @param axis [Symbol] :vertical (rows) or :horizontal (columns)
      # @param gap [Integer] Boxes between adjacent slots
      def initialize(area, axis:, gap: 0)
        raise ArgumentError, "axis must be one of #{AXES.inspect}, got #{axis.inspect}" unless AXES.include?(axis)
        raise ArgumentError, "gap must be a non-negative Integer, got #{gap.inspect}" unless gap.is_a?(Integer) && gap >= 0

        @area = area
        @axis = axis
        @gap = gap
        @slots = []
      end

      # Declare the next slot.
      #
      # @param size [Integer, :fill] Size along the axis in grid boxes, or :fill
      # @yieldparam cell [GridRect] The slot's cell, once the stack is laid out
      # @return [void]
      def slot(size, &block)
        unless size == :fill || (size.is_a?(Integer) && size.positive?)
          raise ArgumentError, "slot size must be a positive Integer or :fill, got #{size.inspect}"
        end

        @slots << [size, block]
        nil
      end

      # Lay out every declared slot.
      #
      # @return [Array<GridRect>] One cell per slot, in declaration order
      # @raise [ArgumentError] if the fixed slots and gaps exceed the area, or
      #   leave a :fill slot less than one box
      def cells
        sizes = resolved_sizes
        cursor = start

        sizes.map do |size|
          cell = cell_at(cursor, size)
          cursor += size + @gap
          cell
        end
      end

      # Lay out the slots and call each slot's block with its cell.
      #
      # @return [Array<GridRect>] One cell per slot, in declaration order
      def render
        laid_out = cells
        @slots.each_with_index do |(_size, block), i|
          block&.call(laid_out[i])
        end
        laid_out
      end

      private

      def vertical?
        @axis == :vertical
      end

      def start
        vertical? ? @area.row : @area.col
      end

      def extent
        vertical? ? @area.height : @area.width
      end

      def unit
        vertical? ? 'rows' : 'columns'
      end

      def cell_at(cursor, size)
        if vertical?
          GridRect.new(@area.col, cursor, @area.width, size)
        else
          GridRect.new(cursor, @area.row, size, @area.height)
        end
      end

      def resolved_sizes
        fixed = @slots.map(&:first).grep(Integer)
        fill_count = @slots.count { |size, _| size == :fill }
        gaps = @gap * [@slots.length - 1, 0].max
        claimed = fixed.sum + gaps

        if claimed > extent
          raise ArgumentError,
                "#{@axis} stack needs #{claimed} #{unit} (#{fixed.sum} in slots, #{gaps} in gaps) " \
                "but its area has #{extent}"
        end

        fill_sizes = share(extent - claimed, fill_count)
        @slots.map { |size, _| size == :fill ? fill_sizes.shift : size }
      end

      # Split the remainder evenly over the fill slots, earliest first.
      def share(remainder, count)
        return [] if count.zero?

        base, extra = remainder.divmod(count)
        if base < 1
          raise ArgumentError,
                "#{@axis} stack has #{remainder} #{unit} left for #{count} :fill slot(s); each needs at least 1"
        end

        Array.new(count) { |i| base + (i < extra ? 1 : 0) }
      end
    end
  end
end
