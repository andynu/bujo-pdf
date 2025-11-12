# Refactoring Plan

This document outlines the architectural improvements needed to make the planner generator more maintainable, extensible, and well-organized.

## Overall Progress

**Last Updated**: 2025-11-11

**Phase 1: Foundation** - ✅ **100% COMPLETE**
- Task 2: Extract Low-Level Utilities ✅
- Task 5: Layout Management System ✅
- Task 6: Context Object System ✅

**Phase 2: Components & Architecture** - ✅ **~90% COMPLETE**
- Task 3: Extract Components ✅ (Core complete, calendar components deferred)
- Task 4: Page Architecture Refactoring ✅
- Infrastructure: Page Generation Pipeline ✅ (Plan 03)
- Infrastructure: Reusable Sub-Components ✅ (Plan 04)

**Phase 3: Polish** - ⬜ **NOT STARTED**
- Task 1: Gem Structure ⬜
- Task 7: Code Organization ⬜
- Task 8: Testing Infrastructure ⬜
- Task 9: Documentation ⬜

**Task 10: Migration Strategy** - ✅ **ONGOING** (iterative approach working well)

**Summary**: The architectural refactoring is essentially complete! All core functionality has been extracted and the system is now maintainable, extensible, and well-organized. Remaining work is packaging, organization, and polish.

## Goals

Transform the monolithic generator script into a well-structured gem with:
- Clear separation of concerns ✅
- Reusable components ✅
- Consistent layout management ✅
- Dynamic navigation context ✅
- Easy extensibility for new page types ✅

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
- [x] Create `Component` base class
  - [x] Standard interface: `initialize(pdf, grid_system, context)`
  - [x] `render` method to draw the component
  - [x] Access to grid helpers and context
  - [x] Content area awareness for layout constraints
- [x] Create `WeekSidebar` component (left sidebar)
  - [x] Week list rendering
  - [x] Month indicators
  - [x] Current week highlighting
- [x] Create `RightSidebar` component
  - [x] Tab-based navigation
  - [x] Dynamic tab definitions
  - [x] Active tab highlighting
- [x] Create `TopNavigation` component
  - [x] Year link
  - [x] Previous/next week links
  - [x] Week title
- [ ] Create `SeasonalCalendar` component (deferred - uses inline rendering)
- [ ] Create `YearAtGlance` component (deferred - uses inline rendering)
- [x] Create Weekly Page components
  - [x] `DailySection` component
  - [x] `CornellNotes` component
- [x] Create reusable sub-components (Plan 04)
  - [x] `SubComponent::Base` base class
  - [x] `SubComponent::Fieldset` (for seasonal calendar)
  - [x] `SubComponent::WeekColumn` (for daily sections)
  - [x] `SubComponent::RuledLines` (for note areas)
  - [x] `SubComponent::DayHeader` (for calendar days)

**Status**: ✅ Core Components Completed 2025-11-11 (Plans 02, 04, 05)
- Created `lib/bujo_pdf/component.rb` (base class)
- Created `lib/bujo_pdf/component_context.rb` (hybrid layout helper)
- Created `lib/bujo_pdf/components/top_navigation.rb`
- Created `lib/bujo_pdf/components/week_sidebar.rb`
- Created `lib/bujo_pdf/components/right_sidebar.rb`
- Created `lib/bujo_pdf/components/daily_section.rb`
- Created `lib/bujo_pdf/components/cornell_notes.rb`
- Created `lib/bujo_pdf/sub_components/` directory with 4 sub-components
- Updated `WeeklyPage` to use component-based architecture
- Verified PDF generation working correctly (58 pages)
- Commits: 961d331, 6721c64, 6d11767, dc53d6c, c9b3774, bef41e5, deb98e5
- Branches: `extract-components`, `extract-reusable-sub-components`
- **Note**: SeasonalCalendar and YearAtGlance components deferred as lower priority (used on fewer pages)

### 4. Page Architecture Refactoring
- [x] Create `Page` base class
  - [x] Standard lifecycle: `initialize`, `setup_page`, `render_chrome`, `render`, `finalize_page`
  - [x] Access to context and layout
  - [x] Component composition support
  - [x] Content area awareness
  - [x] Chrome/content separation
- [x] Create concrete page classes:
  - [x] `Pages::SeasonalCalendar`
  - [x] `Pages::YearAtGlanceEvents`
  - [x] `Pages::YearAtGlanceHighlights`
  - [x] `Pages::YearAtGlanceBase` (shared base for Events/Highlights)
  - [x] `Pages::WeeklyPage`
  - [x] `Pages::ReferenceCalibration`
  - [x] `Pages::BlankDotGrid`
- [x] Implement page registry/factory
  - [x] Map page keys to page classes (`PageFactory`)
  - [x] Instantiate pages with context
  - [x] Automatic layout application

