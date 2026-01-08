# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

**Issue tracking**: This project uses [bd (beads)](https://github.com/steveyegge/beads). Use `bd` commands instead of markdown TODOs. See AGENTS.md for workflow details.

## Project Overview

Ruby-based PDF planner generator creating programmable bullet journal PDFs for digital note-taking apps (Noteshelf, GoodNotes). Generates a full year planner with seasonal calendars, year-at-a-glance grids, weekly pages with Cornell notes layout, and internal PDF navigation.

## Quick Start

```bash
bundle install           # Install dependencies
bin/bujo-pdf            # Generate for current year
bin/bujo-pdf 2025       # Generate for specific year
```

**Output**: `planner_{year}.pdf` (~4-5MB, 91+ pages, <5 seconds generation)

## Architecture Summary

**See `docs/ARCHITECTURE.md` for detailed diagrams, module descriptions, and design patterns.**

### Core Concepts

| Concept | Location | Purpose |
|---------|----------|---------|
| Grid System | `lib/bujo_pdf/utilities/grid_system.rb` | 43×55 grid abstraction over Prawn coordinates |
| Canvas | `lib/bujo_pdf/canvas.rb` | Bundles PDF + grid into single object |
| Layouts | `lib/bujo_pdf/layouts/` | Declarative page chrome (sidebars, navigation) |
| Components | `lib/bujo_pdf/components/` | Reusable rendering verbs (`h1`, `box`, `ruled_lines`) |
| Pages | `lib/bujo_pdf/pages/` | Individual page types |

### Grid Coordinate System

All positioning uses grid coordinates (not Prawn points):

- **Dimensions**: 43 columns × 55 rows, 14.17pt box size (≈5mm)
- **Origin**: Top-left (col 0, row 0) - rows increase downward
- **Conversion**: `grid.x(col)`, `grid.y(row)`, `grid.rect(col, row, w, h)`

Prawn uses bottom-left origin with Y increasing upward. The grid system handles this inversion.

### Layout System

Pages declare layout intent; layouts handle chrome:

```ruby
class MyPage < Pages::Base
  def setup
    use_layout :standard_with_sidebars, current_week: @week_num
  end
end
```

- `:full_page` - No sidebars, full 43×55 content area
- `:standard_with_sidebars` - Week sidebar + nav tabs, 39-col content area

### Component Verbs

Pages inherit rendering verbs from `Components::All`:

```ruby
def render
  h1(5, 2, "Title")
  ruled_lines(5, 5, 30, 20)
  box(10, 25, 20, 10, stroke: true)
end
```

## Key File Locations

```
lib/bujo_pdf/
├── pages/           # Page classes (weekly_page.rb, seasonal_calendar.rb, etc.)
├── layouts/         # Layout classes (full_page_layout.rb, standard_with_sidebars_layout.rb)
├── components/      # Component verbs (text.rb, box.rb, ruled_lines.rb, etc.)
├── utilities/       # GridSystem, DateCalculator
├── themes/          # Color schemes (light, earth, dark)
├── constants.rb     # Layout constants, colors
└── canvas.rb        # Canvas value object

config/              # User configuration (dates.yml, calendars.yml, collections.yml)
docs/                # Architecture diagrams and detailed documentation
```

## Named Destinations (Navigation)

PDF internal links use named destinations:

- `week_N` - Weekly pages (1-53)
- `seasonal`, `year_events`, `year_highlights` - Year overview pages
- `index_N`, `future_log_N`, `review_N`, `quarter_N` - Front matter
- `grid_*` - Grid template pages
- `collection_<id>` - User-configured collection pages

## Convention-Based Outline System

The DSL supports automatic PDF outline (bookmark) generation from page declarations.

### Outline Modes

Set the mode at the top of your recipe:

```ruby
BujoPdf.define_pdf :my_recipe do |year:|
  outline_mode :auto    # Auto-generate outline entries from page titles
  # ... pages
end
```

- `:manual` - (Default) Only explicit `outline:` params create entries. Backward compatible.
- `:auto` - Automatically generate outline entries from page registry titles.
- `:none` - No outline entries generated, even if explicitly specified.

### Per-Page Overrides

Control individual page outline entries:

```ruby
# Explicit title
page :seasonal_calendar, id: :seasonal, outline: 'Seasonal View', year: year

# Suppress in auto mode
page :reference, id: :ref, outline: false

# Auto-derive title (uses page class's registered title)
page :monthly_overview, id: :jan, outline: true, month: 1, year: year
```

### Group Hierarchy

Groups create hierarchical outline sections in `:auto` mode:

```ruby
outline_mode :auto

group :monthly_pages do
  # Pages here become children of "Monthly Pages" section
  page :monthly_overview, id: :jan, month: 1, year: year
  page :monthly_overview, id: :feb, month: 2, year: year
end
# Creates outline: "Monthly Pages" > "January 2025", "February 2025"

group :utilities, outline: false do
  # No section - pages appear at root level
  page :reference
end

group :front_matter, outline: 'Getting Started' do
  # Custom section title
  page :index, id: :index
end
```

### Manual Sections

For fine-grained control, use `outline_section` directly:

```ruby
outline_section 'Q1 Weeks', dest: :first do
  weeks_in(year).first(13).each do |week|
    page :weekly, id: :"week_#{week.number}", outline: "Week #{week.number}"
  end
end
```

## Prawn Gotchas

1. **Coordinate origin**: Bottom-left (0,0), Y increases upward
2. **Bounding boxes**: Create local coordinate systems - (0,0) becomes box bottom-left
3. **Link annotations**: Use `[left, bottom, right, top]` format, absolute page coordinates
4. **Text box `at:`**: Specifies top-left corner (but Y still measured from page bottom)
5. **Character encoding**: Built-in fonts use Windows-1252. Avoid Unicode arrows (→), em dashes (—). Use ASCII equivalents (->, --)

## Testing

```bash
bundle exec rake test           # Run test suite
ruby test_links.rb              # Debug link annotations
ruby test_coords.rb             # Debug coordinate system
```

Enable debug grid overlay: Set `DEBUG_GRID = true` in `lib/bujo_pdf/planner_generator.rb`

## Dependencies

- **prawn** ~> 2.4 - PDF generation
- **Ruby Date** - Calendar calculations (stdlib)

---

**Detailed documentation**: `docs/ARCHITECTURE.md` (modules, patterns, diagrams)

Last updated: cd30d69
