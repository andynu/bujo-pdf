# Bullet Journal PDF Planner - Design Specification

## Overview
Create a programmable bullet journal planner PDF optimized for digital note-taking apps (Noteshelf, GoodNotes) with embedded hyperlinks for navigation. The planner must be generatable for any specified year with accurate dates and day-of-week calculations.

## Technical Requirements

### App Compatibility
- **Target Apps**: Noteshelf, GoodNotes
- **Navigation Method**: Standard PDF hyperlinks and named destinations
- **Page Size**: US Letter (8.5" x 11" / 612 x 792 points)
- **Orientation**: Portrait
- **Links**: Must use PDF link annotations with named destinations for internal navigation
- **Fonts**: Use standard PDF fonts (Helvetica) for maximum compatibility

### Generation Requirements
- Must be programmatically generated with Ruby and Prawn gem
- Accept year as input parameter
- Calculate all dates dynamically for the specified year
- Handle leap years correctly
- Calculate proper day-of-week for each date
- Generate appropriate number of weeks for the year (52-53)

## Page Structure

### 1. Year at a Glance - Events (Page 1)

**Layout**:
- Title: "Year [YYYY] - Events" centered at top
- Grid layout with 12 columns (one per month) and 31 rows (max days in a month)
- Header row showing abbreviated month names (Jan, Feb, Mar, etc.)
- Each cell represents one day

**Cell Contents**:
- Day number in corner
- Two-letter day-of-week abbreviation (Mo, Tu, We, Th, Fr, Sa, Su)
- Empty space for user to write events
- Cells for non-existent days (e.g., Feb 30) should be grayed out

**Dimensions**:
- Use full page width minus margins (~80pt total margin)
- Divide width equally among 12 months
- Cell height calculated to fit 32 rows (1 header + 31 days) in available vertical space
- Leave room for navigation footer at bottom

**Named Destination**: "year_events"

### 2. Year at a Glance - Highlights (Page 2)

**Layout**: Identical to Events page
**Title**: "Year [YYYY] - Highlights"
**Purpose**: Separate page for tracking different information (goals, memories, achievements, etc.)
**Named Destination**: "year_highlights"

### 3. Weekly Pages (Pages 3 through end)

