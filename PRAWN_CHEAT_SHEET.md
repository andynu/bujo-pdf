# Prawn Graphics Cheat Sheet

## Drawing Shapes

### Rectangles

```ruby
# Basic rectangle (define path only)
pdf.rectangle [x, y], width, height

# Stroke rectangle
pdf.stroke_rectangle [x, y], width, height

# Fill rectangle
pdf.fill_rectangle [x, y], width, height

# Fill and stroke
pdf.fill_and_stroke_rectangle [x, y], width, height

# Rounded corners
pdf.rounded_rectangle [x, y], width, height, radius
pdf.stroke_rounded_rectangle [x, y], width, height, 10
pdf.fill_rounded_rectangle [x, y], width, height, 10
pdf.fill_and_stroke_rounded_rectangle [x, y], width, height, 10
```

**Note**: `[x, y]` is the **top-left** corner, but `y` is measured from **page bottom**.

### Circles and Ellipses

```ruby
# Circle (center point, radius)
pdf.circle [100, 100], 25
pdf.stroke_circle [100, 100], 25
pdf.fill_circle [100, 100], 25
pdf.fill_and_stroke_circle [100, 100], 25

# Ellipse (center point, x-radius, y-radius)
pdf.ellipse [100, 100], 50, 25  # Wider than tall
pdf.stroke_ellipse [100, 100], 50, 25
pdf.fill_ellipse [100, 100], 50, 25
pdf.fill_and_stroke_ellipse [100, 100], 50, 25
```

**Note**: Drawing point moves to center after completing circle/ellipse.

### Lines

```ruby
# Simple line between two points
pdf.line [x1, y1], [x2, y2]
pdf.line(x1, y1, x2, y2)  # Alternative syntax

# Horizontal line
pdf.horizontal_line x1, x2, at: y_position
pdf.horizontal_rule  # Full width of current bounding box

# Vertical line
pdf.vertical_line y1, y2, at: x_position

# Path-based lines (for complex shapes)
pdf.move_to [x, y]  # Move without drawing
pdf.line_to [x, y]  # Draw from current position
pdf.stroke  # Actually render the line
```

### Polygons

```ruby
# Basic polygon (list of points)
pdf.polygon [x1, y1], [x2, y2], [x3, y3], [x4, y4]
pdf.stroke_polygon [100, 100], [200, 100], [150, 200]
pdf.fill_polygon [100, 100], [200, 100], [150, 200]
pdf.fill_and_stroke_polygon [100, 100], [200, 100], [150, 200]

# Rounded polygon (radius first, then points)
pdf.rounded_polygon 10, [100, 100], [200, 100], [150, 200]
pdf.stroke_rounded_polygon 10, [100, 100], [200, 100], [150, 200]
pdf.fill_rounded_polygon 10, [100, 100], [200, 100], [150, 200]
pdf.fill_and_stroke_rounded_polygon 10, [100, 100], [200, 100], [150, 200]
```

### Curves (Bezier)

```ruby
# Curve from current position to destination
pdf.curve_to [100, 100], bounds: [[90, 90], [75, 75]]

# Curve with explicit start and end points
pdf.curve [50, 100], [100, 100], bounds: [[90, 90], [75, 75]]
```

**Note**: `:bounds` contains two control points for the Bezier curve.

## Path Operations

When you need fine control over fill/stroke behavior:

```ruby
# Define shape, then stroke it
pdf.rectangle [100, 100], 50, 50
pdf.stroke

# Define shape, then fill it
pdf.circle [200, 200], 25
pdf.fill

# Define shape, fill and stroke
pdf.polygon [x1, y1], [x2, y2], [x3, y3]
pdf.fill_and_stroke

# Close path before stroking
pdf.move_to [x1, y1]
pdf.line_to [x2, y2]
pdf.line_to [x3, y3]
pdf.close_and_stroke

# Fill with specific rule
pdf.polygon [x1, y1], [x2, y2], [x3, y3]
pdf.fill(fill_rule: :even_odd)  # or default nonzero winding
```

## Color Management

### Setting Colors

```ruby
# Hex string (6 digits, no #)
pdf.fill_color "ff0000"      # Red fill
pdf.stroke_color "0000ff"    # Blue stroke

# CMYK (values 0-100)
pdf.fill_color 0, 99, 95, 0     # CMYK fill
pdf.stroke_color 100, 0, 50, 25 # CMYK stroke

# Get current color
current_fill = pdf.fill_color
current_stroke = pdf.stroke_color
```

### Color Format Conversions

```ruby
# RGB array to hex
hex = rgb2hex([255, 120, 8])  # => "ff7808"

# Hex to RGB array
rgb = hex2rgb("ff7808")  # => [255, 120, 8]
```

### Common Colors

```ruby
pdf.stroke_color "000000"  # Black
pdf.stroke_color "FFFFFF"  # White
pdf.stroke_color "FF0000"  # Red
pdf.stroke_color "00FF00"  # Green
pdf.stroke_color "0000FF"  # Blue
pdf.stroke_color "CCCCCC"  # Light gray
pdf.stroke_color "808080"  # Medium gray
```

