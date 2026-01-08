# Documentation Gaps - Loop 00001

## Summary
- **Total Gaps Found:** 6
- **MISSING (undocumented features):** 5
- **STALE (removed features still documented):** 0
- **INACCURATE (wrong descriptions):** 0
- **INCOMPLETE (needs more detail):** 1

---

## Gap List

### GAP-001: PDF DSL (define_pdf, recipes)
- **Type:** MISSING
- **Feature:** PDF DSL for creating custom planner definitions
- **Code Location:** `lib/bujo_pdf/pdf_dsl.rb`, `lib/bujo_pdf/dsl/`
- **README Location:** Not mentioned
- **Description:**
  The PDF DSL is a powerful API that allows users to programmatically define custom planner configurations using `BujoPdf.define_pdf` and `BujoPdf.generate_from_recipe`. This includes support for inline pages, outline modes (`:auto`, `:manual`, `:none`), groups with hierarchical outlines, and custom page blocks.
- **Evidence:**
  - Code: Full DSL implementation with `define_pdf`, `generate_from_recipe`, inline page blocks, `outline_mode`, `group` with outline hierarchy
  - README: Only documents `BujoPdf.generate` - no mention of DSL, recipes, or custom definitions
- **User Impact:** Users who want to create custom planner layouts must discover this feature through code exploration. This is a major extensibility feature that would enable advanced customization.

### GAP-002: Alternative Recipes (daily, project_planner)
- **Type:** MISSING
- **Feature:** Built-in alternative planner recipes beyond standard_planner
- **Code Location:** `lib/bujo_pdf/pdfs/daily.rb`, `lib/bujo_pdf/pdfs/project_planner.rb`
- **README Location:** Not mentioned
- **Description:**
  Two additional built-in recipes exist beyond the standard planner:
  - **daily**: A planner with 365/366 dedicated daily pages including Tasks, Notes, Events, and Reflection sections
  - **project_planner**: A minimal planner demonstrating outline_mode :auto with 12 monthly overview pages
- **Evidence:**
  - Code: Complete recipe definitions with page structures and metadata
  - README: Only mentions the standard planner workflow
- **User Impact:** Users don't know they can generate alternative planner formats. The daily planner in particular is a distinct product that some users would prefer over weekly pages.

### GAP-003: Monthly Overview Page
- **Type:** MISSING
- **Feature:** Single-month calendar view with notes area
- **Code Location:** `lib/bujo_pdf/pages/monthly_overview.rb`
- **README Location:** Not mentioned in Output section
- **Description:**
  MonthlyOverview is a standalone page type showing a single month's calendar with a notes/planning area below. It's used by the project_planner recipe but not exposed in documentation.
- **Evidence:**
  - Code: Full implementation with mini calendar, header, and ruled notes section
  - README: Only mentions "Monthly Reviews" (reflection templates), not monthly overview/calendar pages
- **User Impact:** Users building custom planners might want monthly calendar pages but don't know this component exists.

### GAP-004: Visual TOC Page
- **Type:** MISSING
- **Feature:** Visual Table of Contents page with thumbnail previews
- **Code Location:** `lib/bujo_pdf/pages/visual_toc.rb`
- **README Location:** Not mentioned
- **Description:**
  VisualToc renders a grid of thumbnail images linking to different planner sections. Requires pre-generated thumbnails from `bin/generate-thumbnails`.
- **Evidence:**
  - Code: Full implementation with SECTIONS config, thumbnail rendering, and link annotations
  - README: Not mentioned in Output section or anywhere else
- **User Impact:** Users might want a visual table of contents but don't know it's available as a page type.

### GAP-005: Grids Overview Page
- **Type:** INCOMPLETE
- **Feature:** Grid types overview/index page
- **Code Location:** `lib/bujo_pdf/pages/grids_overview.rb`
- **README Location:** Partially mentioned at line 184
- **Description:**
  The README lists "Grids Overview" in the Output section (line 184) but doesn't explain what it is or how it differs from the Grid Showcase. The Grid Showcase shows all types in quadrants; Grids Overview is a separate navigational page.
- **Evidence:**
  - Code: Dedicated page class `grids_overview.rb`
  - README: Listed but not described - only "Grid Showcase (all types in quadrants)" gets explanation
- **User Impact:** Minor - users see it listed but may not understand the distinction between Showcase and Overview pages.

### GAP-006: generate-page-snapshots Script
- **Type:** MISSING
- **Feature:** Script to generate page snapshot images for documentation
- **Code Location:** `bin/generate-page-snapshots`
- **README Location:** Not mentioned
- **Description:**
  Utility script for generating PNG snapshots of individual pages, useful for documentation and visual verification.
- **Evidence:**
  - Code: Script exists in bin/ directory
  - README: Only mentions `bin/generate-examples` for downloadable PDFs
- **User Impact:** Low - primarily useful for documentation contributors, but might be valuable for users wanting to preview pages before generation.

---

## Gaps by Type

### MISSING Features
| Gap ID | Feature | Code Location | User Impact |
|--------|---------|---------------|-------------|
| GAP-001 | PDF DSL | lib/bujo_pdf/pdf_dsl.rb | High - major extensibility feature |
| GAP-002 | Alternative Recipes | lib/bujo_pdf/pdfs/*.rb | High - distinct planner products |
| GAP-003 | Monthly Overview Page | lib/bujo_pdf/pages/monthly_overview.rb | Medium - useful for custom planners |
| GAP-004 | Visual TOC Page | lib/bujo_pdf/pages/visual_toc.rb | Low - optional feature |
| GAP-006 | generate-page-snapshots | bin/generate-page-snapshots | Low - documentation tooling |

### STALE Documentation
| Gap ID | Feature | README Section | What Changed |
|--------|---------|----------------|--------------|
| *(none found)* | | | |

### INACCURATE Documentation
| Gap ID | Feature | What's Wrong | Correct Behavior |
|--------|---------|--------------|------------------|
| *(none found)* | | | |

### INCOMPLETE Documentation
| Gap ID | Feature | What's Missing |
|--------|---------|----------------|
| GAP-005 | Grids Overview Page | Description of what it is and how it differs from Grid Showcase |

---

## Priority Indicators

### High Priority Gaps
Features that regular users would benefit from knowing about:
1. GAP-001: PDF DSL - Major extensibility feature enabling custom planner creation
2. GAP-002: Alternative Recipes - Different planner formats (daily, project) users might prefer

### Medium Priority Gaps
Features that advanced users might want:
1. GAP-003: Monthly Overview Page - Useful component for custom planners

### Low Priority Gaps
Advanced features or edge cases:
1. GAP-004: Visual TOC Page - Optional visual navigation feature
2. GAP-005: Grids Overview Page - Just needs brief clarification
3. GAP-006: generate-page-snapshots - Developer/documentation tooling

---

## Recommendations

1. **Add "Custom Planners" section to README** documenting:
   - The PDF DSL (`BujoPdf.define_pdf`, `generate_from_recipe`)
   - Available recipes (:standard_planner, :daily, :project_planner)
   - How to invoke alternative recipes from CLI or Ruby API

2. **Expand Output section** to:
   - Add Monthly Overview page description
   - Clarify Grids Overview vs Grid Showcase
   - Optionally mention Visual TOC availability

3. **Consider "Developer Tools" section** for:
   - generate-page-snapshots and other bin/ utilities
   - Thumbnail generation workflow
