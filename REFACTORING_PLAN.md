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

**Phase 3: Polish** - 🔄 **IN PROGRESS** (~75% COMPLETE)
- Task 1: Gem Structure ✅ (Completed - v0.1.0)
- Task 7: Code Organization ✅ (DRY refactoring complete)
- Task 8: Testing Infrastructure 🔄 (Basic tests complete, expansion pending)
- Task 9: Documentation 🔄 (README complete, YARD/guides pending)

**Task 10: Migration Strategy** - ✅ **COMPLETED** (incremental migration successful)

**Summary**: The architectural refactoring is complete! All core functionality has been extracted and the system is now maintainable, extensible, well-organized, and distributed as a Ruby gem. Remaining work is expanded testing infrastructure and additional documentation.

## Goals

Transform the monolithic generator script into a well-structured gem with:
- Clear separation of concerns ✅
- Reusable components ✅
- Consistent layout management ✅
- Dynamic navigation context ✅
- Easy extensibility for new page types ✅

## Tasks

### 1. Gem Structure (plans/09_gem_structure.md)
- [x] Convert project to gem format with proper directory structure
- [x] Create `lib/bujo_pdf/` directory structure
- [x] Add `gemspec` file with dependencies and metadata
- [x] Set up proper requires and autoloading
- [x] Add version management
- [x] Create executable/CLI entry point

**Status**: ✅ Completed 2025-11-11 (Plan 09)
- Created `lib/bujo_pdf/version.rb` (VERSION = '0.1.0')
- Created `bujo-pdf.gemspec` with metadata, dependencies, and file manifest
- Created `lib/bujo_pdf.rb` main entry point with ordered requires
- Created `bin/bujo-pdf` CLI executable with --version, --help, and year argument
- Created `Rakefile` with build, test, and install tasks
- Created `CHANGELOG.md` following Keep a Changelog format
- Created `LICENSE` (MIT License)
- Created `README.md` with gem-focused documentation
- Updated `Gemfile` to use gemspec for dependency management
- Updated `gen.rb` to thin wrapper using gem infrastructure
- Updated `.gitignore` for gem build artifacts
- All 20 tests pass with 86 assertions
- Gem builds successfully: `bujo-pdf-0.1.0.gem`
- CLI works: `bujo-pdf --version`, `bujo-pdf --help`, `bujo-pdf 2025`
- PDFs generate correctly (58 pages, 3.1MB)
- Backward compatibility maintained
- Commit: e620ab7 on branch `main`

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

### 7. Code Organization - DRY Refactoring (plans/07_code_organization.md)
- [x] Eliminate code duplication from component extraction
  - [x] Extract parameterized helper for labeled sections in CornellNotes
  - [x] Centralize component option validation with `require_options` helper
  - [x] Add style context managers (`with_fill_color`, `with_stroke_color`, `with_font`)
  - [x] Create StandardLayoutPage base class for sidebar layout pages
  - [x] Centralize constant definitions using Styling module
- [x] Improve maintainability
  - [x] Reduce duplicate code by 85+ lines
  - [x] Establish single source of truth for constants
  - [x] Add automatic style state management
  - [x] Simplify page setup for standard layouts

**Status**: ✅ Completed 2025-11-11 (Plan 07)
- Eliminated 85+ lines of duplicated code
- Created `lib/bujo_pdf/pages/standard_layout_page.rb` base class
- Added `require_options`, `with_fill_color`, `with_stroke_color`, `with_font` helpers to Component base
- Centralized constants (BORDERS, COLS, DOT_SPACING, etc.) using Styling module
- Parameterized labeled section rendering in CornellNotes
- Verified PDF generation working correctly (58 pages, 3.1M matches baseline)
- Commits: fc6f4db, 9d56730, 259b085, 619248d, 26dabee on branch `main`

### 8. Testing Infrastructure
- [x] Set up test framework (Minitest)
- [x] Unit tests for grid system
- [ ] Unit tests for date calculations
- [ ] Integration tests for page generation
- [ ] Visual regression tests (optional)

**Partial Status**: Basic testing infrastructure in place (Plan 01)
- Minitest framework configured with 20 passing tests (86 assertions)
- Comprehensive grid system tests covering coordinate conversion, boundary calculations
- Dot grid rendering tests
- Test suite runs via `rake test` and `ruby test/test_all.rb`
- All tests passing throughout refactoring
- Remaining: Expand test coverage for date calculations, page generation, and visual regression

### 9. Documentation
- [x] Update README with gem usage
- [ ] Add API documentation (YARD)
- [ ] Component usage examples
- [ ] Custom page creation guide
- [ ] Layout customization guide

**Partial Status**: README.md completed 2025-11-11 (Plan 09)
- Created comprehensive README.md with installation, usage, features, and architecture overview
- Includes both CLI and Ruby API examples
- Documents output structure and development workflow
- References CLAUDE.md for detailed technical documentation
- Remaining: YARD API docs, usage guides for customization

### 10. Migration Strategy
- [x] Keep current `gen.rb` working during refactoring
- [x] Create new gem structure alongside current code
- [x] Migrate one page type at a time
- [x] Update tests as we migrate
- [x] Switch to gem-based generation when complete
- [x] Update `gen.rb` to use gem infrastructure (no archival needed)

**Status**: ✅ Completed 2025-11-11
- Incremental migration approach was successful throughout all phases
- `gen.rb` remained functional during entire refactoring process
- All page types migrated to component-based architecture
- Tests updated and passing throughout migration (20 tests, 86 assertions)
- `gen.rb` now uses gem infrastructure as thin wrapper (backward compatible)
- No archival necessary - gen.rb continues to serve as convenient local entry point
- All refactoring completed without breaking changes

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

**Phase 3: Polish** (Lower Priority) - 🔄 **IN PROGRESS** (~75% COMPLETE)
8. ✅ Gem structure and distribution - Plan 09
9. ✅ Code organization (DRY refactoring) - Plan 07
10. 🔄 Testing infrastructure expansion - Plan 08 (basic tests complete)
11. 🔄 Documentation (YARD, guides) - (README complete)

**Detailed Plans Created**: See `plans/` directory
- `plans/01_extract_low_level_utilities.md` ✅
- `plans/02_extract_components.md` ✅ (core complete)
- `plans/03_page_generation_pipeline.md` ✅
- `plans/04_extract_reusable_sub_components.md` ✅
- `plans/05_page_and_layout_abstraction.md` ✅
- `plans/06_render_context_system.md` ✅
- `plans/07_code_organization.md` ✅
- `plans/08_testing_infrastructure.md` ⬜
- `plans/09_gem_structure.md` ✅
- `plans/10_declarative_layout_system.md` ✅
- `plans/index.md` - Tracks all plan statuses

## Notes

- We want to preserve all current functionality during refactoring
- The diagnostic grid should remain available for debugging
- All pages should respect the grid-based layout system
- Navigation should be dynamic and context-aware
- The system should be extensible for future page types
