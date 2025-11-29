# Plan #18: Flat PDF Outline (Bookmarks)

## Status: COMPLETED ✅

## Overview

Simplify the **PDF outline/bookmarks** (metadata navigation tree in PDF viewers) by flattening the deeply nested structure. Remove all individual week entries and keep only year-level pages, month pages (linking to first week of each month), and reference pages.

## Implementation

Modified `lib/bujo_pdf/planner_generator.rb`'s `build_outline` method to create a flat bookmark structure.

### Previous Structure (Deeply Nested)
```
- 2025 Overview
  - Seasonal Calendar
  - Year at a Glance - Events
  - Year at a Glance - Highlights
  - Multi-Year Overview
- Monthly Pages
  - January 2025
    - Week 1
    - Week 2
    - Week 3
    - Week 4
    - Week 5
  - February 2025
    - Week 6
    - Week 7
    - ...
  - (all months with all weeks)
- Templates
  - Grid Types Showcase
  - Grid Reference & Calibration
  - Dot Grid
```

### New Structure (Flat)
```
- Seasonal Calendar
- Year at a Glance - Events
- Year at a Glance - Highlights
- Multi-Year Overview
- January 2025 (links to Week 1)
- February 2025 (links to Week 6)
- March 2025 (links to Week 10)
- April 2025 (links to Week 14)
- May 2025 (links to Week 18)
- June 2025 (links to Week 23)
- July 2025 (links to Week 27)
- August 2025 (links to Week 31)
- September 2025 (links to Week 36)
- October 2025 (links to Week 40)
- November 2025 (links to Week 44)
- December 2025 (links to Week 49)
- Grid Types Showcase
- Grid Reference & Calibration
- Dot Grid
```

All entries at the same level, no nesting. Total: 19 bookmark entries (4 year pages + 12 months + 3 reference pages).

## Benefits

1. **Simpler navigation**: No need to expand nested sections to find content
2. **Faster access**: Reduced clicks to reach any month
3. **Cleaner bookmark sidebar**: Less visual clutter in PDF readers
4. **Preserved functionality**: All major navigation targets still accessible

## Technical Changes

**File**: `lib/bujo_pdf/planner_generator.rb`

Changed from nested `section` blocks to flat `page` entries:

```ruby
@pdf.outline.define do
  # Year overview pages (flat, no nesting)
  page destination: seasonal_page, title: 'Seasonal Calendar'
  page destination: events_page, title: 'Year at a Glance - Events'
  page destination: highlights_page, title: 'Year at a Glance - Highlights'
  page destination: multi_year_page, title: 'Multi-Year Overview'

  # Month pages (flat, linking to first week of each month)
  (1..12).each do |month|
    month_name = Date::MONTHNAMES[month]
    weeks_in_month = Utilities::DateCalculator.weeks_for_month(year, month)

    if weeks_in_month.any?
      first_week = weeks_in_month.first
      page destination: week_pages[first_week], title: "#{month_name} #{year}"
    end
  end

  # Reference/template pages (flat, no nesting)
  page destination: grid_showcase_page, title: 'Grid Types Showcase'
  page destination: reference_page, title: 'Grid Reference & Calibration'
  page destination: dots_page, title: 'Dot Grid'
end
```

Removed all `section` nesting and individual week entries, keeping only the first week of each month.

---

## Original Plan (Archived)

**Note**: The original plan below described creating a physical TOC page, but the actual requirement was to flatten the PDF outline/bookmarks metadata structure instead.

## Visual Layout Design

### Single Page Design (Recommended)

Using the standard layout with sidebars (39-column content area):

