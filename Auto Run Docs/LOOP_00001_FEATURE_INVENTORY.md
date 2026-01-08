# Feature Inventory - Loop 00001

## README Analysis

### README Location
`/Users/andy/projects/bujo-pdf/README.md`

### README Structure
| Section | Description | Line Numbers |
|---------|-------------|--------------|
| Title & Description | Project overview and purpose | 1-3 |
| Download Example PDFs | Pre-generated planner links by theme | 5-16 |
| Features | Bullet list of major capabilities | 17-29 |
| Page Gallery | Visual thumbnails of page types | 30-39 |
| Installation | Gem install instructions | 41-59 |
| Usage | CLI commands and Ruby API | 61-108 |
| Calendar Integration | iCal import feature details | 110-165 |
| Output | List of generated page types | 166-191 |
| Development | Setup and testing for contributors | 192-214 |
| Architecture | High-level component overview | 215-225 |
| Testing | Test suite documentation | 227-267 |
| Contributing | Contribution guidelines | 269-274 |
| License | MIT license reference | 275-277 |
| Code of Conduct | Community standards | 279-281 |

### Features Documented in README
| Feature | Section | Description in README |
|---------|---------|----------------------|
| Color Themes | Features | Light, Earth, and Dark themes for different preferences |
| Seasonal Calendar | Features | Year-at-a-glance view organized by seasons with mini month calendars |
| Year-at-a-Glance Pages | Features | Events and Highlights grids (12 months x 31 days) |
| Weekly Pages | Features | Daily sections with Cornell notes layout for structured note-taking |
| Grid Templates | Features | 8 full-page grid types: dot, graph, lined, isometric, perspective, hexagon |
| Wheel Pages | Features | Daily and Year wheel templates for circular planning |
| PDF Navigation | Features | Internal hyperlinks with multi-tap tab cycling through grid pages |
| Calendar Integration | Features | Import events from iCal URLs (Google, Apple, Outlook) |
| Dot Grid Backgrounds | Features | 5mm dot spacing throughout for handwriting guidance |
| Grid-Based Layout | Features | Precise 43x55 grid system for consistent alignment |
| CLI: bujo-pdf | Usage | Generate planner from command line with year/theme options |
| CLI: --theme flag | Usage | Select color theme (light, earth, dark) |
| CLI: --list-themes | Usage | Show available themes |
| CLI: --version | Usage | Show version number |
| CLI: --help | Usage | Show help message |
| Ruby API | Usage | BujoPdf.generate method for programmatic generation |
| Index Pages | Output | 2 pages with numbered lines for hand-built TOC |
| Future Log | Output | 2 pages for 6-month spreads for long-term event capture |
| Multi-Year Overview | Output | 4-year calendar spread |
| Quarterly Planning | Output | 4 pages for 12-week goal-setting |
| Monthly Reviews | Output | 12 reflection templates interleaved with weeks |
| Grid Showcase | Output | All grid types in quadrants preview |
| Tracker Example | Output | Habit and mood tracking inspiration |
| Reference Page | Output | Grid calibration and measurement guide |
| Collection Pages | Output | User-configured via config/collections.yml |
| dates.yml config | Calendar Integration | Manual date highlighting (takes precedence over calendar events) |
| calendars.yml config | Calendar Integration | iCal URL configuration with colors, icons, caching |

---

## Codebase Analysis

### Project Type
- **Language/Framework:** Ruby / Prawn PDF library
- **Application Type:** CLI tool and Ruby gem

