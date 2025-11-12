# Plan #11: Multi-Year Layout Implementation

## Overview
Create a new page type that displays multiple years side-by-side with months as rows, enabling year-over-year comparison. Each cell will link to the corresponding week in that year's planner.

## Grid Layout Analysis

### Available Content Area
Using `StandardWithSidebarsLayout`:
- Total grid: 43 cols × 55 rows
- Left sidebar (weeks): 3 cols
- Right sidebar (nav tabs): 1 col
- **Content area: 39 cols × 55 rows**

### Proposed Grid Allocation

**Header section (rows 0-2):**
- Page title: "Multi-Year Overview"
- Year column headers

**Month labels (column 0-2):**
- Month names aligned left
- 3 cols for "September" etc.

**Year data columns:**
- Remaining: 36 cols for year data
- Per year: 36 ÷ N years
  - 2 years: 18 cols each
  - 3 years: 12 cols each
  - 4 years: 9 cols each
  - 6 years: 6 cols each (recommended maximum)

**Row allocation (rows 3-54):**
- 12 months need rows
- Available: 52 rows
- Per month: 52 ÷ 12 = 4.33 boxes
- **Use 4 boxes per month** = 48 rows total
- Leaves 4 rows at bottom for summary/notes

## Component Architecture

### New Classes Required

#### 1. `Pages::MultiYearOverview`
**Location:** `lib/bujo_pdf/pages/multi_year_overview.rb`

**Responsibilities:**
- Set up page layout (use `StandardWithSidebarsLayout`)
- Coordinate rendering of month grid
- Handle year range (e.g., 2024-2027)
- Position month labels and year headers

**Constructor:**
```ruby
def initialize(pdf, start_year, year_count, week_calculator)
  @pdf = pdf
  @start_year = start_year
  @year_count = year_count  # 2-6 recommended
  @week_calculator = week_calculator
end
```

**Key methods:**
```ruby
def setup
  use_layout :standard_with_sidebars,
    current_week: nil,  # No week highlighted
    highlight_tab: :multi_year,  # New tab identifier
    year: @start_year,
    total_weeks: 52
end

def render(content_area)
  draw_header(content_area)
  draw_month_labels(content_area)
  draw_year_columns(content_area)
  draw_grid_lines(content_area)
end
```

#### 2. `Components::MultiYearCell`
**Location:** `lib/bujo_pdf/components/multi_year_cell.rb`

**Responsibilities:**
- Render individual month cell for a specific year
- Calculate which week(s) the month starts in
- Create link annotation to appropriate week page
- Handle edge cases (December/January transitions)

**Interface:**
```ruby
def initialize(pdf, year, month_num, grid_system)
  @pdf = pdf
  @year = year
  @month_num = month_num  # 1-12
  @grid = grid_system
end

def render(col, row, width_boxes, height_boxes)
  # Calculate first day of month
  first_day = Date.new(@year, @month_num, 1)

  # Get week number using DateCalculator
  week_num = calculate_week_number(first_day)

  # Draw cell with week number
  draw_cell_content(col, row, width_boxes, height_boxes, week_num)

  # Add link to week page
  add_week_link(col, row, width_boxes, height_boxes, week_num)
end
```

#### 3. Update `Components::NavigationTabs`
**Location:** `lib/bujo_pdf/components/navigation_tabs.rb`

**Add new tab:**
```ruby
TABS = [
  { label: "Year Events", dest: "year_events" },
  { label: "Year Highlights", dest: "year_highlights" },
  { label: "Multi-Year", dest: "multi_year" },  # NEW
  { label: "Seasonal", dest: "seasonal" },
  { label: "Reference", dest: "reference" }
]
```

## Grid Layout Implementation

### Month Label Column (cols 0-2)
```ruby
def draw_month_labels(content_area)
  MONTH_NAMES = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]

  (0...12).each do |month_idx|
    row = 3 + (month_idx * 4)  # Start at row 3, 4 boxes per month

    grid_text_box(
      MONTH_NAMES[month_idx],
      content_area[:col] + 0,      # Left edge of content
      content_area[:row] + row,    # Row position
      3,                           # Width: 3 boxes
      4,                           # Height: 4 boxes per month
      align: :right,
      valign: :center,
      size: 10
    )
  end
end
```

### Year Column Headers (row 0-2)
```ruby
def draw_header(content_area)
  col_width = 36 / @year_count  # Available cols ÷ years

  (0...@year_count).each do |year_idx|
    year = @start_year + year_idx
    col = content_area[:col] + 3 + (year_idx * col_width)

    grid_text_box(
      year.to_s,
      col,
      content_area[:row] + 0,
      col_width,
      2,
      align: :center,
      valign: :center,
      size: 14,
      style: :bold
    )
  end
end
```

