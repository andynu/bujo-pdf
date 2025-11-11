# Component Documentation

This document describes the reusable layout components in the planner generator.

## Right Sidebar Component

**Location**: `draw_right_sidebar` and `draw_right_sidebar_tabs` (gen.rb:1276-1339)

### Overview

The right sidebar displays rotated navigation tabs along the right edge of the page. It consists of:
- **Top tabs**: Left-aligned (Year, Events, Highlights) linking to overview pages
- **Bottom tab**: Right-aligned (Dots) linking to the blank dot grid template

### Grid-Based Layout

- **Position**: Column 43 (at right edge, beyond last grid column), 1 box wide
- **Tab height**: 3 boxes per tab (quantized/uniform)
- **Top tabs**: Start at row 3 (provides clearance from top edge)
- **Bottom tab**: Positioned 4 boxes from bottom (reserves space for footer + margin)

### API

#### `draw_right_sidebar()`

Main method that draws the complete right sidebar with default tabs.

**Default tabs:**
```ruby
Top (left-aligned):
  - "Year" → seasonal calendar page
  - "Events" → year at a glance events page
  - "Highlights" → year at a glance highlights page

Bottom (right-aligned):
  - "Dots" → blank dot grid template page
```

**Usage:**
```ruby
draw_right_sidebar()  # Call on any page to add right sidebar
```

#### `draw_right_sidebar_tabs(tabs, start_row:, align:)`

Helper method to draw a list of tabs at a specific grid position.

**Parameters:**
- `tabs`: Array of `{label:, dest:}` hashes
  - `label`: String to display (rotated -90°)
  - `dest`: Named destination to link to
- `start_row`: Grid row to start from (integer)
- `align`: Text alignment (`:left` or `:right`)

**Example:**
```ruby
# Draw custom tabs starting at row 10, left-aligned
custom_tabs = [
  { label: "Custom", dest: "custom_page" },
  { label: "Extra", dest: "extra_page" }
]
draw_right_sidebar_tabs(custom_tabs, start_row: 10, align: :left)
```

### Visual Design

- **Text rotation**: -90° (clockwise) - text reads top-to-bottom when page is upright
- **Font**: Helvetica, 8pt, gray (#888888)
- **Clickable area**: Entire 3-box region per tab (not just text)
- **Text alignment**:
  - Top tabs: `:left` (text starts at top when rotated)
  - Bottom tabs: `:right` (text ends at bottom when rotated)

### Layout Calculations

```ruby
# Each tab occupies exactly 3 boxes vertically
tab_height_boxes = 3

# Position at right edge (beyond last grid column)
sidebar_col = GRID_COLS  # 43

# Top tabs start at row 3 (gives clearance from top)
top_start_row = 3

# Bottom tab positioned from bottom
# GRID_ROWS (55) - footer (3 boxes) - margin (1 box) - tab height (3 boxes) = 48
bottom_start_row = GRID_ROWS - 4 - 3
```

### Link Behavior

Each tab is fully clickable across its entire 3-box region:
```ruby
grid_link(sidebar_col, row, 1, tab_height_boxes, tab[:dest])
```

Users can click anywhere in the tab's vertical space, not just on the text.

### Customization

To add more tabs:

```ruby
def draw_right_sidebar
  # Top section
  top_tabs = [
    { label: "Year", dest: "seasonal" },
    { label: "Events", dest: "year_events" },
    { label: "Highlights", dest: "year_highlights" },
    { label: "Custom", dest: "custom_page" }  # New tab!
  ]

  draw_right_sidebar_tabs(top_tabs, start_row: 2, align: :left)

  # Bottom section (unchanged)
  # ...
end
```

Each additional tab will automatically stack 3 boxes below the previous one.

### Coordinate System Notes

**Text positioning with rotation:**
- Text is rotated -90° around the top-left corner of the tab region
- After rotation, the text box extends downward (in page coordinates)
- The `at:` parameter is adjusted to `[tab_x - tab_width_pt, tab_y]` to position text correctly within rotated space

**Why height becomes width:**
```ruby
tab_width_pt = grid_height(tab_height_boxes)  # Rotated: 3 boxes tall → horizontal width
```

After -90° rotation, vertical height becomes horizontal width in the rotated coordinate space.

## Future Components

Additional components to be documented:
- Left week sidebar
- Fieldset with legend
- Cornell notes layout
- Seasonal calendar grid
- Year-at-a-glance grid

---

## Component Design Principles

1. **Grid-based positioning**: All components use grid coordinates (col, row, boxes)
2. **Quantized dimensions**: Heights/widths in whole or fractional boxes (e.g., 3 boxes per tab)
3. **Composable**: Components can be mixed and matched on any page
4. **Configurable**: Accept parameters for customization while maintaining defaults
5. **Self-contained**: Each component manages its own styling (colors, fonts, etc.)
6. **Named destinations**: All navigation uses semantic destination names, not page numbers
