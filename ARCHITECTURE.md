# Architecture

This document describes the technical architecture of the BujoPdf planner generator.

## Overview

BujoPdf uses a component-based architecture built on top of the [Prawn PDF library](https://github.com/prawnpdf/prawn). The system is organized into five main layers:

1. **Generator** - Orchestrates PDF creation and page ordering
2. **Pages** - Individual page types (seasonal calendar, weekly pages, etc.)
3. **Layouts** - Declarative layout system with automatic sidebar management
4. **Components** - Reusable UI elements (sidebars, fieldsets, headers)
5. **Utilities** - Core helpers (grid system, date calculations, dot grids)

![System Overview](docs/system-overview.svg)

## Core Concepts

### Grid-Based Layout System

All positioning uses a **grid coordinate system** rather than raw PDF points:

- **Grid dimensions**: 43 columns × 55 rows
- **Box size**: 14.17pt (≈5mm) matching dot spacing
- **Page size**: 612pt × 792pt (US Letter)

**Coordinate conversion methods:**
- `grid_x(col)` - Convert column to x-coordinate
- `grid_y(row)` - Convert row to y-coordinate (row 0 = top)
- `grid_width(boxes)` - Convert box count to width
- `grid_height(boxes)` - Convert box count to height
- `grid_rect(col, row, w, h)` - Get bounding box coordinates

This abstraction ensures all elements align perfectly with the dot grid background.

![Grid System](docs/grid-system.svg)

### Declarative Layout System

Pages declare their layout intent rather than implementing layout details:

```ruby
class MyPage < Pages::Base
  def setup
    use_layout :standard_with_sidebars,
      current_week: @week_num,
      highlight_tab: :year_events,
      year: @year,
      total_weeks: @total_weeks
  end
end
```

**Available layouts:**
- `:full_page` - No sidebars, full 43×55 content area
- `:standard_with_sidebars` - Left week sidebar (3 cols) + right nav tabs (1 col)

Layouts automatically:
- Render navigation sidebars
- Calculate content area boundaries
- Handle highlighting (current week, current tab)

**Benefits:**
- Single source of truth for sidebar behavior
- Changes to sidebars require editing only the layout class
- Pages focus on content, not chrome

![Layout System](docs/layout-system.svg)

### Component Architecture

Reusable components encapsulate UI patterns:

- **WeekSidebar** - Vertical week list with month indicators
- **NavigationTabs** - Rotated tabs for year pages
- **Fieldset** - HTML-like `<fieldset>` boxes with legend labels
- **SeasonLabel** - Rotated text labels for seasonal sections

Components receive a `RenderContext` with PDF object, coordinates, and page state.

![Component Hierarchy](docs/component-hierarchy.svg)

## Key Classes

![Page Generation Flow](docs/page-generation-flow.svg)

### PlannerGenerator (`lib/bujo_pdf/planner_generator.rb`)

**Responsibility**: Generate a complete planner PDF for a specified year

**Main flow** (`generate` method):
1. Create reusable dot grid stamp (reduces file size ~90%)
2. Generate overview pages (seasonal, year events, year highlights, multi-year)
3. Generate weekly pages (52-53 depending on year)
4. Generate template pages (reference, blank dots)
5. Build PDF outline/bookmarks

### PageFactory (`lib/bujo_pdf/page_factory.rb`)

**Responsibility**: Create page instances with dependency injection

Maps page types to classes:
- `:seasonal` → `Pages::SeasonalCalendar`
- `:year_events` → `Pages::YearEvents`
- `:year_highlights` → `Pages::YearHighlights`
- `:weekly` → `Pages::WeeklyPage`
- `:reference` → `Pages::ReferencePage`
- `:dots` → `Pages::BlankDots`

### RenderContext (`lib/bujo_pdf/render_context.rb`)

**Responsibility**: Immutable context object passed to all renderers

Contains:
- PDF object
- Year and week information
- Page tracking (current page, total pages)
- Destination/navigation info

Provides helper methods:
- `current_page?(type)` - Check if on a specific page type
- `weekly_page?` - Check if on a weekly page
- `destination(type)` - Get named destination string

### DateCalculator (`lib/bujo_pdf/utilities/date_calculator.rb`)

**Responsibility**: All date/week calculations for the planner

**Week numbering system:**
- Week 1 starts on the Monday on or before January 1
- Weeks increment sequentially through the year
- Total weeks: typically 52-53 depending on year

**Key methods:**
- `year_start_monday(year)` - First Monday of the year's week 1
- `total_weeks(year)` - Total weeks in the year
- `week_number_for_date(date, year)` - Get week number for any date
- `week_start(year, week)` / `week_end(year, week)` - Week boundaries
- `season_for_month(month)` - Determine season

### GridSystem (`lib/bujo_pdf/utilities/grid_system.rb`)

**Responsibility**: Convert grid coordinates to PDF points

Core module mixed into all page and component classes. See "Grid-Based Layout System" above for details.

### DotGrid (`lib/bujo_pdf/utilities/dot_grid.rb`)

**Responsibility**: Draw dot grid backgrounds

Uses Prawn stamps for efficiency:
```ruby
DotGrid.create_stamp(pdf, "page_dots")  # Create once
pdf.stamp("page_dots")                   # Reuse everywhere
```

Draws dots at every grid intersection (43×55 = 2,365 dots per page).

## Page Types

### Seasonal Calendar (`lib/bujo_pdf/pages/seasonal_calendar.rb`)

- Four seasons in quadrants with fieldset borders
- Mini month calendars with clickable dates
- Each date links to its corresponding weekly page
- Rotated season labels

### Year-at-a-Glance (`lib/bujo_pdf/pages/year_events.rb`, `year_highlights.rb`)

- 12 columns (months) × 31 rows (days)
- Day numbers with day-of-week abbreviations
- Each cell links to corresponding weekly page
- Uses standard layout with navigation tabs

### Multi-Year Overview (`lib/bujo_pdf/pages/multi_year_overview.rb`)

- Spans multiple years with monthly groupings
- Color-coded or formatted for long-term planning
- Provides context beyond the current year

### Weekly Pages (`lib/bujo_pdf/pages/weekly_page.rb`)

- **Daily section** (17.5% of usable height): 7 columns for Mon-Sun
- **Cornell notes section** (82.5%):
  - Cues column (25%)
  - Notes column (75%)
  - Summary area (20% of section)
- Navigation: previous/next week, back to year overview
- Time period labels (AM/PM/EVE) on Monday column

### Reference Page (`lib/bujo_pdf/pages/reference_page.rb`)

- Grid calibration with measurements
- Centimeter markings along edges
- Grid system documentation
- Coordinate system reference

### Blank Dots (`lib/bujo_pdf/pages/blank_dots.rb`)

- Simple full-page dot grid template
- No chrome or navigation

## Navigation System

### Named Destinations

PDF named destinations enable hyperlink navigation:

- `seasonal` - Seasonal calendar page
- `year_events` - Year at a Glance - Events
- `year_highlights` - Year at a Glance - Highlights
- `multi_year_overview` - Multi-year overview page
- `week_N` - Weekly page N (e.g., `week_1`, `week_42`)
- `reference` - Grid reference/calibration page
- `dots` - Blank dot grid page

### Link Annotations

Clickable regions use Prawn's `link_annotation` method:

```ruby
@pdf.link_annotation([left, bottom, right, top],
                    Dest: "week_#{week_num}",
                    Border: [0, 0, 0])
```

Coordinates use `[left, bottom, right, top]` format, all measured from page bottom.

The `grid_link` helper simplifies this:

```ruby
grid_link(col, row, width_boxes, height_boxes, "week_1")
```

## File Organization

```
lib/bujo_pdf/
├── planner_generator.rb      # Main orchestrator
├── page_factory.rb            # Page creation with DI
├── render_context.rb          # Immutable context object
├── constants.rb               # Layout constants
├── pages/                     # Page implementations
│   ├── base.rb
│   ├── seasonal_calendar.rb
│   ├── year_events.rb
│   ├── year_highlights.rb
│   ├── multi_year_overview.rb
│   ├── weekly_page.rb
│   ├── reference_page.rb
│   └── blank_dots.rb
├── layouts/                   # Layout system
│   ├── base_layout.rb
│   ├── full_page_layout.rb
│   ├── standard_with_sidebars_layout.rb
│   └── layout_factory.rb
├── components/                # Reusable UI components
│   ├── week_sidebar.rb
│   ├── navigation_tabs.rb
│   ├── fieldset.rb
│   └── season_label.rb
└── utilities/                 # Core helpers
    ├── grid_system.rb
    ├── date_calculator.rb
    ├── dot_grid.rb
    └── style_helpers.rb
```

## Design Principles

### Single Responsibility

Each class has one clear purpose:
- Pages generate content
- Layouts manage chrome
- Components render reusable UI
- Utilities provide calculations

### Declarative Over Imperative

Pages declare "what" they want (layout type, navigation state) rather than "how" to render it.

### Grid-Based Positioning

All coordinates use the grid system, ensuring perfect alignment with dot backgrounds.

### Immutable Context

`RenderContext` is immutable, preventing state bugs during rendering.

### Dependency Injection

`PageFactory` injects dependencies (PDF, context, utilities) rather than pages creating them.

## Testing Strategy

### Unit Tests (`test/unit/`)

Fast tests (<1 second) for utilities and components:
- **GridSystem**: Coordinate conversion, helpers
- **DateCalculator**: Week numbering, boundaries, edge cases
- **DotGrid**: Position calculations
- **RenderContext**: Initialization, query methods

### Integration Tests (`test/integration/`)

Slower tests (~30 seconds) for full PDF generation:
- Successful generation without errors
- PDF file size validation
- Multi-year generation
- Leap year handling
- Performance benchmarks

### Coverage

- **Overall**: 84%+ coverage
- **Per-file minimum**: 15% (presentation layer harder to test)
- **SimpleCov** reports in `coverage/` directory

## Performance Optimizations

### Dot Grid Stamps

Instead of drawing 2,365 dots per page (43×55 grid), create a stamp once and reuse:

```ruby
DotGrid.create_stamp(@pdf, "page_dots")  # ~90% smaller file size
```

### Efficient Link Annotations

Links use absolute coordinates calculated once, no repeated conversions.

### Minimal Font Embedding

Uses PDF built-in fonts (Helvetica) to reduce file size.

## Extension Points

### Adding New Page Types

1. Create page class in `lib/bujo_pdf/pages/`
2. Inherit from `Pages::Base`
3. Implement `render(content_area)` method
4. Register in `PageFactory`
5. Add to generator flow

### Creating New Layouts

1. Create layout class in `lib/bujo_pdf/layouts/`
2. Inherit from `BaseLayout`
3. Implement `calculate_content_area` and `render_chrome` methods
4. Register symbol in `LayoutFactory`

### Adding Components

1. Create component class in `lib/bujo_pdf/components/`
2. Implement `render(context)` method
3. Mix in `Utilities::GridSystem` if needed
4. Use from pages or layouts

## Debug Mode

Toggle `DEBUG_GRID` in `planner_generator.rb`:

```ruby
DEBUG_GRID = true  # Show diagnostic grid overlay
```

Adds:
- Red dots at grid intersections
- Dashed red lines every 5 boxes
- Coordinate labels `(col, row)`

Useful for verifying layout calculations.

## Further Reading

- **CLAUDE.md** - Detailed technical documentation for Claude Code
- **COMPONENTS.md** - Component design patterns
- **GRID_HELPERS.md** - Grid system helper methods
- **PRAWN_CHEAT_SHEET.md** - Prawn PDF library reference
- **REFACTORING_PLAN.md** - Future architectural improvements
