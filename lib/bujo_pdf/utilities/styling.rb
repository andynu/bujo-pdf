# frozen_string_literal: true

# Styling module provides centralized styling constants for the planner generator
# Organizes colors, grid dimensions, and other styling attributes
module Styling
  # Color palette for the planner
  # All colors are 6-digit hex strings (e.g., 'CCCCCC')
  module Colors
    # Dot grid and borders
    DOT_GRID = 'CCCCCC'           # Light gray for background dots
    BORDERS = 'E5E5E5'            # Very light gray for borders
    SECTION_HEADERS = 'AAAAAA'    # Muted gray for section headers
    WEEKEND_BG = 'CCCCCC'         # Darker gray for weekend backgrounds (used at 10% opacity)

    # Diagnostic/debug colors
    DIAGNOSTIC_RED = 'FF0000'     # Red for diagnostic grid overlay
    DIAGNOSTIC_LABEL_BG = 'FFFFFF' # White background for diagnostic labels

    # Text colors
    TEXT_BLACK = '000000'         # Standard black text
    TEXT_GRAY = '888888'          # Gray text for secondary content
  end

  # Grid-based layout system constants
  # The planner uses a grid where each box corresponds to dot spacing
  module Grid
    # Dot grid dimensions
    DOT_SPACING = 14.17  # 5mm in points (1mm ≈ 2.834pt)
    DOT_RADIUS = 0.5     # Radius of each dot in points
    DOT_GRID_PADDING = 5 # Padding around dot grid in points

    # Page dimensions (US Letter)
    PAGE_WIDTH = 612     # 8.5 inches × 72pt/inch
    PAGE_HEIGHT = 792    # 11 inches × 72pt/inch

    # Calculated grid dimensions
    # These define how many grid boxes fit on the page
    COLS = (PAGE_WIDTH / DOT_SPACING).floor   # 43 columns
    ROWS = (PAGE_HEIGHT / DOT_SPACING).floor  # 55 rows
  end
end
