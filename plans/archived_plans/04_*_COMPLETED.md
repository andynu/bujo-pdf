# Plan 04: Extract Reusable Sub-Components

## Executive Summary

This plan creates a foundational layer of reusable sub-components that will be used by higher-level page components. These sub-components represent common UI patterns that appear across multiple pages in the planner (weekly pages, year-at-a-glance, seasonal calendar). By extracting them now, we establish building blocks that will simplify the component extraction work in Plan 02.

## Dependencies

- **Requires**: Plan 01 (Extract Low-Level Utilities) - COMPLETED
- **Requires**: Plan 03 (Page Generation Pipeline) - COMPLETED
- **Precedes**: Plan 02 (Extract Components)

## Goals

1. Create reusable sub-components for common layout patterns
2. Establish a `SubComponent` base class with standard interface
3. Extract and encapsulate rendering logic for:
   - Week columns (daily columns with variable rows)
   - Calendar day grids (month calendars with day-of-week headers)
   - Year-month grids (year columns with month rows)
   - Fieldsets (bordered sections with legend labels)
   - Additional sub-components as identified
4. Enable grid-based positioning and sizing for all sub-components
5. Maintain backward compatibility with existing page generation

## Technical Approach

### Architecture

```
lib/bujo_pdf/
  component_context.rb   # Local coordinate system helper (NEW)
  sub_components/
    base.rb              # SubComponent base class
    week_column.rb       # Daily column component
    calendar_days.rb     # Month calendar grid
    year_months.rb       # Year-month grid (NEW)
    fieldset.rb          # Bordered section with legend
    ruled_lines.rb       # Horizontal ruled lines (NEW)
    day_header.rb        # Single day header cell (NEW)
```

### Base Class Interface

All sub-components will inherit from `SubComponent::Base` and implement:

```ruby
class SubComponent::Base
  attr_reader :pdf, :grid

  def initialize(pdf, grid_system, **options)
    @pdf = pdf
    @grid = grid_system
    @options = options
  end

  # Render at specific grid position
  def render_at(col, row, width_boxes, height_boxes)
    raise NotImplementedError
  end

  # Helper: create bounding box for component rendering
  def in_grid_box(col, row, width_boxes, height_boxes, &block)
    box = @grid.grid_rect(col, row, width_boxes, height_boxes)
    @pdf.bounding_box([box[:x], box[:y]],
                      width: box[:width],
                      height: box[:height], &block)
  end

  # Helper: create ComponentContext for local coordinate system
  def with_context(col, row, width_boxes, height_boxes, &block)
    box = @grid.grid_rect(col, row, width_boxes, height_boxes)
    ComponentContext.new(@pdf, box[:x], box[:y], box[:width], box[:height], &block)
  end
end
```

**Integration between Base and ComponentContext**:
Sub-components can use either:
1. `in_grid_box` - Simple bounding box (existing pattern)
2. `with_context` - Full ComponentContext with local grid + proportional helpers (new pattern)

Example:
```ruby
class WeekColumn < SubComponent::Base
  def render_at(col, row, width_boxes, height_boxes)
    # Use ComponentContext for complex layout with both grid and proportional needs
    with_context(col, row, width_boxes, height_boxes) do |ctx|
      # Local coordinate system available
      day_width = ctx.divide_width(7)
      header_height = ctx.grid_height(1.5)
      # ... render content
    end
  end
end
```

### Component Context for Local Coordinate Systems

To enable sub-components to work in their own local coordinate space with both grid quantization and proportional layouts, we introduce a `ComponentContext` helper:

