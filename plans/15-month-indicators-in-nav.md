# Plan #15: Three-Letter Month Indicators in Week Sidebar

## Current State Analysis

The `WeekSidebar` component currently displays:
- **Single-character month abbreviations** (J, F, M, A, M, J, J, A, S, O, N, D) via `char: 1` parameter
- Month letters appear in **bold** for non-current weeks
- Month letters appear in **bold and black** for the current week
- Week numbers are **regular weight** for non-current weeks, **bold** for current week
- Sidebar width: **2 boxes** (columns 0.25-2.25)
- Font size: **7pt Helvetica**
- Color: **#888888** (gray) for non-current weeks, **#000000** (black) for current week

## Goal

Change from single-character month indicators to **three-letter month abbreviations** (JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC) while maintaining the existing bold styling and layout integrity.

## Implementation Plan

### 1. Update Month Abbreviation Length

**File**: `lib/bujo_pdf/components/week_sidebar.rb`

**Change Line 45**:
```ruby
# Current:
@week_months = Utilities::DateCalculator.week_to_month_abbrev_map(context[:year], char: 1)

# Updated:
@week_months = Utilities::DateCalculator.week_to_month_abbrev_map(context[:year], char: 3)
```

**Rationale**: The `DateCalculator.week_to_month_abbrev_map` method already supports variable-length abbreviations via the `char` parameter. Simply changing `char: 1` to `char: 3` will produce "JAN", "FEB", "MAR", etc.

### 2. Assess Sidebar Width Constraints

**Current dimensions**:
- Sidebar width: 2 boxes × 14.17pt/box = **28.34pt**
- Internal padding: 0.3 boxes × 2 sides = 0.6 boxes = **8.5pt** total
- Available text width: **19.84pt**
- Font size: **7pt**

**Text width analysis**:
- Single character "J": ~3.5pt @ 7pt Helvetica
- Three characters "JAN": ~10.5pt @ 7pt Helvetica
- Space: ~2pt
- Week number "w01": ~12pt @ 7pt Helvetica
- **Total for "JAN w01"**: ~24.5pt

**Conclusion**: The current sidebar width (19.84pt available) is **insufficient** for three-letter abbreviations plus week numbers. We need to widen the sidebar or reduce font size.

### 3. Sidebar Width Options

**Option A: Widen sidebar to 2.5 boxes** (RECOMMENDED)
```ruby
SIDEBAR_WIDTH_BOXES = 2.5  # Was 2
# Available width: 2.5 × 14.17 - 8.5 = 26.9pt
# Sufficient for "JAN w01" (~24.5pt) with small margin
```

**Trade-offs**:
- Reduces content area from 39 boxes to 38.5 boxes (1.3% reduction)
- Maintains 7pt font size (readability)
- Minimal impact on overall layout

**Option B: Reduce font size to 6pt**
```ruby
FONT_SIZE = 6  # Was 7
# "JAN w01" @ 6pt: ~21pt
# Fits in current 19.84pt width
```

**Trade-offs**:
- No change to content area width
- Reduced readability (6pt is quite small)
- May look cramped

**Option C: Remove padding**
```ruby
PADDING_BOXES = 0.1  # Was 0.3
# Available width increases to ~25pt
```

**Trade-offs**:
- Text too close to sidebar edges
- Reduced visual breathing room
- Still tight fit

**Recommendation**: **Option A** (widen to 2.5 boxes) provides the best balance of readability and layout impact.

### 4. Update Layout Constants

**File**: `lib/bujo_pdf/layouts/standard_with_sidebars.rb`

**Current left sidebar allocation**:
```ruby
LEFT_SIDEBAR_WIDTH = 3  # boxes
```

**No change needed**: The layout already allocates 3 boxes for the left sidebar. The WeekSidebar uses columns 0.25-2.25 (2 boxes) within this 3-box area. Widening to 2.5 boxes still fits comfortably.

### 5. Font Weight Considerations

**Current behavior**:
- Month abbreviations: **bold** (Helvetica-Bold)
- Week numbers: **regular** (Helvetica) for non-current, **bold** for current

**No changes needed**: The three-letter abbreviations in bold will actually improve visual hierarchy since they'll be more prominent and clearly distinguish months from weeks.

### 6. Testing Considerations

**Visual inspection checklist**:
1. Month abbreviations appear on correct weeks (first week of each month)
2. Three-letter abbreviations are fully visible (not truncated)
3. Text doesn't overflow sidebar boundaries
4. Bold styling is preserved for month abbreviations
5. Current week highlighting works correctly
6. Links to week pages function properly
7. Alignment is consistent (right-aligned)

