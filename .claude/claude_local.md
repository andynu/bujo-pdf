# PDF Coordinate System Documentation

## Page Dimensions
- **Page Size**: LETTER (8.5" × 11")
- **Width**: 612 points (8.5 inches × 72 points/inch)
- **Height**: 792 points (11 inches × 72 points/inch)
- **Orientation**: Portrait (taller than wide)

## Coordinate System Fundamentals

### Origin and Axes
- **Origin (0,0)**: Bottom-left corner of the page
- **X-axis**: Runs horizontally, left to right
  - X = 0 at left edge
  - X = 612 at right edge
- **Y-axis**: Runs vertically, bottom to top
  - Y = 0 at bottom edge
  - Y = 792 at top edge

### Important Y-Coordinate Reference Points
```
Y = 792  ← Top of page
Y = 787  ← 5pt from top (WEEKLY_TOP_MARGIN)
Y = 752  ← 40pt from top (PAGE_MARGIN_TOP)
...
Y = 100  ← 100pt from bottom
Y = 75   ← Bottom tab area starts (FOOTER_HEIGHT + 50)
Y = 25   ← Footer line (FOOTER_HEIGHT)
Y = 0    ← Bottom of page
```

## Rotation and Text Orientation

### Right Sidebar Text (Rotated -90 degrees)
The right sidebar uses `-90` degree rotation to make text read when tilting your head right:

#### Top Tabs (Year, Events, Highlights)
- **Text alignment**: LEFT within rotated box
- **Starting Y**: ~742 (near top)
- **Effect**: Text starts at top and flows downward
- **Coordinate behavior**:
  - Text box "width" (50pt) becomes vertical extent after rotation
  - Text box "height" (20pt) becomes horizontal extent after rotation
  - Left-aligned text starts at beginning of box (lower Y values)

#### Bottom Tab (Dots)
- **Text alignment**: RIGHT within rotated box
- **Starting Y**: 75 (FOOTER_HEIGHT + 50)
- **Effect**: Text appears at END of rotated box (higher Y values)
- **Coordinate behavior**:
  - Right-aligned text appears at far end of 50pt width
  - Must SUBTRACT from Y to move DOWN the page in rotated space
  - Link box must be portrait-oriented: ~20pt wide (X) × ~25pt tall (Y)

### Critical Rotation Insights

1. **Inside `@pdf.rotate()` block**: Coordinates are in rotated space
   - Adding to Y moves UP the page (counter-intuitive!)
   - Subtracting from Y moves DOWN the page
   - Width/height dimensions are relative to rotated orientation

2. **Outside `@pdf.rotate()` block**: Coordinates are in page space
   - Standard coordinate system applies
   - Y increases = moving up the page

3. **Link annotations**: Must be placed in the SAME space as the text
   - If text is in rotation block, link should be too
   - Use same coordinate system as the text

4. **Text alignment in rotated space**:
   - LEFT-aligned: Text starts at beginning (lower Y in rotated coords)
   - RIGHT-aligned: Text ends at end (higher Y in rotated coords)
   - Must adjust link box position to match where text actually appears

## Sidebar Layout Offsets

### Left Sidebar (Week Navigation)
- **X position**: 5pt from left edge (WEEKLY_SIDEBAR_X)
- **Width**: 25pt (WEEKLY_SIDEBAR_WIDTH)
- **Gap to content**: 5pt (WEEKLY_SIDEBAR_GAP)
- **Content starts at**: 35pt from left (5 + 25 + 5)

### Right Sidebar (Tab Navigation)
- **Text X position**: 607pt from left (WEEKLY_RIGHT_SIDEBAR_TEXT_X)
- **Link X position**: 597pt from left (WEEKLY_RIGHT_SIDEBAR_LINK_X)
- **Offset**: 10pt (text is 10pt right of link box)
- **Why offset?**: Visual alignment - text appears slightly inset from link area

## Common Pitfalls

1. **"Moving down" in rotated space**: Use NEGATIVE offsets, not positive
2. **Link box orientation**: Must match rotated text (portrait for vertical text)
3. **Right-aligned text position**: Appears at END of box, need offset adjustment
4. **Y-coordinate confusion**: Remember Y=0 is at BOTTOM, Y=792 is at TOP
5. **Rotation origin**: The point around which rotation happens - affects positioning

## Example: Bottom "Dots" Tab

```ruby
bottom_y = 75  # FOOTER_HEIGHT (25) + 50

# Text box spans from Y=75 to Y=125 (50pt width becomes height when rotated)
# RIGHT-aligned text appears near Y=100-125 (at the END of the 50pt span)

# To cover text with link:
link_offset = -30  # Negative to move DOWN
text_width = 25
link_box = [
  597,                           # X start (WEEKLY_RIGHT_SIDEBAR_LINK_X)
  75 + (-30) - 25,              # Y start (bottom_y + offset - text_width) = 20
  597 + 20,                      # X end (20pt wide)
  75 + (-30)                     # Y end = 45
]
# Link covers Y=20 to Y=45, X=597 to X=617
```

## Testing Link Positions

To verify link placement:
1. Look at where text visually appears on the page
2. Note approximate Y position from bottom edge
3. Link box should cover that Y range
4. For rotated text, remember portrait orientation (tall, not wide)
