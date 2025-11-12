# Architecture Diagrams

This directory contains D2 architecture diagrams and their rendered SVG outputs for the BujoPDF planner generator.

## Available Diagrams

### 1. System Overview (`system-overview.d2`)
**High-level system architecture**

Shows the complete component hierarchy and relationships:
- **PlannerGenerator**: Main orchestrator (hexagon shape)
- **Pages Module**: All page types (SeasonalCalendar, YearEvents, YearHighlights, WeeklyPage, ReferencePage, BlankDotsPage)
- **Layouts Module**: Layout system (BaseLayout, FullPageLayout, StandardWithSidebarsLayout, LayoutFactory)
- **Components Module**: Reusable UI components (WeekSidebar, NavigationTabs, Fieldset, DotGrid)
- **Utilities Module**: Helper systems (GridSystem, DateCalculator)
- **Prawn PDF Library**: Underlying PDF generation engine

Demonstrates dependency flow from generator through pages to components and utilities, all interfacing with Prawn.

### 2. Page Generation Flow (`page-generation-flow.d2`)
**Sequential PDF generation workflow**

Illustrates the step-by-step process from user invocation to PDF output:
1. User runs `ruby gen.rb 2025`
2. PlannerGenerator creates PDF document
3. Sets up named destinations for navigation
4. Generates seasonal calendar page
5. Generates year-at-a-glance pages (Events & Highlights grids)
6. Generates reference page (grid calibration)
7. Loops through 52-53 weekly pages
8. Generates blank dots template
9. Builds PDF outline/bookmarks
10. Saves `planner_YYYY.pdf` to disk

### 3. Layout System (`layout-system.d2`)
**Declarative layout architecture**

Details how pages declare layout intent and the layout system handles rendering:
- **Page classes** call `setup()` method
- **LayoutFactory** creates appropriate layout instances
- **BaseLayout** provides render hooks (render_before, render_after)
- **StandardWithSidebarsLayout**: Renders week sidebar (3 cols) + nav tabs (1 col), calculates 39-col content area
- **FullPageLayout**: Provides full 43×55 grid access (no sidebars)
- **Content area hash** passed to page render() methods with grid coordinates

Shows separation of concerns: layouts handle chrome/navigation, pages focus on content.

### 4. Component Hierarchy (`component-hierarchy.d2`)
**Component structure and dependencies**

Documents reusable components and their responsibilities:
- **WeekSidebar**: Vertical week list (1-53) with month indicators and clickable links
- **NavigationTabs**: Rotated year page tabs (seasonal, events, highlights) with highlighting
- **Fieldset**: HTML-like bordered sections with legend labels for semantic grouping
- **DotGrid**: 5mm dot grid background (#CCCCCC light gray)

All components use GridSystem utilities for positioning and Prawn for drawing operations. Shows how layouts and pages compose these components.

### 5. Grid System (`grid-system.d2`)
**Coordinate system visualization**

Explains the grid-based layout foundation:
- **Grid structure**: 43 columns × 55 rows, 14.17pt (5mm) box size
- **Prawn coordinates**: Bottom-left origin (0,0), Y increases upward
- **Grid coordinates**: Top-left origin (col 0, row 0), rows increase downward
- **Helper methods**:
  - `grid_x(col)` → x coordinate
  - `grid_y(row)` → y coordinate (inverted for Prawn)
  - `grid_width(boxes)` → width in points
  - `grid_height(boxes)` → height in points
  - `grid_rect(col, row, w, h)` → bounding box hash
- **Coordinate conversion**: Grid coordinates to Prawn coordinates with examples
- **Link annotations**: Special handling for clickable regions with [left, bottom, right, top] format

Critical for understanding how all positioning works throughout the codebase.

## Viewing Diagrams

### SVG Files
Open `.svg` files in any web browser or image viewer:
```bash
# Linux
xdg-open docs/system-overview.svg

# macOS
open docs/system-overview.svg
```

### D2 Source Files
View and edit `.d2` source files in any text editor. Re-render after changes:
```bash
cd docs/
d2 --sketch system-overview.d2 system-overview.svg
```

### ASCII Output
Generate ASCII/text diagrams for terminal viewing:
```bash
d2 --sketch system-overview.d2  # Outputs to terminal
```

## Regenerating Diagrams

If you modify the D2 source files, regenerate SVG outputs:

```bash
cd /home/andy/projects/bujo-pdf/docs

# Regenerate individual diagram
d2 --sketch system-overview.d2 system-overview.svg

# Regenerate all diagrams
for f in *.d2; do
  d2 --sketch "$f" "${f%.d2}.svg"
done
```

## D2 Resources

- **D2 Language**: https://d2lang.com
- **D2 Tour**: https://d2lang.com/tour/intro
- **Shape Reference**: https://d2lang.com/tour/shapes
- **Layout Engines**: https://d2lang.com/tour/layouts

## Integration with Documentation

These diagrams complement the written documentation:
- **CLAUDE.md**: Project overview, architecture prose, development workflow
- **CLAUDE.local.md**: Grid system implementation details
- **idea.md**: Original design specification
- **These diagrams**: Visual architecture reference

Use diagrams for quick architectural understanding, documentation for detailed implementation guidance.