### Year Data Grid
```ruby
def draw_year_columns(content_area)
  col_width = 36 / @year_count

  (0...@year_count).each do |year_idx|
    year = @start_year + year_idx
    base_col = content_area[:col] + 3 + (year_idx * col_width)

    (0...12).each do |month_idx|
      month_num = month_idx + 1
      row = 3 + (month_idx * 4)

      cell = Components::MultiYearCell.new(@pdf, year, month_num, self)
      cell.render(
        base_col,
        content_area[:row] + row,
        col_width,
        4  # Height per month
      )
    end
  end
end
```

### Grid Lines
```ruby
def draw_grid_lines(content_area)
  @pdf.stroke_color COLOR_BORDERS
  @pdf.line_width 0.5

  # Horizontal lines between months
  (0..12).each do |i|
    row = 3 + (i * 4)
    y = grid_y(content_area[:row] + row)

    @pdf.stroke_line(
      [grid_x(content_area[:col]), y],
      [grid_x(content_area[:col] + content_area[:width]), y]
    )
  end

  # Vertical lines between years
  col_width = 36 / @year_count
  (0..@year_count).each do |i|
    col = content_area[:col] + 3 + (i * col_width)
    x = grid_x(col)

    @pdf.stroke_line(
      [x, grid_y(content_area[:row] + 3)],
      [x, grid_y(content_area[:row] + 51)]
    )
  end
end
```

## Week Calculation Logic

### Date-to-Week Mapping
```ruby
class Components::MultiYearCell
  def calculate_week_number(date)
    # Use the same logic as DateCalculator
    year_start = Date.new(date.year, 1, 1)
    days_back = (year_start.wday + 6) % 7  # Monday-based
    year_start_monday = year_start - days_back

    days_from_start = (date - year_start_monday).to_i
    week_num = (days_from_start / 7) + 1
  end

  def draw_cell_content(col, row, w, h, week_num)
    # Display week number in cell
    grid_text_box(
      "W#{week_num}",
      col,
      row,
      w,
      h,
      align: :center,
      valign: :center,
      size: 9
    )
  end

  def add_week_link(col, row, w, h, week_num)
    grid_link(
      col,
      row,
      w,
      h,
      "week_#{week_num}"
    )
  end
end
```

## Integration Points

### 1. Generator Setup (`PlannerGenerator`)
```ruby
def generate
  setup_named_destinations

  # Existing pages...
  generate_seasonal_calendar
  generate_year_at_a_glance_events
  generate_year_at_a_glance_highlights

  # NEW: Add multi-year overview
  generate_multi_year_overview

  # Continue with existing...
  generate_reference_page
  generate_weekly_pages
  # ...
end

def setup_named_destinations
  # Existing destinations...

  # NEW: Multi-year destination
  @pdf.add_dest('multi_year', @pdf.dest_xyz(0, @pdf.page.dimensions[3], nil))
end

def generate_multi_year_overview
  @pdf.start_new_page

  # Generate for 4 years starting with current year
  page = Pages::MultiYearOverview.new(
    @pdf,
    @year,           # Start year
    4,               # Number of years to show
    @date_calculator
  )

  page.setup
  page.render(page.content_area)
end
```

### 2. PDF Outline/Bookmarks
```ruby
def build_outline
  @pdf.outline.update do
    page title: "Seasonal Calendar", destination: 'seasonal'
    page title: "Year at a Glance - Events", destination: 'year_events'
    page title: "Year at a Glance - Highlights", destination: 'year_highlights'

    # NEW
    page title: "Multi-Year Overview", destination: 'multi_year'

    page title: "Reference", destination: 'reference'
    # ... weeks ...
  end
end
```

## Navigation Flow

### From Multi-Year Page
- Click any month cell → jumps to that month's first week
- Right sidebar tabs → navigate to other overview pages
- Left sidebar weeks → navigate to specific weeks (of current year)

### To Multi-Year Page
- Right navigation tabs from any page with `StandardWithSidebarsLayout`
- PDF outline/bookmarks
- Links from weekly pages (optional enhancement)

## Cell Content Options

### Option A: Week Number Only (Simplest)
```
+-------+
| W23   |
+-------+
```

### Option B: Week + Day Count
```
+-------+
| W23   |
| (7d)  |
+-------+
```

### Option C: Week Range
```
+-------+
| W23-26|
+-------+
```
(Show week range spanning the entire month)

