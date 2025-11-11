# Refactoring Plan

This document outlines the architectural improvements needed to make the planner generator more maintainable, extensible, and well-organized.

## Goals

Transform the monolithic generator script into a well-structured gem with:
- Clear separation of concerns
- Reusable components
- Consistent layout management
- Dynamic navigation context
- Easy extensibility for new page types

## Tasks

### 1. Gem Structure
- [ ] Convert project to gem format with proper directory structure
- [ ] Create `lib/bujo_pdf/` directory structure
- [ ] Add `gemspec` file with dependencies and metadata
- [ ] Set up proper requires and autoloading
- [ ] Add version management
- [ ] Create executable/CLI entry point

### 2. Extract Low-Level Utilities
- [x] Create `GridSystem` class for grid coordinate helpers
  - [x] `grid_x(col)`, `grid_y(row)` methods
  - [x] `grid_width(boxes)`, `grid_height(boxes)` methods
  - [x] `grid_rect(col, row, width, height)` method
  - [x] Grid constants (DOT_SPACING, GRID_COLS, GRID_ROWS)
- [x] Create `Diagnostics` module for debug tools
  - [x] `draw_diagnostic_grid(label_every:)` method
  - [x] Grid overlay rendering
  - [x] Coordinate labels
- [x] Create `DotGrid` module for dot grid rendering
  - [x] `draw_dot_grid(width, height)` method
  - [x] Dot positioning and styling
- [x] Create `Styling` module for color/font constants
  - [x] Color definitions (borders, weekends, section headers, etc.)
  - [x] Font size constants
  - [x] Spacing constants

**Status**: ✅ Completed 2025-11-11 (Plan 01)
- Created `lib/bujo_pdf/utilities/styling.rb`
- Created `lib/bujo_pdf/utilities/grid_system.rb`
- Created `lib/bujo_pdf/utilities/dot_grid.rb`
- Created `lib/bujo_pdf/utilities/diagnostics.rb`
- Updated PlannerGenerator with backward compatibility layer
- Added unit tests (20 tests, 86 assertions, all passing)
- Verified PDF generation working correctly (58 pages)
- Commit: bf128fc on branch `extract-low-level-utilities`

### 3. Extract Components into Separate Classes
- [ ] Create `Component` base class
  - [ ] Standard interface: `initialize(pdf, grid_system, context)`
  - [ ] `render` method to draw the component
  - [ ] Access to grid helpers and context
- [ ] Create `Sidebar::Left` component
  - [ ] Week list rendering
  - [ ] Month indicators
  - [ ] Current week highlighting
- [ ] Create `Sidebar::Right` component
  - [ ] Tab-based navigation
  - [ ] Dynamic tab definitions
  - [ ] Active tab highlighting
- [ ] Create `Navigation::TopNav` component
  - [ ] Year link
  - [ ] Previous/next week links
  - [ ] Week title
- [ ] Create `Calendar::SeasonalGrid` component
- [ ] Create `Calendar::YearAtGlance` component
- [ ] Create `Calendar::WeeklyPage` component
  - [ ] Daily section sub-component
  - [ ] Cornell notes sub-component
- [ ] Create `FieldSet` component (for seasonal calendar)

### 4. Page Architecture Refactoring
- [ ] Create `Page` base class
  - [ ] Standard lifecycle: `initialize`, `setup`, `render`, `finalize`
  - [ ] Access to context and layout
  - [ ] Component composition support
- [ ] Create concrete page classes:
  - [ ] `Pages::SeasonalCalendar`
  - [ ] `Pages::YearAtGlanceEvents`
  - [ ] `Pages::YearAtGlanceHighlights`
  - [ ] `Pages::WeeklyPage`
  - [ ] `Pages::ReferenceCalibration`
  - [ ] `Pages::BlankDotGrid`
- [ ] Implement page registry/factory
  - [ ] Map page keys to page classes
  - [ ] Instantiate pages with context