```ruby
# Component context wraps a bounding box with local grid helpers
class ComponentContext
  attr_reader :width_pt, :height_pt, :width_boxes, :height_boxes

  def initialize(pdf, x, y, width_pt, height_pt)
    @pdf = pdf
    @width_pt = width_pt
    @height_pt = height_pt
    @width_boxes = width_pt / DOT_SPACING
    @height_boxes = height_pt / DOT_SPACING

    @pdf.bounding_box([x, y], width: width_pt, height: height_pt) do
      yield self
    end
  end

  # Local grid helpers (relative to component origin)
  def grid_x(col_fraction)
    col_fraction * DOT_SPACING
  end

  def grid_y(row_fraction)
    @height_pt - (row_fraction * DOT_SPACING)
  end

  def grid_width(boxes)
    boxes * DOT_SPACING
  end

  def grid_height(boxes)
    boxes * DOT_SPACING
  end

  # Proportional divisions - divide component space equally
  def divide_width(parts)
    @width_pt / parts.to_f
  end

  def divide_height(parts)
    @height_pt / parts.to_f
  end

  # Get sub-region (returns hash compatible with bounding_box)
  def region(col_fraction, row_fraction, width_boxes, height_boxes)
    {
      x: grid_x(col_fraction),
      y: grid_y(row_fraction),
      width: grid_width(width_boxes),
      height: grid_height(height_boxes)
    }
  end

  # Delegate unknown methods to underlying PDF for drawing operations
  def method_missing(method, *args, **kwargs, &block)
    @pdf.send(method, *args, **kwargs, &block)
  end

  def respond_to_missing?(method, include_private = false)
    @pdf.respond_to?(method, include_private) || super
  end
end
```

**Benefits of ComponentContext**:
- **Local coordinate system**: Grid methods work relative to component origin (0,0)
- **Grid quantization**: Use `grid_x`, `grid_y`, `grid_width`, `grid_height` for dot-grid alignment
- **Proportional layout**: Use `divide_width(7)` to split component into 7 equal columns
- **Hybrid approach**: Mix grid-based and proportional positioning as needed
- **Transparent PDF access**: Delegate drawing methods directly to PDF object

**Example Usage - Weekly daily columns**:
```ruby
# Get the daily section box in global grid coordinates
daily_box = grid_rect(content_start_col, content_start_row, content_width_boxes, daily_rows)

# Create component context for local coordinate system
ComponentContext.new(@pdf, daily_box[:x], daily_box[:y],
                     daily_box[:width], daily_box[:height]) do |ctx|
  day_width = ctx.divide_width(7)  # Divide into 7 equal columns

  7.times do |i|
    day_x = i * day_width

    # Create nested context for each day column
    ctx.bounding_box([day_x, ctx.height_pt], width: day_width, height: ctx.height_pt) do
      # Now working in day column's local coordinates!
      ctx.text_box "#{day_name}\n#{date}",
                   at: [PADDING, ctx.height_pt - PADDING],  # Local coordinates
                   width: day_width - (PADDING * 2),
                   height: ctx.grid_height(1.5)  # Use grid units for header height

      # Mix proportional and grid-based positioning
      line_y = ctx.grid_y(2.5)  # 2.5 boxes from top (grid-quantized)
      ctx.stroke_horizontal_line 0, day_width, at: line_y
    end
  end
end
```

**Example Usage - Cornell notes layout**:
```ruby
# Get the notes section box in global grid coordinates
notes_box = grid_rect(content_start_col, notes_start_row, content_width_boxes, notes_rows)

# Create component context for Cornell notes
ComponentContext.new(@pdf, notes_box[:x], notes_box[:y],
                     notes_box[:width], notes_box[:height]) do |ctx|
  # Proportional width division: 25% cues, 75% notes
  cues_width = ctx.divide_width(4)      # 25%
  notes_width = cues_width * 3          # 75%

  # Grid-based height division: 80% main area, 20% summary
  main_height = ctx.grid_height(ctx.height_boxes * 0.8)
  summary_height = ctx.height_pt - main_height

  # Cues column (local coordinates)
  ctx.bounding_box([0, ctx.height_pt], width: cues_width, height: main_height) do
    ctx.text_box "Cues", at: [ctx.grid_width(0.5), ctx.height_pt - ctx.grid_height(0.5)]
    ctx.stroke_bounds
  end

  # Notes column (local coordinates)
  ctx.bounding_box([cues_width, ctx.height_pt], width: notes_width, height: main_height) do
    ctx.text_box "Notes", at: [ctx.grid_width(0.5), ctx.height_pt - ctx.grid_height(0.5)]
    ctx.stroke_bounds
  end

  # Summary section spans full width (local coordinates)
  ctx.bounding_box([0, summary_height], width: ctx.width_pt, height: summary_height) do
    ctx.text_box "Summary", at: [ctx.grid_width(0.5), summary_height - ctx.grid_height(0.5)]
    ctx.stroke_bounds
  end
end
```

