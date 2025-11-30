# frozen_string_literal: true

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
  class GridRect
    attr_reader :col, :row, :width, :height

    def initialize(col, row, width, height)
      @col = col
      @row = row
      @width = width
      @height = height
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