### 5. Layout Management System
- [ ] Create `Layout` class to define content areas
  - [ ] Define sidebar positions and widths
  - [ ] Define header/nav area height
  - [ ] Define footer area height
  - [ ] Calculate available content area
- [ ] Create layout masks/constraints
  - [ ] `content_area` - usable grid boxes for content
  - [ ] `with_sidebars` - content area minus left/right sidebars
  - [ ] `with_header` - content area minus header space
  - [ ] `full_content` - content area minus all chrome (header + sidebars)
- [ ] Apply layouts automatically to pages
  - [ ] Pages declare which layout they use
  - [ ] Layout provides grid coordinates for content area
  - [ ] No more manual sidebar position calculations per page

### 6. Context Object System
- [ ] Create `RenderContext` class
  - [ ] Current page number (PDF page index)
  - [ ] Current page key (symbol like `:week_42`, `:year_events`)
  - [ ] Total page count (for "X of Y" displays)
  - [ ] Year being generated
  - [ ] Week information (for weekly pages)
  - [ ] Navigation state (prev/next page keys)
- [ ] Pass context to all components and pages
  - [ ] Components can query current page
  - [ ] Enable dynamic navigation highlighting
- [ ] Implement navigation highlighting
  - [ ] Left sidebar highlights current week
  - [ ] Right sidebar tabs highlight current section
  - [ ] Active states for all nav elements

### 7. Code Organization
- [ ] Separate constants into logical grouping files
  - [ ] `constants/grid.rb` - Grid system constants
  - [ ] `constants/colors.rb` - Color definitions
  - [ ] `constants/layout.rb` - Layout dimensions
  - [ ] `constants/typography.rb` - Font sizes
- [ ] Extract date/week calculation utilities
  - [ ] `DateCalculator` class for week numbering
  - [ ] Year start/end date calculations
  - [ ] Week range calculations
- [ ] Improve method organization
  - [ ] Move related methods into modules
  - [ ] Use composition over inheritance where appropriate

### 8. Testing Infrastructure
- [ ] Set up test framework (RSpec or Minitest)
- [ ] Unit tests for grid system
- [ ] Unit tests for date calculations
- [ ] Integration tests for page generation
- [ ] Visual regression tests (optional)

### 9. Documentation
- [ ] Update README with gem usage
- [ ] Add API documentation (YARD)
- [ ] Component usage examples
- [ ] Custom page creation guide
- [ ] Layout customization guide

### 10. Migration Strategy
- [ ] Keep current `gen.rb` working during refactoring
- [ ] Create new gem structure alongside current code
- [ ] Migrate one page type at a time
- [ ] Update tests as we migrate
- [ ] Switch to gem-based generation when complete
- [ ] Archive old `gen.rb` as reference

## Benefits of Refactoring

1. **Maintainability**: Smaller, focused classes are easier to understand and modify
2. **Extensibility**: Easy to add new page types, components, or layouts
3. **Reusability**: Components can be reused across different page types
4. **Testability**: Isolated classes can be unit tested independently
5. **Consistency**: Layout system ensures consistent spacing across all pages
6. **Context awareness**: Dynamic navigation highlighting based on current page
7. **Gem distribution**: Can be shared and used in other projects

## Priority Order

**Phase 1: Foundation** (High Priority)
1. Extract low-level utilities (GridSystem, Styling)
2. Create Layout management system
3. Create Context object system

**Phase 2: Components** (Medium Priority)
4. Extract components (Sidebars, Navigation)
5. Page architecture refactoring

**Phase 3: Polish** (Lower Priority)
6. Gem structure
7. Testing infrastructure
8. Documentation

## Notes

- We want to preserve all current functionality during refactoring
- The diagnostic grid should remain available for debugging
- All pages should respect the grid-based layout system
- Navigation should be dynamic and context-aware
- The system should be extensible for future page types
