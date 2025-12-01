# frozen_string_literal: true

require_relative 'styling'

module BujoPdf
  # Immutable value object representing a rectangular region in grid coordinates.
  # Supports splatting into both positional and keyword argument APIs.
  #
  # @example Positional splatting
  #   rect = GridRect.new(5, 10, 20, 15)
  #   ruled_lines(*rect, color: 'red')  # => ruled_lines(5, 10, 20, 15, color: 'red')
  #
  # @example Keyword splatting
  #   rect = GridRect.new(5, 10, 20, 15)
  #   SomeComponent.new(pdf: pdf, grid: grid, **rect)
  #
  # @example Point-based access (for Prawn coordinate system)
  #   rect = GridRect.new(5, 10, 20, 15)
  #   rect.x        # => x coordinate in points
  #   rect.y        # => y coordinate in points
  #   rect.width_pt # => width in points
  #   rect.height_pt # => height in points
  #   rect[:x]      # => x coordinate in points (hash-style access)
  #
  class GridRect
    attr_reader :col, :row, :width, :height

    def initialize(col, row, width, height)
      @col = col
      @row = row
      @width = width
      @height = height
    end

    # Grid constants (from Styling::Grid)
    DOT_SPACING = Styling::Grid::DOT_SPACING
    PAGE_HEIGHT = Styling::Grid::PAGE_HEIGHT

    # Point-based accessors (for Prawn coordinate system)
    # These convert grid coordinates to PDF points

    # X coordinate in points (left edge)
    # @return [Float]
    def x
      @col * DOT_SPACING
    end

    # Y coordinate in points (top edge, measured from page bottom)
    # @return [Float]
    def y
      PAGE_HEIGHT - (@row * DOT_SPACING)
    end

    # Width in points
    # @return [Float]
    def width_pt
      @width * DOT_SPACING
    end

    # Height in points
    # @return [Float]
    def height_pt
      @height * DOT_SPACING
    end

    # Hash-style access for backward compatibility with code expecting {x:, y:, width:, height:}
    # @param key [Symbol] One of :x, :y, :width, :height, :col, :row
    # @return [Float, Integer] The requested value
    def [](key)
      case key
      when :x then x
      when :y then y
      when :width then width_pt
      when :height then height_pt
      when :col then col
      when :row then row
      when :width_boxes then width
      when :height_boxes then height
      else
        raise KeyError, "Unknown key: #{key.inspect}"
      end
    end

    # Enable positional splatting: ruled_lines(*rect, color: 'red')
    # Note: to_a is used by splat in method calls, to_ary for implicit conversion
    def to_a
      [col, row, width, height]
    end

    alias to_ary to_a

    # Enable keyword splatting: Component.new(**rect)
    def to_hash
      { col: col, row: row, width: width, height: height }
    end

    alias to_h to_hash

    # Convert to point-based hash (for Prawn coordinate system)
    # @return [Hash] {x:, y:, width:, height:} in points
    def to_point_hash
      { x: x, y: y, width: width_pt, height: height_pt }
    end

    def ==(other)
      return false unless other.is_a?(GridRect)

      col == other.col && row == other.row &&
        width == other.width && height == other.height
    end

    def inspect
      "#<GridRect col=#{col} row=#{row} width=#{width} height=#{height}>"
    end
  end
end