### Features Found in Code
| Feature | Location | Type | User-Facing? |
|---------|----------|------|--------------|
| CLI: bujo-pdf command | bin/bujo-pdf | CLI | Yes |
| CLI: --version / -v | bin/bujo-pdf:18-20 | CLI | Yes |
| CLI: --help / -h | bin/bujo-pdf:21-23 | CLI | Yes |
| CLI: --theme / -t | bin/bujo-pdf:24-32 | CLI | Yes |
| CLI: --list-themes | bin/bujo-pdf:32-35 | CLI | Yes |
| CLI: year argument | bin/bujo-pdf:36-43 | CLI | Yes |
| Light theme | lib/bujo_pdf/themes/light.rb | Config | Yes |
| Earth theme | lib/bujo_pdf/themes/earth.rb | Config | Yes |
| Dark theme | lib/bujo_pdf/themes/dark.rb | Config | Yes |
| Ruby API: BujoPdf.generate | lib/bujo_pdf.rb:136-140 | API | Yes |
| Ruby API: BujoPdf.define_pdf (DSL) | lib/bujo_pdf/pdf_dsl.rb:73-77 | API | Yes |
| Ruby API: BujoPdf.generate_from_recipe | lib/bujo_pdf/pdf_dsl.rb:161-163 | API | Yes |
| Recipe: standard_planner | lib/bujo_pdf/pdfs/standard_planner.rb | Config | Yes |
| Recipe: daily | lib/bujo_pdf/pdfs/daily.rb | Config | Yes |
| Recipe: project_planner | lib/bujo_pdf/pdfs/project_planner.rb | Config | Yes |
| Seasonal Calendar page | lib/bujo_pdf/pages/seasonal_calendar.rb | Page | Yes |
| Year Events page | lib/bujo_pdf/pages/year_at_glance_events.rb | Page | Yes |
| Year Highlights page | lib/bujo_pdf/pages/year_at_glance_highlights.rb | Page | Yes |
| Multi-Year Overview page | lib/bujo_pdf/pages/multi_year_overview.rb | Page | Yes |
| Weekly page | lib/bujo_pdf/pages/weekly_page.rb | Page | Yes |
| Index page | lib/bujo_pdf/pages/index_pages.rb | Page | Yes |
| Future Log page | lib/bujo_pdf/pages/future_log.rb | Page | Yes |
| Monthly Review page | lib/bujo_pdf/pages/monthly_review.rb | Page | Yes |
| Monthly Overview page | lib/bujo_pdf/pages/monthly_overview.rb | Page | Yes |
| Quarterly Planning page | lib/bujo_pdf/pages/quarterly_planning.rb | Page | Yes |
| Collection page | lib/bujo_pdf/pages/collection_page.rb | Page | Yes |
| Reference/Calibration page | lib/bujo_pdf/pages/reference_calibration.rb | Page | Yes |
| Tracker Example page | lib/bujo_pdf/pages/tracker_example.rb | Page | Yes |
| Daily Wheel page | lib/bujo_pdf/pages/daily_wheel.rb | Page | Yes |
| Year Wheel page | lib/bujo_pdf/pages/year_wheel.rb | Page | Yes |
| Grid Showcase page | lib/bujo_pdf/pages/grid_showcase.rb | Page | Yes |
| Grids Overview page | lib/bujo_pdf/pages/grids_overview.rb | Page | Yes |
| Dot Grid page | lib/bujo_pdf/pages/grids/dot_grid_page.rb | Page | Yes |
| Graph Grid page | lib/bujo_pdf/pages/grids/graph_grid_page.rb | Page | Yes |
| Lined Grid page | lib/bujo_pdf/pages/grids/lined_grid_page.rb | Page | Yes |
| Isometric Grid page | lib/bujo_pdf/pages/grids/isometric_grid_page.rb | Page | Yes |
| Perspective Grid page | lib/bujo_pdf/pages/grids/perspective_grid_page.rb | Page | Yes |
| Hexagon Grid page | lib/bujo_pdf/pages/grids/hexagon_grid_page.rb | Page | Yes |
| Visual TOC page | lib/bujo_pdf/pages/visual_toc.rb | Page | Yes |
| Inline page DSL | lib/bujo_pdf/pages/inline_page.rb | API | Yes |
| PDF DSL: outline_mode | lib/bujo_pdf/dsl/outline.rb | API | Yes |
| PDF DSL: group with outline | lib/bujo_pdf/dsl/builder.rb | API | Yes |
| PDF DSL: page with outline | lib/bujo_pdf/dsl/page_declaration.rb | API | Yes |
| dates.yml configuration | lib/bujo_pdf/dsl/configuration/dates.rb | Config | Yes |
| calendars.yml configuration | lib/bujo_pdf/dsl/configuration/calendars.rb | Config | Yes |
| collections.yml configuration | lib/bujo_pdf/dsl/configuration/collections.rb | Config | Yes |
| iCal fetching | lib/bujo_pdf/dsl/configuration/calendars/ical_fetcher.rb | Feature | Yes |
| iCal parsing | lib/bujo_pdf/dsl/configuration/calendars/ical_parser.rb | Feature | Yes |
| Event caching | lib/bujo_pdf/dsl/configuration/calendars/event_store.rb | Feature | Yes |
| Recurring event expansion | lib/bujo_pdf/dsl/configuration/calendars/recurring_event_expander.rb | Feature | Yes |
| Script: generate-downloadable-pdfs | bin/generate-downloadable-pdfs | Script | Yes |
| Script: generate-page-snapshots | bin/generate-page-snapshots | Script | Yes |
| Script: generate-component-examples | bin/generate-component-examples | Script | Dev |
| Script: render-component | bin/render-component | Script | Dev |
| Script: update-doc-assets | bin/update-doc-assets | Script | Dev |
| Rake: test | Rakefile | Dev | Yes |
| Rake: test_unit | Rakefile | Dev | Yes |
| Rake: test_integration | Rakefile | Dev | Yes |
| Rake: generate[year] | Rakefile | Dev | Yes |
| Rake: test_install | Rakefile | Dev | Yes |