Generate one page per week for the entire year:
- Start with the Monday of the week containing January 1st (or Jan 1 if it's Monday)
- Continue through the last week containing December 31st
- Each page should have a unique named destination: "week_1", "week_2", etc.

**Weekly Page Layout**:

**Header Section**:
- Title: "Week [N]: [Start Date] - [End Date, YYYY]"
  - Example: "Week 1: Jan 1 - Jan 7, 2025"
- Centered, bold, 14pt font

**Daily Section (Upper 35% of usable space)**:
- 7 equal-width columns, one for each day of the week
- Column headers show:
  - Full day name (Monday, Tuesday, etc.)
  - Numeric date (M/D format, e.g., 1/1)
- Below each header: 4 evenly-spaced horizontal ruled lines for daily notes/tasks
- Each column has a border around it

**Cornell Notes Section (Lower 65% of usable space)**:

Divided into three areas:

1. **Cues/Questions Column** (Left, 25% width):
   - Header: "Cues/Questions" centered
   - Ruled lines throughout (~15pt spacing)
   - Light gray lines (not black)
   - Full height of main notes section

2. **Notes Column** (Right, 75% width):
   - Header: "Notes" centered
   - Ruled lines throughout (~15pt spacing)
   - Light gray lines (not black)
   - Full height of main notes section

3. **Summary Section** (Bottom, full width):
   - Spans the full width of both columns above
   - Height: ~20% of Cornell notes section
   - Header: "Summary" centered
   - Ruled lines throughout (~15pt spacing)
   - Light gray lines (not black)

All three sections should have visible borders.

### 4. Navigation Footer (All Pages)

**Position**: Bottom of every page
**Height**: 25 points
**Layout**: 
- Thin horizontal line separator at top
- 12 equally-spaced single letters representing months: J F M A M J J A S O N D
- Each letter is a clickable link

**Link Behavior**:
- Each letter links to the first week of that month
- Calculate week number based on which week contains the 1st of each month
- Links use named destinations: "week_[N]"
- Example: Clicking "M" (March) jumps to the week containing March 1st

**Visual Design**:
- Letters centered in their allocated space
- 10pt Helvetica font
- Simple, minimalist appearance
- No boxes around letters (just clickable areas)

## Color Scheme

**Primary Colors**:
- Black: Text and primary lines (000000)
- Light Gray: Ruled lines in Cornell notes (CCCCCC)
- Medium Gray: Footer separator, non-existent days background (AAAAAA, EEEEEE)

**Philosophy**: Minimal color for maximum writing space and readability

## Spacing and Margins

- **Page Margins**: 40 points on all sides
- **Footer Space**: 25 points reserved at bottom
- **Title Space**: ~60-80 points at top of each page
- **Line Spacing in Cornell Notes**: ~15 points between ruled lines
- **Daily Task Lines**: Evenly distributed in available space (typically 4 lines)

## Grid and Alignment

**Year at a Glance**:
- Perfect grid alignment required
- Equal column widths
- Equal row heights (except adjust for actual days in month)
- Consistent cell padding

**Weekly Pages**:
- 7 equal-width columns for days
- Precise Cornell notes column divisions (25% / 75%)
- All ruled lines perfectly horizontal
- Consistent spacing throughout

## Typography

**Fonts**:
- Headers: Helvetica-Bold
- Body text: Helvetica
- Sizes:
  - Page titles: 14-16pt
  - Section headers: 10pt
  - Day numbers/dates: 6-9pt
  - Footer links: 10pt

## Data Calculations

**Critical Date Calculations**:
1. Determine if year is leap year (affects February)
2. Calculate day-of-week for every date
3. Determine days in each month (28/29/30/31)
4. Calculate which week number contains the 1st of each month
5. Calculate total weeks in year (52 or 53)
6. Handle year boundaries (weeks that span December/January)

**Week Numbering**:
- Week 1 starts with the Monday on or before January 1st
- Weeks increment sequentially
- Each week represents 7 consecutive days (Mon-Sun)

## File Generation

**Output**:
- Filename: `planner_[YYYY].pdf`
- Example: `planner_2025.pdf`

**Process**:
1. Accept year as command-line argument (default to current year)
2. Calculate all dates and week boundaries
3. Create named destinations for all pages
4. Generate year-at-a-glance pages
5. Generate weekly pages in sequence
6. Add navigation footer to every page with proper links
7. Output single PDF file

## Testing Checklist

After generation, verify:
- [ ] All dates are correct for the specified year
- [ ] Day-of-week abbreviations match actual dates
- [ ] Leap year handled correctly (Feb 29 if applicable)
- [ ] All navigation links work (click each month letter)
- [ ] Links jump to correct week pages
- [ ] No broken named destinations
- [ ] PDF opens correctly in Noteshelf
- [ ] PDF opens correctly in GoodNotes
- [ ] All pages are US Letter size
- [ ] Text is selectable (not rasterized)
- [ ] Ruled lines are visible but subtle

## Design Philosophy

**Minimalist Approach**:
- Maximum white space for writing
- Simple, clean lines
- No decorative elements
- Functional typography
- Intuitive navigation

**Digital-First**:
- Optimized for stylus input
- Clickable navigation for quick access
- Consistent layout for muscle memory
- High contrast for screen readability

**Programmable**:
- No manual date entry required
- Regenerate for any year in seconds
- Consistent layout across all years
- Easy to modify and customize

## Future Enhancement Ideas

- Add monthly overview pages
- Include habit trackers
- Add project planning pages
- Include blank dot grid pages
- Add goal-setting templates
- Include yearly review sections
- Add customizable cover page
- Support custom color schemes
- Add optional month-based sections
- Include quarterly planning pages

## Implementation Notes

**Ruby/Prawn Specific**:
- Use `Prawn::Document.generate` for PDF creation
- Use `add_dest()` for named destinations
- Use `link_annotation()` for clickable areas
- Use `bounding_box` for precise layout control
- Use `stroke_bounds` for visible boxes
- Calculate all positions relative to page dimensions
- Use proper date libraries (Date class) for calculations

**Performance**:
- Should generate complete planner in under 5 seconds
- File size should be under 2MB for full year
- No external dependencies beyond Prawn gem

## Version Control Recommendations

Track these elements in version control:
- Main generator script
- Layout constants and dimensions
- Color scheme definitions
- Typography specifications
- Calculation algorithms
- README and documentation
- Example output (sample pages as PDF)

## Accessibility Considerations

- Use semantic structure where possible
- Maintain high contrast ratios
- Keep text readable (minimum 6pt font)
- Ensure links have adequate click areas
- Test with different PDF readers
- Verify compatibility with iPad annotation tools

---

## Sample Command-Line Usage

```bash
# Install dependencies
gem install prawn

# Generate planner for current year
ruby planner_generator.rb

# Generate planner for specific year
ruby planner_generator.rb 2026

# Generate multiple years
for year in 2025 2026 2027; do
  ruby planner_generator.rb $year
done
```

## Expected Output

Running the generator should produce:
- Console output showing progress
- Final page count confirmation
- Generated PDF file in working directory
- No errors or warnings

---

This specification ensures the planner is:
✓ Programmatically generated
✓ Compatible with Noteshelf and GoodNotes
✓ Fully navigable via embedded links
✓ Accurate for any specified year
✓ Optimized for digital handwriting
✓ Minimalist and functional
✓ Easy to regenerate and customize
