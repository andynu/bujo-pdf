# frozen_string_literal: true

module BujoPdf
  module Themes
    # Dark theme - Modern dark mode with good contrast for digital note-taking
    DARK = {
      name: 'Dark',
      colors: {
        background: '1E1E1E',       # Dark charcoal background
        dot_grid: '505050',         # Medium gray dots (visible but not overwhelming)
        borders: '555555',          # Medium gray borders (lighter than before)
        section_headers: '888888',  # Light gray headers
        weekend_bg: '505050',       # Medium gray for weekend backgrounds (10% opacity)
        text_black: 'B0B0B0',       # Medium-light gray text (darker than before)
        text_gray: 'A0A0A0',        # Medium-light gray for secondary content
        empty_cell_overlay: '000000', # Black overlay for empty cells (20% opacity)
        diagnostic_red: 'FF6B6B',   # Brighter red for visibility on dark
        diagnostic_label_bg: '2A2A2A' # Slightly lighter than background
      }
    }.freeze
  end
end
