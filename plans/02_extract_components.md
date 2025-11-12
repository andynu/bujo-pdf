# Plan 02: Extract Components into Reusable Classes

**Status**: Not Started
**Priority**: Phase 2 - High Priority (Building on Foundation)
**Estimated Complexity**: Medium (Reduced from High due to Plan 04)
**Dependencies**:
- Plan 01 (Extract Low-Level Utilities) - ✅ COMPLETED
- Plan 03 (Page Generation Pipeline) - ✅ COMPLETED
- Plan 04 (Extract Reusable Sub-Components) - ✅ COMPLETED ⭐ **KEY DEPENDENCY**

## Quick Reference: Plan 02 Updated for Plan 04

**What changed:** Plan 04 extracted low-level sub-components (WeekColumn, Fieldset, RuledLines, CalendarDays, DayHeader, etc.). Plan 02 now focuses on **page-level coordinators** that compose these sub-components.

**Key concept:**
- **Sub-Components (Plan 04)**: Low-level building blocks with `render_at(col, row, w, h)` interface
- **Components (Plan 02)**: Page-level coordinators that compose sub-components

**Work reduction:** ~40% (from 100-140 hours to 66-86 hours)

**Components still needed:**
1. Component base class (with sub-component factory methods)
2. RenderContext
3. DateCalculator
4. TopNavigation, WeekSidebar, RightSidebar (navigation)
5. SeasonalCalendar, YearAtGlance (calendars - use sub-components)
6. DailySection, CornellNotes, WeeklyPage (weekly page - use sub-components)

---

## Executive Summary

This plan outlines the extraction of page-level components from the monolithic `PlannerGenerator` class into a well-structured component architecture. Building on the foundation established in Plan 01 (grid system, styling, diagnostics), Plan 03 (page generation pipeline), and **Plan 04 (reusable sub-components)**, we will create page-level components that compose together the lower-level sub-components.

**Key distinction from Plan 04:**
- **Plan 04 Sub-Components**: Low-level, reusable building blocks (WeekColumn, Fieldset, RuledLines, DayHeader, etc.)
- **Plan 02 Components**: Page-level coordinators that compose sub-components into complete pages or sections

The component extraction will transform rendering logic from procedural methods into object-oriented components with clear interfaces, dependencies, and responsibilities. This will enable:
- Independent testing of each component
- Reuse across different page types
- Easy customization and theming
- Clear separation of concerns
- Better code organization and maintainability
- Composition of sub-components into higher-level structures

## Relationship with Plan 04 Sub-Components

**Plan 04 completed the extraction of reusable sub-components** that serve as building blocks for Plan 02. Understanding this relationship is critical:

### Sub-Components (Plan 04) vs Components (Plan 02)

| Aspect | Sub-Components (Plan 04) | Components (Plan 02) |
|--------|--------------------------|----------------------|
| **Level** | Low-level building blocks | Page-level coordinators |
| **Base Class** | `SubComponent::Base` | `Component` |
| **Positioning** | `render_at(col, row, w, h)` | `render()` - knows its own position |
| **Responsibilities** | Single UI pattern (e.g., ruled lines, day header) | Compose sub-components into sections/pages |
| **State** | Stateless - configured via options | May hold RenderContext, coordinate sub-components |
| **Examples** | WeekColumn, Fieldset, RuledLines, DayHeader, CalendarDays | DailySection, CornellNotes, SeasonalCalendar, WeeklyPage |

### Available Sub-Components from Plan 04

These are **already implemented** and ready to use:

1. **SubComponent::WeekColumn** - Single day column with header and ruled lines
2. **SubComponent::Fieldset** - HTML-like fieldset with legend border
3. **SubComponent::RuledLines** - Horizontal ruled lines for writing
4. **SubComponent::DayHeader** - Single day header cell
5. **SubComponent::CalendarDays** - Month calendar grid with day links
6. **SubComponent::YearMonths** - Year-month grid (alternative layout)

### How Components Use Sub-Components

**Example: DailySection Component**

```ruby
class Components::DailySection < Component
  def render
    # Create 7 WeekColumn sub-components
    7.times do |i|
      week_column = create_week_column(  # Factory method from Component base
        date: start_date + i,
        day_name: day_names[i],
        weekend: i >= 5
      )

      # Position and render the sub-component
      week_column.render_at(col_for_day(i), row, day_width, height)
    end
  end
end
```

**Key benefits:**
- DailySection focuses on **layout coordination** (7-column positioning)
- WeekColumn handles **rendering details** (header, lines, time labels)
- Both can be tested independently
- WeekColumn can be reused in other contexts

### ComponentContext from Plan 04

The `ComponentContext` helper (from Plan 04) is available for use in components:

```ruby
# Use ComponentContext for local coordinate system + hybrid grid/proportional layout
with_context(col, row, width_boxes, height_boxes) do |ctx|
  # Mix grid quantization and proportional divisions
  day_width = ctx.divide_width(7)         # Proportional: 7 equal parts
  header_height = ctx.grid_height(1.5)    # Grid: 1.5 boxes

  # Local coordinates (0,0 = component origin)
  ctx.text_box "Header", at: [0, ctx.height_pt], width: day_width
end
```

## Technical Approach

### 1. Architecture Overview

We will create a component hierarchy that **builds on top of** the sub-components from Plan 04:

```
SubComponent::Base (from Plan 04)
├── WeekColumn - Single day column with header and ruled lines
├── Fieldset - HTML-like fieldset with legend border
├── RuledLines - Horizontal ruled lines for writing
├── DayHeader - Single day header cell
├── CalendarDays - Month calendar grid
└── YearMonths - Year-month grid

Component (Base Class) - NEW in Plan 02
├── Navigation Components (Page-level coordinators)
│   ├── TopNavigation - Week page navigation (prev/next, year link, title)
│   ├── WeekSidebar - Left sidebar with week list
│   └── RightSidebar - Right sidebar with tabbed navigation
├── Page Components (Complete page coordinators)
│   ├── SeasonalCalendar - Full seasonal calendar layout (uses Fieldset, CalendarDays)
│   ├── YearAtGlance - 12×31 grid for events/highlights
│   └── WeeklyPage - Complete weekly page layout (uses all components)
└── Section Components (Page section coordinators)
    ├── DailySection - 7-day horizontal view (uses WeekColumn sub-components)
    └── CornellNotes - Cues/Notes/Summary layout (uses RuledLines sub-components)
```

**Key relationships:**
- **Sub-Components** (Plan 04): Stateless renderers, positioned via `render_at(col, row, width, height)`
- **Components** (Plan 02): Page-level coordinators that use ComponentContext and compose sub-components
- **Component → Sub-Component**: Components instantiate and position sub-components

### 2. Component Base Class Design

Every component will inherit from a base `Component` class that provides:
- Access to PDF instance
- Access to GridSystem instance
- Access to RenderContext (current page, navigation state)
- **Factory methods for creating sub-components** (NEW - from Plan 04)
- Standard lifecycle: `initialize`, `render`, `validate`
- Helper methods for common operations
- Consistent error handling

