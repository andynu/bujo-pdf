# Plans Index

This file tracks the status of all plans in the plans directory.

## Last Updated
2025-11-12 (Completed Plan 17)

## Active Plans

### Plan 18: Flat Table of Contents (Not Started)
- **File**: `18-flat-toc.md`
- **Status**: Not Started
- **Priority**: Feature Enhancement
- **Goal**: Create comprehensive visual table of contents page listing all major sections and weeks in flat, non-hierarchical format

### Plan 19: Flat-File Configuration for Highlighted Dates (Not Started)
- **File**: `19-flat-file-date-config.md`
- **Status**: Not Started
- **Priority**: Feature Enhancement
- **Goal**: Add YAML configuration file for highlighting special dates (holidays, events) throughout the planner

### Plan 20: iCal URL Integration for Event Highlighting (Not Started)
- **File**: `20-ical-url-integration.md`
- **Status**: Not Started
- **Priority**: Feature Enhancement
- **Dependencies**: Plan 19 (Flat-File Date Config)
- **Goal**: Support fetching events from iCal URLs to automatically highlight special dates in the planner

### Plan 21: Multi-Tap Navigation Cycling for Right Sidebar (Not Started)
- **File**: `21-multi-tap-navigation-cycling.md`
- **Status**: Not Started
- **Created**: 2025-11-11 23:45 EST
- **Last Modified**: 2025-11-11 23:45 EST
- **Last Worked**: 2025-11-11 23:45 EST
- **Changed Since Work**: No
- **Priority**: Feature Enhancement
- **Dependencies**: Plan 06 (RenderContext System) - COMPLETED, Plan 10 (Declarative Layout System) - COMPLETED
- **Goal**: Implement multi-tap navigation system for right sidebar tabs that cycles through multiple related pages with array-based destination syntax

### Plan 22: Quantized Weekday Column Width Component (Not Started)
- **File**: `22-quantized-weekday-widths.md`
- **Status**: Not Started
- **Priority**: Code Quality
- **Goal**: Create WeekGrid component with quantized column widths for consistent visual rhythm across 7-day grids in different contexts

### Plan 23: Additional Grid Types (Not Started)
- **File**: `23-additional-grid-types.md`
- **Status**: Not Started
- **Created**: 2025-11-12
- **Last Modified**: 2025-11-12
- **Last Worked**: 2025-11-12
- **Changed Since Work**: No
- **Priority**: Feature Enhancement
- **Dependencies**: None
- **Goal**: Add isometric, perspective, and hexagon grid types for technical drawing, architectural sketching, and game mapping use cases

## Discarded Plans

### Plan 15: Three-Letter Month Indicators in Week Sidebar (Discarded)
- **File**: `15-month-indicators-in-nav.md`
- **Status**: Discarded
- **Priority**: Feature Enhancement
- **Goal**: Change from single-character month indicators to three-letter month abbreviations (JAN, FEB, MAR, etc.) in the week sidebar
- **Reason**: Insufficient space on iPad. The 2-box sidebar width cannot accommodate three-letter abbreviations plus week numbers without compromising readability or layout integrity.

## Recently Completed Plans

### Plan 17: Monthly Bookmarks in PDF Outline (Completed 2025-11-12)
- **File**: `17-month-toc-pages.md`
- **Status**: Completed
- **Created**: 2025-11-12
- **Last Modified**: 2025-11-12
- **Last Worked**: 2025-11-12
- **Changed Since Work**: No
- **Priority**: Feature Enhancement
- **Dependencies**: None
- **Commits**: eeafacc
- **Goal**: Add monthly groupings to PDF outline/bookmarks (sidebar navigation in PDF readers) to provide better hierarchical navigation from year to month to week
- **Result**: Successfully implemented hierarchical PDF outline structure with monthly sections. The outline now displays "Monthly Pages" with 12 month subsections (January 2025 - December 2025), each containing their corresponding weekly pages. Weeks spanning months appear in both month sections for easier navigation. Metadata-only change with no impact on page count or file size.

