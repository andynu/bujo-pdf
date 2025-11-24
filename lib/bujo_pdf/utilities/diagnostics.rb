# frozen_string_literal: true

require_relative 'styling'

# Diagnostics module provides debugging tools for grid-based layouts
#
# The diagnostic grid overlay helps visualize the grid coordinate system
# and verify that elements are positioned correctly. It draws:
# - Red dots at every grid intersection
# - Dashed red grid lines at regular intervals
# - Coordinate labels showing (col, row) at intersections
#
# Example usage:
#   Diagnostics.draw_grid(pdf, grid_system, enabled: true, label_every: 5)
module Diagnostics
  # Draw diagnostic grid overlay
  #
  # This method draws a red grid overlay with coordinate labels to help
  # debug layout positioning. It should be called early in page generation
  # (before other content) so the diagnostic grid appears behind content.
  #
  # @param pdf [Prawn::Document] The Prawn PDF document instance
  # @param grid_system [GridSystem] The grid system instance for coordinate conversion
  # @param enabled [Boolean] Whether to draw the grid (default: true)
  # @param label_every [Integer] Draw grid lines every N boxes (default: 5)
  #
  # @example
  #   Diagnostics.draw_grid(pdf, grid_system, enabled: DEBUG_GRID, label_every: 5)
  #
  # Note: This method temporarily changes colors and line styles but restores
  # them to defaults (black fill/stroke) when complete.
  def self.draw_grid(pdf, grid_system, enabled: true, label_every: 5)
    return unless enabled

    # Draw red dots at every grid intersection
    pdf.fill_color Styling::Colors.DIAGNOSTIC_RED
    (0..grid_system.rows).each do |row|
      y = grid_system.y(row)
      (0..grid_system.cols).each do |col|
        x = grid_system.x(col)
        pdf.fill_circle [x, y], 1.0  # Slightly larger than regular dots (0.5pt)
      end
    end

    # Draw dashed grid lines every label_every boxes
    pdf.stroke_color Styling::Colors.DIAGNOSTIC_RED
    pdf.line_width 0.25
    pdf.dash(1, space: 2)

    # Vertical lines
    (0..grid_system.cols).step(label_every).each do |col|
      x = grid_system.x(col)
      pdf.stroke_line [x, 0], [x, grid_system.page_height]
    end

    # Horizontal lines
    (0..grid_system.rows).step(label_every).each do |row|
      y = grid_system.y(row)
      pdf.stroke_line [0, y], [grid_system.page_width, y]
    end

    # Reset line style
    pdf.undash
    pdf.line_width 1

    # Add coordinate labels at intersections
    pdf.fill_color Styling::Colors.DIAGNOSTIC_RED
    pdf.font "Helvetica", size: 6

    (0..grid_system.rows).step(label_every).each do |row|
      y = grid_system.y(row)
      (0..grid_system.cols).step(label_every).each do |col|
        x = grid_system.x(col)

        # Draw white background rectangle for label readability
        label = "(#{col},#{row})"
        label_width = 25
        label_height = 10

        pdf.fill_color Styling::Colors.DIAGNOSTIC_LABEL_BG
        pdf.fill_rectangle [x + 2, y - 2], label_width, label_height

        # Draw the label text
        pdf.fill_color Styling::Colors.DIAGNOSTIC_RED
        pdf.text_box label,
                     at: [x + 2, y - 2],
                     width: label_width,
                     height: label_height,
                     size: 6,
                     overflow: :shrink_to_fit
      end
    end

    # Reset colors to defaults
    pdf.fill_color Styling::Colors.TEXT_BLACK
    pdf.stroke_color Styling::Colors.TEXT_BLACK
  end
end
