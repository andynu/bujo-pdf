# Bujo-PDF Architecture

This document provides a comprehensive overview of the bujo-pdf planner generator architecture, including system components, data flow, and design patterns.

## Table of Contents

1. [System Overview](#system-overview)
2. [Page Generation Flow](#page-generation-flow)
3. [Layout System](#layout-system)
4. [Component Hierarchy](#component-hierarchy)
5. [Grid System](#grid-system)
6. [Design Principles](#design-principles)
7. [Key Patterns](#key-patterns)

---

## System Overview

The bujo-pdf generator is built on a modular architecture with clear separation of concerns across five main modules.

![System Overview](system-overview.svg)

### Core Modules

**PlannerGenerator** - Central orchestrator that coordinates the entire PDF generation process. Manages the Prawn PDF document, sets up named destinations, and delegates to specialized page generators.

**Pages Module** - Contains specialized page classes, each responsible for rendering a specific page type:
- `SeasonalCalendar` - Four-season calendar overview with mini month calendars
- `YearEvents` / `YearHighlights` - 12×31 grids for tracking events and highlights
- `WeeklyPage` - Weekly spread with daily sections and Cornell notes
- `ReferencePage` - Grid calibration and system documentation
- `BlankDotsPage` - Template page with dot grid

**Layouts Module** - Declarative layout system that handles page chrome (sidebars, navigation):
- `BaseLayout` - Abstract base with lifecycle hooks
- `FullPageLayout` - No sidebars, full page content
- `StandardWithSidebarsLayout` - Week sidebar + navigation tabs
- `LayoutFactory` - Creates layout instances by symbol name

**Components Module** - Reusable UI components:
- `WeekSidebar` - Vertical week list with month indicators and click targets
- `NavigationTabs` - Rotated tabs for year overview pages
- `Fieldset` - Bordered sections with legend labels (HTML-like `<fieldset>`)
- `DotGrid` - Dot grid background renderer

**Utilities Module** - Helper classes providing cross-cutting functionality:
- `GridSystem` - Grid-based coordinate system (43×55 grid)
- `DateCalculator` - Week numbering and date calculations

---

## Page Generation Flow

The generator follows a sequential process to build the complete planner PDF.

![Page Generation Flow](page-generation-flow.svg)

### Generation Steps

1. **Initialization** - User runs `bin/bujo-pdf generate [year]`
2. **PDF Setup** - PlannerGenerator creates Prawn document, configures fonts and page size
3. **Named Destinations** - Registers navigation targets (`seasonal`, `year_events`, `week_N`, etc.)
4. **Seasonal Calendar** - Generates four-season overview page with mini calendars
5. **Year at a Glance** - Creates Events and Highlights grids (12 months × 31 days)
6. **Reference Page** - Generates calibration grid with measurements and documentation
7. **Weekly Pages Loop** - Iterates through 52-53 weeks, generating one page per week
8. **Blank Template** - Creates blank dot grid page for custom content
9. **PDF Outline** - Builds bookmark structure for navigation
10. **Output** - Saves to `planner_{year}.pdf`

### Key Data Flows

- Year parameter flows from CLI → Generator → all page classes
- Week numbers calculated by DateCalculator → used in WeeklyPage and navigation
- Content area boundaries calculated by layouts → passed to page render methods
- Named destinations registered early → referenced by link annotations throughout

---

## Layout System

The layout system implements a declarative approach where pages declare their layout intent rather than implementation details.

![Layout System](layout-system.svg)

### Layout Lifecycle

```ruby
# Page declares layout intent
class WeeklyPage < Pages::Base
  def setup
    use_layout :standard_with_sidebars,
      current_week: @week_num,
      highlight_tab: nil,
      year: @year,
      total_weeks: @total_weeks
  end
end
```

**Execution Flow:**

1. Page calls `use_layout(type, options)` in `setup` method
2. `LayoutFactory.create(type)` instantiates appropriate layout class
3. Layout's `render_before` hook executes:
   - Renders navigation sidebars (week list, year tabs)
   - Calculates content area boundaries
   - Stores content_area in `@layout_state`
4. Page's `render(content_area)` method executes with calculated boundaries
5. Layout's `render_after` hook executes (currently empty, for future enhancements)

### Layout Types

**StandardWithSidebarsLayout**
- Left sidebar: 3 columns (week list 1-52/53)
- Right sidebar: 1 column (year page tabs)
- Content area: 39 columns × 55 rows
- Used by: WeeklyPage, YearEvents, YearHighlights

**FullPageLayout**
- No sidebars
- Content area: 43 columns × 55 rows (full page)
- Used by: SeasonalCalendar, ReferencePage, BlankDotsPage

### Benefits

- **Single source of truth** - Sidebar rendering logic exists only in layout classes
- **DRY principle** - Pages don't duplicate sidebar code
- **Easy modification** - Change sidebar behavior in one place
- **Clear separation** - Layout concerns separated from content concerns

---

## Component Hierarchy

Components provide reusable rendering functionality that can be composed by layouts and pages.

![Component Hierarchy](component-hierarchy.svg)

### Component Contracts

Each component has a clear input/output contract:

**WeekSidebar**
- Inputs: `year`, `total_weeks`, `current_week` (highlight)
- Outputs: Renders vertical week list with month labels and click targets
- Grid usage: 3 columns wide, full height
- Link targets: `week_N` named destinations

**NavigationTabs**
- Inputs: `highlight_tab` (`:year_events`, `:year_highlights`, or `nil`)
- Outputs: Renders three rotated tabs for year overview pages
- Grid usage: 1 column wide, divided into three sections
- Link targets: `year_events`, `year_highlights`, `seasonal` destinations

**Fieldset**
- Inputs: `position`, `legend`, `border_inset`, `legend_offset`
- Outputs: Renders HTML-like `<fieldset>` with legend label
- Grid usage: Variable, specified by position bounds
- Styling: Configurable rotation, stroke color, insets

**DotGrid**
- Inputs: `width`, `height` (in points)
- Outputs: Renders dot grid at 5mm spacing
- Grid usage: Fills specified area
- Styling: Light gray dots (`COLOR_DOT_GRID`)

### Component Composition

Layouts compose components:
```ruby
# StandardWithSidebarsLayout rendering sidebars
WeekSidebar.new(@pdf, @grid).render(year: @year, total_weeks: @total_weeks, current_week: current_week)
NavigationTabs.new(@pdf, @grid).render(highlight_tab: highlight_tab)
```

Pages can also use components directly:
```ruby
# SeasonalCalendar using Fieldset
Fieldset.new(@pdf, @grid).render(
  position: :top_left,
  legend: 'Winter',
  border_inset: 0.5,
  legend_offset: {col: 0.5, row: -0.3}
)
```

---

## Grid System

All positioning in the planner uses a grid-based coordinate system that abstracts Prawn's point-based system.

![Grid System](grid-system.svg)

### Grid Specifications

- **Grid dimensions**: 43 columns × 55 rows
- **Box size**: 14.17pt (≈5mm) - matches dot spacing
- **Page size**: 612pt × 792pt (US Letter)
- **Coordinate origin**: Top-left (row 0, col 0)

### Coordinate System Differences

**Prawn Coordinates** (native):
- Origin: Bottom-left (0, 0)
- X-axis: Left to right (0 → 612)
- Y-axis: Bottom to top (0 → 792)

**Grid Coordinates** (abstraction):
- Origin: Top-left (col 0, row 0)
- Columns: Left to right (0 → 42)
- Rows: Top to bottom (0 → 54)

### Helper Methods

The `GridSystem` utility provides conversion methods:

```ruby
# Position helpers
grid_x(col)           # Column → X coordinate (left to right)
grid_y(row)           # Row → Y coordinate (converts to bottom-up)

# Dimension helpers
grid_width(boxes)     # Box count → width in points
grid_height(boxes)    # Box count → height in points

# Region helpers
grid_rect(col, row, w, h)  # Returns {x:, y:, width:, height:}
grid_inset(rect, padding)  # Apply padding to rect

# Convenience helpers
grid_text_box(text, col, row, w, h, **opts)  # Text at grid position
grid_link(col, row, w, h, dest, **opts)      # Link at grid position
grid_bottom(row, h)                          # Calculate bottom Y
```

### Usage Examples

```ruby
# Create bounding box at grid position
box = grid_rect(5, 10, 20, 15)  # col 5, row 10, 20 wide, 15 tall
@pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
  # Content renders here
end

# Place text using grid coordinates
grid_text_box("Hello", 10, 20, 15, 2,
  align: :center,
  valign: :center,
  size: 10)

# Create clickable link region
grid_link(5, 10, 10, 2, "week_1")  # Links to week_1 destination
```

### Debug Mode

Enable `DEBUG_GRID = true` in `lib/bujo_pdf/planner_generator.rb` to overlay diagnostic grid:
- Red dots at grid intersections
- Dashed red lines every 5 boxes
- Coordinate labels showing `(col, row)`

---

## Design Principles

### 1. Separation of Concerns

Each module has a single, well-defined responsibility:
- **Pages** - What to render (content)
- **Layouts** - Where to render (positioning, chrome)
- **Components** - How to render (reusable UI elements)
- **Utilities** - Cross-cutting concerns (coordinates, dates)

### 2. Declarative Over Imperative

Pages declare their layout needs rather than implementing layout logic:

```ruby
# Declarative (good)
use_layout :standard_with_sidebars, current_week: 15

# vs. Imperative (bad)
render_week_sidebar
render_navigation_tabs
calculate_content_area
```

### 3. Grid-Based Positioning

All positioning uses grid coordinates instead of raw points:
- Consistent spacing (5mm dots)
- Alignment guaranteed
- Easy to reason about
- Maintainable layouts

### 4. Single Source of Truth

Each piece of layout logic exists in exactly one place:
- Sidebar rendering → Layout classes
- Week calculations → DateCalculator
- Coordinate conversion → GridSystem
- Component rendering → Component classes

### 5. Composition Over Inheritance

Components are composed, not inherited:
- Layouts compose navigation components
- Pages compose fieldset components
- No deep inheritance hierarchies

---

## Key Patterns

### Factory Pattern

`LayoutFactory` creates layout instances by symbol name:

```ruby
layout = LayoutFactory.create(:standard_with_sidebars)
```

Benefits:
- Decouples page classes from layout implementations
- Easy to add new layouts
- Symbol-based API is concise and clear

### Template Method Pattern

`BaseLayout` defines the lifecycle, subclasses implement hooks:

```ruby
class BaseLayout
  def apply(page)
    render_before(page)
    yield calculate_content_area  # Template method
    render_after(page)
  end
end
```

### Strategy Pattern

Pages can choose their layout strategy at runtime:

```ruby
use_layout :full_page           # Full page strategy
use_layout :standard_with_sidebars  # Sidebar strategy
```

### Adapter Pattern

`GridSystem` adapts Prawn's coordinate system to a grid-based system:
- Converts grid coordinates → Prawn points
- Handles Y-axis inversion (top-down vs. bottom-up)
- Provides semantic positioning methods

---

## File Structure

```
lib/bujo_pdf/
├── planner_generator.rb       # Main orchestrator
├── pages/                      # Page classes
│   ├── base.rb
│   ├── seasonal_calendar.rb
│   ├── year_events.rb
│   ├── year_highlights.rb
│   ├── weekly_page.rb
│   ├── reference_page.rb
│   └── blank_dots_page.rb
├── layouts/                    # Layout classes
│   ├── base_layout.rb
│   ├── full_page_layout.rb
│   ├── standard_with_sidebars_layout.rb
│   └── layout_factory.rb
├── components/                 # Reusable components
│   ├── week_sidebar.rb
│   ├── navigation_tabs.rb
│   ├── fieldset.rb
│   └── dot_grid.rb
├── utilities/                  # Helper classes
│   ├── grid_system.rb
│   └── date_calculator.rb
└── constants.rb               # Layout constants
```

---

## Extending the System

### Adding a New Page Type

1. Create page class in `lib/bujo_pdf/pages/`
2. Inherit from `Pages::Base`
3. Implement `setup` (declare layout) and `render` (draw content) methods
4. Register named destination in `PlannerGenerator`
5. Call page generation in main flow

### Adding a New Layout

1. Create layout class in `lib/bujo_pdf/layouts/`
2. Inherit from `BaseLayout`
3. Implement `render_before` and/or `render_after` hooks
4. Implement `calculate_content_area`
5. Register in `LayoutFactory`

### Adding a New Component

1. Create component class in `lib/bujo_pdf/components/`
2. Accept `@pdf` and `@grid` in constructor
3. Implement `render(**options)` method
4. Use grid system for positioning
5. Document input/output contract

---

## Performance Considerations

- **Generation time**: Typically under 5 seconds for full year
- **File size**: Should be under 2MB
- **Memory usage**: Efficient Prawn usage, no memory leaks
- **Link annotations**: ~800-1000 clickable regions per planner
- **Dot grid**: Efficient drawing using repeated patterns

---

## Testing Strategy

The project includes several test files for verifying PDF behavior:

- `test_links.rb` - Link annotation positioning
- `test_coords.rb` - Coordinate system verification
- Additional test files for debugging specific PDF features

Tests help verify:
- Link click targets align with visual elements
- Grid system produces correct coordinates
- Prawn coordinate system behavior

---

## Related Documentation

- **CLAUDE.md** - Project overview, development commands, component details
- **CLAUDE.local.md** - Detailed grid system documentation and examples
- **REFACTORING_PLAN.md** - Future architectural improvements
- **idea.md** - Original design specification

---

## Regenerating Diagrams

All architecture diagrams are generated from D2 source files in `docs/`:

```bash
# Regenerate all SVGs
cd docs
d2 system-overview.d2 system-overview.svg
d2 page-generation-flow.d2 page-generation-flow.svg
d2 layout-system.d2 layout-system.svg
d2 component-hierarchy.d2 component-hierarchy.svg
d2 grid-system.d2 grid-system.svg

# Or use the helper script (if created)
./regenerate-diagrams.sh
```

To modify diagrams, edit the `.d2` source files and regenerate SVGs.