```ruby
class Component
  attr_reader :pdf, :grid_system, :context

  def initialize(pdf, grid_system, context = {})
    @pdf = pdf
    @grid_system = grid_system
    @context = context
    validate_context
  end

  # Main rendering method - must be implemented by subclasses
  def render
    raise NotImplementedError, "#{self.class} must implement #render"
  end

  # Override in subclasses to validate required context
  def validate_context
    # No-op in base class
  end

  protected

  # Convenience delegators to grid_system
  def grid_x(col); @grid_system.x(col); end
  def grid_y(row); @grid_system.y(row); end
  def grid_width(boxes); @grid_system.width(boxes); end
  def grid_height(boxes); @grid_system.height(boxes); end
  def grid_rect(col, row, w, h); @grid_system.rect(col, row, w, h); end
  def grid_link(col, row, w, h, dest); @grid_system.link(col, row, w, h, dest); end
  def grid_text_box(text, col, row, w, h, **opts)
    @grid_system.text_box(text, col, row, w, h, **opts)
  end

  # Factory methods for creating sub-components (from Plan 04)
  def create_sub_component(klass, **options)
    klass.new(@pdf, @grid_system, **options)
  end

  def create_week_column(**options)
    create_sub_component(SubComponent::WeekColumn, **options)
  end

  def create_fieldset(**options)
    create_sub_component(SubComponent::Fieldset, **options)
  end

  def create_ruled_lines(**options)
    create_sub_component(SubComponent::RuledLines, **options)
  end

  def create_day_header(**options)
    create_sub_component(SubComponent::DayHeader, **options)
  end

  def create_calendar_days(**options)
    create_sub_component(SubComponent::CalendarDays, **options)
  end

  # Helper: create ComponentContext for local coordinate system (from Plan 04)
  def with_context(col, row, width_boxes, height_boxes, &block)
    box = grid_rect(col, row, width_boxes, height_boxes)
    ComponentContext.new(@pdf, box[:x], box[:y], box[:width], box[:height], &block)
  end
end
```

**Integration with Plan 04:**
- Components use `create_*` factory methods to instantiate sub-components
- Components call `sub_component.render_at(col, row, width, height)` to position them
- Components can use `with_context` for local coordinate systems
- Sub-components handle their own rendering logic

### 3. Context Object Design

The `RenderContext` will carry state information through the rendering pipeline:

```ruby
class RenderContext
  attr_reader :year, :current_page, :total_pages, :page_type
  attr_accessor :week_num, :total_weeks, :start_date

  def initialize(year:, page_type: :unknown)
    @year = year
    @page_type = page_type
    @current_page = nil
    @total_pages = nil
    @week_num = nil
    @total_weeks = nil
    @start_date = nil
  end

  def weekly_page?
    page_type == :weekly
  end

  def overview_page?
    [:seasonal, :year_events, :year_highlights].include?(page_type)
  end

  def navigation_enabled?
    # Determine if navigation should be shown
    true
  end
end
```

## Implementation Steps

### 1. Create Component Infrastructure

**Files to create:**
- `lib/bujo_pdf/component.rb` - Base Component class
- `lib/bujo_pdf/render_context.rb` - Context object
- `lib/bujo_pdf/components/` - Directory for component classes

**Key decisions:**
- Components should be stateless where possible (state in context)
- All rendering parameters passed via context or constructor
- Components should not directly modify global state
- Components should be independently testable

**Testing approach:**
- Mock PDF and GridSystem for unit tests
- Test each component with various context scenarios
- Verify coordinate calculations
- Test edge cases (first week, last week, empty months, etc.)

### 2. Extract Layout Components

#### 2.1 Fieldset Component → **Extracted in Plan 04**

**Status:** ✅ **Completed in Plan 04 as SubComponent::Fieldset**

This component was extracted as a **sub-component** in Plan 04 (Extract Reusable Sub-Components). It is now available for use by page-level components in Plan 02.

**Location:** `lib/bujo_pdf/sub_components/fieldset.rb`

**Usage in Plan 02 components:**
```ruby
# In SeasonalCalendar or other components
fieldset = create_fieldset(
  legend: "Winter",
  legend_position: :top_left,
  legend_rotation: 90,
  inset_boxes: 0.5
)
fieldset.render_at(col, row, width_boxes, height_boxes)
```

**No additional work needed** - use the existing sub-component.

#### 2.2 Footer Component

**Current location:** `gen.rb:1572-1574` (draw_footer method - currently empty)

**Complexity:** Low
- Currently unused/empty
- Placeholder for future functionality
- Low priority for extraction

**Decision:** **Defer extraction until footer functionality is implemented**

**Future design considerations:**
- Page numbers
- Copyright/attribution
- Custom footer text
- Dynamic content based on page type

### 3. Extract Navigation Components

#### 3.1 TopNavigation Component

**Current location:** `gen.rb:1051-1113` (within draw_weekly_page)

**Complexity:** Medium
- Conditional rendering (first/last week)
- Multiple clickable links
- Centered title with side navigation
- Gray styling for links

**Extracted logic:**
- Year link (always present)
- Previous week link (if not first week)
- Next week link (if not last week)
- Week title with date range

**Component interface:**
```ruby
class Components::TopNavigation < Component
  def validate_context
    raise ArgumentError, "week_num required" unless context[:week_num]
    raise ArgumentError, "total_weeks required" unless context[:total_weeks]
    raise ArgumentError, "start_date required" unless context[:start_date]
    raise ArgumentError, "year required" unless context[:year]
  end

  def render
    draw_year_link
    draw_prev_week_link if show_prev?
    draw_next_week_link if show_next?
    draw_title
  end

  private

  def show_prev?
    context[:week_num] > 1
  end

  def show_next?
    context[:week_num] < context[:total_weeks]
  end

  def draw_year_link
    # Link to seasonal calendar
  end

  def draw_prev_week_link
    # Link to previous week
  end

  def draw_next_week_link
    # Link to next week
  end

  def draw_title
    # Centered week title with date range
  end
end
```

**Testing strategy:**
- Test first week (no previous link)
- Test last week (no next link)
- Test middle week (both links)
- Test single-week year (edge case)
- Test date formatting across year boundary

**Grid positioning:**
- Rows 0-1 (2 boxes)
- Columns 3-41 (content area, 39 boxes)
- Internal layout: [Year: 4 boxes] [Prev: 3 boxes] [Title: centered] [Next: 3 boxes]

#### 3.2 WeekSidebar Component

**Current location:** `gen.rb:1242-1318` (draw_week_sidebar method)

**Complexity:** Medium-High
- Dynamic height based on total weeks (52-53)
- Month letter indicators at week starts
- Current week highlighting
- Clickable links for all weeks except current

**Extracted logic:**
- Week number calculation
- Month letter mapping
- Week-to-row positioning
- Current week detection and styling

**Component interface:**
```ruby
class Components::WeekSidebar < Component
  def validate_context
    # current_week_num can be nil (for overview pages)
    raise ArgumentError, "total_weeks required" unless context[:total_weeks]
    raise ArgumentError, "year required" unless context[:year]
  end

  def render
    calculate_month_week_mapping
    render_week_list
  end

  private

  def calculate_month_week_mapping
    # Build hash of week_num => month_letter
    # Identifies which week each month starts in
  end

  def render_week_list
    # Draw each week with proper formatting
    # Highlight current week if specified
    # Add links to all other weeks
  end

  def current_week?(week_num)
    context[:current_week_num] == week_num
  end

  def format_week_label(week_num)
    # "w42" or "J w1" (with month letter)
  end
end
```