**Key benefits demonstrated**:
- **Proportional divisions**: Split width into 25%/75% for cues/notes without hardcoded widths
- **Grid quantization**: Use grid units for padding, margins, and vertical spacing
- **Local coordinates**: All positioning relative to component origin, not page origin
- **Nestable contexts**: Each section can have its own ComponentContext
- **Mixed units**: Combine proportional percentages with grid-based measurements

### Design Principles

1. **Grid-based positioning**: All components position themselves using grid coordinates
2. **Local coordinate systems**: Components work in their own coordinate space using ComponentContext
3. **Hybrid layout**: Support both grid-quantized (for alignment) and proportional (for divisions) positioning
4. **Configuration over hardcoding**: Accept configuration options for styling, content, behavior
5. **Composability**: Sub-components can contain other sub-components
6. **Single responsibility**: Each component handles one specific UI pattern
7. **Testability**: Components can be tested independently with mock PDF/grid objects

## Implementation Steps

### 1. Create SubComponent Base Class and ComponentContext

**Files**:
- `lib/bujo_pdf/sub_components/base.rb`
- `lib/bujo_pdf/component_context.rb`

**Tasks**:
- 1.1 Define `SubComponent::Base` class
- 1.2 Implement `initialize(pdf, grid_system, **options)` constructor
- 1.3 Add `render_at(col, row, width_boxes, height_boxes)` abstract method
- 1.4 Add `in_grid_box` helper for bounding box creation
- 1.5 Add attribute accessors for `pdf`, `grid`, `options`
- 1.6 Define `ComponentContext` class for local coordinate systems
- 1.7 Implement local grid helpers (`grid_x`, `grid_y`, `grid_width`, `grid_height`)
- 1.8 Implement proportional division helpers (`divide_width`, `divide_height`)
- 1.9 Implement `region` method for sub-region calculation
- 1.10 Add `method_missing` delegation to underlying PDF object
- 1.11 Document both classes with YARD comments and usage examples

### 2. Extract WeekColumn Sub-Component

**File**: `lib/bujo_pdf/sub_components/week_column.rb`

**Purpose**: Render a single day column in the weekly view with configurable rows.

**Current location**: `gen.rb:1115-1169` (within `draw_weekly_page`)

**Configuration**:
```ruby
{
  date: Date.new(2025, 1, 6),           # The date for this column
  day_name: "Monday",                    # Day name for header
  rows: 9,                               # Number of grid rows for column
  show_time_labels: true,                # Show AM/PM/EVE labels (Monday only)
  line_spacing_boxes: 1.5,               # Spacing between ruled lines
  header_size_boxes: 1.5,                # Height of day header
  weekend: false                          # Apply weekend styling
}
```

**Tasks**:
- 2.1 Create `WeekColumn` class inheriting from `SubComponent::Base`
- 2.2 Implement `render_at` using ComponentContext for local coordinates
  - 2.2.1 Create ComponentContext for the column's bounding box
  - 2.2.2 Draw day header using local grid coordinates
  - 2.2.3 Apply weekend background color if applicable
  - 2.2.4 Draw ruled lines using local proportional spacing
  - 2.2.5 Add time labels (AM/PM/EVE) if configured
  - 2.2.6 Draw border around column
- 2.3 Extract styling constants (colors, fonts) from options
- 2.4 Demonstrate hybrid layout: grid-quantized header + proportional line spacing
- 2.5 Add unit tests for WeekColumn rendering
- 2.6 Update `draw_weekly_page` to use WeekColumn component

