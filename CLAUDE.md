# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby-based PDF planner generator that creates programmable bullet journal PDFs optimized for digital note-taking apps (Noteshelf, GoodNotes). The generator creates a full year planner with:

- **Seasonal calendar** - Year-at-a-glance view organized by seasons
- **Year-at-a-glance pages** - Events and Highlights grids (12 months × 31 days)
- **Weekly pages** - One page per week with daily sections and Cornell notes layout
- **Navigation system** - Internal PDF hyperlinks with named destinations
- **Dot grid backgrounds** - 5mm dot spacing for handwriting guidance
- **Grid-based layout system** - All positioning based on a 43×55 grid system

## Development Commands

### Generate Planner
```bash
# Generate for current year
bin/bujo-pdf 

# Generate for specific year
bin/bujo-pdf 2025

# Install dependencies first if needed
bundle install
```

### Testing Link Functionality
The repository includes multiple test files (`test_*.rb`) for debugging PDF link annotations and coordinate systems. These are experiments for understanding Prawn's coordinate system and link behavior:

```bash
# Run individual tests
ruby test_links.rb
ruby test_coords.rb
# etc.
```

## Architecture

### Main Generator Class: `PlannerGenerator`

**Core responsibility**: Generate a complete planner PDF for a specified year

**Main flow** :
1. Set up named destinations for navigation
2. Generate seasonal calendar page
3. Generate year-at-a-glance pages (Events & Highlights)
4. Generate grid reference/calibration page
5. Generate 52-53 weekly pages (one per week)
6. Generate blank dot grid template page
7. Build PDF outline/bookmarks

### Grid-Based Layout System

The planner uses a **grid coordinate system** where all positioning is based on dot grid boxes:

- **Grid dimensions**: 43 columns × 55 rows
- **Box size**: 14.17pt (≈5mm) matching `DOT_SPACING`
- **Page size**: 612pt × 792pt (US Letter)

**Key helper methods** (in `lib/bujo_pdf/utilities/grid_system.rb`):
- `x(col)` - Convert column to x-coordinate
- `y(row)` - Convert row to y-coordinate (row 0 = top)
- `width(boxes)` - Convert box count to width
- `height(boxes)` - Convert box count to height
- `rect(col, row, w, h)` - Get bounding box coordinates

**Coordinate system notes**:
- Prawn's origin is bottom-left (0,0), Y increases upward
- Grid system: Row 0 is top, increases downward
- `grid_y(row)` converts from grid coordinates to Prawn coordinates

### Declarative Layout System

The planner uses a **declarative layout system** where pages declare their layout intent rather than implementing layout details. Layouts automatically handle sidebar rendering and content area management.

**Available Layouts:**
- `:full_page` - No sidebars, full 43×55 content area (reference page, blank dots)
- `:standard_with_sidebars` - Left week sidebar (3 cols) + right nav tabs (1 col), content area 39 cols (weekly pages, year overviews)

**Usage in pages:**
```ruby
class MyPage < Pages::Base
  def setup
    use_layout :standard_with_sidebars,
      current_week: @week_num,      # Highlight this week (or nil)
      highlight_tab: :year_events,  # Highlight this tab (or nil)
      year: @year,
      total_weeks: @total_weeks
  end
end
```

**What layouts do automatically:**
- Render navigation sidebars (left week list, right year tabs)
- Calculate content area boundaries
- Provide `content_area` hash to page render methods
- Handle sidebar highlighting (current week, current tab)

**Layout classes** (lib/bujo_pdf/layouts/):
- `BaseLayout` - Abstract base with lifecycle hooks (render_before, render_after)
- `FullPageLayout` - Full page, no chrome
- `StandardWithSidebarsLayout` - Week sidebar + navigation tabs
- `LayoutFactory` - Creates layouts by symbol name

**Key benefit**: Single source of truth for sidebar rendering. Changing sidebar behavior requires editing only the layout class, not every page that uses it.

### Fieldset Component

The `Fieldset` component (`lib/bujo_pdf/components/fieldset.rb`) creates HTML-like `<fieldset>` boxes with legend labels. Used extensively for seasonal calendar sections.

**Parameters**:
- Position: `:top_left`, `:top_right`, `:bottom_left`, `:bottom_right`
- Legend label and styling
- Border inset (in grid boxes)
- Legend offset for fine-tuning

**Rotation conventions**:
- `+90` = counter-clockwise (text reads bottom-to-top)
- `-90` = clockwise (text reads top-to-bottom)

### Debug Mode

Toggle `DEBUG_GRID` constant in `lib/bujo_pdf/planner_generator.rb` to overlay diagnostic grid:
- Red dots at grid intersections
- Dashed red lines every N boxes
- Coordinate labels showing `(col, row)`

```ruby
DEBUG_GRID = true   # Enable for development
DEBUG_GRID = false  # Disable for production
```

Call `draw_diagnostic_grid(label_every: 5)` in page rendering methods to visualize the grid.

### Date Calculations

**Week numbering system** (critical for navigation):
- Week 1 starts on the Monday on or before January 1
- Weeks increment sequentially through the year
- Total weeks: typically 52-53 depending on year

**Key calculation** (see `lib/bujo_pdf/utilities/date_calculator.rb`):
```ruby
first_day = Date.new(@year, 1, 1)
days_back = (first_day.wday + 6) % 7  # Convert to Monday-based
year_start_monday = first_day - days_back
# Calculate week number for any date
days_from_start = (date - year_start_monday).to_i
week_num = (days_from_start / 7) + 1
```