**Grid positioning:**
- Columns 0-1 (2 boxes wide)
- Rows 2-54 (53 rows, one per week)
- Internal padding: 0.5 boxes on each side

**Testing strategy:**
- Test with 52 weeks
- Test with 53 weeks
- Test month boundaries (first week of each month)
- Test current week highlighting
- Test nil current_week (overview pages)
- Test year starting on different days of week

**Performance considerations:**
- Month-week mapping calculated once per render
- Consider caching for multiple page renders
- Minimize date calculations

#### 3.3 RightSidebar Component

**Current location:** `gen.rb:1320-1367` (draw_right_sidebar_nav, draw_right_sidebar methods)

**Complexity:** Medium
- Two-way stacking (top-down, bottom-up)
- Rotated text in tabs
- Automatic positioning calculation
- Configurable tab height

**Extracted logic:**
- Tab positioning (top-aligned, bottom-aligned)
- Text rotation
- Link creation
- Declarative menu definition

**Component interface:**
```ruby
class Components::RightSidebar < Component
  def initialize(pdf, grid_system, context = {})
    super
    @top_tabs = context.fetch(:top_tabs, [])
    @bottom_tabs = context.fetch(:bottom_tabs, [])
    @start_row = context.fetch(:start_row, 1)
    @tab_height = context.fetch(:tab_height, 3)
    @sidebar_col = context.fetch(:sidebar_col, 42)
  end

  def render
    render_top_tabs
    render_bottom_tabs
  end

  private

  def render_top_tabs
    @top_tabs.each_with_index do |tab, idx|
      row = @start_row + (idx * @tab_height)
      render_tab(row, tab[:label], tab[:dest], align: :left)
    end
  end

  def render_bottom_tabs
    @bottom_tabs.each_with_index do |tab, idx|
      row = Styling::Grid::ROWS - @tab_height - (idx * @tab_height)
      render_tab(row, tab[:label], tab[:dest], align: :right)
    end
  end

  def render_tab(row, label, dest, align:)
    # Delegate to draw_right_nav_tab or inline implementation
  end
end
```

**Sub-component: RightNavTab**

Extract the `draw_right_nav_tab` method as a separate helper component:

```ruby
class Components::RightNavTab
  # Stateless helper for rendering a single tab
  def self.render(pdf, grid_system, col, row, height_boxes, label, dest, align: :left, padding_boxes: 0.5)
    # Rotated text + clickable link
  end
end
```

**Grid positioning:**
- Column 42 (at right edge, 1 box wide)
- Top tabs: start at row 1, stack downward
- Bottom tabs: start at row 52, stack upward
- Each tab: 3 boxes tall (default)

**Testing strategy:**
- Test with 0 tabs (should render nothing)
- Test with only top tabs
- Test with only bottom tabs
- Test with both
- Test tab collision (too many tabs)
- Test different tab heights
- Test text rotation and alignment

### 4. Extract Calendar Components

#### 4.1 SeasonalCalendar Component

**Current location:** `gen.rb:524-677` (draw_seasonal_calendar, draw_season_grid, draw_month_grid methods)

**Complexity:** High → **Reduced by composing sub-components**
- Multi-level layout (seasons → months → calendars)
- **Uses Fieldset sub-component** for season borders (from Plan 04)
- **Uses CalendarDays sub-component** for month calendars (from Plan 04)
- Coordinates positioning of 12 months across 2 columns
- Handles season grouping logic

**Component hierarchy (updated with sub-components):**
```
SeasonalCalendar (parent component)
├── Uses Fieldset sub-component (Plan 04) for season borders
└── Uses CalendarDays sub-component (Plan 04) for each month (×12)
```

**Component interface (using sub-components):**
```ruby
class Components::SeasonalCalendar < Component
  def validate_context
    raise ArgumentError, "year required" unless context[:year]
  end

  def render
    draw_header
    draw_seasons
  end

  private

  def draw_header
    # Year title in rows 0-1
    grid_text_box(context[:year].to_s, 0, 0, 43, 2,
                  align: :center, valign: :center, size: 18, style: :bold)
  end

  def draw_seasons
    # Left column: Winter (Jan-Feb), Spring (Mar-Jun)
    draw_season_grid("Winter", [1, 2], start_col: 2, start_row: 2, width: 20)
    draw_season_grid("Spring", [3, 4, 5, 6], start_col: 2, start_row: 20, width: 20)

    # Right column: Summer (Jul-Aug), Fall (Sep-Nov), Winter (Dec)
    draw_season_grid("Summer", [7, 8], start_col: 22, start_row: 2, width: 21)
    draw_season_grid("Fall", [9, 10, 11], start_col: 22, start_row: 20, width: 21)
    draw_season_grid("Winter", [12], start_col: 22, start_row: 47, width: 21)
  end

  def draw_season_grid(season_name, months, start_col:, start_row:, width:)
    height = calculate_season_height(months.size)

    # Use Fieldset sub-component (from Plan 04) for season border
    fieldset = create_fieldset(
      legend: season_name,
      legend_position: :top_left,
      legend_rotation: 90,
      inset_boxes: 0.5
    )
    fieldset.render_at(start_col, start_row, width, height)

    # Render each month using CalendarDays sub-component (from Plan 04)
    months.each_with_index do |month, idx|
      month_row = start_row + (idx * 9) + 1  # Offset for spacing

      calendar = create_calendar_days(
        year: context[:year],
        month: month,
        show_month_header: true,
        link_to_weeks: true
      )
      calendar.render_at(start_col + 1, month_row, width - 2, 8)
    end
  end

  def calculate_season_height(num_months)
    # Each month: 8 boxes + 1 gutter = 9 boxes per month
    (num_months * 9)
  end
end
```

**Benefits of using sub-components:**
- Fieldset sub-component handles all border and legend logic
- CalendarDays sub-component handles month calendar rendering, week links, etc.
- SeasonalCalendar focuses on season grouping and positioning
- Changes to calendar appearance isolated to CalendarDays sub-component
- Can easily test Fieldset and CalendarDays independently

**Season definitions:**
```ruby
SEASONS = {
  left_column: [
    { name: "Winter", months: [1, 2] },      # Jan-Feb
    { name: "Spring", months: [3, 4, 5, 6] } # Mar-Jun
  ],
  right_column: [
    { name: "Summer", months: [7, 8] },      # Jul-Aug
    { name: "Fall", months: [9, 10, 11] },   # Sep-Nov
    { name: "Winter", months: [12] }         # Dec
  ]
}
```

**Grid positioning:**
- Header: rows 0-1, full width (43 boxes)
- Label offset: 2 boxes on left for season labels
- Left column: columns 2-21 (20 boxes)
- Right column: columns 22-42 (21 boxes)
- Seasons start at row 2

**Testing strategy:**
- Test all 12 months render
- Test season boundaries
- Test fieldset positioning
- Test month grid alignment
- Test leap year (February with 29 days)
- Test years starting on different weekdays
- Test week number calculations

#### 4.2 CalendarDays Component → **Extracted in Plan 04**

**Status:** ✅ **Completed in Plan 04 as SubComponent::CalendarDays**

