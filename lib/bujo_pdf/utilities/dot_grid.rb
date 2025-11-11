# frozen_string_literal: true

require_relative 'styling'

# DotGrid module provides functionality for drawing dot grid backgrounds
#
# The dot grid serves as a visual guide for handwriting and drawing,
# commonly used in bullet journals and planners. Dots are placed at
# regular intervals matching the grid system spacing.
#
# Example usage:
#   # Draw dots across entire page
#   DotGrid.draw(pdf, 612, 792)
#
#   # Draw dots with custom styling
#   DotGrid.draw(pdf, 400, 600, spacing: 15, radius: 0.75, color: 'DDDDDD')
#
#   # Create a reusable stamp for efficiency (recommended for multi-page documents)
#   DotGrid.create_stamp(pdf, "page_dots")
#   pdf.stamp("page_dots")  # Use on each page
module DotGrid
  # Draw a dot grid pattern within specified dimensions
  #
  # Dots are aligned with the grid coordinate system, starting at (0, 0)
  # which corresponds to the top-left corner in grid coordinates.
  #
  # @param pdf [Prawn::Document] The Prawn PDF document instance
  # @param width [Float] Width of area to fill with dots (in points)
  # @param height [Float] Height of area to fill with dots (in points)
  # @param spacing [Float] Distance between dots (default: DOT_SPACING)
  # @param radius [Float] Radius of each dot (default: DOT_RADIUS)
  # @param color [String] 6-digit hex color code (default: COLOR_DOT_GRID)
  #
  # @example Draw full-page dot grid
  #   DotGrid.draw(pdf, 612, 792)
  #
  # @example Draw in a bounding box with custom color
  #   pdf.bounding_box([100, 700], width: 400, height: 600) do
  #     DotGrid.draw(pdf, 400, 600, color: 'DDDDDD')
  #   end
  #
  # Note: This method temporarily changes the fill color but restores it
  # to black ('000000') when complete.
  def self.draw(pdf, width, height,
                spacing: Styling::Grid::DOT_SPACING,
                radius: Styling::Grid::DOT_RADIUS,
                color: Styling::Colors::DOT_GRID)
    # Save current color and switch to dot grid color
    pdf.fill_color color

    # Align with grid coordinate system: start at (0, height) which
    # corresponds to grid position (0, 0) - top-left corner
    start_x = 0
    start_y = height

    # Calculate how many dots fit in the given dimensions
    cols = (width / spacing).floor
    rows = (height / spacing).floor

    # Draw dots at exact grid positions
    (0..rows).each do |row|
      y = start_y - (row * spacing)
      (0..cols).each do |col|
        x = start_x + (col * spacing)
        pdf.fill_circle [x, y], radius
      end
    end

    # Restore fill color to black
    pdf.fill_color Styling::Colors::TEXT_BLACK
  end

  # Create a reusable PDF stamp for the dot grid pattern
  #
  # This is the recommended approach for multi-page documents as it significantly
  # reduces file size by storing the dot pattern once and referencing it on each page.
  # Typical file size reduction: 85-90% compared to drawing dots on every page.
  #
  # @param pdf [Prawn::Document] The Prawn PDF document instance
  # @param stamp_name [String] Name to identify this stamp (default: "dot_grid")
  # @param width [Float] Width of area to fill with dots (default: PAGE_WIDTH)
  # @param height [Float] Height of area to fill with dots (default: PAGE_HEIGHT)
  # @param spacing [Float] Distance between dots (default: DOT_SPACING)
  # @param radius [Float] Radius of each dot (default: DOT_RADIUS)
  # @param color [String] 6-digit hex color code (default: COLOR_DOT_GRID)
  #
  # @example Create and use a full-page dot grid stamp
  #   DotGrid.create_stamp(pdf, "page_dots")
  #   pdf.stamp("page_dots")  # Use on current page
  #   pdf.start_new_page
  #   pdf.stamp("page_dots")  # Reuse on next page
  #
  # @example Custom dimensions for a bounding box
  #   DotGrid.create_stamp(pdf, "notes_area", 400, 600)
  #   pdf.bounding_box([100, 700], width: 400, height: 600) do
  #     pdf.stamp("notes_area")
  #   end
  def self.create_stamp(pdf, stamp_name = "dot_grid",
                        width: Styling::Grid::PAGE_WIDTH,
                        height: Styling::Grid::PAGE_HEIGHT,
                        spacing: Styling::Grid::DOT_SPACING,
                        radius: Styling::Grid::DOT_RADIUS,
                        color: Styling::Colors::DOT_GRID)
    pdf.create_stamp(stamp_name) do
      draw(pdf, width, height, spacing: spacing, radius: radius, color: color)
    end
  end
end