### Plan 16: Automatic Tab Bolding in Right Navigation Sidebar (Already Implemented)
- **File**: `16-bold-current-tab-in-nav.md`
- **Status**: Already Implemented
- **Priority**: Feature Enhancement
- **Dependencies**: Plan 06 (RenderContext System) - COMPLETED
- **Goal**: Automatic tab highlighting in right sidebar navigation
- **Result**: Feature already fully implemented through RenderContext-based system. Right sidebar tabs automatically bold and highlight current page.

### Plan 11: Multi-Year Layout Implementation (Completed 2025-11-12)
- **File**: `11-multi-year-layout.md`
- **Status**: Completed
- **Created**: 2025-11-11 (estimated)
- **Last Modified**: 2025-11-12 00:46 EST
- **Last Worked**: 2025-11-12 01:15 EST
- **Changed Since Work**: No
- **Priority**: Feature Enhancement
- **Dependencies**: Plan 10 (Declarative Layout System) - COMPLETED
- **Commits**: 7f1b8a2
- **Goal**: Create multi-year overview page displaying multiple years side-by-side with months as rows, enabling year-over-year comparison with clickable week links
- **Result**: Successfully implemented multi-year overview page showing 4 years (2024-2027) with 12 months as rows. Uses 3-letter month abbreviations, blank cells for data collection with invisible links to week pages, integrated with standard sidebar layout and "Multi" navigation tab.