This component was extracted as a **sub-component** in Plan 04 (Extract Reusable Sub-Components). It renders month calendar grids with clickable day links.

**Location:** `lib/bujo_pdf/sub_components/calendar_days.rb`

**Usage in Plan 02 components:**
```ruby
# In SeasonalCalendar or YearAtGlance
calendar = create_calendar_days(
  year: 2025,
  month: 1,
  show_month_header: true,
  link_to_weeks: true
)
calendar.render_at(col, row, width_boxes, height_boxes)
```

**No additional work needed** - use the existing sub-component.

#### 4.3 YearAtGlance Component

**Current location:** `gen.rb:813-954` (draw_year_at_glance method)

**Complexity:** High
- 12 columns (months) × 31 rows (days)
- Fractional box calculations
- Month headers with week links
- Day cells with dual text (number + abbreviation)
- Empty cells for non-existent days (e.g., Feb 30)
- Click links for each day

**Component interface:**
```ruby
class Components::YearAtGlance < Component
  def validate_context
    raise ArgumentError, "year required" unless context[:year]
    raise ArgumentError, "title required" unless context[:title]
  end

  def render
    draw_header
    draw_month_headers
    draw_days_grid
  end

  private

  def draw_header
    # Title in rows 0-1 (2 boxes)
  end

  def draw_month_headers
    # Row 2: 12 month abbreviations
    # Each clickable (links to first week of month)
  end

  def draw_days_grid
    # Rows 3-52: 31 days × 12 months
    # Day height: 50 boxes / 31 days ≈ 1.613 boxes per day
    # Complex fractional positioning
  end

  def draw_day_cell(month, day_num, x, y, width, height)
    # Day number
    # Day abbreviation (Mo, Tu, etc.)
    # Week link
  end

  def draw_empty_cell(x, y, width, height)
    # Gray background for non-existent days
  end
end
```

**Grid positioning:**
- Content area: columns 3-41 (39 boxes)
- Header: rows 0-1 (2 boxes)
- Month headers: row 2 (1 box)
- Days: rows 3-52 (50 rows for 31 days, fractional heights)
- Column width: 39 / 12 ≈ 3.25 boxes per month

**Fractional calculations:**
- Day height: 50 / 31 ≈ 1.6129 boxes per day
- Must use floating point arithmetic
- Accumulation of rounding errors?
- Test alignment with grid at boundaries

**Testing strategy:**
- Test all 12 months render
- Test 31-day months (Jan, Mar, May, Jul, Aug, Oct, Dec)
- Test 30-day months (Apr, Jun, Sep, Nov)
- Test February (28 and 29 days)
- Test empty cell rendering
- Test fractional positioning accuracy
- Test week link destinations
- Test clickable areas don't overlap

**Performance considerations:**
- 372 cells (12 months × 31 days)
- Each with border, text, and link
- Consider optimizing bounding box usage
- Batch similar operations

#### 4.4 WeeklyPage Component

**Current location:** `gen.rb:1011-1234` (draw_weekly_page method)

**Complexity:** Very High
- Complete page layout with multiple sections
- Uses TopNavigation, WeekSidebar, RightSidebar components
- Contains DailySection and CornellNotes sub-components
- Complex grid calculations

**Component hierarchy:**
```
WeeklyPage (coordinator)
├── TopNavigation
├── WeekSidebar
├── RightSidebar
├── DailySection
└── CornellNotes
```

**Component interface:**
```ruby
class Components::WeeklyPage < Component
  def validate_context
    raise ArgumentError, "start_date required" unless context[:start_date]
    raise ArgumentError, "week_num required" unless context[:week_num]
    raise ArgumentError, "total_weeks required" unless context[:total_weeks]
    raise ArgumentError, "year required" unless context[:year]
  end

  def render
    # This is a coordinator component that delegates to sub-components
    render_background
    render_navigation
    render_content
  end

  private

  def render_background
    # Dot grid stamp
    # Debug grid overlay
  end

  def render_navigation
    Components::TopNavigation.new(@pdf, @grid_system, navigation_context).render
    Components::WeekSidebar.new(@pdf, @grid_system, sidebar_context).render
    Components::RightSidebar.new(@pdf, @grid_system, right_sidebar_context).render
  end

  def render_content
    Components::DailySection.new(@pdf, @grid_system, daily_context).render
    Components::CornellNotes.new(@pdf, @grid_system, notes_context).render
  end

  def navigation_context
    {
      week_num: context[:week_num],
      total_weeks: context[:total_weeks],
      start_date: context[:start_date],
      year: context[:year]
    }
  end

  def sidebar_context
    {
      current_week_num: context[:week_num],
      total_weeks: context[:total_weeks],
      year: context[:year]
    }
  end

  def right_sidebar_context
    {
      top_tabs: [
        { label: "Year", dest: "seasonal" },
        { label: "Events", dest: "year_events" },
        { label: "Highlights", dest: "year_highlights" }
      ],
      bottom_tabs: [
        { label: "Dots", dest: "dots" }
      ]
    }
  end

  def daily_context
    {
      start_date: context[:start_date],
      content_start_col: 3,
      content_start_row: 2,
      content_width_boxes: 39,
      daily_rows: 9
    }
  end

  def notes_context
    {
      content_start_col: 3,
      notes_start_row: 11,  # After daily section
      cues_cols: 10,
      notes_cols: 29,
      notes_main_rows: 35,
      summary_rows: 9
    }
  end
end
```

**Grid layout:**
- Columns 0-2: Left sidebar (WeekSidebar)
- Columns 3-41: Content area (39 boxes)
- Column 42: Right sidebar (RightSidebar)
- Rows 0-1: Top navigation (2 boxes)
- Rows 2-10: Daily section (9 boxes)
- Rows 11-45: Cues/Notes (35 boxes)
- Rows 46-54: Summary (9 boxes)

**Testing strategy:**
- Test with different weeks (first, middle, last)
- Test component integration
- Test context passing
- Test with 52 and 53 week years
- Test date ranges across month/year boundaries
- Test all sub-components render

#### 4.5 DailySection Component

**Current location:** `gen.rb:1115-1179` (within draw_weekly_page)

**Complexity:** Medium-High → **Reduced with Sub-Components**
- 7 columns (Monday-Sunday)
- **Uses WeekColumn sub-component** for each day (from Plan 04)
- Coordinates positioning using ComponentContext
- Handles weekend background shading configuration

**Component interface (using sub-components):**
```ruby
class Components::DailySection < Component
  def validate_context
    raise ArgumentError, "start_date required" unless context[:start_date]
    raise ArgumentError, "content_start_col required" unless context[:content_start_col]
    raise ArgumentError, "content_start_row required" unless context[:content_start_row]
    raise ArgumentError, "content_width_boxes required" unless context[:content_width_boxes]
    raise ArgumentError, "daily_rows required" unless context[:daily_rows]
  end

  def render
    # Use ComponentContext for proportional column division
    with_context(context[:content_start_col],
                 context[:content_start_row],
                 context[:content_width_boxes],
                 context[:daily_rows]) do |ctx|

      day_width_boxes = context[:content_width_boxes] / 7.0

      7.times do |i|
        render_day_column(i, day_width_boxes)
      end
    end
  end

  private

  def render_day_column(day_index, day_width_boxes)
    date = context[:start_date] + day_index
    col = context[:content_start_col] + (day_index * day_width_boxes)

    # Create WeekColumn sub-component (from Plan 04)
    week_column = create_week_column(
      date: date,
      day_name: date.strftime("%A"),
      rows: context[:daily_rows],
      show_time_labels: day_index == 0,  # Monday only
      line_spacing_boxes: 1.5,
      header_size_boxes: 1.5,
      weekend: weekend?(day_index)
    )

    # Position and render the sub-component
    week_column.render_at(col, context[:content_start_row],
                          day_width_boxes, context[:daily_rows])
  end

  def weekend?(day_index)
    day_index == 5 || day_index == 6  # Saturday or Sunday
  end
end
```