### Recommendation
Start with **Option A** (week number only). Clean, simple, aligns with grid system. Add complexity later if needed.

## Edge Cases to Handle

### 1. December/January Transition
- December week may span into next year
- Link to correct year's week page
- Consider visual indicator (color, border)

### 2. 53-Week Years
- Some years have 53 weeks
- Week calculation must handle this
- Cell might show "W53" for late December

### 3. Month Spanning Multiple Weeks
- Most months span 4-5 weeks
- Cell links to **first** week of month
- Consider adding tooltip or annotation

### 4. Multi-Year Planners
If generating planners for multiple years:
```ruby
# Generate linked multi-year set
(2024..2027).each do |year|
  generator = PlannerGenerator.new(year)
  generator.generate
end

# Multi-year page needs cross-PDF links (Prawn limitation)
# Alternative: Generate one mega-PDF with all years
```

## File Structure

```
lib/bujo_pdf/
├── pages/
│   └── multi_year_overview.rb          # NEW
├── components/
│   ├── multi_year_cell.rb              # NEW
│   └── navigation_tabs.rb              # MODIFY (add tab)
├── layouts/
│   └── standard_with_sidebars.rb       # MODIFY (handle new tab)
└── planner_generator.rb                # MODIFY (add generation)
```

## Testing Approach

### 1. Visual Testing
```ruby
# test_multi_year.rb
require_relative 'lib/bujo_pdf/planner_generator'

pdf = Prawn::Document.new(page_size: 'LETTER')
calculator = DateCalculator.new(2024)

page = Pages::MultiYearOverview.new(pdf, 2024, 4, calculator)
page.setup
page.render(page.content_area)

pdf.render_file('test_multi_year.pdf')
```

### 2. Link Testing
- Verify all 48 cells (12 months × 4 years) have clickable links
- Test week number calculations against known dates
- Verify links point to correct week destinations

### 3. Grid Alignment
- Enable `DEBUG_GRID = true`
- Verify cells align to grid intersections
- Check month labels align with cell rows

## Configuration Options

### Command-Line Arguments
```ruby
# gen.rb modifications
year = (ARGV[0] || Date.today.year).to_i
year_count = (ARGV[1] || 4).to_i  # NEW: optional year count

generator = PlannerGenerator.new(year)
generator.set_multi_year_count(year_count)  # Configure years to display
generator.generate
```

### Constants
```ruby
# lib/bujo_pdf/constants.rb

# Multi-Year Layout
MULTI_YEAR_DEFAULT_COUNT = 4
MULTI_YEAR_MAX_COUNT = 6
MULTI_YEAR_MONTH_HEIGHT_BOXES = 4
MULTI_YEAR_MONTH_LABEL_WIDTH = 3
MULTI_YEAR_HEADER_HEIGHT = 2
```

## Future Enhancements

1. **Configurable content per cell:**
   - Week number
   - Important dates/events
   - Mini month calendar
   - Custom text field

2. **Color coding:**
   - Highlight current month across years
   - Season-based background colors
   - Weekend vs weekday distinction

3. **Interactive features:**
   - Hover tooltips (PDF limitation)
   - Alternative: Add legend explaining week numbers

4. **Comparison mode:**
   - Show same month across all years
   - Vertical layout (years as rows, months as columns)

5. **Export/Print optimization:**
   - Landscape orientation option
   - Larger font for projection
   - High-contrast mode

## Implementation Sequence

**Phase 1: Core Structure** (1-2 hours)
1. Create `Pages::MultiYearOverview` skeleton
2. Add named destination and outline entry
3. Integrate into `PlannerGenerator`
4. Test page creation (empty page with title)

**Phase 2: Grid Layout** (2-3 hours)
5. Implement month label column
6. Implement year header row
7. Add grid lines
8. Test with `DEBUG_GRID` enabled

**Phase 3: Cell Content** (2-3 hours)
9. Create `Components::MultiYearCell`
10. Implement week calculation
11. Add week number display
12. Test grid alignment

**Phase 4: Navigation** (1-2 hours)
13. Add link annotations to cells
14. Update `NavigationTabs` component
15. Test all navigation flows

**Phase 5: Polish** (1-2 hours)
16. Styling (fonts, colors, spacing)
17. Edge case handling (53-week years, etc.)
18. Documentation in CLAUDE.md

**Total estimated time: 7-12 hours**

---

This plan provides a complete, grid-aligned multi-year overview page that integrates cleanly with the existing component architecture and navigation system. The 4-year default (2024-2027) fits comfortably in the 39-column content area with 9 boxes per year, leaving clear visual separation between columns.