```
┌─────────────────────────────────────────────┐
│ [Week Sidebar] TABLE OF CONTENTS [Nav Tabs]│
│                                             │
│  Two-Column Format:                         │
│  ┌─────────────────┬─────────────────┐     │
│  │ Major Sections  │ Weekly Pages    │     │
│  │                 │                 │     │
│  │ • Seasonal      │ Week 1  (Jan 1) │     │
│  │   Calendar      │ Week 2  (Jan 8) │     │
│  │ • Year Events   │ Week 3 (Jan 15) │     │
│  │ • Year          │ Week 4 (Jan 22) │     │
│  │   Highlights    │ Week 5 (Jan 29) │     │
│  │ • Reference     │ ...             │     │
│  │ • Blank Dots    │ Week 52 (Dec)   │     │
│  │                 │ Week 53 (Dec)*  │     │
│  └─────────────────┴─────────────────┘     │
└─────────────────────────────────────────────┘
```

**Layout Specifications:**
- **Use `StandardWithSidebarsLayout`** for consistency
- **Content area**: 39 columns wide (after 3-col week sidebar, 1-col nav tabs)
- **Two columns within content area**:
  - Left column (12 boxes): Major sections (5-6 entries)
  - Right column (27 boxes): Weekly entries (52-53 entries)

### Grid Positioning

```ruby
# Content area is cols 3-41 (39 boxes), full height minus header
content_cols = 39

# Left column: Major sections
major_sections_col = 3
major_sections_width = 12

# Right column: Weekly pages
weekly_col = 3 + 12 + 1  # After major sections + gutter
weekly_width = 26

# Header (2 rows)
header_height = 2

# Start content at row 3
content_start_row = 3
```

## TOC Entries

### Major Sections (Left Column)

1. **Seasonal Calendar** → `seasonal`
2. **Year at a Glance - Events** → `year_events`
3. **Year at a Glance - Highlights** → `year_highlights`
4. **Grid Reference** → `reference`
5. **Blank Dot Grid** → `dots`

### Weekly Pages (Right Column)

- **Week 1** (Jan 1-7) → `week_1`
- **Week 2** (Jan 8-14) → `week_2`
- ...
- **Week 52** (Dec 18-24) → `week_52`
- **Week 53*** (Dec 25-31) → `week_53` (only if year has 53 weeks)

**Date Range Format**: Show starting Monday's date
**Month Grouping**: Subtle visual grouping by month (different text color or small month header)

## Implementation Details

### New Page Class

**File**: `lib/bujo_pdf/pages/table_of_contents.rb`

```ruby
module Pages
  class TableOfContents < Base
    def setup
      use_layout :standard_with_sidebars,
        current_week: nil,  # No week highlighted
        highlight_tab: nil, # No tab highlighted
        year: @year,
        total_weeks: @total_weeks
    end

    def render(content_area)
      render_header(content_area)
      render_major_sections(content_area)
      render_weekly_entries(content_area)
      draw_dot_grid_background(content_area)
    end

    private

    def render_header(content_area)
      # Center-aligned title "TABLE OF CONTENTS"
      # Spanning full content width, 2 boxes tall
    end

    def render_major_sections(content_area)
      # Left column (12 boxes wide)
      # List 5 major section entries with links
      # Each entry: clickable with link annotation
    end

    def render_weekly_entries(content_area)
      # Right column (26 boxes wide)
      # List all 52-53 weeks with date ranges
      # Group by month with subtle headers
      # Each entry: clickable with link annotation
    end
  end
end
```

### Entry Rendering Pattern

Each TOC entry follows this pattern:

```ruby
def render_toc_entry(text, destination, col, row, width_boxes)
  # Text box (clickable visual)
  grid_text_box(
    text,
    col, row, width_boxes, 1,  # 1 box tall per entry
    align: :left,
    size: 9,
    color: '333333'
  )

  # Link annotation
  grid_link(col, row, width_boxes, 1, destination)
end
```

### Month Grouping for Weeks

Insert subtle month headers in the weekly column:

```ruby
# Before rendering Week 5 (first week of February)
if week.start_date.month != previous_month
  grid_text_box(
    Date::MONTHNAMES[week.start_date.month],
    weekly_col, current_row, weekly_width, 0.5,
    align: :left,
    size: 7,
    color: 'AAAAAA',
    style: :italic
  )
  current_row += 0.5
end
```