**Benefits of using WeekColumn sub-component:**
- Daily column rendering logic encapsulated in WeekColumn
- DailySection focuses on layout/positioning (7-column division)
- WeekColumn handles headers, ruled lines, time labels internally
- Reusable: WeekColumn can be used in other contexts (e.g., different layouts)
- Testable: WeekColumn can be tested independently

**Grid positioning:**
- Rows 2-10 (9 boxes tall)
- Columns 3-41 (39 boxes wide)
- Column width: 39 / 7 ≈ 5.57 boxes per day

**Layout details:**
- Header: ~30pt (day name + date)
- Lines: 4 ruled lines evenly spaced
- Line spacing: calculated from available space
- Time labels: 6pt font, only on Monday column

**Testing strategy:**
- Test all 7 days render
- Test weekend shading (Saturday, Sunday)
- Test time labels only on Monday
- Test date formatting
- Test weeks spanning months
- Test weeks spanning years

#### 4.6 CornellNotes Component

**Current location:** `gen.rb:1181-1233` (within draw_weekly_page)

**Complexity:** Medium → **Simplified with Sub-Components**
- Three sections: Cues, Notes, Summary
- **Uses RuledLines sub-component** for each section (from Plan 04)
- Handles proportional layout (25%/75% width split)
- Section headers and borders

**Component interface (using sub-components):**
```ruby
class Components::CornellNotes < Component
  def validate_context
    raise ArgumentError, "content_start_col required" unless context[:content_start_col]
    raise ArgumentError, "notes_start_row required" unless context[:notes_start_row]
    raise ArgumentError, "cues_cols required" unless context[:cues_cols]
    raise ArgumentError, "notes_cols required" unless context[:notes_cols]
    raise ArgumentError, "notes_main_rows required" unless context[:notes_main_rows]
    raise ArgumentError, "summary_rows required" unless context[:summary_rows]
  end

  def render
    draw_cues_section
    draw_notes_section
    draw_summary_section
  end

  private

  def draw_cues_section
    # Draw section border and header
    cues_box = grid_rect(context[:content_start_col],
                         context[:notes_start_row],
                         context[:cues_cols],
                         context[:notes_main_rows])

    @pdf.bounding_box([cues_box[:x], cues_box[:y]],
                      width: cues_box[:width],
                      height: cues_box[:height]) do
      @pdf.text "Cues/Questions", size: 8, style: :bold
      @pdf.stroke_bounds

      # Use RuledLines sub-component (from Plan 04)
      ruled_lines = create_ruled_lines(
        line_spacing_boxes: 1.5,
        margin_left_boxes: 0.5,
        margin_right_boxes: 0.5,
        skip_first: true  # Skip header area
      )
      ruled_lines.render_at(context[:content_start_col], context[:notes_start_row] + 1,
                            context[:cues_cols], context[:notes_main_rows] - 1)
    end
  end

  def draw_notes_section
    # Similar pattern with RuledLines for notes area
    notes_col = context[:content_start_col] + context[:cues_cols]

    # Draw border and header, then use RuledLines sub-component
    ruled_lines = create_ruled_lines(
      line_spacing_boxes: 1.5,
      margin_left_boxes: 0.5,
      margin_right_boxes: 0.5,
      skip_first: true
    )
    ruled_lines.render_at(notes_col, context[:notes_start_row] + 1,
                          context[:notes_cols], context[:notes_main_rows] - 1)
  end

  def draw_summary_section
    # Use RuledLines for summary area
    summary_row = context[:notes_start_row] + context[:notes_main_rows]
    total_width = context[:cues_cols] + context[:notes_cols]

    ruled_lines = create_ruled_lines(
      line_spacing_boxes: 1.5,
      margin_left_boxes: 0.5,
      margin_right_boxes: 0.5,
      skip_first: true
    )
    ruled_lines.render_at(context[:content_start_col], summary_row + 1,
                          total_width, context[:summary_rows] - 1)
  end
end
```

**Benefits of using RuledLines sub-component:**
- Line rendering logic encapsulated and reusable
- Consistent line spacing across all sections
- Easy to adjust spacing, margins, and style
- CornellNotes focuses on section layout, not line drawing

**Grid positioning:**
- Cues: columns 3-12 (10 boxes)
- Notes: columns 13-41 (29 boxes)
- Main area: rows 11-45 (35 boxes)
- Summary: rows 46-54 (9 boxes), full width

**Layout ratios:**
- Cues: 25% of content width
- Notes: 75% of content width
- Main area: 80% of notes section
- Summary: 20% of notes section

**Testing strategy:**
- Test section dimensions
- Test borders render correctly
- Test headers positioned properly
- Test dot grid shows through (transparent background)

### 5. Create DateCalculator Utility

**Purpose:** Extract date and week calculation logic

**Current locations:**
- Week number calculation: repeated in multiple places
- Year start Monday calculation: repeated
- Date range calculations

**Utility interface:**
```ruby
class DateCalculator
  attr_reader :year

  def initialize(year)
    @year = year
  end

  # Get the Monday on or before January 1
  def year_start_monday
    @year_start_monday ||= calculate_year_start_monday
  end

  # Calculate week number for a given date
  def week_number(date)
    days_from_start = (date - year_start_monday).to_i
    (days_from_start / 7) + 1
  end

  # Calculate total weeks in the year
  def total_weeks
    @total_weeks ||= calculate_total_weeks
  end

  # Get start date for a given week number
  def week_start_date(week_num)
    year_start_monday + ((week_num - 1) * 7)
  end

  # Get end date for a given week number
  def week_end_date(week_num)
    week_start_date(week_num) + 6
  end

  # Get first week of a given month
  def first_week_of_month(month)
    first_of_month = Date.new(year, month, 1)
    week_number(first_of_month)
  end

  private

  def calculate_year_start_monday
    first_day = Date.new(year, 1, 1)
    days_back = (first_day.wday + 6) % 7
    first_day - days_back
  end

  def calculate_total_weeks
    first_day = Date.new(year, 1, 1)
    last_day = Date.new(year, 12, 31)
    start_date = year_start_monday

    week_num = 0
    current_date = start_date

    while current_date <= last_day || week_num == 0
      week_num += 1
      current_date += 7
    end

    week_num
  end
end
```

**Usage in components:**
```ruby
# In component initialize or render
date_calc = DateCalculator.new(context[:year])
week_num = date_calc.week_number(date)
```

**Testing strategy:**
- Test years starting on each day of week
- Test leap years vs non-leap years
- Test 52-week years
- Test 53-week years
- Test week number accuracy for each day of year
- Test edge cases (Jan 1, Dec 31)
- Test month boundaries

