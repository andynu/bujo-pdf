# Plan #13: Ultra-Light Weekend Background Shading for Year-at-a-Glance Pages

## Overview
Add subtle weekend background shading (CCCCCC at 0.1 transparency) to weekend cells in the year-at-a-glance grid layouts (Events and Highlights pages), matching the treatment already applied to weekly pages.

## Files Requiring Modification

### Primary Target Files
1. **`lib/bujo_pdf/pages/year_events.rb`** - Year at a Glance - Events page
2. **`lib/bujo_pdf/pages/year_highlights.rb`** - Year at a Glance - Highlights page

### Potential Shared Logic Location
Consider extracting weekend cell identification to:
- **`lib/bujo_pdf/utilities/date_calculator.rb`** - Add weekend detection helper method

## Implementation Details

### 1. Weekend Cell Identification Logic

Add helper method to determine if a given day in a month is a weekend:

```ruby
# In lib/bujo_pdf/utilities/date_calculator.rb or in the page class itself
def weekend_day?(year, month, day)
  return false if day > Date.civil(year, month, -1).day # Invalid day for month
  date = Date.new(year, month, day)
  date.saturday? || date.sunday?
end
```

### 2. Drawing Approach

**Render order is critical:**
```
1. Weekend background rectangles (first layer)
2. Dot grid pattern (middle layer)
3. Text content (top layer)
4. Link annotations (invisible, on top)
```

**Implementation in `render` method:**

```ruby
def render
  # Step 1: Draw weekend backgrounds FIRST (before dot grid)
  draw_weekend_backgrounds

  # Step 2: Draw dot grid (existing code)
  draw_dot_grid(content_area[:width], content_area[:height])

  # Step 3: Draw month headers, day numbers, links (existing code)
  draw_month_headers
  draw_day_grid
end
```

### 3. Weekend Background Drawing Method

```ruby
def draw_weekend_backgrounds
  content_x = content_area[:x]
  content_y = content_area[:y]

  # Grid dimensions from year-at-a-glance layout
  # 12 months (columns) × 31 days (rows)
  month_width = content_area[:width] / 12.0
  day_height = (content_area[:height] - HEADER_HEIGHT) / 31.0

  (1..12).each do |month|
    (1..31).each do |day|
      # Skip if this day doesn't exist in this month
      next unless day <= Date.civil(@year, month, -1).day

      # Check if weekend
      if weekend_day?(@year, month, day)
        # Calculate cell boundaries
        cell_x = content_x + (month - 1) * month_width
        cell_y = content_y - HEADER_HEIGHT - (day * day_height)

        # Draw transparent background rectangle
        @pdf.fill_color COLOR_WEEKEND_BG
        @pdf.fill_rectangle(
          [cell_x, cell_y + day_height],
          month_width,
          day_height
        )
        @pdf.fill_color '000000' # Reset to black
      end
    end
  end
end
```

### 4. Ensuring No Interference

**Key considerations:**

1. **Drawing order**: Weekend backgrounds MUST be drawn before:
   - Dot grid (so dots appear on top)
   - Text content (day numbers, abbreviations)
   - Borders/grid lines

2. **Opacity**: `COLOR_WEEKEND_BG = 'FAFAFA'` is already extremely subtle:
   - RGB(250, 250, 250) vs white RGB(255, 255, 255)
   - Only ~2% gray, barely perceptible
   - Will not interfere with text legibility

3. **Fill vs Stroke**: Use `fill_rectangle` not `stroke_rectangle`:
   - No borders on weekend cells
   - Pure background fill
   - Reset fill color to black immediately after

4. **Link annotations**: Links are separate layer, unaffected:
   - Links use transparent borders `[0, 0, 0]`
   - Link rectangles are annotation objects, not drawn graphics
   - No visual or functional interference

5. **Dot grid compatibility**:
   - Dots are drawn with light gray `COLOR_DOT_GRID = 'CCCCCC'`
   - Weekend background is lighter than dots
   - Dots will remain visible over weekend background

## Implementation Steps

### Step 1: Add Weekend Detection Helper
```ruby
# In the page class or utilities
def weekend_day?(year, month, day)
  return false if day > Date.civil(year, month, -1).day
  date = Date.new(year, month, day)
  date.saturday? || date.sunday?
end
```

### Step 2: Create Background Drawing Method
```ruby
def draw_weekend_backgrounds
  # Implementation as shown above
  # Iterate through 12 months × 31 days
  # Fill weekend cells with COLOR_WEEKEND_BG
end
```

### Step 3: Modify Render Method
```ruby
def render
  draw_weekend_backgrounds  # FIRST - bottom layer
  draw_dot_grid(...)        # SECOND - middle layer
  draw_month_headers        # THIRD - top layer
  draw_day_grid             # FOURTH - top layer with links
end
```

### Step 4: Test Rendering
- Generate PDF for a year
- Verify weekends are subtly shaded
- Confirm dots, text, and links are unaffected
- Check that shading aligns with actual weekend dates

## Edge Cases to Handle

1. **Month length validation**: Don't shade Feb 30, Apr 31, etc.
   ```ruby
   next unless day <= Date.civil(@year, month, -1).day
   ```

2. **Leap years**: Date.civil handles this automatically
   - Feb 29 will be correctly identified as a weekend in leap years

3. **Coordinate precision**:
   - Use floating-point division for column/row widths
   - Avoid rounding errors in cell boundaries

4. **Bounding box context**:
   - If rendering inside a bounding_box, coordinates are local
   - Use `content_area[:x]` and `content_area[:y]` as offsets

## Visual Quality Assurance

**Before committing, verify:**
- [ ] Weekend shading is visible but extremely subtle
- [ ] Dots are clearly visible over weekend background
- [ ] Day numbers are crisp and legible
- [ ] Link click regions work correctly on weekend cells
- [ ] Shading aligns precisely with cell boundaries
- [ ] No gaps or overlaps in weekend cells
- [ ] Feb 29 is shaded correctly in leap years only
- [ ] Invalid dates (e.g., Feb 30) are not shaded

## Alignment with Existing Patterns

This approach mirrors the weekend treatment in `lib/bujo_pdf/pages/weekly_page.rb`:
- Same `COLOR_WEEKEND_BG` constant
- Fill rectangles before drawing content
- Transparent, non-intrusive visual treatment
- Consistent user experience across weekly and yearly views

## Performance Considerations

- Total cells to evaluate: 12 months × 31 days = 372 cells
- Weekend cells to fill: ~104 cells per year (52 weeks × 2 days)
- Negligible performance impact for this volume
- No caching needed