### Navigation System

**Named destinations**:
- `seasonal` - Seasonal calendar page
- `year_events` - Year at a Glance - Events
- `year_highlights` - Year at a Glance - Highlights
- `week_N` - Weekly page N (e.g., `week_1`, `week_42`)
- `reference` - Grid reference/calibration page
- `dots` - Blank dot grid page

**Link annotations** use `[left, bottom, right, top]` format (all from page bottom):
```ruby
@pdf.link_annotation([left, bottom, right, top],
                    Dest: "week_#{week_num}",
                    Border: [0, 0, 0])
```

**Sidebar navigation**:
- Left sidebar: `lib/bujo_pdf/components/week_sidebar.rb` - Vertical week list with month indicators
- Right sidebar: `lib/bujo_pdf/components/navigation_tabs.rb` - Rotated tabs for year pages

## Layout Constants

The codebase uses extensive layout constants in `lib/bujo_pdf/constants.rb` organized by section:
- Page dimensions and global layout
- Seasonal calendar layout
- Year at a glance layout
- Weekly page layout (top nav, daily section, Cornell notes)
- Dot grid settings
- Colors (light gray for dots/borders, subtle weekend background)

**Key color scheme**:
- `COLOR_DOT_GRID = 'CCCCCC'` - Light gray dots
- `COLOR_BORDERS = 'E5E5E5'` - Very light gray borders
- `COLOR_SECTION_HEADERS = 'AAAAAA'` - Muted gray headers
- `COLOR_WEEKEND_BG = 'FAFAFA'` - Extremely subtle weekend shading

## Page Generation Methods

Each page type has its own class in `lib/bujo_pdf/pages/`:

1. **Seasonal Calendar** (`seasonal_calendar.rb`)
   - Grid-based layout with four seasons
   - Fieldset borders with season labels
   - Mini month calendars with clickable dates

2. **Year at a Glance** (`year_events.rb`, `year_highlights.rb`)
   - 12 columns (months) × 31 rows (days)
   - Day numbers with day-of-week abbreviations
   - Each cell links to corresponding week

3. **Weekly Pages** (`weekly_page.rb`)
   - Daily section (17.5% of usable height): 7 columns with headers and ruled lines
   - Cornell notes section (82.5%): Cues column (25%), Notes column (75%), Summary (20% of section)
   - Navigation links: previous/next week, back to year overview
   - Time period labels (AM/PM/EVE) on Monday column

4. **Reference Page** (`reference_page.rb`)
   - Calibration grid with measurements
   - Centimeter markings along edges
   - Grid system documentation
   - Prawn coordinate system reference

## Common Patterns

### Drawing in Grid Coordinates
```ruby
# Get grid-based bounding box
box = grid_rect(5, 10, 20, 15)  # col, row, width_boxes, height_boxes

# Use with bounding_box
@pdf.bounding_box([box[:x], box[:y]], width: box[:width], height: box[:height]) do
  # Draw content using local coordinates
end
```

### Clickable Link Areas
```ruby
# Calculate cell boundaries
cell_x = grid_x(col)
cell_y = grid_y(row)
cell_width = grid_width(boxes)
cell_height = grid_height(boxes)

# Link uses bottom coordinate
link_bottom = cell_y - cell_height
@pdf.link_annotation([cell_x, link_bottom, cell_x + cell_width, cell_y],
                    Dest: "week_#{week_num}",
                    Border: [0, 0, 0])
```

### Text Positioning
```ruby
@pdf.text_box "Content",
              at: [grid_x(5), grid_y(10)],  # Top-left corner
              width: grid_width(10),
              height: grid_height(2),
              align: :center,
              valign: :center
```

### Rotated Text
```ruby
# Clockwise rotation for top-to-bottom reading
@pdf.rotate(-90, origin: [x, y]) do
  @pdf.text_box "Label", at: [x, y], width: 50, height: 20
end
```

## Prawn-Specific Considerations

1. **Bounding boxes create local coordinate systems** - (0,0) becomes bottom-left of box
2. **Text box `at:` parameter** - Specifies top-left corner (but Y still from bottom)
3. **Link annotations** - Use absolute page coordinates even inside bounding boxes
4. **Rotation origin** - Specify the point around which to rotate
5. **Color values** - 6-digit hex strings (e.g., `'CCCCCC'`)

## Dependencies

- **prawn** ~> 2.4 - PDF generation library
- **Ruby date library** - Built-in Date class for calendar calculations

## Output

- **Filename**: `planner_{year}.pdf`
- **Page count**: 57-58 pages typical (4 overview + 52-53 weekly + 2 templates)
- **File size**: Should be under 2MB
- **Generation time**: Under 5 seconds

## Key Files

- **bin/bujo-pdf** - CLI executable for generating planners
- **lib/bujo_pdf/** - Component-based generator library
  - **pages/** - Page classes (seasonal calendar, year-at-a-glance, weekly pages)
  - **layouts/** - Layout classes (full page, standard with sidebars)
  - **components/** - Reusable components (week sidebar, navigation tabs, fieldsets)
  - **utilities/** - Helper classes (grid system, date calculator)
- **Gemfile** - Dependencies specification
- **idea.md** - Original design specification
- **CLAUDE.local.md** - Detailed grid system documentation
- **test_*.rb** - Test scripts for PDF link coordinate debugging
