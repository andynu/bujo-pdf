# frozen_string_literal: true

require_relative 'styling'
require_relative 'grid_factory'

# DotGrid module provides functionality for drawing grid backgrounds
#
# The grid serves as a visual guide for handwriting and drawing,
# commonly used in bullet journals and planners.
#
# Supports multiple grid types:
# - :dots - Standard dot grid (default)
# - :isometric - Isometric grid with 30-60-90° triangles
# - :perspective - Perspective grid with vanishing points
# - :hexagon - Tessellating hexagon grid
#
# Example usage:
#   # Draw dots across entire page (backward compatible)
#   DotGrid.draw(pdf, 612, 792)
#
#   # Draw specific grid type
#   DotGrid.draw(pdf, 612, 792, type: :isometric)
#   DotGrid.draw(pdf, 612, 792, type: :hexagon, orientation: :pointy_top)
#
#   # Create a reusable stamp for efficiency (recommended for multi-page documents)
#   DotGrid.create_stamp(pdf, "page_dots")
#   DotGrid.create_stamp(pdf, "isometric_grid", type: :isometric)
#   pdf.stamp("page_dots")  # Use on each page
module DotGrid
  # Draw a grid pattern within specified dimensions
  #
  # Grid is aligned with the grid coordinate system, starting at (0, 0)
  # which corresponds to the top-left corner in grid coordinates.
  #
  # @param pdf [Prawn::Document] The Prawn PDF document instance
  # @param width [Float] Width of area to fill with grid (in points)
  # @param height [Float] Height of area to fill with grid (in points)
  # @param type [Symbol] Grid type (:dots, :isometric, :perspective, :hexagon)
  # @param options [Hash] Grid-specific rendering options
  # @option options [Float] :spacing Distance between grid elements (default: DOT_SPACING)
  # @option options [Float] :radius Radius of each dot (for :dots type, default: DOT_RADIUS)
  # @option options [String] :color 6-digit hex color code (default: COLOR_DOT_GRID)
  # @option options [String] :line_color Line color for non-dot grids (default: COLOR_DOT_GRID)
  # @option options [Float] :line_width Line width for non-dot grids (default: 0.25)
  # @option options [Symbol] :orientation Hexagon orientation (:flat_top, :pointy_top)
  # @option options [Integer] :num_points Perspective vanishing points (1, 2, or 3)
  #
  # @example Draw full-page dot grid (backward compatible)
  #   DotGrid.draw(pdf, 612, 792)
  #
  # @example Draw isometric grid
  #   DotGrid.draw(pdf, 612, 792, type: :isometric)
  #
  # @example Draw hexagon grid with custom options
  #   DotGrid.draw(pdf, 612, 792, type: :hexagon,
  #     spacing: 20, orientation: :pointy_top, line_color: 'AAAAAA')
  #
  # Note: This method temporarily changes colors but restores them when complete.
  def self.draw(pdf, width, height, type: :dots, **options)
    # For backward compatibility, handle old parameter names
    if options[:color] && !options[:fill_color]
      options[:fill_color] = options[:color]
    end

    # Create and render the appropriate grid type
    renderer = BujoPdf::Utilities::GridFactory.create(type, pdf, width, height, **options)
    renderer.render
  end

  # Create a reusable PDF stamp for a grid pattern
  #
  # This is the recommended approach for multi-page documents as it significantly
  # reduces file size by storing the grid pattern once and referencing it on each page.
  # Typical file size reduction: 85-90% compared to drawing on every page.
  #
  # @param pdf [Prawn::Document] The Prawn PDF document instance
  # @param stamp_name [String] Name to identify this stamp (default: "dot_grid")
  # @param type [Symbol] Grid type (:dots, :isometric, :perspective, :hexagon)
  # @param width [Float] Width of area to fill (default: PAGE_WIDTH)
  # @param height [Float] Height of area to fill (default: PAGE_HEIGHT)
  # @param options [Hash] Grid-specific rendering options (spacing, color, etc.)
  #
  # @example Create and use a full-page dot grid stamp (backward compatible)
  #   DotGrid.create_stamp(pdf, "page_dots")
  #   pdf.stamp("page_dots")  # Use on current page
  #   pdf.start_new_page
  #   pdf.stamp("page_dots")  # Reuse on next page
  #
  # @example Create stamps for all grid types
  #   DotGrid.create_stamp(pdf, "page_dots", type: :dots)
  #   DotGrid.create_stamp(pdf, "page_isometric", type: :isometric)
  #   DotGrid.create_stamp(pdf, "page_perspective", type: :perspective)
  #   DotGrid.create_stamp(pdf, "page_hexagon", type: :hexagon)
  #
  # @example Custom dimensions for a bounding box
  #   DotGrid.create_stamp(pdf, "notes_area", width: 400, height: 600)
  #   pdf.bounding_box([100, 700], width: 400, height: 600) do
  #     pdf.stamp("notes_area")
  #   end
  def self.create_stamp(pdf, stamp_name = "dot_grid",
                        type: :dots,
                        width: Styling::Grid::PAGE_WIDTH,
                        height: Styling::Grid::PAGE_HEIGHT,
                        **options)

    pdf.create_stamp(stamp_name) do
      draw(pdf, width, height, type: type, **options)
    end
  end
end