### 3. Extract CalendarDays Sub-Component

**File**: `lib/bujo_pdf/sub_components/calendar_days.rb`

**Purpose**: Render a month calendar grid with day-of-week headers, numeric days, and week links.

**Current location**: `gen.rb:813-967` (within `draw_year_at_glance`)

**Configuration**:
```ruby
{
  year: 2025,
  month: 1,                              # 1-12
  month_name: "January",                 # Display name
  show_month_header: true,               # Display month name header
  link_to_weeks: true,                   # Make days clickable to week pages
  highlight_today: false,                # Highlight current day (optional)
  days_row_start: 3,                     # Grid row for day numbers
  days_row_count: 50,                    # Number of rows for days (handles up to 31)
  show_dow_headers: true                 # Show day-of-week abbreviations
}
```

**Tasks**:
- 3.1 Create `CalendarDays` class inheriting from `SubComponent::Base`
- 3.2 Implement `render_at` to draw calendar month
  - 3.2.1 Draw month header (if configured)
  - 3.2.2 Draw day-of-week abbreviation headers
  - 3.2.3 Calculate week numbers for each day
  - 3.2.4 Draw day number cells (1-31)
  - 3.2.5 Add link annotations to week pages
  - 3.2.6 Apply borders and styling
- 3.3 Extract date calculation logic to helper methods
- 3.4 Add unit tests for CalendarDays
- 3.5 Update `draw_year_at_glance` to use CalendarDays component

### 4. Create YearMonths Sub-Component (NEW)

**File**: `lib/bujo_pdf/sub_components/year_months.rb`

**Purpose**: Render a grid with year columns and month rows (inverse of CalendarDays).

**Use case**: Alternative year-at-a-glance view, future planning pages.

**Configuration**:
```ruby
{
  start_year: 2025,
  year_count: 3,                         # Number of years to display
  months: 12,                            # Number of months (rows)
  show_year_headers: true,               # Column headers with year
  show_month_labels: true,               # Row labels with month names
  cell_content: :blank,                  # :blank, :checkbox, :dot
  borders: :full                         # :full, :outer, :none
}
```

**Tasks**:
- 4.1 Create `YearMonths` class inheriting from `SubComponent::Base`
- 4.2 Implement `render_at` to draw year-month grid
  - 4.2.1 Calculate column width (years) and row height (months)
  - 4.2.2 Draw year column headers
  - 4.2.3 Draw month row labels
  - 4.2.4 Draw grid cells with configured content
  - 4.2.5 Apply borders and styling
- 4.3 Add configuration for cell rendering (blank, checkbox, dot)
- 4.4 Add unit tests for YearMonths
- 4.5 Document use cases and examples

### 5. Extract Fieldset Sub-Component

**File**: `lib/bujo_pdf/sub_components/fieldset.rb`

**Purpose**: Draw HTML-like `<fieldset>` borders with legend labels.

**Current location**: `gen.rb:356-522` (existing `draw_fieldset` method)

**Configuration**:
```ruby
{
  legend: "Winter",                      # Legend text
  legend_position: :top_left,            # :top_left, :top_right, :bottom_left, :bottom_right
  legend_rotation: 90,                   # Rotation angle (90, -90, 0)
  legend_font: "Helvetica",
  legend_size: 10,
  inset_boxes: 0.5,                      # Border inset from edge
  legend_offset: [0, 0],                 # Fine-tuning adjustment [x, y]
  border_color: 'E5E5E5',
  content_block: nil                      # Optional block to render content inside
}
```

**Tasks**:
- 5.1 Create `Fieldset` class inheriting from `SubComponent::Base`
- 5.2 Implement `render_at` to draw fieldset
  - 5.2.1 Calculate inset boundaries
  - 5.2.2 Draw border rectangle with gap for legend
  - 5.2.3 Position and rotate legend text
  - 5.2.4 Execute content block if provided
