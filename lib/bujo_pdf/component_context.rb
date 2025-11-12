# frozen_string_literal: true

require_relative 'utilities/styling'

# ComponentContext provides a local coordinate system for sub-components
#
# When rendering complex sub-components, it's often useful to work in a local
# coordinate system where (0,0) is the component's origin, rather than the page origin.
# ComponentContext creates a bounding box and provides both grid-based and proportional
# layout helpers that work in local coordinates.
#
# This enables a hybrid layout approach:
# - Grid quantization for alignment (headers, margins, spacing)
# - Proportional division for equal spacing (7 day columns, 25%/75% splits)
#
# @example Weekly columns with local coordinates
#   ComponentContext.new(pdf, x, y, width, height) do |ctx|
#     # Divide width into 7 equal columns
#     day_width = ctx.divide_width(7)
#
#     7.times do |i|
#       # Position using proportional coordinates
#       day_x = i * day_width
#
#       # Height using grid quantization
#       header_height = ctx.grid_height(1.5)
#
#       # Draw in local coordinates
#       ctx.text_box "Day #{i+1}",
#                    at: [day_x, ctx.height_pt],
#                    width: day_width,
#                    height: header_height
#     end
#   end
#
# @example Cornell notes layout
#   ComponentContext.new(pdf, x, y, width, height) do |ctx|
#     # Proportional width division: 25% cues, 75% notes
#     cues_width = ctx.divide_width(4)
#     notes_width = cues_width * 3
#
#     # Grid-based height division
#     main_height = ctx.grid_height(ctx.height_boxes * 0.8)
#     summary_height = ctx.height_pt - main_height
#
#     # All coordinates are local
#     ctx.bounding_box([0, ctx.height_pt], width: cues_width, height: main_height) do
#       ctx.text "Cues"
#       ctx.stroke_bounds
#     end
#   end
class ComponentContext
  # @return [Float] Component width in points
  attr_reader :width_pt

  # @return [Float] Component height in points
  attr_reader :height_pt

  # @return [Float] Component width in grid boxes (fractional)
  attr_reader :width_boxes

  # @return [Float] Component height in grid boxes (fractional)
  attr_reader :height_boxes

  # Initialize a ComponentContext and execute a block within it
  #
  # Creates a Prawn bounding box at the specified position and yields a
  # ComponentContext instance to the block. All drawing operations within
  # the block use local coordinates relative to the component origin.
  #
  # @param pdf [Prawn::Document] The PDF document instance
  # @param x [Float] X position in page coordinates (from left edge)
  # @param y [Float] Y position in page coordinates (from bottom edge)
  # @param width_pt [Float] Component width in points
  # @param height_pt [Float] Component height in points
  # @yield [context] Block to execute within the component context
  # @yieldparam context [ComponentContext] The component context instance
  def initialize(pdf, x, y, width_pt, height_pt)
    @pdf = pdf
    @width_pt = width_pt
    @height_pt = height_pt
    @width_boxes = width_pt / Styling::Grid::DOT_SPACING
    @height_boxes = height_pt / Styling::Grid::DOT_SPACING

    @pdf.bounding_box([x, y], width: width_pt, height: height_pt) do
      yield self
    end
  end

  # Convert a fractional grid column to local x-coordinate
  #
  # @param col_fraction [Float] Column position in grid boxes (can be fractional)
  # @return [Float] X-coordinate in points from local origin
  #
  # @example
  #   ctx.grid_x(0)     # => 0.0 (left edge)
  #   ctx.grid_x(0.5)   # => 7.085 (half a grid box from left)
  #   ctx.grid_x(5)     # => 70.85 (5 grid boxes from left)
  def grid_x(col_fraction)
    col_fraction * Styling::Grid::DOT_SPACING
  end

  # Convert a fractional grid row to local y-coordinate
  #
  # Row 0 is at the top of the component, increasing downward (grid convention).
  # The returned y-coordinate is measured from the bottom (Prawn convention).
  #
  # @param row_fraction [Float] Row position in grid boxes (can be fractional)
  # @return [Float] Y-coordinate in points from local origin (bottom)
  #
  # @example
  #   ctx.grid_y(0)     # => height_pt (top of component)
  #   ctx.grid_y(1)     # => height_pt - 14.17 (1 box down from top)
  #   ctx.grid_y(2.5)   # => height_pt - 35.425 (2.5 boxes down from top)
  def grid_y(row_fraction)
    @height_pt - (row_fraction * Styling::Grid::DOT_SPACING)
  end

  # Convert grid boxes to width in points
  #
  # @param boxes [Float] Number of grid boxes
  # @return [Float] Width in points
  #
  # @example
  #   ctx.grid_width(1)    # => 14.17
  #   ctx.grid_width(5)    # => 70.85
  #   ctx.grid_width(0.5)  # => 7.085
  def grid_width(boxes)
    boxes * Styling::Grid::DOT_SPACING
  end

  # Convert grid boxes to height in points
  #
  # @param boxes [Float] Number of grid boxes
  # @return [Float] Height in points
  #
  # @example
  #   ctx.grid_height(1)    # => 14.17
  #   ctx.grid_height(5)    # => 70.85
  #   ctx.grid_height(0.5)  # => 7.085
  def grid_height(boxes)
    boxes * Styling::Grid::DOT_SPACING
  end

  # Divide component width into equal parts
  #
  # This is useful for proportional layouts where you need to split a region
  # into N equal columns, regardless of how it aligns with the grid.
  #
  # @param parts [Integer, Float] Number of equal parts to divide into
  # @return [Float] Width of each part in points
  #
  # @example
  #   ctx.divide_width(7)  # => width_pt / 7 (for 7 day columns)
  #   ctx.divide_width(4)  # => width_pt / 4 (for 25% width)
  def divide_width(parts)
    @width_pt / parts.to_f
  end

  # Divide component height into equal parts
  #
  # This is useful for proportional layouts where you need to split a region
  # into N equal rows, regardless of how it aligns with the grid.
  #
  # @param parts [Integer, Float] Number of equal parts to divide into
  # @return [Float] Height of each part in points
  #
  # @example
  #   ctx.divide_height(3)  # => height_pt / 3 (for thirds)
  #   ctx.divide_height(5)  # => height_pt / 5 (for 20% height)
  def divide_height(parts)
    @height_pt / parts.to_f
  end

  # Get a sub-region using local grid coordinates
  #
  # Returns a hash compatible with Prawn's bounding_box method.
  #
  # @param col_fraction [Float] Starting column in local grid coordinates
  # @param row_fraction [Float] Starting row in local grid coordinates
  # @param width_boxes [Float] Width in grid boxes
  # @param height_boxes [Float] Height in grid boxes
  # @return [Hash] Region with :x, :y, :width, :height keys
  #
  # @example
  #   region = ctx.region(1, 2, 5, 3)
  #   ctx.bounding_box([region[:x], region[:y]],
  #                    width: region[:width],
  #                    height: region[:height]) do
  #     # Draw in sub-region
  #   end
  def region(col_fraction, row_fraction, width_boxes, height_boxes)
    {
      x: grid_x(col_fraction),
      y: grid_y(row_fraction),
      width: grid_width(width_boxes),
      height: grid_height(height_boxes)
    }
  end

  # Delegate unknown methods to the underlying PDF object
  #
  # This allows transparent access to all Prawn drawing methods
  # (text, text_box, stroke_line, etc.) directly on the context.
  #
  # @param method [Symbol] Method name to call on PDF
  # @param args [Array] Positional arguments
  # @param kwargs [Hash] Keyword arguments
  # @param block [Proc] Block to pass to method
  # @return [Object] Result of PDF method call
  def method_missing(method, *args, **kwargs, &block)
    @pdf.send(method, *args, **kwargs, &block)
  end

  # Check if a method can be delegated to PDF
  #
  # @param method [Symbol] Method name
  # @param include_private [Boolean] Include private methods in check
  # @return [Boolean] True if method can be called
  def respond_to_missing?(method, include_private = false)
    @pdf.respond_to?(method, include_private) || super
  end
end
