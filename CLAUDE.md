# CLAUDE.md

**Note**: This project uses [bd (beads)](https://github.com/steveyegge/beads)
for issue tracking. Use `bd` commands instead of markdown TODOs.
See AGENTS.md for workflow details.

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

### Canvas Value Object

The `Canvas` class (`lib/bujo_pdf/canvas.rb`) bundles a PDF document with its grid system into a single object. This simplifies component interfaces:

```ruby
# Canvas provides both pdf and grid access
def initialize(canvas:)
  @pdf = canvas.pdf
  @grid = canvas.grid
end

# Convenience delegators allow direct coordinate access
canvas.x(5)      # instead of canvas.grid.x(5)
canvas.rect(...)  # instead of canvas.grid.rect(...)
```

### GridRect Value Object

`GridRect` (`lib/bujo_pdf/utilities/grid_rect.rb`) represents rectangular grid regions and supports Ruby splatting:

```ruby
rect = GridRect.new(5, 10, 20, 15)  # col, row, width, height

# Positional splatting into method calls
ruled_lines(*rect, color: 'red')  # => ruled_lines(5, 10, 20, 15, color: 'red')

# Keyword splatting into constructors
Component.new(**rect)  # => Component.new(col: 5, row: 10, width: 20, height: 15)
```

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

### Component Verb System

Components provide **verb methods** that pages can call directly for common rendering tasks. This creates a clean, declarative API where pages describe what to render rather than how.

**Architecture:**
- Each component defines a `Mixin` module with its verb method(s)
- `Components::All` aggregates all mixins
- `Pages::Base` includes `Components::All`, giving all pages access to verbs

**Available verbs:**
```ruby
# Drawing primitives
box(col, row, width, height, stroke:, stroke_width:, fill:, radius:, opacity:)
hline(col, row, width, color:, stroke:)
vline(col, row, height, color:, stroke:)

# Text rendering
text(col, row, content, size:, height:, color:, style:, position:, align:, width:, rotation:)
h1(col, row, content, color:, style:, position:, align:, width:)
h2(col, row, content, color:, style:)

# Grid background effects
grid_dots(col, row, width, height, color:)   # Render dots over region
erase_dots(col, row, width, height:)          # Clear dots in region
ruled_lines(col, row, width, height, color:, stroke:)  # Ruled lines with dots on top

# Complex components
mini_month(col, row, width, month:, year:, align:, show_links:, show_weekend_bg:, quantize:)
ruled_list(col, row, width, entries:, start_num:, show_page_box:, line_color:, num_color:)
fieldset(col, row, width, height, legend:, position:, **options)

# Layout helpers
margins(col, row, width, height, left:, right:, top:, bottom:, all:)  # Returns Cell struct
```

**Usage in pages:**
```ruby
class MyPage < Pages::Base
  def render
    # Draw ruled lines - dots automatically rendered on top
    ruled_lines(2, 5, 20, 10)

    # Draw text after (appears on top of everything)
    @pdf.text_box "Title", at: [@grid_system.x(2), @grid_system.y(3)]
  end
end
```

**Adding a new component with verb:**

1. Create `lib/bujo_pdf/components/my_component.rb`:
```ruby
module BujoPdf
  module Components
    class MyComponent
      module Mixin
        def my_verb(col, row, width, height, **options)
          MyComponent.new(
            canvas: @canvas,
            col: col, row: row, width: width, height: height,
            **options
          ).render
        end
      end

      def initialize(canvas:, col:, row:, width:, height:, **options)
        @canvas = canvas
        @pdf = canvas.pdf
        @grid = canvas.grid
      end

      def render
        # Use @pdf and @grid for drawing
      end
    end
  end
end
```

2. Add to `lib/bujo_pdf/components/all.rb`:
```ruby
module All
  def self.included(base)
    base.include GridDots::Mixin
    base.include RuledLines::Mixin
    base.include MyComponent::Mixin  # Add this
  end
end
```

3. Add require to `lib/bujo_pdf.rb`

**Key benefit**: Pages become declarative - they call verbs like `ruled_lines(...)` instead of manually managing PDF state, colors, and z-index.

### WeekGrid Component

The `WeekGrid` component (`lib/bujo_pdf/components/week_grid.rb`) renders 7-column week-based grids with optional quantization for visual consistency across pages.

**Key feature**: When `quantize: true` and width is divisible by 7 grid boxes, columns align exactly with the dot grid and have identical widths across all pages using the same box count.

**Usage via grid helper**:
```ruby
# Basic usage with quantization
grid.week_grid(5, 10, 35, 15, quantize: true).render

# With block for custom cell rendering
grid.week_grid(5, 10, 35, 15) do |day_index, cell_rect|
  # day_index: 0-6 (Monday-Sunday)
  # cell_rect: {x:, y:, width:, height:} in points
  pdf.text_box "Day #{day_index}", at: [cell_rect[:x], cell_rect[:y]]
end
```

**Parameters**:
- `quantize`: Enable box-aligned column widths (default: true)
- `show_headers`: Render M/T/W/T/F/S/S labels (default: true)
- `first_day`: Week start day `:monday` or `:sunday` (default: :monday)
- `header_height`: Height for headers in points (default: DOT_SPACING)
- `cell_callback`: Proc for custom cell rendering

**Quantization behavior**:
- **35 boxes ÷ 7 = 5 boxes/day**: Quantized (grid-aligned)
- **37 boxes ÷ 7 = 5.29 boxes/day**: Proportional (fallback)
- **42 boxes ÷ 7 = 6 boxes/day**: Quantized (grid-aligned)

**Used by**: DailySection component in weekly pages for consistent day column widths.

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
- `index_N` - Index page N (e.g., `index_1`, `index_2`) - 4 pages by default
- `future_log_N` - Future log page N (e.g., `future_log_1`, `future_log_2`) - 2 pages
- `collection_<id>` - Collection pages (e.g., `collection_books_to_read`) - user-configured
- `review_N` - Monthly review page N (e.g., `review_1` for January) - 12 pages
- `quarter_N` - Quarterly planning page N (e.g., `quarter_1` for Q1) - 4 pages
- `tracker_example` - Tracker ideas inspiration page
- `seasonal` - Seasonal calendar page
- `year_events` - Year at a Glance - Events
- `year_highlights` - Year at a Glance - Highlights
- `multi_year` - Multi-year overview page
- `week_N` - Weekly page N (e.g., `week_1`, `week_42`)
- `grid_showcase` - Grid types showcase (entry point)
- `grids_overview` - Basic grids overview page
- `grid_dot` - Full-page dot grid (5mm)
- `grid_graph` - Full-page graph grid (5mm)
- `grid_lined` - Full-page ruled lines (10mm)
- `grid_isometric` - Full-page isometric grid
- `grid_perspective` - Full-page 1-point perspective grid
- `grid_hexagon` - Full-page hexagon grid
- `reference` - Grid calibration page

**Link annotations** use `[left, bottom, right, top]` format (all from page bottom):
```ruby
@pdf.link_annotation([left, bottom, right, top],
                    Dest: "week_#{week_num}",
                    Border: [0, 0, 0])
```

**Sidebar navigation**:
- Left sidebar: `lib/bujo_pdf/components/week_sidebar.rb` - Vertical week list with month indicators
- Right sidebar: `lib/bujo_pdf/components/right_sidebar.rb` - Rotated tabs for year and grid pages

**Multi-tap navigation cycling** (Plan 21):
Right sidebar tabs can cycle through multiple related pages using destination arrays:

```ruby
# In StandardWithSidebarsLayout#build_top_tabs
{ label: "Grids", dest: [:grid_showcase, :grids_overview, :grid_dot, :grid_graph, :grid_lined, :grid_isometric, :grid_perspective, :grid_hexagon] }
```

**Behavior**:
- When not on any page in the cycle → clicking goes to first page (entry point)
- When on a page in the cycle → clicking advances to next page in sequence
- After last page → wraps back to first page
- Tab is highlighted (bold) when on any page in the cycle

**Example: Grids tab cycling** (8 pages):
1. Click "Grids" from weekly page → `grid_showcase` (all grid types in quadrants)
2. Click "Grids" again → `grids_overview` (basic grids overview)
3. Click "Grids" again → `grid_dot` → `grid_graph` → `grid_lined`
4. Continue → `grid_isometric` → `grid_perspective` → `grid_hexagon`
5. Click "Grids" again → cycles back to `grid_showcase`

**Implementation**: `lib/bujo_pdf/layouts/standard_with_sidebars_layout.rb:137-256`

**Sidebar tab overrides** (`lib/bujo_pdf/dsl/sidebar_overrides.rb`):
Pages can customize where sidebar tabs navigate based on context. For example, the "Future" tab navigates to `future_log_1` from weeks 1-26 but `future_log_2` from weeks 27-53:

```ruby
# Pages register overrides during setup
overrides.set(from: :week_1, tab: :future, to: :future_log_1)
overrides.set(from: :week_27, tab: :future, to: :future_log_2)

# Layouts query overrides when rendering tabs
dest = overrides.get(current_page_key, "Future") || default_dest
```

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

1. **Index Pages** (`index_pages.rb`)
   - Numbered blank pages at the front for hand-built table of contents
   - Classic bullet journal technique for custom TOC entries
   - Numbered lines with ruled entry areas and page number boxes
   - Named destinations (`index_1`, `index_2`, etc.) for hyperlinking
   - Configurable page count (default: 4 pages)

2. **Future Log** (`future_log.rb`)
   - 6-month spread for capturing events beyond current planning horizon
   - 3 months per page (2 pages total by default)
   - Month headers with ruled entry lines
   - Minimal structure for flexible use
   - Named destinations (`future_log_1`, `future_log_2`)

3. **Collection Pages** (`collection_page.rb`)
   - User-configured titled blank pages for custom collections
   - Examples: "Books to Read", "Project Ideas", "Recipes to Try"
   - Title header with optional subtitle
   - Full dot grid background for flexible use
   - Configured via `config/collections.yml`
   - Named destinations (`collection_<id>`) for hyperlinking from index

4. **Monthly Review Pages** (`monthly_review.rb`)
   - Prompt-based templates for monthly reflection
   - Three sections: What Worked, What Didn't Work, Focus for Next Month
   - Ruled lines for writing under each prompt
   - One page per month (12 pages total)
   - Named destinations (`review_1` through `review_12`)

5. **Quarterly Planning Pages** (`quarterly_planning.rb`)
   - 12-week planning cycles inspired by "12 Week Year"
   - Quarter header with date range (Q1: Jan-Mar, etc.)
   - Goals section with numbered prompts
   - 12-week grid with links to weekly pages
   - One page per quarter (4 pages total)
   - Named destinations (`quarter_1` through `quarter_4`)

6. **Seasonal Calendar** (`seasonal_calendar.rb`)
   - Grid-based layout with four seasons
   - Fieldset borders with season labels
   - Mini month calendars with clickable dates

7. **Year at a Glance** (`year_events.rb`, `year_highlights.rb`)
   - 12 columns (months) × 31 rows (days)
   - Day numbers with day-of-week abbreviations
   - Each cell links to corresponding week

8. **Weekly Pages** (`weekly_page.rb`)
   - Daily section (17.5% of usable height): 7 columns with headers and ruled lines
   - Cornell notes section (82.5%): Cues column (25%), Notes column (75%), Summary (20% of section)
   - Navigation links: previous/next week, back to year overview
   - Time period labels (AM/PM/EVE) on Monday column

9. **Grid Pages** (`grid_showcase.rb`, `grids_overview.rb`, `grids/` directory)
   - **Grid Showcase**: All grid types displayed in quadrants (entry point)
   - **Grids Overview**: Clickable samples of basic grids
   - **Dot Grid Page**: Full-page 5mm dot grid
   - **Graph Grid Page**: Full-page 5mm square grid
   - **Lined Grid Page**: Full-page 10mm ruled lines
   - **Isometric Grid Page**: Full-page 30-60-90 degree diamond grid
   - **Perspective Grid Page**: Full-page 1-point perspective with guide rectangles
   - **Hexagon Grid Page**: Full-page tessellating flat-top hexagons
   - Accessed via multi-tap Grids navigation tab (8 pages cycle)

10. **Tracker Example Page** (`tracker_example.rb`)
    - "Show, don't prescribe" example of grid usage
    - Habit tracker example with 31-day grid
    - Mood/energy log with weekly format
    - List of other tracking ideas
    - Inspires creativity without prescribing structure
    - Named destination `tracker_example`

11. **Reference Page** (`reference_calibration.rb`)
    - Calibration grid with measurements
    - Centimeter markings along edges
    - Grid system documentation
    - Prawn coordinate system reference

12. **Wheel Pages** (`daily_wheel.rb`, `year_wheel.rb`)
    - Daily Wheel: Circular daily planning template
    - Year Wheel: Circular year-at-a-glance visualization

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
6. **Character encoding** - Built-in fonts use Windows-1252, avoid fancy Unicode characters (arrows, em dashes, etc.). Use simple ASCII equivalents (->  instead of →, -- instead of —)

## Dependencies

- **prawn** ~> 2.4 - PDF generation library
- **Ruby date library** - Built-in Date class for calendar calculations

## Output

- **Filename**: `planner_{year}.pdf`
- **Page count**: 91+ pages typical (4 index + 2 future log + collections + 12 reviews + 4 quarters + 4 overview + 52-53 weekly + 8 grids + 4 templates)
- **File size**: ~4-5MB
- **Generation time**: Under 5 seconds

## Key Files

- **bin/bujo-pdf** - CLI executable for generating planners
- **bin/generate-examples** - Generate planners for current+next year in all themes
- **lib/bujo_pdf/** - Component-based generator library
  - **pages/** - Page classes (seasonal calendar, year-at-a-glance, weekly pages, grids)
  - **layouts/** - Layout classes (full page, standard with sidebars)
  - **components/** - Reusable components (week sidebar, navigation tabs, fieldsets)
  - **utilities/** - Helper classes (grid system, date calculator, grid renderers)
  - **themes/** - Color theme definitions (light, earth, dark)
- **config/** - Configuration file examples (dates.yml, calendars.yml)
- **Gemfile** - Dependencies specification

---
Last updated: 18e8f80
