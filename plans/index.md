# Plans Index

This file tracks the status of all plans in the plans directory.

## Last Updated
2025-11-13 16:17 EST (Completed Plan #21: Multi-Tap Navigation Cycling)

## Active Plans

### Plan 22: Quantized Weekday Column Width Component (Not Started)
- **File**: `22-quantized-weekday-widths.md`
- **Status**: Not Started
- **Priority**: Code Quality
- **Goal**: Create WeekGrid component with quantized column widths for consistent visual rhythm across 7-day grids in different contexts

## Archived Plans

See `archived_plans/index.md` for detailed information about completed and discarded plans.

### Completed Plans (25 total)
- Plan 21: Multi-Tap Navigation Cycling - Cyclic navigation tabs with Grids reference pages (2025-11-13)
- Plan 20: iCal URL Integration - Calendar event highlighting from iCal URLs (2025-11-13)
- Plan 23: Additional Grid Types - Isometric, perspective, hexagon grids (2025-11-12)
- Plan 19: Flat-File Date Configuration - YAML-based date highlighting (2025-11-12)
- Plan 18: Flat PDF Outline - Single-level bookmark structure (2025-11-12)
- Plan 17: Monthly Bookmarks - Hierarchical PDF outline with months (2025-11-12)
- Plan 16: Automatic Tab Bolding - Already implemented via RenderContext (2025-11-12)
- Plan 14: Remove gen.rb - Standardized on bin/bujo-pdf (2025-11-12)
- Plan 13: Weekend Background Shading - Subtle shading on calendar views (2025-11-11)
- Plan 12: Inline Weekday Indicators - Weekdays inline with day numbers (2025-11-11)
- Plan 11: Multi-Year Layout - 4-year comparison view (2025-11-12)
- Plan 10: Declarative Layout System - Automatic sidebar management (2025-11-11)
- Plan 09: Gem Structure - Distributable Ruby gem v0.1.0 (2025-11-11)
- Plan 08: Testing Infrastructure - 98 tests, 2428 assertions (2025-11-11)
- Plan 07: Eliminate Code Duplication - Removed 85+ lines (2025-11-11)
- Plan 06: RenderContext System - Context-aware rendering (2025-11-11)
- Plan 05: Page and Layout Abstraction - Foundation for components (2025-11-11)
- Plan 04: Extract Reusable Sub-Components - Foundation for extraction (2025-11-11)
- Plan 03: Page Generation Pipeline - Refactored generation flow (2025-11-11)
- Plan 02: Extract Components - Core weekly page components (2025-11-11)
- Plan 01: Extract Low-Level Utilities - Foundation utilities (2025-11-11)

### Discarded Plans (1 total)
- Plan 15: Three-Letter Month Indicators - Insufficient space on iPad

## Upcoming Plans

The following plans are referenced in REFACTORING_PLAN.md but not yet created:
- Documentation - YARD and Guides (Phase 3)

## Archival Process

When a plan is completed or discarded:

1. **Move the plan file** to `archived_plans/` directory
2. **Rename with suffix**:
   - Completed: Add `_COMPLETED` suffix (e.g., `23-additional-grid-types_COMPLETED.md`)
   - Discarded: Add `_DISCARDED` suffix (e.g., `15-month-indicators-in-nav_DISCARDED.md`)
3. **Update archived_plans/index.md**: Add full plan entry with all metadata
4. **Update this file**: Replace detailed entry with single-line summary in the "Archived Plans" section
5. **Update "Last Updated"** timestamp at top of both index files

This keeps the main index focused on active work while preserving complete history in the archive.

## Notes

- Plans are executed using the `/execplan` command
- Status values: Planning, In Progress, Completed, Blocked, Deferred
- Changed Since Work: Indicates if plan file has been modified since last work session
- Detailed information for archived plans is in `archived_plans/index.md`