### 6. Update PlannerGenerator

**Changes required:**
1. Require all component files
2. Create RenderContext instance
3. Replace rendering methods with component calls
4. Pass context to components
5. Remove extracted methods
6. Update tests

**Example transformation:**

Before:
```ruby
def generate_seasonal_calendar
  @pdf.add_dest("seasonal", @pdf.dest_fit)
  @pdf.stamp("page_dots")
  draw_diagnostic_grid(label_every: 5)
  draw_week_sidebar(nil, calculate_total_weeks)
  draw_right_sidebar
  draw_seasonal_calendar
  draw_footer
end
```

After:
```ruby
def generate_seasonal_calendar
  @pdf.add_dest("seasonal", @pdf.dest_fit)
  @pdf.stamp("page_dots")
  draw_diagnostic_grid(label_every: 5)

  context = RenderContext.new(year: @year, page_type: :seasonal)
  context.total_weeks = @date_calculator.total_weeks

  Components::SeasonalCalendar.new(@pdf, @grid_system, context).render

  # Sidebars
  sidebar_context = { total_weeks: context.total_weeks, year: @year }
  Components::WeekSidebar.new(@pdf, @grid_system, sidebar_context).render
  Components::RightSidebar.new(@pdf, @grid_system, default_right_sidebar_context).render
end
```

### 7. Create Component Tests

**Test structure:**
```
test/
  components/
    test_fieldset.rb
    test_top_navigation.rb
    test_week_sidebar.rb
    test_right_sidebar.rb
    test_seasonal_calendar.rb
    test_month_grid.rb
    test_year_at_glance.rb
    test_weekly_page.rb
    test_daily_section.rb
    test_cornell_notes.rb
  utilities/
    test_date_calculator.rb
  test_all.rb
```

**Test approach for components:**
1. Mock PDF with test double
2. Create real GridSystem instance
3. Provide minimal context
4. Verify PDF method calls (text_box, link_annotation, etc.)
5. Verify coordinates are within bounds
6. Test edge cases

**Example test:**
```ruby
require 'minitest/autorun'
require_relative '../../lib/bujo_pdf/component'
require_relative '../../lib/bujo_pdf/components/fieldset'

class TestFieldset < Minitest::Test
  def setup
    @pdf = Minitest::Mock.new
    @grid_system = GridSystem.new(@pdf)
  end

  def test_render_top_left_position
    context = {
      col: 5,
      row: 10,
      width_boxes: 20,
      height_boxes: 15,
      legend: "Test",
      position: :top_left
    }

    fieldset = Components::Fieldset.new(@pdf, @grid_system, context)

    # Set up expectations for PDF method calls
    @pdf.expect(:font, nil, ["Helvetica-Bold", { size: 12 }])
    @pdf.expect(:width_of, 30.0, ["Test"])
    @pdf.expect(:stroke_color, nil, [String])
    # ... more expectations

    fieldset.render

    @pdf.verify
  end

  def test_validates_required_context
    assert_raises(KeyError) do
      Components::Fieldset.new(@pdf, @grid_system, {})
    end
  end
end
```

## Migration Strategy

### Phase 1: Foundation (Week 1-2)
1. ✅ **COMPLETED IN PLAN 04:** Sub-components extracted (WeekColumn, Fieldset, RuledLines, etc.)
2. ✅ **COMPLETED IN PLAN 04:** ComponentContext helper created
3. ✅ **COMPLETED IN PLAN 01:** GridSystem, Styling utilities
4. ✅ **COMPLETED IN PLAN 03:** Page generation pipeline
5. Create Component base class (Plan 02 specific)
6. Create RenderContext class
7. Create DateCalculator utility
8. Set up component test infrastructure
9. Add factory methods to Component base class for sub-components

**Deliverables:**
- `lib/bujo_pdf/component.rb` (NEW - with sub-component factory methods)
- `lib/bujo_pdf/render_context.rb` (NEW)
- `lib/bujo_pdf/utilities/date_calculator.rb` (NEW)
- Test infrastructure for components
- ✅ Sub-components already available from Plan 04

### Phase 2: Navigation Components (Week 2-3)
1. ✅ Extract TopNavigation
2. ✅ Extract WeekSidebar
3. ✅ Extract RightSidebar (including RightNavTab)
4. ✅ Test all navigation components
5. ✅ Update PlannerGenerator to use navigation components

**Deliverables:**
- `lib/bujo_pdf/components/top_navigation.rb`
- `lib/bujo_pdf/components/week_sidebar.rb`
- `lib/bujo_pdf/components/right_sidebar.rb`
- `lib/bujo_pdf/components/right_nav_tab.rb`
- Tests for all above
- Updated PlannerGenerator

### Phase 3: Calendar Components (Week 3-4)
1. Extract SeasonalCalendar (composes Fieldset and CalendarDays sub-components)
2. Extract YearAtGlance
3. Test both components
4. Update PlannerGenerator

**Deliverables:**
- `lib/bujo_pdf/components/seasonal_calendar.rb` (uses sub-components)
- `lib/bujo_pdf/components/year_at_glance.rb`
- Tests for both
- Updated PlannerGenerator

**Note:** Fieldset and CalendarDays sub-components already exist from Plan 04

### Phase 4: Weekly Page Components (Week 4-5)
1. Extract DailySection (composes WeekColumn sub-components)
2. Extract CornellNotes (composes RuledLines sub-components)
3. Extract WeeklyPage coordinator
4. Test all components
5. Update PlannerGenerator

**Deliverables:**
- `lib/bujo_pdf/components/daily_section.rb` (uses WeekColumn sub-components)
- `lib/bujo_pdf/components/cornell_notes.rb` (uses RuledLines sub-components)
- `lib/bujo_pdf/components/weekly_page.rb`
- Tests for all
- Updated PlannerGenerator

**Note:** WeekColumn, RuledLines, and DayHeader sub-components already exist from Plan 04

### Phase 5: Integration and Cleanup (Week 5-6)
1. ✅ Remove old methods from PlannerGenerator
2. ✅ Full integration testing
3. ✅ Visual regression testing
4. ✅ Performance testing
5. ✅ Documentation updates
6. ✅ Code review and refactoring

**Deliverables:**
- Cleaned up PlannerGenerator
- Comprehensive test suite
- Updated documentation (CLAUDE.md, CLAUDE.local.md)
- Performance benchmarks

## Detailed Component Specifications

### Component File Structure

```
lib/bujo_pdf/
  component.rb                    # Base Component class
  render_context.rb              # RenderContext class
  components/
    # Layout components
    fieldset.rb                  # Fieldset with legend
    footer.rb                    # Footer (future)

    # Navigation components
    top_navigation.rb            # Weekly page top nav
    week_sidebar.rb              # Left sidebar week list
    right_sidebar.rb             # Right sidebar tabs
    right_nav_tab.rb             # Single right sidebar tab

    # Calendar components
    seasonal_calendar.rb         # Full seasonal calendar
    month_grid.rb                # Single month mini-calendar
    year_at_glance.rb            # 12×31 events/highlights grid

    # Weekly page components
    weekly_page.rb               # Complete weekly page
    daily_section.rb             # 7-day horizontal view
    cornell_notes.rb             # Cues/Notes/Summary layout

  utilities/
    date_calculator.rb           # Date/week calculations
    grid_system.rb               # Grid coordinate system
    dot_grid.rb                  # Dot grid rendering
    diagnostics.rb               # Debug overlays
    styling.rb                   # Colors and constants
```