- 5.3 Refactor existing `draw_fieldset` to delegate to component
- 5.4 Add unit tests for Fieldset with various configurations
- 5.5 Update seasonal calendar to use Fieldset component

### 6. Extract RuledLines Sub-Component (NEW)

**File**: `lib/bujo_pdf/sub_components/ruled_lines.rb`

**Purpose**: Draw horizontal ruled lines for writing, with configurable spacing and style.

**Use case**: Daily sections, note areas, summary sections.

**Configuration**:
```ruby
{
  line_spacing_boxes: 1.5,               # Spacing between lines
  line_color: 'E5E5E5',                  # Line color
  line_width: 0.5,                       # Line stroke width
  margin_left_boxes: 0,                  # Left margin
  margin_right_boxes: 0,                 # Right margin
  skip_first: false,                     # Skip first line
  line_style: :solid                     # :solid, :dashed, :dotted
}
```

**Tasks**:
- 6.1 Create `RuledLines` class inheriting from `SubComponent::Base`
- 6.2 Implement `render_at` to draw ruled lines
  - 6.2.1 Calculate number of lines that fit in height
  - 6.2.2 Apply left/right margins
  - 6.2.3 Draw lines with configured spacing
  - 6.2.4 Support different line styles
- 6.3 Add unit tests for RuledLines
- 6.4 Update WeekColumn to optionally use RuledLines component

### 7. Extract DayHeader Sub-Component (NEW)

**File**: `lib/bujo_pdf/sub_components/day_header.rb`

**Purpose**: Render a single day header cell with date information.

**Use case**: Weekly pages, calendar views.

**Configuration**:
```ruby
{
  date: Date.new(2025, 1, 6),
  format: :full,                         # :full, :short, :abbrev
  show_day_name: true,
  show_date_number: true,
  show_month: false,
  weekend: false,
  font_size: 10,
  header_height_boxes: 1.5
}
```

**Tasks**:
- 7.1 Create `DayHeader` class inheriting from `SubComponent::Base`
- 7.2 Implement `render_at` to draw day header
  - 7.2.1 Format date string based on configuration
  - 7.2.2 Apply weekend styling if applicable
  - 7.2.3 Draw header with proper alignment
- 7.3 Add unit tests for DayHeader
- 7.4 Update WeekColumn to optionally use DayHeader component

### 8. Integration and Testing

**Tasks**:
- 8.1 Create integration tests that combine sub-components
- 8.2 Verify backward compatibility with existing page generation
- 8.3 Generate full planner PDF and compare with baseline
- 8.4 Update documentation with sub-component usage examples
- 8.5 Add visual regression tests for sub-components (optional)

### 9. Update PlannerGenerator Integration

**Tasks**:
- 9.1 Add sub-component factory methods to PlannerGenerator
  - 9.1.1 `create_week_column(**options)`
  - 9.1.2 `create_calendar_days(**options)`
  - 9.1.3 `create_year_months(**options)`
  - 9.1.4 `create_fieldset(**options)`
  - 9.1.5 `create_ruled_lines(**options)`
  - 9.1.6 `create_day_header(**options)`
- 9.2 Refactor page generation methods to use sub-components
  - 9.2.1 Update `draw_weekly_page` to use WeekColumn
  - 9.2.2 Update `draw_year_at_glance` to use CalendarDays
  - 9.2.3 Update seasonal calendar to use Fieldset
- 9.3 Maintain backward compatibility with legacy methods
- 9.4 Add deprecation warnings for old methods (optional)

### 10. Documentation

**Tasks**:
- 10.1 Write YARD documentation for all sub-component classes
- 10.2 Create usage guide in `docs/sub_components.md`
- 10.3 Add code examples for each sub-component
- 10.4 Document configuration options comprehensively
- 10.5 Create visual reference guide with screenshots (optional)

## Testing Strategy

### Unit Tests

Each sub-component will have unit tests covering:
- Rendering with default configuration
- Rendering with custom configuration
- Grid positioning accuracy
- Color and styling application
- Edge cases (boundary dates, extreme sizes)

