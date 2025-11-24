# frozen_string_literal: true

module BujoPdf
  module Themes
    # Earth theme - Warm, natural tones with pale tan background and muted green dots
    EARTH = {
      name: 'Earth',
      colors: {
        background: 'F5F1E8',       # Very pale tan/cream background
        dot_grid: '758C74',         # Desaturated medium-dark green dots
        borders: 'D4CDB8',          # Muted tan borders
        section_headers: '8B9A8B',  # Muted olive-green headers
        weekend_bg: '758C74',       # Green for weekend backgrounds (10% opacity)
        text_black: '696953',       # Warm olive-green for calendar text
        text_gray: '6B7565',        # Olive-gray for secondary content
        empty_cell_overlay: '758C74', # Green overlay for empty cells (20% opacity)
        diagnostic_red: 'D97757',   # Muted terracotta instead of bright red
        diagnostic_label_bg: 'F5F1E8' # Matches background
      }
    }.freeze
  end
end
