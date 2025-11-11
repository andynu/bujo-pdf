# frozen_string_literal: true

require_relative 'styling'

# GridSystem provides a coordinate conversion system for grid-based layout
#
# The grid system uses a top-left origin (0,0) where:
# - Column 0 is the left edge, increases rightward
# - Row 0 is the top edge, increases downward
#
# This is converted to Prawn's coordinate system where:
# - Origin (0,0) is at bottom-left
# - X increases rightward
# - Y increases upward
#
# Example usage:
#   grid = GridSystem.new(pdf)
#   box = grid.rect(5, 10, 20, 15)  # col 5, row 10, 20×15 boxes
#   pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
#     # Draw content
#   end
class GridSystem
  attr_reader :pdf, :dot_spacing, :page_width, :page_height, :cols, :rows

  # Initialize a new GridSystem
  #
  # @param pdf [Prawn::Document] The Prawn PDF document instance
  # @param dot_spacing [Float] Distance between dots in points (default: 14.17pt = 5mm)
  # @param page_width [Float] Page width in points (default: 612pt = 8.5")
  # @param page_height [Float] Page height in points (default: 792pt = 11")
  def initialize(pdf, dot_spacing: Styling::Grid::DOT_SPACING,
                 page_width: Styling::Grid::PAGE_WIDTH,
                 page_height: Styling::Grid::PAGE_HEIGHT)
    @pdf = pdf
    @dot_spacing = dot_spacing
    @page_width = page_width
    @page_height = page_height
    @cols = (page_width / dot_spacing).floor
    @rows = (page_height / dot_spacing).floor
  end

  # Convert grid column to x-coordinate in points
  #
  # @param col [Integer] Column number (0-based, 0 = left edge)
  # @return [Float] X coordinate in points
  #
  # @example
  #   grid.x(0)   # => 0.0 (left edge)
  #   grid.x(1)   # => 14.17
  #   grid.x(21)  # => 297.57 (approximate center)
  def x(col)
    col * @dot_spacing
  end

  # Convert grid row to y-coordinate in points (measured from bottom)
  #
  # @param row [Integer] Row number (0-based from TOP, 0 = top edge)
  # @return [Float] Y coordinate in points (measured from bottom)
  #
  # @example
  #   grid.y(0)   # => 792.0 (top of page)
  #   grid.y(27)  # => 409.41 (approximate center)
  #   grid.y(54)  # => 27.18 (near bottom)
  #
  # Note: Row 0 is at the top, but returns a high Y value because
  # Prawn measures Y from the bottom of the page
  def y(row)
    @page_height - (row * @dot_spacing)
  end

  # Convert number of grid boxes to width in points
  #
  # @param boxes [Numeric] Number of grid boxes (can be fractional)
  # @return [Float] Width in points
  #
  # @example
  #   grid.width(1)    # => 14.17
  #   grid.width(10)   # => 141.7
  #   grid.width(0.5)  # => 7.085
  def width(boxes)
    boxes * @dot_spacing
  end

  # Convert number of grid boxes to height in points
  #
  # @param boxes [Numeric] Number of grid boxes (can be fractional)
  # @return [Float] Height in points
  #
  # @example
  #   grid.height(1)    # => 14.17
  #   grid.height(10)   # => 141.7
  #   grid.height(0.5)  # => 7.085
  def height(boxes)
    boxes * @dot_spacing
  end

  # Get bounding box coordinates for a grid region
  #
  # @param col [Integer] Column number of top-left corner
  # @param row [Integer] Row number of top-left corner
  # @param width_boxes [Numeric] Width in grid boxes
  # @param height_boxes [Numeric] Height in grid boxes
  # @return [Hash] Hash with :x, :y, :width, :height keys
  #
  # @example
  #   # Full-width header, 2 boxes tall
  #   grid.rect(0, 0, 43, 2)
  #   # => { x: 0, y: 792, width: 609.31, height: 28.34 }
  #
  #   # Sidebar: 3 boxes wide, full height
  #   grid.rect(0, 0, 3, 55)
  def rect(col, row, width_boxes, height_boxes)
    {
      x: x(col),
      y: y(row),
      width: width(width_boxes),
      height: height(height_boxes)
    }
  end

  # Create a text box positioned using grid coordinates
  #
  # @param text [String] Text content to display
  # @param col [Integer] Column number of top-left corner
  # @param row [Integer] Row number of top-left corner
  # @param width_boxes [Numeric] Width in grid boxes
  # @param height_boxes [Numeric] Height in grid boxes
  # @param options [Hash] Additional text_box options (align, valign, size, etc.)
  #
  # @example
  #   grid.text_box("Hello", 5, 10, 10, 2, align: :center, valign: :center)
  def text_box(text, col, row, width_boxes, height_boxes, **options)
    @pdf.text_box text,
                  at: [x(col), y(row)],
                  width: width(width_boxes),
                  height: height(height_boxes),
                  **options
  end

  # Create a link annotation positioned using grid coordinates
  #
  # @param col [Integer] Column number of top-left corner
  # @param row [Integer] Row number of top-left corner
  # @param width_boxes [Numeric] Width in grid boxes
  # @param height_boxes [Numeric] Height in grid boxes
  # @param dest [String] Destination name (e.g., "week_1", "seasonal")
  # @param options [Hash] Additional link_annotation options
  #
  # @example
  #   grid.link(5, 10, 10, 2, "week_42")
  def link(col, row, width_boxes, height_boxes, dest, **options)
    left = x(col)
    top = y(row)
    right = x(col + width_boxes)
    bottom = y(row + height_boxes)

    # Default to invisible border
    opts = { Border: [0, 0, 0] }.merge(options)

    @pdf.link_annotation([left, bottom, right, top],
                         Dest: dest,
                         **opts)
  end

  # Apply grid-based padding to a rect result
  #
  # @param rect [Hash] Result from rect() method
  # @param padding_boxes [Numeric] Inset amount in grid boxes (can be fractional)
  # @return [Hash] New hash with padded coordinates and dimensions
  #
  # @example
  #   box = grid.rect(5, 10, 20, 15)
  #   padded = grid.inset(box, 0.5)  # 0.5 boxes of padding on all sides
  def inset(rect, padding_boxes)
    padding_pt = width(padding_boxes)
    {
      x: rect[:x] + padding_pt,
      y: rect[:y] - padding_pt,
      width: rect[:width] - (padding_pt * 2),
      height: rect[:height] - (padding_pt * 2)
    }
  end

  # Calculate the bottom Y coordinate for a grid box
  #
  # @param row [Integer] Row number of top edge
  # @param height_boxes [Numeric] Height in grid boxes
  # @return [Float] Y coordinate of bottom edge (in Prawn coordinates)
  #
  # @example
  #   top = grid.y(10)
  #   bottom = grid.bottom(10, 2)  # For a box 2 boxes tall
  def bottom(row, height_boxes)
    y(row + height_boxes)
  end
end