### Context Object Specifications

**RenderContext:**
- `year` (Integer): The year being generated
- `page_type` (Symbol): :seasonal, :year_events, :year_highlights, :weekly, :reference, :dots
- `current_page` (Integer, optional): Current PDF page number
- `total_pages` (Integer, optional): Total pages in document
- `week_num` (Integer, optional): Current week number (for weekly pages)
- `total_weeks` (Integer): Total weeks in year (52 or 53)
- `start_date` (Date, optional): Week start date (for weekly pages)

**Component-specific context:**
- Each component documents required context keys
- Use `validate_context` to check for required keys
- Raise `ArgumentError` for missing required context
- Provide sensible defaults for optional context

### Error Handling

**Component validation:**
```ruby
class Component
  def validate_context
    # Override in subclasses
  end

  def require_context(*keys)
    keys.each do |key|
      unless context.key?(key)
        raise ArgumentError, "#{self.class.name} requires :#{key} in context"
      end
    end
  end
end
```

**Usage:**
```ruby
class Components::TopNavigation < Component
  def validate_context
    require_context(:week_num, :total_weeks, :start_date, :year)
  end
end
```

**Graceful degradation:**
- Components should fail fast with clear error messages
- Context validation happens in initialize
- Rendering errors should not leave PDF in bad state
- Consider adding rescue blocks for non-critical features

### Performance Considerations

**Component instantiation:**
- Components are created per render (not reused)
- Keep initialization lightweight
- Heavy calculations in render or memoized methods

**Grid calculations:**
- GridSystem methods are fast (simple arithmetic)
- No need to cache grid_x, grid_y results
- Complex layouts may benefit from precalculating positions

**PDF operations:**
- Minimize bounding_box nesting
- Batch similar operations (e.g., all borders, then all text)
- Use stamps for repeated elements (already done for dot grid)

**Date calculations:**
- DateCalculator caches expensive operations
- Week number lookups are O(1) after initialization
- Consider precomputing week-to-month mapping

### Testing Strategy

**Unit tests for each component:**
- Test with minimal context
- Mock PDF to verify method calls
- Test edge cases and boundary conditions
- Test validation logic

**Integration tests:**
- Test components working together
- Test full page generation
- Compare PDF output with baseline
- Visual regression testing (optional)

**Test helpers:**
```ruby
module ComponentTestHelper
  def mock_pdf
    Minitest::Mock.new
  end

  def real_grid_system
    pdf = mock_pdf
    GridSystem.new(pdf)
  end

  def minimal_context(**overrides)
    { year: 2025 }.merge(overrides)
  end
end
```

## Risk Assessment

### Low Risk
- **Base Component class:** Simple, well-defined interface
- **RenderContext:** Plain data object, easy to test
- **DateCalculator:** Pure functions, easy to test
- **Simple components:** Fieldset, MonthGrid, Footer

### Medium Risk
- **Navigation components:** Multiple interdependencies
- **Calendar components:** Complex layout calculations
- **Context passing:** Need to maintain consistency
- **Test coverage:** Ensuring all edge cases are covered

### High Risk
- **WeeklyPage coordinator:** Integrates many components
- **YearAtGlance:** Fractional box calculations, rounding errors
- **Breaking existing functionality:** Must maintain visual output
- **Performance:** Component overhead vs monolithic code

### Mitigation Strategies

1. **Incremental extraction:** One component at a time
2. **Backward compatibility:** Keep old methods as wrappers during transition
3. **Comprehensive testing:** Unit + integration + visual tests
4. **Visual verification:** Generate PDFs and compare before/after
5. **Performance monitoring:** Measure generation time
6. **Clear interfaces:** Document context requirements
7. **Code reviews:** Peer review for each component
8. **Rollback plan:** Git branches for easy rollback

## Success Criteria

### Functional Requirements
- [ ] All pages render identically to before refactoring
- [ ] All hyperlinks work correctly
- [ ] All components render in correct positions
- [ ] No visual differences in generated PDFs
- [ ] All date calculations are accurate

### Code Quality Requirements
- [ ] Each component has unit tests with >90% coverage
- [ ] All components have clear documentation
- [ ] Context requirements are documented and validated
- [ ] No code duplication between components
- [ ] Components are independently testable
- [ ] Clear separation of concerns

### Architecture Requirements
- [ ] Component base class provides consistent interface
- [ ] RenderContext carries all necessary state
- [ ] DateCalculator handles all date/week calculations
- [ ] Components are in separate files under lib/bujo_pdf/components/
- [ ] No circular dependencies
- [ ] Clean require statements

### Performance Requirements
- [ ] PDF generation time within 10% of baseline
- [ ] No memory leaks or excessive memory usage
- [ ] Component instantiation overhead minimal

### Documentation Requirements
- [ ] Each component has header documentation
- [ ] Context requirements documented
- [ ] CLAUDE.md updated with component architecture
- [ ] REFACTORING_PLAN.md updated
- [ ] Example usage for each component

## Dependencies

### External Dependencies
- `prawn` ~> 2.4 (already a dependency)
- `date` (built-in Ruby library)
- Testing framework: `minitest` (already added in Plan 01)

### Internal Dependencies
```
Component (base class)
  ├── GridSystem (from Plan 01)
  ├── Styling (from Plan 01)
  └── RenderContext (new)

DateCalculator (new utility)
  └── Date (Ruby stdlib)

All Components
  ├── Component (base class)
  ├── GridSystem
  └── RenderContext

SeasonalCalendar
  ├── Fieldset (component)
  └── MonthGrid (component)

WeeklyPage
  ├── TopNavigation (component)
  ├── WeekSidebar (component)
  ├── RightSidebar (component)
  ├── DailySection (component)
  └── CornellNotes (component)

PlannerGenerator (updated)
  ├── All Components
  ├── DateCalculator
  └── RenderContext
```

### Dependency Graph
```
Styling (no dependencies)
  └── GridSystem
      └── Component (base)
          ├── All component implementations
          └── RenderContext
              └── DateCalculator

PlannerGenerator
  ├── GridSystem
  ├── DateCalculator
  ├── RenderContext
  └── All Components
```

## Future Enhancements

### Component System Enhancements
1. **Component composition DSL:**
   ```ruby
   layout do
     header TopNavigation, height: 2
     sidebar WeekSidebar, width: 2
     content do
       section DailySection, height: 9
       section CornellNotes, height: 44
     end
   end
   ```

2. **Theme system:**
   - Inject theme colors into components
   - Dark mode, light mode, colorful mode
   - Custom font choices

3. **Component library:**
   - More calendar views (monthly, quarterly)
   - Different note-taking layouts (bullet journal, hourly)
   - Custom decorative elements

4. **Dynamic layouts:**
   - Responsive sizing based on content
   - User-configurable layouts
   - A/B testing different layouts

### Advanced Features
1. **Context highlighting:**
   - Highlight current week in sidebars
   - Active tab indication
   - Current month highlighting

