# Plan #17: Monthly Table of Contents Pages

## Overview
Add dedicated TOC pages for each month (12 total) to provide navigation structure between the year-at-a-glance pages and individual weekly pages. These pages serve as monthly landing pages with navigation to all weeks in that month.

## Content Design for Monthly TOC Pages

### Primary Content
1. **Month header** - Large month name with year (e.g., "January 2025")
2. **Week grid** - Visual representation of weeks in the month:
   - Each week shows: week number, date range, days of week with dates
   - Clickable week boxes linking to weekly pages
   - Current month days highlighted vs. overflow days from adjacent months
3. **Notable dates section** (optional future enhancement):
   - Space for holidays/observances for that month
   - Could be pre-populated with common holidays

### Secondary Navigation
- **Previous/Next month TOC links** - Navigate between monthly TOC pages
- **Back to Year Overview link** - Return to year-at-a-glance pages
- **Jump to week links** - Quick navigation sidebar (similar to weekly pages)

## Page Sequence Integration

### Placement Strategy
**Option A (Recommended): Month TOC before first week of each month**
```
Seasonal Calendar
Year Events
Year Highlights
Reference Page
→ January TOC (new)
  Week 1
  Week 2
  Week 3
  Week 4
→ February TOC (new)
  Week 5
  Week 6
  ...
```

**Rationale:**
- Natural hierarchical navigation: Year → Month → Week
- TOC appears when user first enters each month's weeks
- Preserves sequential week numbering
- Easy to implement: insert before first week of each month

**Option B: All TOCs grouped before weekly pages**
```
Seasonal Calendar
Year Events
Year Highlights
Reference Page
→ January TOC
→ February TOC
... (all 12 TOCs)
Week 1
Week 2
...
```

**Not recommended** - breaks natural navigation flow

### Named Destinations
Add new destinations:
- `month_jan`, `month_feb`, ..., `month_dec` - Monthly TOC pages
- Update year-at-a-glance pages to link to month TOCs instead of directly to weeks

## Page Class Structure

### New File: `lib/bujo_pdf/pages/month_toc.rb`

```ruby
module Pages
  class MonthToc < Base
    def initialize(pdf, year, month_num, weeks_in_month, first_week_num, total_weeks)
      super(pdf, year)
      @month_num = month_num           # 1-12
      @weeks_in_month = weeks_in_month # Array of week numbers for this month
      @first_week_num = first_week_num # For highlighting in sidebar
      @total_weeks = total_weeks       # For week sidebar rendering
    end

    def setup
      use_layout :standard_with_sidebars,
        current_week: @first_week_num,
        highlight_tab: nil,  # Or create new :month_toc tab type
        year: @year,
        total_weeks: @total_weeks
    end

    def render(content_area)
      draw_month_header(content_area)
      draw_week_grid(content_area)
      draw_navigation_footer(content_area)
    end

    private

    def draw_month_header(content_area)
      # Large month name + year
      # Grid position: top 3 rows of content area
    end

    def draw_week_grid(content_area)
      # Visual week calendar for the month
      # Each week: box with week#, date range, day columns
      # Clickable links to weekly pages
    end

    def draw_navigation_footer(content_area)
      # Previous/Next month links
      # Back to Year Overview link
    end
  end
end
```

### Supporting Utility Method

Add to `lib/bujo_pdf/utilities/date_calculator.rb`:

```ruby
def weeks_for_month(year, month_num)
  # Returns array of week numbers that include dates in this month
  # Handles edge cases: weeks spanning month boundaries

  first_of_month = Date.new(year, month_num, 1)
  last_of_month = Date.new(year, month_num, -1)

  first_week = week_number_for_date(year, first_of_month)
  last_week = week_number_for_date(year, last_of_month)

  (first_week..last_week).to_a
end

def primary_month_for_week(year, week_num)
  # Returns month number (1-12) that contains most days of this week
  # Used to decide which month TOC to place before a week
end
```

## Grid Layout Approach

### Month Header (Rows 0-2)
```
┌─────────────────────────────────────────┐
│         JANUARY 2025                    │  3 boxes tall
│                                         │  Centered, large font
└─────────────────────────────────────────┘
```

### Week Grid (Rows 3-35)
```
┌───────────────────────────────────────────┐
│  Week 1  │ Dec 30 - Jan 5, 2025          │
│  ┌─────┬─────┬─────┬─────┬─────┬─────┬──│
│  │ Mon │ Tue │ Wed │ Thu │ Fri │ Sat │Su│
│  │ 30* │ 31* │  1  │  2  │  3  │  4  │ 5│  (* = prev month)
│  └─────┴─────┴─────┴─────┴─────┴─────┴──│
│  [Clickable area linking to Week 1]      │
├───────────────────────────────────────────┤
│  Week 2  │ Jan 6 - Jan 12, 2025          │
│  ... (similar structure)                  │
├───────────────────────────────────────────┤
│  Week 3, Week 4, Week 5 ...              │
└───────────────────────────────────────────┘
```

**Grid allocation per week:**
- 5-6 rows per week box
- Day columns: 7 equal-width sections
- Week label: Left 20% of width
- Date range: Right 80% of width or second row

### Navigation Footer (Rows 48-52)
```
┌─────────────────────────────────────────┐
│  ← December  │ Year Overview │ February →│
└─────────────────────────────────────────┘
```

### Alternative: Compact Week List
If visual calendar per week is too space-intensive:

```
Week 1  │ Dec 30 - Jan 5   │ → [link]
Week 2  │ Jan 6 - Jan 12   │ → [link]
Week 3  │ Jan 13 - Jan 19  │ → [link]
Week 4  │ Jan 20 - Jan 26  │ → [link]
Week 5  │ Jan 27 - Feb 2   │ → [link]
```

Simpler, more compact, focuses on navigation over visualization.

## Navigation Link Updates

### 1. Year-at-a-Glance Pages
**Current behavior:** Date cells link directly to `week_N`

**New behavior:** Month column headers link to `month_jan`, `month_feb`, etc.
- Or: First date of each month links to month TOC
- Subsequent dates still link directly to weeks

### 2. Weekly Pages
**Current behavior:** "Back to Year Overview" links to `year_events`

**New behavior options:**
- **Option A:** Change to "Back to Month" → links to `month_jan`, etc.
- **Option B:** Two links: "Month" and "Year"
- **Option C:** Keep current behavior (direct to year overview)

**Recommendation:** Option B - provide both month and year navigation

### 3. Month TOC Page Navigation
- Previous/Next month TOC
- Link to Year Events or Year Highlights
- Each week box links to corresponding weekly page
- Week sidebar still functional for jump-to-week

## PDF Outline/Bookmarks Integration

### Current Bookmark Structure
```
Planner 2025
├─ Seasonal Calendar
├─ Year at a Glance - Events
├─ Year at a Glance - Highlights
├─ Weekly Pages
│  ├─ Week 1
│  ├─ Week 2
│  └─ ...
├─ Reference
└─ Blank Dots
```

### New Bookmark Structure
```
Planner 2025
├─ Seasonal Calendar
├─ Year at a Glance - Events
├─ Year at a Glance - Highlights
├─ Reference
├─ Blank Dots
└─ Monthly Pages
   ├─ January 2025
   │  ├─ Week 1
   │  ├─ Week 2
   │  ├─ Week 3
   │  ├─ Week 4
   │  └─ Week 5
   ├─ February 2025
   │  ├─ Week 5
   │  ├─ Week 6
   │  └─ ...
   └─ December 2025
      └─ ...
```

**Implementation in `generate` method:**
```ruby
# After year-at-a-glance pages, before weekly pages
outline.section "Monthly Pages", destination: "month_jan" do
  (1..12).each do |month_num|
    month_name = Date::MONTHNAMES[month_num]
    weeks = weeks_for_month(@year, month_num)

    outline.section "#{month_name} #{@year}", destination: "month_#{month_abbrev(month_num)}" do
      weeks.each do |week_num|
        outline.page title: "Week #{week_num}", destination: "week_#{week_num}"
      end
    end
  end
end
```

## Implementation Steps

### Phase 1: Core Infrastructure
1. Create `MonthToc` page class with basic layout
2. Add `weeks_for_month` utility method
3. Implement named destinations for month TOC pages
4. Update page generation sequence in `PlannerGenerator#generate`

### Phase 2: Content Rendering
5. Implement month header rendering
6. Implement week list/grid with date ranges
7. Add clickable link regions to weekly pages
8. Add navigation footer (prev/next month, year overview)

### Phase 3: Navigation Integration
9. Update year-at-a-glance pages to link to month TOCs
10. Update weekly pages to link back to month TOC
11. Update PDF outline/bookmarks structure

### Phase 4: Polish
12. Style consistency with existing pages
13. Test edge cases (53-week years, month boundaries)
14. Add to reference documentation

## Edge Cases to Handle

1. **Weeks spanning months**: Week 5 might contain Jan 27 - Feb 2
   - Show in both January and February TOCs?
   - Or show only in "primary" month (where most days fall)?
   - **Recommendation:** Show in both, with visual indicator for partial weeks

2. **53-week years**: December might have 5-6 weeks
   - Grid layout needs to accommodate variable week counts (4-6 weeks per month)

3. **First week of year**: Might start in previous December
   - January TOC shows Week 1, but dates start Dec 30

4. **Year boundaries**: Week 52/53 spans into next year
   - December TOC shows partial week

## Alternative Designs

### Minimal Approach
Skip full TOC pages, instead:
- Add month headers as spacer pages between months
- Simple "January 2025" title page with "Continue to Week 1 →" link
- Lighter weight, less development effort

### Enhanced Approach
Add notable dates section:
- Pre-populate with US holidays (New Year's, Memorial Day, etc.)
- Configuration option to include/exclude
- Could reference external holiday data file

## Testing Considerations

1. **Visual verification**: Generate planner and check:
   - Month TOC pages appear before first week of each month
   - All links navigate correctly
   - Week grid shows correct dates and week numbers

2. **Edge case testing**: Test with years that have:
   - 52 weeks (e.g., 2025)
   - 53 weeks (e.g., 2026)
   - Different first day of year (Mon vs Sun)

3. **Bookmark verification**: Check PDF outline structure in viewer

## Estimated Complexity

- **Development time**: 4-6 hours
- **Lines of code**: ~200-300 new lines
- **Files modified**: 5-6 files
- **Risk level**: Low - well-isolated feature, follows existing patterns

## Benefits

1. **Improved navigation hierarchy**: Year → Month → Week flow
2. **Month-level overview**: See all weeks in a month at once
3. **Better PDF structure**: Clearer bookmarks and navigation
4. **Room for enhancement**: Foundation for adding monthly goals, events, etc.