**Status**: ✅ Completed 2025-11-11 (Plan 05)
- Created `lib/bujo_pdf/pages/base.rb` (page base class with lifecycle)
- Created `lib/bujo_pdf/pages/weekly_page.rb`
- Created `lib/bujo_pdf/pages/seasonal_calendar.rb`
- Created `lib/bujo_pdf/pages/year_at_glance_base.rb`
- Created `lib/bujo_pdf/pages/year_at_glance_events.rb`
- Created `lib/bujo_pdf/pages/year_at_glance_highlights.rb`
- Created `lib/bujo_pdf/pages/reference_calibration.rb`
- Created `lib/bujo_pdf/pages/blank_dot_grid.rb`
- Created `lib/bujo_pdf/page_factory.rb` (page registry)
- All pages use lifecycle hooks and layouts
- Verified PDF generation working correctly (58 pages)
- Commits: b1a40dc, 86f12bc on branch `page-and-layout-abstraction`

### 5. Layout Management System
- [x] Create `Layout` class to define content areas
  - [x] Define sidebar positions and widths
  - [x] Define header/nav area height
  - [x] Define footer area height
  - [x] Calculate available content area
  - [x] Background rendering configuration (dots, diagnostics)
- [x] Create layout factory methods
  - [x] `Layout.weekly_layout` - for weekly pages with navigation/sidebars
  - [x] `Layout.full_page` - for pages without chrome
  - [x] `Layout.custom` - for arbitrary content area definitions
- [x] Apply layouts automatically to pages
  - [x] Pages declare which layout they use via `default_layout`
  - [x] Layout provides grid coordinates for content area
  - [x] No more manual sidebar position calculations per page
  - [x] Content area constraints enforced automatically

**Status**: ✅ Completed 2025-11-11 (Plan 05)
- Created `lib/bujo_pdf/layout.rb`
- Layout factory methods for common page types
- Content area calculation and positioning
- Integration with Page base class lifecycle
- Components automatically respect layout boundaries
- Verified PDF generation working correctly (58 pages)
- Commits: b1a40dc, 86f12bc on branch `page-and-layout-abstraction`

### 6. Context Object System
- [x] Create `RenderContext` class
  - [x] Current page number (PDF page index)
  - [x] Current page key (symbol like `:week_42`, `:year_events`)
  - [x] Total page count (for "X of Y" displays)
  - [x] Year being generated
  - [x] Week information (for weekly pages)
  - [x] Hash-style access for backward compatibility
  - [x] `current_page?` method for context-aware rendering
- [x] Pass context to all components and pages
  - [x] Components can query current page via context
  - [x] Enable dynamic navigation highlighting
  - [x] Context passed through page lifecycle
  - [x] Backward compatible with hash-based context
- [x] Implement navigation highlighting
  - [x] Left sidebar highlights current week
  - [x] Right sidebar tabs highlight current section
  - [x] Active states for all nav elements
  - [x] Bold font and black color for current page
  - [x] No link on current page (non-interactive)

**Status**: ✅ Completed 2025-11-11 (Plan 06)
- Created `lib/bujo_pdf/render_context.rb` with typed accessors and `current_page?` method
- Updated `lib/bujo_pdf/component.rb` with `context` and `current_page?` helpers
- Updated `lib/bujo_pdf/pages/base.rb` to accept both RenderContext and Hash
- Updated `lib/bujo_pdf/planner_generator.rb` to create RenderContext for all pages
- Updated `lib/bujo_pdf/components/right_sidebar.rb` with current page highlighting
- Updated `lib/bujo_pdf/components/week_sidebar.rb` to use `context.current_page?`
- Automatic page numbering using `@pdf.page_number` (no manual tracking)
- Verified PDF generation working correctly (58 pages)
- Commits: 95f6006, 5a3f8eb, 9a081dd on branch `extract-components`

### 7. Code Organization (plans/07_code_organization.md)
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

**Phase 1: Foundation** (High Priority) - ✅ **COMPLETED**
1. ✅ Extract low-level utilities (GridSystem, Styling) - Plan 01
2. ✅ Create Layout management system - Plan 05
3. ✅ Create Context object system - Plan 05

**Phase 2: Components & Architecture** (Medium Priority) - ✅ **MOSTLY COMPLETED**
4. ✅ Page generation pipeline refactoring - Plan 03
5. ✅ Extract reusable sub-components - Plan 04
6. ✅ Page architecture refactoring - Plan 05
7. ✅ Extract components (Sidebars, Navigation, Weekly Page components) - Plan 02
   - ⚠️ Calendar components (SeasonalCalendar, YearAtGlance) deferred as lower priority

**Phase 3: Polish** (Lower Priority) - ⬜ **NOT STARTED**
8. ⬜ Gem structure and distribution
9. ⬜ Code organization (split constants files)
10. ⬜ Testing infrastructure expansion
11. ⬜ Documentation (YARD, guides)

**Detailed Plans Created**: See `plans/` directory
- `plans/01_extract_low_level_utilities.md` ✅
- `plans/02_extract_components.md` ✅ (core complete)
- `plans/03_page_generation_pipeline.md` ✅
- `plans/04_extract_reusable_sub_components.md` ✅
- `plans/05_page_and_layout_abstraction.md` ✅
- `plans/06_render_context_system.md` ✅
- `plans/index.md` - Tracks all plan statuses

## Notes

- We want to preserve all current functionality during refactoring
- The diagnostic grid should remain available for debugging
- All pages should respect the grid-based layout system
- Navigation should be dynamic and context-aware
- The system should be extensible for future page types