### Plan 14: Remove gen.rb and Standardize on bin/bujo-pdf (Completed 2025-11-12)
- **File**: `14-remove-gen-rb.md`
- **Status**: Completed
- **Created**: 2025-11-11 23:54 EST
- **Last Modified**: 2025-11-12
- **Last Worked**: 2025-11-12
- **Changed Since Work**: No
- **Priority**: Code Cleanup
- **Dependencies**: Plan 09 (Gem Structure and Distribution) - COMPLETED
- **Result**: Successfully removed gen.rb and updated all documentation (CLAUDE.md, CLAUDE.local.md, plans/*.md, REFACTORING_PLAN.md) to use bin/bujo-pdf. All 98 tests pass.

### Plan 13: Ultra-Light Weekend Background Shading for Year-at-a-Glance Pages (Completed 2025-11-11)
- **File**: `13-weekend-backgrounds.md`
- **Status**: Completed
- **Created**: 2025-11-11 23:03 EST
- **Last Modified**: 2025-11-11 23:03 EST
- **Last Worked**: 2025-11-11 23:55 EST
- **Changed Since Work**: No
- **Priority**: Feature Enhancement
- **Dependencies**: None
- **Commits**: 640b2f4, 57bda26
- **Result**: Successfully added subtle weekend background shading to all calendar views using WEEKEND_BG color ('CCCCCC') at 10% opacity. Shading now appears on: (1) Year-at-a-glance pages (Events and Highlights) for all valid Saturday/Sunday cells, (2) Seasonal calendar mini month grids for weekend columns. Consistent weekend visual indicators across entire planner.

### Plan 12: Inline Weekday Indicators with Day Numbers (Completed 2025-11-11)
- **File**: `12-weekday-indicators-inline.md`
- **Status**: Completed
- **Created**: 2025-11-11 (estimated)
- **Last Modified**: 2025-11-11 22:22 EST
- **Last Worked**: 2025-11-11 22:22 EST
- **Changed Since Work**: No
- **Priority**: Feature Enhancement
- **Dependencies**: None
- **Commits**: 4e2e312
- **Result**: Successfully moved weekday abbreviations (Mon, Tue, etc.) to appear inline with day numbers in year-at-a-glance pages. Weekday text rendered in muted gray (AAAAAA) at slightly smaller size (5pt vs 6pt) using formatted_text_box for clean visual hierarchy. Applied to both Events and Highlights pages via shared YearAtGlanceBase class.

### Plan 08: Testing Infrastructure (Completed 2025-11-11)
- **File**: `08_testing_infrastructure.md`
- **Status**: Completed
- **Created**: 2025-11-11 21:15 EST
- **Last Modified**: 2025-11-11 21:15 EST
- **Last Worked**: 2025-11-11 23:45 EST
- **Changed Since Work**: No
- **Priority**: Phase 3 - High Priority (Quality & Maintainability)
- **Dependencies**: Plan 01, Plan 02, Plan 04, Plan 05, Plan 06 - ALL COMPLETED
- **Commits**: 8ddbb6f, b91f005, 5919fe6, 28a4e1a
- **Result**: Established comprehensive testing infrastructure with 98 tests (88 unit + 10 integration), 2428 assertions, all passing. Test suite includes GridSystem, DotGrid, DateCalculator, RenderContext unit tests, and PlannerGeneration integration tests. Custom assertions, MockPDF class, and full README documentation.

### Plan 09: Gem Structure and Distribution (Completed 2025-11-11)
- **File**: `09_gem_structure.md`
- **Status**: Completed
- **Created**: 2025-11-11 21:15 EST
- **Last Modified**: 2025-11-11 21:15 EST
- **Last Worked**: 2025-11-11 23:19 EST
- **Changed Since Work**: No
- **Priority**: Phase 3 - High Priority (Distribution & Packaging)
- **Dependencies**: Plans 01-06 - ALL COMPLETED
- **Commits**: e620ab7
- **Result**: Successfully converted to distributable Ruby gem (v0.1.0) with gemspec, CLI executable (bin/bujo-pdf), version management, MIT license, comprehensive documentation (README, CHANGELOG), and Rakefile for build tasks. All 20 tests pass.

### Plan 07: Eliminate Code Duplication from Component Extraction (Completed 2025-11-11)
- **File**: `07_code_organization.md`
- **Status**: Completed
- **Created**: 2025-11-11 21:15 EST
- **Last Modified**: 2025-11-11 23:10 EST
- **Last Worked**: 2025-11-11 23:10 EST
- **Changed Since Work**: No
- **Priority**: Phase 3 - High Priority (Code Quality & DRY)
- **Dependencies**: Plan 01, Plan 02, Plan 04, Plan 05, Plan 06, Plan 10 - ALL COMPLETED
- **Commits**: fc6f4db, 9d56730, 259b085, 619248d, 26dabee
- **Result**: Eliminated 85+ lines of duplicated code with parameterized helpers, validation, style managers, StandardLayoutPage base, and centralized constants

### Plan 10: Declarative Layout System with Automatic Content Area Management (Completed 2025-11-11)
- **File**: `10_declarative_layout_system.md`
- **Status**: Completed
- **Created**: 2025-11-11 21:33 EST
- **Last Modified**: 2025-11-11 21:33 EST
- **Last Worked**: 2025-11-11 21:50 EST
- **Changed Since Work**: No
- **Priority**: Phase 3 - High Priority (Architecture & DRY)
- **Dependencies**: Plans 01, 02, 04, 05, 06 - ALL COMPLETED
- **Commits**: 47003c9
- **Goal**: Eliminate code duplication by introducing declarative layout system that automatically manages navigation sidebars and content area constraints
- **Result**: Successfully implemented Layouts module with BaseLayout, FullPageLayout, StandardWithSidebarsLayout, and LayoutFactory. Removed ~80 lines of duplicated sidebar code from page classes.

### Plan 06: RenderContext System (Completed 2025-11-11)
- **File**: `06_render_context_system.md`
- **Status**: Completed
- **Last Modified**: 2025-11-11 20:52 EST
- **Last Worked**: 2025-11-11 20:52 EST
- **Changed Since Work**: No
- **Priority**: Phase 2 - Medium Priority (Enhancement)
- **Dependencies**: Plan 01, Plan 02, Plan 05 - ALL COMPLETED
- **Branch**: extract-components
- **Commits**: 95f6006, 5a3f8eb, 9a081dd
- **Goal**: Implement formal RenderContext class to enable context-aware rendering (e.g., bold highlight current page in right sidebar)
- **Bonus**: Refactored to use automatic page numbering from Prawn (eliminates manual tracking)

### Plan 02: Extract Components into Reusable Classes (Completed 2025-11-11)
- **File**: `02_extract_components.md`
- **Status**: Completed (Partial - Core Components)
- **Last Modified**: 2025-11-11 20:50 EST
- **Last Worked**: 2025-11-11 20:31 EST
- **Changed Since Work**: No
- **Priority**: Phase 2 - High Priority (Building on Foundation)
- **Dependencies**: Plan 01 (Extract Low-Level Utilities) - COMPLETED, Plan 04 (Extract Reusable Sub-Components) - COMPLETED, Plan 05 (Page and Layout Abstraction) - COMPLETED
- **Branch**: extract-components
- **Commits**: 961d331, 6721c64, 6d11767
- **Note**: Completed core weekly page components. Remaining calendar components (SeasonalCalendar, YearAtGlance) deferred.

## Completed Plans

1. Plan 17: Monthly Bookmarks in PDF Outline (Completed 2025-11-12)
   - **File**: `17-month-toc-pages.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-12
   - **Last Worked**: 2025-11-12
   - **Priority**: Feature Enhancement
   - **Dependencies**: None
   - **Commits**: eeafacc
   - **Result**: Hierarchical PDF outline with monthly sections grouping weekly pages for improved navigation

1. Plan 14: Remove gen.rb and Standardize on bin/bujo-pdf (Completed 2025-11-12)
   - **File**: `14-remove-gen-rb.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-12
   - **Last Worked**: 2025-11-12
   - **Priority**: Code Cleanup
   - **Dependencies**: Plan 09 (Gem Structure and Distribution) - COMPLETED
   - **Result**: Successfully removed gen.rb and updated all documentation to use bin/bujo-pdf. All 98 tests pass.

1. Plan 13: Ultra-Light Weekend Background Shading for Year-at-a-Glance Pages (Completed 2025-11-11)
   - **File**: `13-weekend-backgrounds.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 23:03 EST
   - **Last Worked**: 2025-11-11 23:55 EST
   - **Priority**: Feature Enhancement
   - **Dependencies**: None
   - **Commits**: 640b2f4, 57bda26
   - **Result**: Weekend background shading added to all calendar views (year-at-a-glance and seasonal calendar) using 10% opacity WEEKEND_BG color

1. Plan 12: Inline Weekday Indicators with Day Numbers (Completed 2025-11-11)
   - **File**: `12-weekday-indicators-inline.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 22:22 EST
   - **Last Worked**: 2025-11-11 22:22 EST
   - **Priority**: Feature Enhancement
   - **Dependencies**: None
   - **Commits**: 4e2e312
   - **Result**: Inline weekday abbreviations with day numbers in muted gray, applied to both Events and Highlights pages

1. Plan 08: Testing Infrastructure (Completed 2025-11-11)
   - **File**: `08_testing_infrastructure.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 21:15 EST
   - **Last Worked**: 2025-11-11 23:45 EST
   - **Priority**: Phase 3 - High Priority (Quality & Maintainability)
   - **Dependencies**: Plan 01, Plan 02, Plan 04, Plan 05, Plan 06 - ALL COMPLETED
   - **Commits**: 8ddbb6f, b91f005, 5919fe6, 28a4e1a
   - **Result**: Comprehensive testing infrastructure with 98 tests, 2428 assertions

1. Plan 09: Gem Structure and Distribution (Completed 2025-11-11)
   - **File**: `09_gem_structure.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 21:15 EST
   - **Last Worked**: 2025-11-11 23:19 EST
   - **Priority**: Phase 3 - High Priority (Distribution & Packaging)
   - **Dependencies**: Plans 01-06 - ALL COMPLETED
   - **Commits**: e620ab7
   - **Result**: Ruby gem v0.1.0 with full distribution infrastructure

1. Plan 07: Eliminate Code Duplication from Component Extraction (Completed 2025-11-11)
   - **File**: `07_code_organization.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 23:10 EST
   - **Last Worked**: 2025-11-11 23:10 EST
   - **Priority**: Phase 3 - High Priority (Code Quality & DRY)
   - **Dependencies**: Plan 01, 02, 04, 05, 06, 10 - ALL COMPLETED
   - **Commits**: fc6f4db, 9d56730, 259b085, 619248d, 26dabee
   - **Result**: Eliminated 85+ lines of code duplication

1. Plan 10: Declarative Layout System (Completed 2025-11-11)
   - **File**: `10_declarative_layout_system.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 21:33 EST
   - **Last Worked**: 2025-11-11 21:50 EST
   - **Priority**: Phase 3 - High Priority (Architecture & DRY)
   - **Dependencies**: Plan 01, 02, 04, 05, 06 - ALL COMPLETED
   - **Commits**: 47003c9
   - **Result**: Removed ~80 lines of duplicated sidebar code

1. Plan 06: RenderContext System (Completed 2025-11-11)
   - **File**: `06_render_context_system.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 20:52 EST
   - **Last Worked**: 2025-11-11 20:52 EST
   - **Priority**: Phase 2 - Medium Priority (Enhancement)
   - **Dependencies**: Plan 01, Plan 02, Plan 05 - ALL COMPLETED
   - **Branch**: extract-components
   - **Commits**: 95f6006, 5a3f8eb, 9a081dd
   - **Bonus**: Automatic page numbering from Prawn

1. Plan 02: Extract Components into Reusable Classes (Completed 2025-11-11)
   - **File**: `02_extract_components.md`
   - **Status**: Completed (Core Components)
   - **Last Modified**: 2025-11-11 20:50 EST
   - **Last Worked**: 2025-11-11 20:31 EST
   - **Priority**: Phase 2 - High Priority (Building on Foundation)
   - **Dependencies**: Plan 01, Plan 04, Plan 05 - ALL COMPLETED
   - **Branch**: extract-components
   - **Commits**: 961d331, 6721c64, 6d11767

1. Plan 05: Page and Layout Abstraction Layer (Completed 2025-11-11)
   - **File**: `05_page_and_layout_abstraction.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 20:40 EST
   - **Last Worked**: 2025-11-11 20:45 EST
   - **Priority**: Phase 2 - High Priority (Foundation for Component System)
   - **Dependencies**: Plan 01 (Extract Low-Level Utilities) - COMPLETED, Plan 03 (Page Generation Pipeline) - COMPLETED, Plan 04 (Extract Reusable Sub-Components) - COMPLETED
   - **Branch**: page-and-layout-abstraction
   - **Commits**: b1a40dc, 86f12bc

1. Plan 04: Extract Reusable Sub-Components (Completed 2025-11-11)
   - **File**: `04_extract_reusable_sub_components.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 19:29 EST
   - **Last Worked**: 2025-11-11 19:40 EST
   - **Priority**: Phase 2 - High Priority (Foundation for Component Extraction)
   - **Dependencies**: Plan 01 (Extract Low-Level Utilities) - COMPLETED, Plan 03 (Page Generation Pipeline) - COMPLETED
   - **Branch**: extract-reusable-sub-components
   - **Commits**: dc53d6c, c9b3774, bef41e5, deb98e5

1. Plan 03: Page Generation Pipeline Refactoring (Completed 2025-11-11)
   - **File**: `03_page_generation_pipeline.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 19:25 EST
   - **Last Worked**: 2025-11-11 19:25 EST
   - **Priority**: Phase 2 - Medium Priority
   - **Dependencies**: Plan 01 (Extract Low-Level Utilities) - COMPLETED
   - **Branch**: page-generation-pipeline
   - **Commits**: f857b1f, fcefc03, f0625ec, 383bf8f

1. Plan 01: Extract Low-Level Utilities (Completed 2025-11-11)
   - **File**: `01_extract_low_level_utilities.md`
   - **Status**: Completed
   - **Last Modified**: 2025-11-11 18:20 PST
   - **Last Worked**: 2025-11-11 18:20 PST
   - **Priority**: Phase 1 - High Priority (Foundation)
   - **Dependencies**: None
   - **Branch**: extract-low-level-utilities
   - **Commit**: bf128fc

## Upcoming Plans

The following plans are referenced in REFACTORING_PLAN.md but not yet created:
- Documentation - YARD and Guides (Phase 3)

Note: "Code Organization - Split Constants" is now covered by Plan 07.
Note: "Testing Infrastructure Enhancement" is now covered by Plan 08.
Note: "Gem Structure and Distribution" is now covered by Plan 09.

## Notes

- Plans are executed using the `/execplan` command
- Status values: Planning, In Progress, Completed, Blocked, Deferred
- Changed Since Work: Indicates if plan file has been modified since last work session