**Test cases**:
- Week 1 (typically shows "JAN")
- Boundary weeks (e.g., week containing Feb 1, Mar 1)
- Current week with month indicator
- Current week without month indicator
- Weeks 10+ (check for number width with "w10", "w11", etc.)

### 7. Implementation Steps (Ordered)

1. **Update sidebar width** in `lib/bujo_pdf/components/week_sidebar.rb`:
   ```ruby
   SIDEBAR_WIDTH_BOXES = 2.5  # Line 32
   ```

2. **Update character count** in `lib/bujo_pdf/components/week_sidebar.rb`:
   ```ruby
   @week_months = Utilities::DateCalculator.week_to_month_abbrev_map(context[:year], char: 3)  # Line 45
   ```

3. **Test generation**:
   ```bash
   ruby gen.rb 2025
   ```

4. **Visual verification**:
   - Open `planner_2025.pdf`
   - Navigate to any weekly page
   - Inspect left sidebar for:
     - Full three-letter month names (JAN, FEB, MAR, etc.)
     - Proper alignment (right-aligned)
     - No text truncation
     - Correct bold styling
     - Proper spacing between month and week number

5. **Edge case testing**:
   - Check week 1 (often shows JAN)
   - Check December weeks (DEC is 3 characters)
   - Check September (SEP is 3 characters)
   - Check current week highlighting

### 8. Potential Issues and Mitigations

**Issue 1: Text overflow/truncation**
- **Detection**: Month abbreviations appear cut off or ellipsized
- **Fix**: Increase `SIDEBAR_WIDTH_BOXES` to 3.0 or reduce `PADDING_BOXES`

**Issue 2: Right alignment looks off**
- **Detection**: Text appears too close to right edge
- **Fix**: Adjust `PADDING_BOXES` to add more right-side padding

**Issue 3: Month abbreviations too prominent**
- **Detection**: Month labels visually overpower week numbers
- **Fix**: Consider using regular weight for month labels instead of bold (would require changing `formatted_text_box` styles)

**Issue 4: Inconsistent spacing**
- **Detection**: Gap between month abbreviation and week number varies
- **Fix**: May need to switch from `formatted_text_box` to manual positioning with two separate `text_box` calls

### 9. Alternative Approach (If Width Constraints Persist)

If 2.5 boxes is still insufficient, consider **stacked layout**:
```
JAN
w01

FEB
w05
```

This would require:
- Doubling row height per week (2 boxes instead of 1)
- Adjusting `SIDEBAR_START_ROW` and row calculations
- Modifying the render loop to use 2-box-tall cells
- Significant layout restructuring

**Not recommended** unless absolutely necessary, as it would reduce the number of visible week indicators and require extensive changes.

### 10. Rollback Plan

If the change causes layout issues:

1. Revert line 45 to `char: 1`
2. Revert line 32 to `SIDEBAR_WIDTH_BOXES = 2`
3. Regenerate PDF
4. Consider alternative approaches (different font, stacked layout, abbreviation format)

### 11. Documentation Updates

After successful implementation:

**Update `lib/bujo_pdf/components/week_sidebar.rb` header comment**:
```ruby
# WeekSidebar component for left sidebar with week list.
#
# Renders a vertical list of all weeks in the year with:
#   - Three-letter month abbreviations (JAN, FEB, MAR, etc.) for weeks where a new month starts
#   - Week numbers (w1, w2, etc.)
#   - Current week highlighted in bold (if specified)
#   - Clickable links to all other weeks
#   - Gray color for non-current weeks
#
# Grid positioning:
#   - Columns 0.25-2.75 (2.5 boxes wide, inset 0.25 from left edge)  # UPDATED
#   - Starts at row 2
#   - One week per row
#   - Internal padding: 0.3 boxes on each side
```

**Update CLAUDE.md** (if sidebar width is mentioned):
- Document the 2.5-box sidebar width
- Note the three-letter month abbreviation format

---

## Summary

**Minimal change required**: This is primarily a **one-line change** (char: 1 → char: 3) with a **one-constant adjustment** (width: 2 → 2.5 boxes).

**Key insight**: The architecture already supports variable-length month abbreviations. The DateCalculator and WeekSidebar are well-designed to handle this with minimal modification.

**Risk level**: **Low** - The change is isolated to the WeekSidebar component, and the existing code already handles formatted text with mixed styling.

**Expected result**: Month indicators change from "J w01" to "JAN w01", with month abbreviations in bold and improved visual clarity for month boundaries.