### ComponentContext Tests

Dedicated tests for ComponentContext functionality:
- Local grid coordinate calculations (grid_x, grid_y, grid_width, grid_height)
- Proportional division calculations (divide_width, divide_height)
- Region calculation accuracy
- Nested ComponentContext behavior
- PDF method delegation
- Integration with bounding_box coordinate transformations

### Integration Tests

Test sub-component composition:
- WeekColumn containing RuledLines and DayHeader
- CalendarDays rendering 12 months
- Fieldset containing other sub-components
- Full page generation using multiple sub-components

### Regression Tests

- Generate complete planner PDF before and after refactoring
- Compare page count, dimensions, visual appearance
- Verify all links still work correctly
- Ensure grid alignment maintained

## Acceptance Criteria

### Functional Requirements

- ✅ All identified sub-components extracted and functional
- ✅ Sub-components can be positioned at any grid coordinate
- ✅ Sub-components accept configuration for styling and behavior
- ✅ Backward compatibility maintained with existing page generation
- ✅ Generated PDFs match baseline output

### Code Quality

- ✅ All sub-components inherit from `SubComponent::Base`
- ✅ Comprehensive unit test coverage (>80%)
- ✅ YARD documentation for all public methods
- ✅ No hardcoded values (use configuration or constants)
- ✅ Code follows existing style conventions

### Documentation

- ✅ Usage guide created with examples
- ✅ Configuration options documented
- ✅ Integration patterns explained
- ✅ Migration guide for existing code

## Migration Path

### Phase 1: Create Infrastructure (Steps 1)
- Establish base class and patterns
- Set up testing infrastructure

### Phase 2: Extract Existing Components (Steps 2, 3, 5)
- Migrate existing rendering logic to sub-components
- Maintain parallel legacy methods

### Phase 3: Create New Components (Steps 4, 6, 7)
- Build additional sub-components identified during extraction
- Enhance capabilities beyond current implementation

### Phase 4: Integration (Steps 8, 9)
- Update PlannerGenerator to use sub-components
- Remove or deprecate legacy methods
- Comprehensive testing

### Phase 5: Documentation (Step 10)
- Complete documentation suite
- Create examples and guides

## Benefits

1. **Reusability**: Sub-components can be used across multiple pages and contexts
2. **Maintainability**: Isolated logic is easier to understand and modify
3. **Testability**: Components can be tested independently
4. **Consistency**: Shared components ensure consistent appearance
5. **Extensibility**: Easy to create variations or new sub-components
6. **Composability**: Complex layouts built from simple building blocks
7. **Foundation for Plan 02**: Simplifies higher-level component extraction
8. **Local coordinate clarity**: ComponentContext eliminates confusion between global and local coordinates
9. **Hybrid layout power**: Supports both grid quantization (alignment) and proportional division (equal spacing)
10. **Reduced cognitive load**: Components think in their own space, not parent's coordinate system

## Risks and Mitigation

### Risk: Breaking existing PDF generation
**Mitigation**: Maintain parallel legacy methods, comprehensive regression testing

### Risk: Over-engineering simple components
**Mitigation**: Keep configuration minimal, add options only as needed

### Risk: Performance overhead from abstraction
**Mitigation**: Profile PDF generation before/after, optimize hot paths

### Risk: Inconsistent interfaces across components
**Mitigation**: Enforce base class contract, code reviews

## Next Steps After Completion

1. Begin Plan 02: Extract Components (Sidebars, Navigation, Pages)
2. Use sub-components as building blocks for higher-level components
3. Consider extracting additional sub-components as patterns emerge
4. Evaluate creating a component library/catalog

## Notes

- Sub-components are lower-level than the components in Plan 02
- Sub-components are "dumb" renderers - they don't manage context or state
- Higher-level components (Plan 02) will compose sub-components and add behavior
- Keep sub-components focused on rendering, not business logic
- Configuration should be explicit, avoid "magic" behavior
