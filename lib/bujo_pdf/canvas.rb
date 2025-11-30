# frozen_string_literal: true

module BujoPdf
  # Value object bundling a PDF document with its grid system.
  #
  # Canvas provides a single object to pass to components instead of separate
  # pdf and grid parameters. Since these always travel together, Canvas simplifies
  # component interfaces and provides a natural place for future grid renderer access.
  #
  # Architecture:
  #   Document -> Page -> Canvas -> Components
  #                         |
  #                   wraps pdf + grid
  #
  # @example Creating a Canvas
  #   pdf = Prawn::Document.new
  #   grid = GridSystem.new(pdf)
  #   canvas = Canvas.new(pdf, grid)
  #
  # @example Using Canvas in a component
  #   class MyComponent
  #     def initialize(canvas:)
  #       @canvas = canvas
  #     end
  #
  #     def render
  #       @canvas.pdf.text "Hello"
  #       x = @canvas.x(5)  # Delegate to grid
  #     end
  #   end
  #
  class Canvas
    # @return [Prawn::Document] The PDF document
    attr_reader :pdf

    # @return [GridSystem] The grid system for positioning
    attr_reader :grid

    # Initialize a new Canvas.
    #
    # @param pdf [Prawn::Document] The PDF document to render into
    # @param grid [GridSystem] The grid system for positioning
    def initialize(pdf, grid)
      @pdf = pdf
      @grid = grid
    end

    # Grid coordinate delegators
    # --------------------------
    # These methods delegate to the grid system for convenience,
    # allowing callers to write `canvas.x(5)` instead of `canvas.grid.x(5)`.

    # Convert grid column to x-coordinate.
    #
    # @param col [Integer, Float] Grid column
    # @return [Float] X-coordinate in points
    def x(col) = @grid.x(col)

    # Convert grid row to y-coordinate.
    #
    # @param row [Integer, Float] Grid row
    # @return [Float] Y-coordinate in points
    def y(row) = @grid.y(row)

    # Convert grid boxes to width in points.
    #
    # @param boxes [Integer, Float] Number of grid boxes
    # @return [Float] Width in points
    def width(boxes) = @grid.width(boxes)

    # Convert grid boxes to height in points.
    #
    # @param boxes [Integer, Float] Number of grid boxes
    # @return [Float] Height in points
    def height(boxes) = @grid.height(boxes)

    # Get a rectangle in page grid coordinates.
    #
    # @param col [Integer] Grid column
    # @param row [Integer] Grid row
    # @param w [Integer] Width in grid boxes
    # @param h [Integer] Height in grid boxes
    # @return [Hash] Rectangle with :x, :y, :width, :height keys
    def rect(col, row, w, h) = @grid.rect(col, row, w, h)

    # Future: grid renderer access
    # ----------------------------
    # When grid renderers are added, they can be accessed via:
    #   def dot_grid = @grid_renderers[:dot]
    #   def graph_grid = @grid_renderers[:graph]
  end
end