---

## Feature Summary

### Totals
- **Features in README:** 31
- **Features in Code:** 58
- **Potential Gaps:** 6 (code features not in README)
- **Potential Stale:** 0 (README features not in code)

### Quick Classification

#### Likely Undocumented (in code, not in README)
1. **Monthly Overview page** - Single-month calendar view with notes area (lib/bujo_pdf/pages/monthly_overview.rb)
2. **Recipe: daily** - Daily planner recipe with one page per day (lib/bujo_pdf/pdfs/daily.rb)
3. **Recipe: project_planner** - Minimal project planner recipe (lib/bujo_pdf/pdfs/project_planner.rb)
4. **Visual TOC page** - Table of contents page class exists (lib/bujo_pdf/pages/visual_toc.rb)
5. **PDF DSL** - Full declarative DSL for defining custom PDFs (BujoPdf.define_pdf, outline_mode, groups)
6. **Grids Overview page** - Grid types overview page (separate from showcase)

#### Possibly Stale (in README, not found in code)
*(None found - all documented features verified in code)*

#### Confirmed Documented (in both)
1. **Color Themes (light/earth/dark)** - accurate
2. **CLI commands (bujo-pdf, --theme, --version, --help, --list-themes)** - accurate
3. **Ruby API (BujoPdf.generate)** - accurate
4. **Seasonal Calendar page** - accurate
5. **Year Events/Highlights pages** - accurate
6. **Weekly pages with Cornell notes** - accurate
7. **Grid pages (dot, graph, lined, isometric, perspective, hexagon)** - accurate
8. **Wheel pages (daily, year)** - accurate
9. **Index pages** - accurate
10. **Future Log pages** - accurate
11. **Quarterly Planning pages** - accurate
12. **Monthly Reviews pages** - accurate
13. **Multi-Year Overview page** - accurate
14. **Tracker Example page** - accurate
15. **Reference/Calibration page** - accurate
16. **Collection pages** - accurate
17. **Grid Showcase page** - accurate
18. **Calendar Integration (iCal)** - accurate
19. **dates.yml configuration** - accurate
20. **calendars.yml configuration** - accurate
21. **collections.yml configuration** - accurate
22. **PDF Navigation with hyperlinks** - accurate
23. **Dot Grid Backgrounds** - accurate
24. **43x55 Grid System** - accurate

---

## Notes

- The README accurately documents the standard planner workflow but does not mention the alternative recipes (daily, project_planner)
- The PDF DSL for creating custom planner definitions is a powerful feature not exposed in user documentation
- The Visual TOC page class exists but doesn't appear to be used in standard recipes
- The convention-based outline system (outline_mode, group hierarchies) is documented in CLAUDE.md but not in README
- Script utilities like `generate-downloadable-pdfs` are mentioned briefly but `generate-page-snapshots` is not
