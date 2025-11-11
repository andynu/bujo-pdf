# Grid-Based Layout System Documentation

## Overview

This planner uses a grid-based layout system where all positioning is based on a dot grid. Each "box" in the grid corresponds to the spacing between dots (14.17pt ≈ 5mm).

## Grid Dimensions

- **Total Grid Size**: 43 columns × 55 rows
- **Box Size**: 14.17pt (5mm) - matches `DOT_SPACING`
- **Page Size**: 612pt × 792pt (8.5" × 11" letter)

## Debug Mode

The system includes a diagnostic grid overlay for layout debugging:

- **DEBUG_GRID constant**: Set to `true` to enable, `false` to disable
- When enabled, `draw_diagnostic_grid()` overlays red dots and grid lines with coordinate labels
- Labels show `(col, row)` at every Nth grid intersection (default: every 5 boxes)

**Usage:**
```ruby
# At top of file
DEBUG_GRID = true  # Enable for development, false for production

# In any page generation method
draw_diagnostic_grid(label_every: 5)  # Add after page content
```

**What it shows:**
- Red dots at every grid intersection (brighter than gray dots)
- Red dashed lines every N boxes (default 5)
- Coordinate labels `(col, row)` at line intersections
- White background behind labels for readability

## Coordinate System

### Prawn's Native Coordinate System
- **Origin**: Bottom-left corner at (0, 0)
- **X-axis**: Increases to the right
- **Y-axis**: Increases upward
- **Y coordinates**: Measured from bottom of page

