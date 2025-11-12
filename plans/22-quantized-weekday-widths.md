# Plan #22: Quantized Weekday Column Width Component

## Context Analysis

The current system likely renders weekday columns (Mon-Sun) with varying widths to maximize space utilization. This creates visual inconsistency when the same 7-day grid appears in different contexts (seasonal calendar mini-months, year-at-a-glance grids, weekly page daily sections). Quantizing to normalized widths creates a consistent visual rhythm across the planner.

## 1. Core Component Design

### Location
`lib/bujo_pdf/components/week_grid.rb`

### Component: `WeekGrid`

This component renders a 7-column week-based grid with optionally quantized column widths.

**Key Responsibilities:**
- Calculate column widths (quantized or proportional)
- Render column boundaries and headers
- Provide cell positioning for content
- Support both grid-box-based and absolute point-based positioning

**Parameters:**
```ruby
WeekGrid.new(
  pdf: @pdf,
  x: grid_x(5),              # Left edge (points or grid coords)
  y: grid_y(10),             # Top edge (points or grid coords)
  width: grid_width(35),     # Total width (points or grid boxes)
  height: grid_height(20),   # Total height (points or grid boxes)
  quantize: true,            # Enable/disable quantization
  first_day: :monday,        # Week start day
  show_headers: true,        # Render day labels
  header_height: 14.17,      # Height reserved for headers
  cell_callback: ->(day_index, cell_rect) { }  # Optional cell renderer
)
```

## 2. Quantization Logic

### Algorithm

**When `quantize: true` and `width` is divisible by 7 boxes:**

```ruby
def calculate_column_widths
  total_boxes = (@width / DOT_SPACING).round

  if @quantize && (total_boxes % 7 == 0)
    # Quantized mode: equal box widths
    boxes_per_column = total_boxes / 7
    widths = Array.new(7, boxes_per_column * DOT_SPACING)
  else
    # Proportional mode: divide available space equally
    width_per_column = @width / 7.0
    widths = Array.new(7, width_per_column)
  end

  widths
end
```

**Result:**
- **Quantized (35 boxes ÷ 7 = 5 boxes/column):** Each column is exactly 5 boxes (70.85pt) wide, aligning perfectly with dot grid
- **Proportional (37 boxes ÷ 7 = 5.29 boxes/column):** Each column is 75.1pt wide, maximizing space but not grid-aligned

### Visual Benefit

With quantization, all week grids across the planner share identical column widths when using the same box count, creating visual consistency:

- Seasonal calendar mini-months: 7 boxes ÷ 7 days = 1 box/day
- Year-at-a-glance: 35 boxes ÷ 7 days = 5 boxes/day
- Weekly page daily section: 35 boxes ÷ 7 days = 5 boxes/day

User's eye recognizes the repeated rhythm immediately.

## 3. Component Interface

### Rendering Methods

```ruby
class WeekGrid
  def render
    draw_column_dividers if @show_dividers
    draw_headers if @show_headers
    render_cells
  end

  def cell_rect(day_index)
    # Returns {x:, y:, width:, height:} for the given day (0=Monday...6=Sunday)
    col_x = @x + @column_widths[0...day_index].sum
    {
      x: col_x,
      y: @y - (@show_headers ? @header_height : 0),
      width: @column_widths[day_index],
      height: @height - (@show_headers ? @header_height : 0)
    }
  end

  def each_cell
    # Yields day_index (0-6) and cell_rect for each column
    7.times do |day_index|
      yield day_index, cell_rect(day_index)
    end
  end

  private

  def draw_headers
    day_labels = %w[M T W T F S S]  # Or full names based on space
    @column_widths.each_with_index do |width, i|
      x_offset = @column_widths[0...i].sum
      @pdf.text_box day_labels[i],
                    at: [@x + x_offset, @y],
                    width: width,
                    height: @header_height,
                    align: :center,
                    valign: :center,
                    size: 8
    end
  end

  def render_cells
    return unless @cell_callback

    each_cell do |day_index, rect|
      @cell_callback.call(day_index, rect)
    end
  end
end
```

## 4. Integration with Existing Grid System

### Grid-Aware Constructor

Allow component to accept grid coordinates directly:

```ruby
class WeekGrid
  def self.from_grid(pdf:, col:, row:, width_boxes:, height_boxes:, **opts)
    new(
      pdf: pdf,
      x: grid_x(col),
      y: grid_y(row),
      width: grid_width(width_boxes),
      height: grid_height(height_boxes),
      **opts
    )
  end
end
```

