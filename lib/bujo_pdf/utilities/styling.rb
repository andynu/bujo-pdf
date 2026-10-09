# frozen_string_literal: true

# Styling module provides centralized styling constants for the planner generator
# Organizes colors, grid dimensions, and other styling attributes
module Styling
  # Color palette for the planner
  # All colors are 6-digit hex strings (e.g., 'CCCCCC')
  # Colors are now theme-aware and dynamically loaded from the active theme
  #
  # This module can be used in two ways:
  # 1. Class method access: Styling::Colors.TEXT_BLACK
  # 2. Include pattern (preferred): include Styling::Colors; then use TEXT_BLACK
  #
  # The include pattern is preferred as it provides cleaner syntax and
  # documents the styling dependency at the top of the class.
  module Colors
    # Get current theme colors hash
    # @return [Hash] The active theme's color hash
    def self.theme_colors
      BujoPdf::Themes.current[:colors]
    end

    # Class methods for backward compatibility
    class << self
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

    # Instance methods for include pattern (preferred)
    # These delegate to the class methods for theme-aware color access
    # Uses snake_case names for Ruby method compatibility
    #
    # Usage: include Styling::Colors; then call color_borders, color_text_black, etc.

    # @return [String] Dot grid color hex value
    def color_dot_grid
      Colors.DOT_GRID
    end

    # @return [String] Border color hex value
    def color_borders
      Colors.BORDERS
    end

    # @return [String] Section header color hex value
    def color_section_headers
      Colors.SECTION_HEADERS
    end

    # @return [String] Weekend background color hex value
    def color_weekend_bg
      Colors.WEEKEND_BG
    end

    # @return [String] Empty cell overlay color hex value
    def color_empty_cell_overlay
      Colors.EMPTY_CELL_OVERLAY
    end

    # @return [String] Diagnostic red color hex value
    def color_diagnostic_red
      Colors.DIAGNOSTIC_RED
    end

    # @return [String] Diagnostic label background color hex value
    def color_diagnostic_label_bg
      Colors.DIAGNOSTIC_LABEL_BG
    end

    # @return [String] Text black color hex value
    def color_text_black
      Colors.TEXT_BLACK
    end

    # @return [String] Text gray color hex value
    def color_text_gray
      Colors.TEXT_GRAY
    end

    # @return [String] Background color hex value
    def color_background
      Colors.BACKGROUND
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
