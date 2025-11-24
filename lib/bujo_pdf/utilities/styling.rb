# frozen_string_literal: true

# Styling module provides centralized styling constants for the planner generator
# Organizes colors, grid dimensions, and other styling attributes
module Styling
  # Color palette for the planner
  # All colors are 6-digit hex strings (e.g., 'CCCCCC')
  # Colors are now theme-aware and dynamically loaded from the active theme
  module Colors
    class << self
      # Get current theme colors
      # @return [Hash] The active theme's color hash
      def theme_colors
        BujoPdf::Themes.current[:colors]
      end

      # Dot grid and borders
      def DOT_GRID
        theme_colors[:dot_grid]
      end

      def BORDERS
        theme_colors[:borders]
      end

      def SECTION_HEADERS
        theme_colors[:section_headers]
      end

      def WEEKEND_BG
        theme_colors[:weekend_bg]
      end

      def EMPTY_CELL_OVERLAY
        theme_colors[:empty_cell_overlay]
      end

      # Diagnostic/debug colors
      def DIAGNOSTIC_RED
        theme_colors[:diagnostic_red]
      end

      def DIAGNOSTIC_LABEL_BG
        theme_colors[:diagnostic_label_bg]
      end

      # Text colors
      def TEXT_BLACK
        theme_colors[:text_black]
      end

      def TEXT_GRAY
        theme_colors[:text_gray]
      end

      # Background color (used for page background)
      def BACKGROUND
        theme_colors[:background]
      end
    end
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