**Usage:**
```ruby
# Direct point-based
WeekGrid.new(pdf: @pdf, x: 100, y: 700, width: 400, height: 200, quantize: true)

# Grid-based (preferred)
WeekGrid.from_grid(pdf: @pdf, col: 5, row: 10, width_boxes: 35, height_boxes: 15, quantize: true)
```

### Helper Extension

Add to `lib/bujo_pdf/utilities/grid_system.rb`:

```ruby
def week_grid(col, row, width_boxes, height_boxes, **opts)
  WeekGrid.from_grid(
    pdf: @pdf,
    col: col,
    row: row,
    width_boxes: width_boxes,
    height_boxes: height_boxes,
    **opts
  )
end
```

## 5. Pages/Components That Benefit

### 5.1 Seasonal Calendar (`lib/bujo_pdf/pages/seasonal_calendar.rb`)

**Current:** Mini-month calendars with manually calculated day columns

**Refactored:**
```ruby
def render_mini_month(month, col_start, row_start, boxes_wide, boxes_tall)
  grid = week_grid(col_start, row_start, boxes_wide, boxes_tall,
                   quantize: true,
                   show_headers: true,
                   header_height: grid_height(0.5))

  grid.each_cell do |day_index, rect|
    # Render date numbers using rect coordinates
    render_date_in_cell(month, day_index, rect)
  end
end
```

### 5.2 Year-at-a-Glance Pages (`year_events.rb`, `year_highlights.rb`)

**Current:** Day columns with varying widths based on total available space

**Refactored:**
```ruby
def render_month_column(month_num, col_start, boxes_wide)
  # Month header
  grid_text_box(Date::MONTHNAMES[month_num], col_start, 2, boxes_wide, 1, align: :center)

  # Weekday headers (quantized for consistency)
  weekday_grid = week_grid(col_start, 3, boxes_wide, 1,
                            quantize: true,
                            show_headers: true,
                            header_height: grid_height(1))

  # Day rows (31 max)
  31.times do |day_num|
    row = 4 + day_num
    date = Date.new(@year, month_num, day_num + 1) rescue next

    day_col = date.wday  # 0=Sunday...6=Saturday
    cell = weekday_grid.cell_rect(day_col)

    # Render day number with link to week
    render_day_cell(date, cell[:x], grid_y(row), cell[:width])
  end
end
```

### 5.3 Weekly Page Daily Section (`weekly_page.rb`)

**Current:** 7 equal columns for Mon-Sun with manual width calculation

**Refactored:**
```ruby
def render_daily_section
  content = layout_content_area  # From layout system

  daily_grid = WeekGrid.new(
    pdf: @pdf,
    x: content[:x],
    y: content[:y],
    width: content[:width],
    height: grid_height(8),  # Daily section height
    quantize: true,
    show_headers: true,
    header_height: grid_height(1),
    cell_callback: ->(day_index, cell) {
      render_daily_cell(@week_dates[day_index], cell)
    }
  )

  daily_grid.render
end

def render_daily_cell(date, cell_rect)
  # Draw ruled lines, day number, etc.
  @pdf.bounding_box([cell_rect[:x], cell_rect[:y]],
                    width: cell_rect[:width],
                    height: cell_rect[:height]) do
    # Content rendering
  end
end
```

## 6. Trade-offs Analysis

### Space Utilization vs. Visual Consistency

| Aspect | Quantized (Box-Aligned) | Proportional (Max Space) |
|--------|-------------------------|--------------------------|
| **Space efficiency** | May waste 0-6 boxes of horizontal space | Uses all available space |
| **Visual consistency** | Identical column widths across pages when using same box count | Column widths vary by context |
| **Grid alignment** | Borders align with dot grid | Borders may fall between dots |
| **Cognitive load** | Lower - user sees repeated pattern | Higher - user must adjust to varying widths |
| **Flexibility** | Constrained to multiples of 7 boxes | Works with any width |

### Specific Scenarios

**Scenario 1: Year-at-a-glance with 42-box content area**
- **Quantized:** 42 ÷ 7 = 6 boxes/day (perfect fit, no waste)
- **Proportional:** 6 boxes/day (same result)
- **Winner:** Tie

**Scenario 2: Weekly page with 39-box content area**
- **Quantized:** Uses 35 boxes (5/day), wastes 4 boxes (2.8mm on each side as margin)
- **Proportional:** 5.57 boxes/day (uses all 39 boxes, columns not grid-aligned)
- **Winner:** Depends on priority - consistency vs. space

**Scenario 3: Mini-month in seasonal calendar with 8-box width**
- **Quantized:** Uses 7 boxes (1/day), wastes 1 box
- **Proportional:** 1.14 boxes/day (columns not grid-aligned)
- **Winner:** Quantized - cleaner 1-box-per-day rhythm