## Placement in PDF Sequence

Insert **after** the year-at-a-glance pages, **before** weekly pages:

1. Seasonal Calendar
2. Year at a Glance - Events
3. Year at a Glance - Highlights
4. **→ Table of Contents** ← NEW
5. Grid Reference
6. Week 1
7. Week 2
8. ...
9. Week 52/53
10. Blank Dot Grid

**Rationale**:
- After overview pages (user has seen the "big picture")
- Before weekly pages (acts as gateway to detailed content)
- Pairs logically with reference page (both are navigation aids)

## Navigation Integration

### Named Destination

```ruby
@pdf.add_dest('toc', @pdf.dest_xyz(0, PAGE_HEIGHT))
```

### Outgoing Links from TOC

All entries are clickable:
- Major sections → their respective destinations
- Weekly entries → `week_N` destinations

### Incoming Links to TOC

Add "Table of Contents" link to:
- **Navigation tabs** (right sidebar): Add new tab below "Year Highlights"
- **Weekly page navigation**: Optional "TOC" button in header alongside "← Week N" / "Week N →"

## Technical Considerations

### Single Page Feasibility

**Vertical space calculation**:
- Content area: ~53 rows available (55 total - 2 header)
- Weekly entries: 52-53 weeks × 1 box each = ~52-53 boxes
- Month headers: ~12 months × 0.5 boxes = 6 boxes
- Total needed: ~58-59 boxes

**Challenge**: Content exceeds single-page height by ~5-6 boxes

**Solutions**:

1. **Reduce entry height** (0.8 boxes instead of 1):
   - 53 weeks × 0.8 = 42.4 boxes
   - 12 month headers × 0.4 = 4.8 boxes
   - Total: ~47 boxes ✓ Fits comfortably

2. **Smaller font** (8pt instead of 9pt):
   - More compact vertical spacing
   - Still readable on tablet

3. **Omit month headers**:
   - Show month in date range: "Week 1 (Jan 1)"
   - Saves 6 boxes, fits easily

**Recommendation**: Use solution #3 (month in date range) for simplicity and clarity.

### Week Number Consistency

Use **same week calculation** as main generator:
- Import `DateCalculator` utility
- Ensure week numbers match sidebar and weekly page headers exactly

```ruby
calculator = DateCalculator.new(@year)
week_data = calculator.weeks  # Array of week info with start dates
```

### Link Validation

All destinations must exist before TOC is rendered:
- Ensure `add_named_destinations` is called first
- TOC references: `seasonal`, `year_events`, `year_highlights`, `week_1..week_N`, `reference`, `dots`

## Alternative: Multi-Page TOC

If single-page TOC becomes cramped, consider **two-page spread**:

**Page 1**: Major sections + Weeks 1-26 (Q1-Q2)
**Page 2**: Weeks 27-53 (Q3-Q4)

Each page uses same layout, split by semester. Provides more breathing room for larger font/spacing.

## Future Enhancements

1. **Page Numbers**: Add actual PDF page numbers next to each entry
   - Requires tracking page count during generation
   - Format: "Week 23 ............... p. 28"

2. **Visual Dividers**: Horizontal rules between month groups
   - Subtle gray lines (COLOR_BORDERS)

3. **Quarter Sections**: Group weeks by quarter instead of month
   - "Q1: Weeks 1-13", "Q2: Weeks 14-26", etc.

4. **Thumbnail Preview**: Small visual indicator for each section type
   - Icon or color dot before entry text

## Summary

**Plan #18** creates a single comprehensive table of contents page that:
- Lists all major sections (5 entries) + all weekly pages (52-53 entries)
- Uses two-column layout within standard sidebar chrome
- Provides clickable navigation to every destination
- Inserts after year-at-a-glance pages, before weekly pages
- Complements Plan #17's month-scoped TOC with year-wide overview
- Fits on single page using compact spacing and month-in-date-range format

This provides users with a "map" of the entire planner at a glance, accessible early in the document flow.