### Grid Coordinate System
- **Column 0**: Left edge of page
- **Row 0**: Top edge of page (inverted from Prawn's Y-axis)
- **Columns**: Increase left to right (0-42)
- **Rows**: Increase top to bottom (0-54)

## Helper Methods

### `grid_x(col)`
Convert a grid column to an x-coordinate in points.

```ruby
grid_x(0)   # => 0 (left edge)
grid_x(21)  # => 297.57 (center column)
grid_x(42)  # => 595.14 (rightmost column)
```

### `grid_y(row)`
Convert a grid row to a y-coordinate in points (measured from bottom).

```ruby
grid_y(0)   # => 792 (top of page)
grid_y(27)  # => 409.41 (center row)
grid_y(54)  # => 27.18 (bottom row)
```

**Note**: Row 0 is at the top, but the returned y-coordinate is high (near page height) because Prawn measures from the bottom.

### `grid_width(boxes)`
Convert a number of grid boxes to width in points.

```ruby
grid_width(1)   # => 14.17pt (one box)
grid_width(10)  # => 141.7pt (ten boxes)
grid_width(43)  # => 609.31pt (full width)
```

### `grid_height(boxes)`
Convert a number of grid boxes to height in points.

```ruby
grid_height(1)   # => 14.17pt (one box)
grid_height(10)  # => 141.7pt (ten boxes)
grid_height(55)  # => 779.35pt (full height)
```

### `grid_rect(col, row, width_boxes, height_boxes)`
Returns a hash with bounding box coordinates for a grid region.

```ruby
# Header spanning full width, 2 boxes tall at top
grid_rect(0, 0, 43, 2)
# => { x: 0, y: 792, width: 609.31, height: 28.34 }

# Box in middle: col 10, row 20, 5 boxes wide, 3 boxes tall
grid_rect(10, 20, 5, 3)
# => { x: 141.7, y: 508.6, width: 70.85, height: 42.51 }
```

**Usage with Prawn:**
```ruby
box = grid_rect(10, 20, 5, 3)
@pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
  # Draw content here
end
```

## Common Layout Patterns

### Full-Width Header (2 boxes tall)
```ruby
header = grid_rect(0, 0, GRID_COLS, 2)
@pdf.bounding_box([header[:x], header[:y]],
                  width: header[:width],
                  height: header[:height]) do
  @pdf.text "Header Text", align: :center, valign: :center
end
```

### Sidebar (Left, 3 boxes wide, full height)
```ruby
sidebar = grid_rect(0, 0, 3, GRID_ROWS)
@pdf.bounding_box([sidebar[:x], sidebar[:y]],
                  width: sidebar[:width],
                  height: sidebar[:height]) do
  # Sidebar content
end
```

### Main Content (Excluding 3-box sidebar)
```ruby
content = grid_rect(3, 2, GRID_COLS - 3, GRID_ROWS - 2)
@pdf.bounding_box([content[:x], content[:y]],
                  width: content[:width],
                  height: content[:height]) do
  # Main content
end
```

### Grid of Equal Boxes (e.g., 7 columns for days)
```ruby
cols = 7
box_width = GRID_COLS / cols  # boxes per column
(0...cols).each do |i|
  box = grid_rect(i * box_width, 5, box_width, 10)
  @pdf.bounding_box([box[:x], box[:y]],
                    width: box[:width],
                    height: box[:height]) do
    @pdf.stroke_bounds
    # Column content
  end
end
```

## Text Positioning with Grid

### text_box with Grid Coordinates
```ruby
# Place text at grid position (col 5, row 10)
@pdf.text_box "Hello",
              at: [grid_x(5), grid_y(10)],
              width: grid_width(10),
              height: grid_height(2)
```

**Important**: For `text_box`, the `at` parameter is the **top-left** corner of the text box, but `y` is still measured from the **bottom** of the page.

## Link Annotations with Grid

Links use `[left, bottom, right, top]` format, all measured from page bottom:

```ruby
# Clickable area at grid position (col 5, row 10), 10 boxes wide, 2 tall
col, row, w_boxes, h_boxes = 5, 10, 10, 2

left = grid_x(col)
right = grid_x(col + w_boxes)
top = grid_y(row)
bottom = grid_y(row + h_boxes)

@pdf.link_annotation([left, bottom, right, top],
                    Dest: "target_page",
                    Border: [0, 0, 0])
```

## Bounding Boxes with Grid

When using `bounding_box`, it creates a **local coordinate system**:

```ruby
box = grid_rect(5, 10, 20, 15)
@pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
  # Inside here, (0, 0) is the bottom-left of this box
  # And the top of the box is at y = box[:height]

  @pdf.text_box "Text at top",
                at: [0, box[:height]],
                width: box[:width],
                height: 20

  # Links inside bounding boxes use local coordinates
  @pdf.link_annotation([0, 0, box[:width], box[:height]],
                      Dest: "somewhere",
                      Border: [0, 0, 0])
end
```

## Dot Grid Drawing

The `draw_dot_grid(width, height)` method draws dots at every grid intersection:

```ruby
# Draw dots across the entire page
draw_dot_grid(PAGE_WIDTH, PAGE_HEIGHT)

# Draw dots in a specific region
box = grid_rect(10, 10, 20, 30)
@pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
  draw_dot_grid(box[:width], box[:height])
end
```

## Examples from the Codebase

### Calibration Page Demo Box
Located at `gen.rb:979-993`:
```ruby
# Full-width header, 2 boxes tall
header_box = grid_rect(0, 0, GRID_COLS, 2)
@pdf.stroke_color 'FF0000'
@pdf.stroke_rectangle [header_box[:x], header_box[:y]],
                      header_box[:width],
                      header_box[:height]

@pdf.text_box "GRID DEMO: Row 0-1 (2 boxes tall), Cols 0-#{GRID_COLS-1} (full width)",
              at: [header_box[:x] + 5, header_box[:y] - 5],
              width: header_box[:width] - 10,
              height: header_box[:height] - 10,
              align: :center,
              valign: :center
```

## Tips and Best Practices

1. **Always use grid methods** instead of hardcoded point values
2. **Think in grid boxes** when designing layouts (e.g., "3 boxes for sidebar, 40 for content")
3. **Align to grid** - if something doesn't align with dots, use grid coordinates
4. **Document your grid layout** - comment which grid boxes each section uses
5. **Test with calibration page** - use the red demo box to verify positioning

## Converting Existing Layouts

To convert pixel/point-based layouts to grid:

1. Measure the element in points
2. Divide by `DOT_SPACING` (14.17) to get approximate box count
3. Round to nearest integer for grid boxes
4. Use `grid_rect()` to position the element

Example:
```ruby
# Old: 200pt wide box at x=50, y=600
width_pt = 200
boxes = (width_pt / DOT_SPACING).round  # => 14 boxes

# New: use grid coordinates
box = grid_rect(3, 14, 14, 5)  # col 3, row 14, 14 boxes wide, 5 tall
```

## Visual Reference

The calibration page (`generate_reference_page`) shows:
- The dot grid as background
- A red demo box (rows 0-1, full width) showing grid positioning
- Grid dimensions and helper methods in the reference section
- Centimeter markings along edges
- Division lines for halves and thirds

## Future Enhancements

Potential additions to the grid system:
- `grid_span(start_col, end_col)` - width from column range
- `grid_margin(boxes)` - standard margins in grid boxes
- Grid-aware layout templates for common page structures
- Visual grid overlay helper for debugging