### Recommendation

**Default to `quantize: true`** for most use cases because:

1. **Visual consistency matters more** in a planner - users flip between pages constantly
2. **Wasted space is minimal** (at most 6 boxes = 85pt = 30mm across entire width)
3. **Grid alignment aids hand-drawn annotations** - users can extend column dividers naturally
4. **Manufacturing tolerance** - if printing with die-cutting, aligned grids simplify tooling

**Use `quantize: false`** only when:
- Space is genuinely constrained (e.g., narrow sidebar)
- Context is isolated (grid appears only once, not repeated)
- Content doesn't align with weekly rhythm anyway

## 7. Implementation Phases

### Phase 1: Core Component
1. Create `lib/bujo_pdf/components/week_grid.rb`
2. Implement width calculation with quantization logic
3. Add rendering methods (headers, dividers, cells)
4. Write unit tests for width calculation edge cases

### Phase 2: Grid System Integration
1. Add `week_grid` helper to `grid_system.rb`
2. Add `from_grid` constructor to component
3. Update `Component` base class if needed

### Phase 3: Refactor Existing Pages
1. **Seasonal calendar** - Replace mini-month rendering
2. **Year-at-a-glance** - Replace weekday header logic
3. **Weekly page** - Replace daily section column calculation

### Phase 4: Enhancements
1. Add `weekend_highlight` option to shade Sat/Sun cells
2. Add `week_start` param to support Sunday-first calendars
3. Add `border_style` param for different divider styles
4. Consider `month_grid` variant for Mon-Sun × Week1-5 grids

## 8. Testing Considerations

### Edge Cases
- Width not divisible by 7 with `quantize: true` (fall back to proportional)
- Zero or negative dimensions (raise error)
- Width too narrow for headers (skip headers or abbreviate)
- Different `first_day` values (test Monday vs. Sunday start)

### Visual Regression Tests
Generate PDFs with:
- Quantized grid at 35 boxes (5 boxes/day)
- Quantized grid at 42 boxes (6 boxes/day)
- Proportional grid at 37 boxes (non-divisible)
- Compare column widths and alignment with dot grid

## 9. Documentation Requirements

### CLAUDE.md Updates
Add section under "Components":

```markdown
### WeekGrid Component

Renders week-based 7-column grids with optional quantization for visual consistency.

**Key feature**: When `quantize: true` and width is divisible by 7 grid boxes,
columns align exactly with the dot grid and have identical widths across all
pages using the same box count.

**Usage:**
```ruby
week_grid(col, row, width_boxes, height_boxes, quantize: true).render
```

**Parameters:**
- `quantize`: Enable box-aligned column widths (default: true)
- `show_headers`: Render M/T/W/T/F/S/S labels (default: true)
- `first_day`: Week start day (default: :monday)
- `cell_callback`: Proc for custom cell rendering
```

### CLAUDE.local.md Updates
Add example to "Common Layout Patterns":

```markdown
### Week-Based Grid (7 Columns)
```ruby
# Quantized: 35 boxes → 5 boxes/day (grid-aligned)
grid = week_grid(5, 10, 35, 15, quantize: true)
grid.each_cell do |day_index, rect|
  # rect is {x:, y:, width:, height:} for this day
  @pdf.stroke_rectangle([rect[:x], rect[:y]], rect[:width], rect[:height])
end
```

## 10. Future Enhancements

### Month Grid Variant
Similar component for month-view grids (7 cols × 5-6 rows):

```ruby
MonthGrid.from_grid(pdf: @pdf, col: 5, row: 10, width_boxes: 35, height_boxes: 30,
                    quantize: true, month: Date.new(2025, 3, 1))
```

### Responsive Quantization
Auto-select optimal box count based on available width:

```ruby
# If given 37 boxes, automatically use 35 (quantized) and return 2-box margin
grid = week_grid(5, 10, 37, 15, quantize: :auto)
grid.margin_boxes  # => 2 (1 box on each side)
```

### Style Presets
Predefined configurations for common use cases:

```ruby
WeekGrid.mini_month(...)       # 1 box/day, single-letter headers
WeekGrid.year_overview(...)    # 5 boxes/day, abbreviated headers
WeekGrid.weekly_detail(...)    # 6+ boxes/day, full day names
```

---

## Summary

This plan creates a reusable, grid-aware component that solves the weekday column width inconsistency problem while respecting the existing grid system architecture. The quantization approach prioritizes visual consistency and grid alignment over maximal space utilization, which is the correct trade-off for a planner where users frequently flip between related pages. The component integrates cleanly with existing helper methods and can be adopted incrementally across the three main page types that render week-based grids.
