# Plan #12: Inline Weekday Indicators with Day Numbers

## Overview
Move weekday abbreviations (Mon, Tue, etc.) to appear inline with day numbers in the year-at-a-glance pages, styled as muted gray text. Day numbers remain in their current position with weekday indicators appearing on the same line.

## Files to Modify

### Primary Changes

1. **`lib/bujo_pdf/pages/year_events.rb`**
   - Modify day number rendering to include inline weekday text
   - Update text styling for two-tone rendering (black day number + gray weekday)

2. **`lib/bujo_pdf/pages/year_highlights.rb`**
   - Same modifications as year_events.rb
   - Ensure consistent behavior across both year-at-a-glance pages

### Constants Review

3. **`lib/bujo_pdf/constants.rb`**
   - Review `COLOR_SECTION_HEADERS` ('AAAAAA') - likely appropriate for weekday text
   - Add new constant if needed: `COLOR_WEEKDAY_INDICATOR = 'AAAAAA'` (or 'BBBBBB' for slightly lighter)
   - No grid spacing changes expected, but verify cell dimensions accommodate inline text

## Current Implementation Analysis

Based on the codebase structure, the year-at-a-glance pages likely render day numbers in a 12×31 grid. Current implementation probably has:

```ruby
# Current pattern (hypothetical)
grid_text_box(day_num.to_s, col, row, width_boxes, height_boxes,
              align: :center, valign: :top)
```

## Proposed Implementation

### Text Styling Approach

**Option A: Formatted Text (Recommended)**
Use Prawn's `formatted_text_box` for inline styling:

```ruby
formatted_text = [
  { text: day_num.to_s, styles: [:bold], color: '000000' },
  { text: " #{day_abbrev}", styles: [], color: 'AAAAAA', size: font_size * 0.85 }
]

@pdf.formatted_text_box(formatted_text,
                        at: [grid_x(col), grid_y(row)],
                        width: grid_width(width_boxes),
                        height: grid_height(height_boxes),
                        align: :center,
                        valign: :top)
```

**Benefits:**
- Single rendering call maintains alignment
- Different colors/sizes for day number vs weekday
- Clean separation of styling concerns

**Option B: Two-Pass Rendering**
Render day number first, then weekday in same cell:

```ruby
# Day number
@pdf.fill_color '000000'
@pdf.text_box(day_num.to_s, at: [x, y], width: w, height: h,
              align: :center, valign: :top)

# Weekday (calculate x-offset after day number width)
@pdf.fill_color 'AAAAAA'
@pdf.text_box(" #{day_abbrev}", at: [x + day_width, y], ...)
```

**Drawbacks:**
- Complex x-offset calculations
- Harder to maintain alignment
- Two rendering calls per cell

### Layout Considerations

**Cell Dimensions:**
- Current grid allocation per cell needs verification
- Inline text format: "1 Mon" or "31 Thu"
- Maximum width needed: "31 Wed" (2 digits + space + 3 letters)
- Font size may need slight reduction for double-digit days

**Spacing Strategy:**
```
Before:    "15"           After:    "15 Wed"
           "Wed"                    (single line)
```

**Font Size Recommendations:**
- Day number: Current size (likely 8-10pt)
- Weekday: 85% of day number size (0.85 multiplier)
- Alternative: Same size but lighter weight/color creates visual hierarchy

### Grid System Adjustments

**No structural changes expected** to the grid system itself, but verify:

1. **Cell height** - Currently sized for two lines of text; may have excess space after consolidation
2. **Cell width** - Must accommodate longest string: "31 Wed"
3. **Alignment** - Center alignment should work naturally with formatted_text_box

**Potential optimization:**
- If cells have excess vertical space after consolidation, could increase day grid size
- Not required for initial implementation

## Implementation Steps

### Phase 1: Extract Current Rendering Logic
1. Read `lib/bujo_pdf/pages/year_events.rb`
2. Identify exact day number rendering method
3. Document current cell dimensions and positioning

### Phase 2: Add Weekday Constant
1. Add to `lib/bujo_pdf/constants.rb`:
   ```ruby
   COLOR_WEEKDAY_INDICATOR = 'AAAAAA'  # Muted gray for inline weekday text
   ```

### Phase 3: Modify Year Events Page
1. Replace day number rendering with formatted_text approach
2. Construct formatted text array with day number + weekday
3. Apply color/size styling as specified
4. Test with edge cases:
   - Single-digit days (1-9)
   - Double-digit days (10-31)
   - Different weekdays (Mon through Sun)

### Phase 4: Modify Year Highlights Page
1. Apply identical changes from Year Events page
2. Ensure consistency between both pages

### Phase 5: Testing & Refinement
1. Generate test PDF for multiple months
2. Verify visual hierarchy (day number prominence vs weekday subtlety)
3. Check alignment across all cells
4. Test with DEBUG_GRID enabled to verify grid alignment
5. Adjust font size ratio if needed (0.85 multiplier may need tuning)

## Code Structure (Pseudocode)

```ruby
# In year_events.rb and year_highlights.rb

def render_day_cell(day_num, date, col, row, width_boxes, height_boxes)
  day_abbrev = date.strftime('%a')  # Mon, Tue, etc.

  formatted_text = [
    {
      text: day_num.to_s,
      styles: [:bold],
      color: '000000',
      size: DAY_NUMBER_FONT_SIZE
    },
    {
      text: " #{day_abbrev}",
      color: COLOR_WEEKDAY_INDICATOR,
      size: DAY_NUMBER_FONT_SIZE * 0.85
    }
  ]

  @pdf.formatted_text_box(
    formatted_text,
    at: [grid_x(col), grid_y(row)],
    width: grid_width(width_boxes),
    height: grid_height(height_boxes),
    align: :center,
    valign: :top,
    overflow: :shrink_to_fit  # Safety net for tight cells
  )

  # Link annotation (unchanged)
  grid_link(col, row, width_boxes, height_boxes, "week_#{week_num}")
end
```

## Edge Cases & Considerations

1. **Leap years** - February 29 cells (already handled by date calculations)
2. **Font metrics** - "Wed" vs "Sat" width differences should be negligible
3. **Link annotations** - Remain unchanged, cover full cell regardless of text
4. **Accessibility** - Color differentiation (black vs gray) provides visual hierarchy
5. **Internationalization** - If supporting other languages, weekday abbreviations may vary in length

## Validation Criteria

Implementation is complete when:
- [ ] Day numbers and weekday abbreviations appear on same line
- [ ] Weekday text is visibly muted (lighter gray than day number)
- [ ] Text remains centered within grid cells
- [ ] Link annotations still work correctly
- [ ] Both year-at-a-glance pages show consistent styling
- [ ] Visual hierarchy clearly emphasizes day number over weekday
- [ ] No text overflow or truncation occurs

## Risk Assessment

**Low Risk:**
- Text formatting is well-supported in Prawn
- Grid system requires no changes
- Isolated to two page classes

**Potential Issues:**
- Font size ratio may need tuning based on visual testing
- Cell width might be tight for "31 Wed" in smaller fonts
- Color contrast may need adjustment for readability

**Mitigation:**
- Use `overflow: :shrink_to_fit` as safety net
- Test across all months before finalizing
- Adjust COLOR_WEEKDAY_INDICATOR constant if needed ('BBBBBB' vs 'AAAAAA')
