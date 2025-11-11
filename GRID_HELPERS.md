# Grid Helper Functions - Usage Guide

This document demonstrates the new grid-based helper functions that simplify common layout patterns.

## Available Helpers

### Core Grid Functions (Original)

```ruby
grid_x(col)                              # Column to x-coordinate
grid_y(row)                              # Row to y-coordinate (row 0 = top)
grid_width(boxes)                        # Convert boxes to width in points
grid_height(boxes)                       # Convert boxes to height in points
grid_rect(col, row, width, height)       # Get bounding box hash
```

### New Helper Functions

```ruby
grid_text_box(text, col, row, w, h, **opts)  # Text positioned by grid
grid_link(col, row, w, h, dest, **opts)      # Link annotation by grid
grid_inset(rect, padding_boxes)              # Apply padding to rect
grid_bottom(row, height_boxes)               # Calculate bottom coordinate
```

## Before & After Examples

### Example 1: Simple Text Box

**Before:**
```ruby
@pdf.text_box "Hello World",
              at: [grid_x(5), grid_y(10)],
              width: grid_width(10),
              height: grid_height(2),
              align: :center,
              valign: :center
```

**After:**
```ruby
grid_text_box("Hello World", 5, 10, 10, 2,
              align: :center,
              valign: :center)
```

### Example 2: Link Annotation

**Before:**
```ruby
cell_x = grid_x(start_col) + (col * grid_width(col_width_boxes))
cell_y = grid_y(cal_row)

# Add clickable link
link_bottom = cell_y - grid_height(1)
@pdf.link_annotation([cell_x, link_bottom,
                      cell_x + grid_width(col_width_boxes), cell_y],
                    Dest: "week_#{week_num}",
                    Border: [0, 0, 0])
```

**After:**
```ruby
# Using grid_link - much cleaner!
grid_link(start_col + col, cal_row, col_width_boxes, 1, "week_#{week_num}")
```

### Example 3: Link for a Grid Rectangle

**Before:**
```ruby
week_box = grid_rect(0, row, 2, 1)

link_left = week_box[:x]
link_bottom = week_box[:y] - week_box[:height]
link_right = week_box[:x] + week_box[:width]
link_top = week_box[:y]

@pdf.link_annotation([link_left, link_bottom, link_right, link_top],
                    Dest: "week_#{week}",
                    Border: [0, 0, 0])
```

**After:**
```ruby
grid_link(0, row, 2, 1, "week_#{week}")
```

### Example 4: Padded/Inset Content

**Before:**
```ruby
box = grid_rect(5, 10, 20, 15)
padding = grid_width(0.5)

@pdf.bounding_box([box[:x] + padding, box[:y] - padding],
                  width: box[:width] - (padding * 2),
                  height: box[:height] - (padding * 2)) do
  # Draw content
end
```

**After:**
```ruby
box = grid_rect(5, 10, 20, 15)
padded = grid_inset(box, 0.5)

@pdf.bounding_box([padded[:x], padded[:y]],
                  width: padded[:width],
                  height: padded[:height]) do
  # Draw content
end
```

### Example 5: Centered Text in Grid Cell

**Before:**
```ruby
@pdf.text_box @month_names[month - 1],
              at: [title_box[:x], title_box[:y]],
              width: title_box[:width],
              height: title_box[:height],
              align: :center,
              valign: :center
```

**After:**
```ruby
grid_text_box(@month_names[month - 1],
              start_col, start_row, width_boxes, 1,
              align: :center,
              valign: :center)
```

## Real-World Refactoring Example

Here's a real example from the codebase showing the transformation:

### Original Code (gen.rb:593-604)
```ruby
cell_x = grid_x(start_col) + (col * grid_width(col_width_boxes))
cell_y = grid_y(cal_row)

@pdf.text_box day.to_s,
              at: [cell_x, cell_y],
              width: grid_width(col_width_boxes),
              height: grid_height(1),
              align: :center,
              valign: :center

# Add clickable link
link_bottom = cell_y - grid_height(1)
@pdf.link_annotation([cell_x, link_bottom, cell_x + grid_width(col_width_boxes), cell_y],
                    Dest: "week_#{week_num}",
                    Border: [0, 0, 0])
```

### Refactored with Grid Helpers
```ruby
cell_col = start_col + (col * col_width_boxes)

grid_text_box(day.to_s, cell_col, cal_row, col_width_boxes, 1,
              align: :center,
              valign: :center)

grid_link(cell_col, cal_row, col_width_boxes, 1, "week_#{week_num}")
```

**Benefits:**
- 12 lines → 6 lines (50% reduction)
- No manual coordinate calculations
- No temporary variables for link coordinates
- Grid-centric thinking throughout
- Easier to understand the layout structure

## Usage Patterns

### Pattern 1: Text + Link in Same Cell
```ruby
# Common pattern: clickable text
col, row, w, h = 10, 5, 8, 2

grid_text_box("Click me", col, row, w, h,
              align: :center, valign: :center)
grid_link(col, row, w, h, "destination")
```

### Pattern 2: Grid Layout with Uniform Cells
```ruby
# Draw a 7-column grid (like days of week)
cols = 7
box_width = GRID_COLS / cols

(0...cols).each do |i|
  grid_text_box(headers[i], i * box_width, 5, box_width, 1,
                align: :center)
end
```

### Pattern 3: Inset Content with Border
```ruby
# Draw border at exact grid edges, content inset
outer = grid_rect(5, 10, 20, 15)
inner = grid_inset(outer, 0.5)

@pdf.stroke_rectangle [outer[:x], outer[:y]], outer[:width], outer[:height]

@pdf.bounding_box([inner[:x], inner[:y]],
                  width: inner[:width],
                  height: inner[:height]) do
  draw_dot_grid(inner[:width], inner[:height])
end
```

## Design Philosophy

These helpers follow key principles:

1. **Grid-centric API**: All positioning in grid boxes, not points
2. **Consistent parameter order**: `col, row, width_boxes, height_boxes`
3. **Keyword arguments**: Optional styling via `**options`
4. **Composability**: Functions work together naturally
5. **Minimal abstraction**: Thin wrappers over Prawn primitives

## When to Use What

- **grid_x/grid_y**: When you need a single coordinate for custom drawing
- **grid_rect**: When you need a bounding box for complex layouts
- **grid_text_box**: Any time you're drawing text aligned to the grid
- **grid_link**: Any time you're creating a clickable region on the grid
- **grid_inset**: When you need padding/margins within a grid area
- **grid_bottom**: When manually constructing link rectangles (rare now)

## Migration Strategy

When refactoring existing code:

1. Look for `text_box` with `at: [grid_x(...), grid_y(...)]` → use `grid_text_box`
2. Look for `link_annotation` with grid calculations → use `grid_link`
3. Look for manual padding calculations → use `grid_inset`
4. Test after each change to ensure behavior is preserved

## Notes

- All helpers work in **grid coordinates** (col, row in boxes)
- Row 0 is always the **top** of the page
- Width and height are always in **grid boxes** (not points)
- The helpers handle the Prawn coordinate system conversion internally
- Link borders default to invisible `[0, 0, 0]` - override if needed
