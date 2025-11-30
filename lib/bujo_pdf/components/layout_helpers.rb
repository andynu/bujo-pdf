# frozen_string_literal: true

module BujoPdf
  module Components
    # LayoutHelpers provides the margins verb for layout calculations.
    #
    # This is a calculation helper rather than a rendering component - it
    # returns grid-box-based bounds that other components can use.
    #
    # For splitting regions into columns/rows, use the GridSystem methods:
    #   - @grid.divide_columns(col:, width:, count:, gap:)
    #   - @grid.divide_rows(row:, height:, count:, gap:)
    #   - @grid.divide_grid(col:, row:, width:, height:, cols:, rows:, ...)
    #
    # Example usage in a page:
    #   def render
    #     # Get inset bounds
    #     inner = margins(0, 0, 43, 55, all: 2)
    #
    #     # Split into columns using grid system
    #     left, right = @grid.divide_columns(col: inner.col, width: inner.width,
    #                                        count: 2, gap: 1)
    #     ruled_lines(left.col, inner.row, left.width, 10)
    #     ruled_lines(right.col, inner.row, right.width, 10)
    #   end
    #
    class LayoutHelpers
      # Mixin providing the margins verb for pages
      #
      # Include via Components::All in Pages::Base
      module Mixin
        # Create an inset region by applying margins
        #
        # Returns a Cell struct with adjusted position and dimensions.
        #
        # @param col [Integer] Starting column position
        # @param row [Integer] Starting row position
        # @param width [Integer] Width in grid boxes
        # @param height [Integer] Height in grid boxes
        # @param left [Integer] Left margin in grid boxes (default: 0)
        # @param right [Integer] Right margin in grid boxes (default: 0)
        # @param top [Integer] Top margin in grid boxes (default: 0)
        # @param bottom [Integer] Bottom margin in grid boxes (default: 0)
        # @param all [Integer, nil] Uniform margin on all sides
        # @return [Cell] Cell struct with adjusted position and dimensions
        #
        # @example Uniform margins
        #   inner = margins(0, 0, 43, 55, all: 2)
        #   h1(inner.col, inner.row, "Title")
        #
        # @example Specific margins
        #   inner = margins(0, 0, 43, 55, left: 3, right: 1, top: 2, bottom: 3)
        #
        # @example Combined with divide_columns
        #   inner = margins(0, 0, 43, 55, all: 2)
        #   cols = @grid.divide_columns(col: inner.col, width: inner.width, count: 2, gap: 1)
        def margins(col, row, width, height, left: 0, right: 0, top: 0, bottom: 0, all: nil)
          @grid.margins(
            col: col, row: row, width: width, height: height,
            left: left, right: right, top: top, bottom: bottom, all: all
          )
        end
      end
    end
  end
end