2. **Interactive PDFs:**
   - Form fields for notes
   - JavaScript actions
   - Navigation enhancements

3. **Accessibility:**
   - Alt text for screen readers
   - High contrast modes
   - Tagged PDF structure

4. **Performance optimizations:**
   - Component caching
   - Lazy rendering
   - Parallel page generation

## Summary of Changes from Original Plan

This updated version of Plan 02 reflects the completion of Plan 04 (Extract Reusable Sub-Components). Key changes:

### What's Different

1. **Leverages existing sub-components** instead of building from scratch
   - Fieldset → Use `SubComponent::Fieldset` from Plan 04
   - MonthGrid → Use `SubComponent::CalendarDays` from Plan 04
   - Individual day columns → Use `SubComponent::WeekColumn` from Plan 04
   - Ruled lines → Use `SubComponent::RuledLines` from Plan 04

2. **Component focus shifted** from rendering to coordination
   - **Old approach:** Components render everything themselves
   - **New approach:** Components compose sub-components and handle positioning

3. **Added factory methods** to Component base class
   - `create_week_column(**options)`
   - `create_fieldset(**options)`
   - `create_ruled_lines(**options)`
   - `create_calendar_days(**options)`
   - etc.

4. **Can use ComponentContext** from Plan 04 for hybrid layouts
   - Mix grid quantization (alignment) with proportional divisions (equal spacing)
   - Local coordinate systems within components

### Work Reduction

**Original estimate:** 100-140 hours

**Reduced estimate:** ~60-80 hours (40% reduction)

**Reason:** Many low-level rendering components already extracted as sub-components in Plan 04. Components in Plan 02 now focus on coordination and composition rather than low-level rendering.

### Components Still Needed

Only page-level coordinators remain:
1. ✅ Component base class (with sub-component factory methods)
2. ✅ RenderContext
3. ✅ DateCalculator utility
4. TopNavigation (week page navigation)
5. WeekSidebar (left sidebar)
6. RightSidebar (right sidebar tabs)
7. SeasonalCalendar (composes Fieldset + CalendarDays)
8. YearAtGlance (12×31 grid)
9. DailySection (composes WeekColumn × 7)
10. CornellNotes (composes RuledLines for 3 sections)
11. WeeklyPage (coordinator for all weekly components)

## Notes

- All components should follow the single responsibility principle
- Components focus on **coordination and composition**, not low-level rendering
- Sub-components (Plan 04) handle **rendering details**
- Use composition over inheritance
- Document all context requirements
- Validate context in initialize
- Test edge cases thoroughly
- Keep components focused on their coordination role
- Use descriptive variable names
- Add comments for complex logic
- Follow Ruby style guide

## References

- **Original code:** `gen.rb` (full file)
- **Plan 01:** Extract Low-Level Utilities (completed)
- **Plan 03:** Page Generation Pipeline (completed)
- **Plan 04:** Extract Reusable Sub-Components (completed) ← **Key dependency**
- **REFACTORING_PLAN.md:** Overall refactoring strategy
- **CLAUDE.md:** Project documentation
- **CLAUDE.local.md:** Grid system documentation
- **Prawn documentation:** https://prawnpdf.org/
- **Ruby style guide:** https://rubystyle.guide/

### Plan 04 Documentation

Refer to `PLANS/04_EXTRACT_REUSABLE_SUB_COMPONENTS.md` for:
- SubComponent::Base class design
- ComponentContext helper for local coordinates
- Available sub-components (WeekColumn, Fieldset, RuledLines, etc.)
- Sub-component configuration options
- Examples of sub-component usage

## Timeline Estimate (Updated for Plan 04 Completion)

### Week 1: Foundation (12-16 hours) ← Reduced
- Component base class: 4 hours
- RenderContext class: 2 hours
- DateCalculator utility: 6 hours (includes testing edge cases)
- Test infrastructure: 2 hours
- ✅ ~~Fieldset component~~ Already done in Plan 04
- ✅ ~~MonthGrid component~~ Already done in Plan 04

### Week 2: Navigation (16-20 hours) ← Unchanged
- TopNavigation: 5 hours
- WeekSidebar: 6 hours
- RightSidebar + RightNavTab: 5 hours
- Integration and testing: 4 hours

### Week 3: Calendar (12-16 hours) ← Reduced
- SeasonalCalendar: 6 hours (simpler with sub-components)
- YearAtGlance: 6 hours
- Testing and debugging: 4 hours

### Week 4: Weekly Page (14-18 hours) ← Reduced
- DailySection: 5 hours (uses WeekColumn sub-components)
- CornellNotes: 4 hours (uses RuledLines sub-components)
- WeeklyPage coordinator: 5 hours
- Integration and testing: 4 hours

### Week 5: Integration and Cleanup (12-16 hours) ← Reduced
- Remove old methods: 3 hours
- Full integration testing: 4 hours
- Visual regression testing: 3 hours
- Documentation: 4 hours
- Code review and final refactoring: 4 hours

**Total Estimate: 66-86 hours (~40% reduction from original 100-140 hours)**

**At 10 hours/week: 7-9 weeks (vs original 10-14 weeks)**

**Reason for reduction:** Low-level rendering logic already extracted to sub-components in Plan 04. Components now focus on coordination, which is simpler and faster to implement.

## Completion Checklist

### Foundation
- [ ] Component base class created (with sub-component factory methods)
- [ ] RenderContext class created
- [ ] DateCalculator utility created and tested
- [ ] Test infrastructure set up
- [✅] ~~Fieldset component~~ Completed in Plan 04 as SubComponent::Fieldset
- [✅] ~~MonthGrid component~~ Completed in Plan 04 as SubComponent::CalendarDays
- [✅] Sub-components available from Plan 04 (WeekColumn, RuledLines, DayHeader, etc.)

### Navigation Components
- [ ] TopNavigation component extracted and tested
- [ ] WeekSidebar component extracted and tested
- [ ] RightSidebar component extracted and tested
- [ ] RightNavTab helper extracted and tested
- [ ] Navigation components integrated into PlannerGenerator

### Calendar Components
- [ ] SeasonalCalendar component extracted and tested
- [ ] YearAtGlance component extracted and tested
- [ ] Calendar components integrated into PlannerGenerator

### Weekly Page Components
- [ ] DailySection component extracted and tested
- [ ] CornellNotes component extracted and tested
- [ ] WeeklyPage coordinator created and tested
- [ ] Weekly page components integrated into PlannerGenerator

### Integration and Cleanup
- [ ] Old methods removed from PlannerGenerator
- [ ] Full integration tests passing
- [ ] Visual regression tests passing
- [ ] Performance benchmarks within acceptable range
- [ ] Documentation updated (CLAUDE.md, CLAUDE.local.md)
- [ ] REFACTORING_PLAN.md updated
- [ ] Code reviewed and approved
- [ ] All tests passing (unit + integration)
- [ ] PDF generation verified working correctly

### Final Verification
- [ ] Generate PDF for multiple years (2024, 2025, 2026)
- [ ] Verify all pages render correctly
- [ ] Verify all links work
- [ ] Verify file size is reasonable
- [ ] Verify generation time is acceptable
- [ ] No warnings or errors in output
- [ ] Code is clean and well-documented
- [ ] Ready for next phase (Gem Structure or Layout Management)