**Note**: Prawn normalizes RGB (divides by 255) and CMYK (divides by 100) automatically for PDF representation.

## Transparency and Opacity

### Basic Transparency

```ruby
# Set transparency for block of content (0.0 = transparent, 1.0 = opaque)
pdf.transparent(0.5) do
  pdf.fill_rectangle [100, 100], 50, 50
  pdf.text "Semi-transparent"
end

# Different opacity for fill vs stroke
pdf.transparent(0.3, 0.8) do  # fill_opacity, stroke_opacity
  pdf.fill_and_stroke_circle [200, 200], 25
end
```

**Parameters**:
- First argument: **fill opacity** (0.0–1.0)
- Second argument: **stroke opacity** (0.0–1.0, defaults to fill opacity)

**Important**: Values automatically constrained to 0.0–1.0 range.

### Opacity Examples

```ruby
# Fully opaque (default)
pdf.transparent(1.0) do
  pdf.fill_rectangle [x, y], 100, 100
end

# 50% transparent
pdf.transparent(0.5) do
  pdf.fill_rectangle [x, y], 100, 100
end

# Fully transparent (invisible)
pdf.transparent(0.0) do
  pdf.fill_rectangle [x, y], 100, 100
end

# Different fill and stroke opacity
pdf.transparent(0.3, 0.9) do  # Faint fill, strong stroke
  pdf.fill_and_stroke_rectangle [x, y], 100, 100
end
```

## Stroke and Fill Options

### Line Width

```ruby
pdf.line_width = 2
pdf.stroke_rectangle [100, 100], 50, 50

pdf.line_width = 0.5
pdf.stroke_circle [200, 200], 25
```

### Line Cap and Join

```ruby
# Line cap: :butt (default), :round, :projecting_square
pdf.cap_style = :round

# Line join: :miter (default), :round, :bevel
pdf.join_style = :round
```

### Dash Patterns

```ruby
# Dashed line
pdf.dash(3)  # 3pt dash, 3pt gap
pdf.stroke_line [x1, y1], [x2, y2]

# Custom pattern
pdf.dash([5, 2, 1, 2])  # 5pt dash, 2pt gap, 1pt dash, 2pt gap

# Solid line (reset)
pdf.undash
```

## Complete Examples

### Semi-Transparent Colored Rectangle

```ruby
pdf.fill_color "ff0000"  # Red
pdf.transparent(0.5) do
  pdf.fill_rectangle [100, 100], 100, 100
end
```

### Stroked and Filled Circle with Different Colors

```ruby
pdf.fill_color "ffcc00"    # Yellow
pdf.stroke_color "ff0000"  # Red
pdf.line_width = 3
pdf.fill_and_stroke_circle [200, 200], 50
```

### Layered Transparent Shapes

```ruby
# Draw overlapping transparent rectangles
pdf.fill_color "ff0000"  # Red
pdf.transparent(0.3) do
  pdf.fill_rectangle [100, 100], 100, 100
end

pdf.fill_color "0000ff"  # Blue
pdf.transparent(0.3) do
  pdf.fill_rectangle [150, 150], 100, 100
end
# Where they overlap, colors blend
```

### Rounded Rectangle with Transparency and CMYK

```ruby
pdf.fill_color 0, 100, 100, 0  # CMYK red
pdf.stroke_color 0, 0, 0, 100  # CMYK black
pdf.line_width = 2

pdf.transparent(0.7, 1.0) do  # 70% fill opacity, 100% stroke
  pdf.fill_and_stroke_rounded_rectangle [100, 100], 150, 100, 15
end
```

### Complex Path with Gradient-like Effect

```ruby
# Create multiple overlapping circles with varying opacity
5.times do |i|
  opacity = 1.0 - (i * 0.15)  # Decreasing opacity
  pdf.fill_color "0000ff"
  pdf.transparent(opacity) do
    pdf.fill_circle [200 + (i * 10), 200], 50 - (i * 5)
  end
end
```

## Tips and Gotchas

1. **Coordinate system**: Y-axis measured from **bottom** of page, increases upward
2. **Rectangle position**: `[x, y]` is the **top-left** corner
3. **Stroke vs fill**: `stroke_*` methods draw outlines, `fill_*` methods draw solid shapes
4. **Transparency performance**: Prawn caches opacity states, so repeated values are efficient
5. **Color formats**: Hex strings don't use `#` prefix (use `"ff0000"` not `"#ff0000"`)
6. **CMYK vs RGB**: CMYK uses 0–100 range, RGB uses 0–255 (or hex)
7. **Path operations**: Some methods only define paths; call `stroke`, `fill`, or `fill_and_stroke` to render
8. **Transparency scope**: `transparent()` only affects content within its block

## Quick Reference: Method Naming Pattern

```
<action>_<shape>

Actions:
- [none]         = Define path only
- stroke_        = Draw outline
- fill_          = Draw solid
- fill_and_stroke_ = Both

Shapes:
- rectangle, rounded_rectangle
- circle, ellipse
- polygon, rounded_polygon
- line, curve
```
