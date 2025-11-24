# frozen_string_literal: true

module BujoPdf
  module Themes
    # Light theme - Classic planner with white background
    LIGHT = {
      name: 'Light',
      colors: {
        background: 'FFFFFF',       # White background
        dot_grid: 'CCCCCC',         # Light gray dots
        borders: 'E5E5E5',          # Very light gray borders
        section_headers: 'AAAAAA',  # Muted gray headers
        weekend_bg: 'CCCCCC',       # Darker gray for weekend backgrounds (10% opacity)
        text_black: '000000',       # Standard black text
        text_gray: '888888',        # Gray text for secondary content
        empty_cell_overlay: '000000', # Black overlay for empty cells (20% opacity)
        diagnostic_red: 'FF0000',   # Red for diagnostic grid overlay
        diagnostic_label_bg: 'FFFFFF' # White background for diagnostic labels
      }
    }.freeze
  end
end
