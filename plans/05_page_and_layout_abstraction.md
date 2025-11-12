# Plan 05: Page and Layout Abstraction Layer

## Executive Summary

This plan introduces a **Page abstraction layer** that sits between the generator and components, establishing a three-tier architecture: **Sub-Components** (Plan 04) → **Components** (Plan 02, refined) → **Pages** (Plan 05, new) → **Layouts** (future). This enables a clean DSL for defining pages and will integrate seamlessly with a future layout system that constrains available rows/columns for content areas.

### Architecture Vision

```
┌─────────────────────────────────────────────────────────┐
│ PlannerGenerator (Orchestration)                        │
│ - Manages PDF lifecycle                                  │
│ - Creates pages with layouts                             │
│ - Handles navigation destinations                        │
└─────────────────────────────────────────────────────────┘
                          │
                          │ creates
                          ▼
┌─────────────────────────────────────────────────────────┐
│ Layout (Future Plan - defines constraints)              │
│ - Specifies content area boundaries (rows/cols)         │
│ - Defines sidebar positions and widths                   │
│ - Sets navigation zones                                  │
│ - Provides theme/styling configuration                   │
└─────────────────────────────────────────────────────────┘
                          │
                          │ applies to
                          ▼
┌─────────────────────────────────────────────────────────┐
│ Page (New - Plan 05)                                    │
│ - Encapsulates a single PDF page                        │
│ - Applies layout constraints to content area            │
│ - Manages background (dot grid, etc.)                   │
│ - Coordinates component rendering within constraints    │
│ - Provides DSL for declarative page definition          │
└─────────────────────────────────────────────────────────┘
                          │
                          │ contains
                          ▼
┌─────────────────────────────────────────────────────────┐
│ Component (Plan 02 - page-level coordinators)           │
│ - Positioned within page content area                   │
│ - Compose sub-components into sections                  │
│ - Handle local layout logic                             │
│ - Examples: DailySection, CornellNotes, SeasonalCalendar│
└─────────────────────────────────────────────────────────┘
                          │
                          │ uses
                          ▼
┌─────────────────────────────────────────────────────────┐
│ SubComponent (Plan 04 - building blocks)                │
│ - Low-level rendering primitives                        │
│ - Stateless, positioned via render_at()                 │
│ - Examples: WeekColumn, Fieldset, RuledLines            │
└─────────────────────────────────────────────────────────┘
```

### Key Terminology

- **SubComponent** (Plan 04): Low-level rendering primitive (e.g., `WeekColumn`, `Fieldset`, `RuledLines`)
- **Component** (Plan 02): Page-level coordinator that composes sub-components (e.g., `DailySection`, `CornellNotes`)
- **Page** (Plan 05): Complete PDF page that contains components, applies layouts, manages backgrounds
- **Layout** (Future): Reusable constraint specification (content area, sidebars, navigation zones)

## Dependencies

- **Requires**: Plan 01 (Extract Low-Level Utilities) - ✅ COMPLETED
- **Requires**: Plan 03 (Page Generation Pipeline) - ✅ COMPLETED
- **Requires**: Plan 04 (Extract Reusable Sub-Components) - ✅ COMPLETED
- **Precedes**: Plan 02 (Extract Components) - Will be modified to work with Page abstraction
- **Enables**: Future Layout Management System

## Goals

1. **Create Page base class** that encapsulates a single PDF page
2. **Establish page lifecycle** (initialize → setup → render components → finalize)
3. **Define content area constraints** that components must respect
4. **Enable layout integration** for future layout system
5. **Provide DSL for page definition** making it easy to declaratively define pages
6. **Maintain backward compatibility** during transition

## Technical Approach

### 1. Page Base Class Design

```ruby
# lib/bujo_pdf/page.rb
class Page
  attr_reader :pdf, :grid, :content_area, :layout

  def initialize(pdf, grid_system, layout: nil, **options)
    @pdf = pdf
    @grid = grid_system
    @layout = layout || default_layout
    @options = options
    @components = []

    # Content area constrained by layout
    @content_area = calculate_content_area

    validate_configuration
  end

  # Main rendering pipeline
  def render
    setup_page      # Background, grid, etc.
    render_chrome   # Sidebars, navigation (outside content area)
    render_content  # Components (within content area)
    finalize_page   # Footer, diagnostics, etc.
  end

  # Override in subclasses to define page-specific logic
  def setup_page
    draw_background if layout.background_enabled?
    draw_debug_grid if layout.debug_mode?
  end

  def render_chrome
    # Override to render sidebars, navigation
    # Uses layout.sidebar_area, layout.nav_area, etc.
  end

  def render_content
    # Render all registered components within content_area
    @components.each do |component|
      component.render
    end
  end

  def finalize_page
    draw_footer if layout.footer_enabled?
    add_page_annotations
  end

  # DSL methods for adding components
  def add_component(component_class, **options)
    # Position component within content_area constraints
    component = component_class.new(@pdf, @grid, content_area: @content_area, **options)
    @components << component
    component
  end

  # Helper to access layout constraints
  def content_cols
    content_area[:width_boxes]
  end

  def content_rows
    content_area[:height_boxes]
  end

  protected

  def default_layout
    # Return sensible defaults (full page content area)
    Layout.new(content_area: { col: 0, row: 0, width: 43, height: 55 })
  end

  def calculate_content_area
    # Extract content area from layout specification
    area = @layout.content_area_spec
    {
      col: area[:col],
      row: area[:row],
      width_boxes: area[:width],
      height_boxes: area[:height],
      # Computed values
      x: @grid.grid_x(area[:col]),
      y: @grid.grid_y(area[:row]),
      width_pt: @grid.grid_width(area[:width]),
      height_pt: @grid.grid_height(area[:height])
    }
  end

  def validate_configuration
    # Ensure layout is valid, options are correct
  end

  # Background rendering
  def draw_background
    case @layout.background_type
    when :dot_grid
      @pdf.stamp("page_dots")
    when :ruled
      # Future: ruled lines background
    when :blank
      # Nothing
    end
  end

  def draw_debug_grid
    if defined?(Diagnostics) && @layout.debug_mode?
      Diagnostics.draw_diagnostic_grid(@pdf, @grid, label_every: 5)
    end
  end

  def draw_footer
    # Future: footer rendering
  end

  def add_page_annotations
    # Named destinations, metadata, etc.
  end
end
```

### 2. Layout Specification (Minimal for Plan 05)

For Plan 05, we introduce a minimal `Layout` class to establish the pattern. The full layout system will be a future plan.

```ruby
# lib/bujo_pdf/layout.rb
class Layout
  attr_reader :name, :content_area_spec, :sidebar_specs, :options

  def initialize(name: "default", content_area:, sidebars: [], **options)
    @name = name
    @content_area_spec = content_area  # { col:, row:, width:, height: }
    @sidebar_specs = sidebars           # [{ position:, col:, row:, width:, height: }]
    @options = options
  end

  def background_enabled?
    @options.fetch(:background, true)
  end

  def background_type
    @options.fetch(:background_type, :dot_grid)
  end

  def debug_mode?
    @options.fetch(:debug, false)
  end

  def footer_enabled?
    @options.fetch(:footer, false)
  end

  # Predefined layouts (factory methods)
  def self.full_page
    new(
      name: "full_page",
      content_area: { col: 0, row: 0, width: 43, height: 55 }
    )
  end

  def self.with_sidebars(left_width: 2, right_width: 1, top_height: 2)
    new(
      name: "with_sidebars",
      content_area: {
        col: left_width,
        row: top_height,
        width: 43 - left_width - right_width,
        height: 55 - top_height
      },
      sidebars: [
        { position: :left, col: 0, row: 0, width: left_width, height: 55 },
        { position: :right, col: 43 - right_width, row: 0, width: right_width, height: 55 },
        { position: :top, col: left_width, row: 0, width: 43 - left_width - right_width, height: top_height }
      ]
    )
  end

  def self.weekly_layout
    # Standard weekly page layout: left sidebar (2 cols), top nav (2 rows), right sidebar (1 col)
    with_sidebars(left_width: 2, right_width: 1, top_height: 2)
  end
end
```

### 3. Concrete Page Classes

Each page type in the planner becomes a concrete `Page` subclass:

```ruby
# lib/bujo_pdf/pages/weekly_page.rb
class Pages::WeeklyPage < Page
  def initialize(pdf, grid_system, week_num:, start_date:, total_weeks:, year:, **options)
    @week_num = week_num
    @start_date = start_date
    @total_weeks = total_weeks
    @year = year

    # Use weekly layout
    super(pdf, grid_system, layout: Layout.weekly_layout, **options)
  end

  def render_chrome
    # Top navigation
    add_chrome_component(Components::TopNavigation,
      week_num: @week_num,
      total_weeks: @total_weeks,
      start_date: @start_date,
      year: @year
    )

    # Left sidebar (week list)
    add_chrome_component(Components::WeekSidebar,
      current_week_num: @week_num,
      total_weeks: @total_weeks,
      year: @year
    )

    # Right sidebar (tabs)
    add_chrome_component(Components::RightSidebar,
      top_tabs: [
        { label: "Year", dest: "seasonal" },
        { label: "Events", dest: "year_events" },
        { label: "Highlights", dest: "year_highlights" }
      ],
      bottom_tabs: [
        { label: "Dots", dest: "dots" }
      ]
    )
  end

  def render_content
    # Daily section (top 17.5% of content area)
    daily_height = (content_rows * 0.175).round
    add_component(Components::DailySection,
      start_date: @start_date,
      height_boxes: daily_height
    )

    # Cornell notes (remaining 82.5%)
    notes_start_row = content_area[:row] + daily_height
    notes_height = content_rows - daily_height
    add_component(Components::CornellNotes,
      start_row: notes_start_row,
      height_boxes: notes_height
    )
  end

  def add_page_annotations
    @pdf.add_dest("week_#{@week_num}", @pdf.dest_fit)
  end

  private

  def add_chrome_component(component_class, **options)
    # Chrome components render outside content area
    # They get full grid access, not constrained by content_area
    component = component_class.new(@pdf, @grid, **options)
    component.render
  end
end
```

```ruby
# lib/bujo_pdf/pages/seasonal_calendar_page.rb
class Pages::SeasonalCalendarPage < Page
  def initialize(pdf, grid_system, year:, **options)
    @year = year

    # Use layout with sidebars but no top nav
    layout = Layout.with_sidebars(left_width: 2, right_width: 1, top_height: 2)
    super(pdf, grid_system, layout: layout, **options)
  end

  def render_chrome
    # Left sidebar (week list)
    add_chrome_component(Components::WeekSidebar,
      current_week_num: nil,  # No current week on overview page
      total_weeks: calculate_total_weeks(@year),
      year: @year
    )

    # Right sidebar
    add_chrome_component(Components::RightSidebar,
      top_tabs: default_year_tabs,
      bottom_tabs: [{ label: "Dots", dest: "dots" }]
    )
  end

  def render_content
    # Seasonal calendar fills entire content area
    add_component(Components::SeasonalCalendar,
      year: @year
    )
  end

  def add_page_annotations
    @pdf.add_dest("seasonal", @pdf.dest_fit)
  end

  private

  def add_chrome_component(component_class, **options)
    component = component_class.new(@pdf, @grid, **options)
    component.render
  end

  def default_year_tabs
    [
      { label: "Year", dest: "seasonal" },
      { label: "Events", dest: "year_events" },
      { label: "Highlights", dest: "year_highlights" }
    ]
  end

  def calculate_total_weeks(year)
    # Delegate to DateCalculator or extract to utility
    # Placeholder for now
    52
  end
end
```

```ruby
# lib/bujo_pdf/pages/year_at_glance_page.rb
class Pages::YearAtGlancePage < Page
  def initialize(pdf, grid_system, year:, page_type:, **options)
    @year = year
    @page_type = page_type  # :events or :highlights

    layout = Layout.with_sidebars(left_width: 2, right_width: 1, top_height: 2)
    super(pdf, grid_system, layout: layout, **options)
  end

  def render_chrome
    # Similar to seasonal calendar
    add_chrome_component(Components::WeekSidebar,
      current_week_num: nil,
      total_weeks: 52,
      year: @year
    )

    add_chrome_component(Components::RightSidebar,
      top_tabs: year_tabs,
      bottom_tabs: [{ label: "Dots", dest: "dots" }]
    )
  end

  def render_content
    # 12×31 grid for events/highlights
    add_component(Components::YearAtGlance,
      year: @year,
      title: page_title
    )
  end

  def add_page_annotations
    dest_name = @page_type == :events ? "year_events" : "year_highlights"
    @pdf.add_dest(dest_name, @pdf.dest_fit)
  end

  private

  def page_title
    @page_type == :events ? "Year at a Glance - Events" : "Year at a Glance - Highlights"
  end

  def year_tabs
    [
      { label: "Year", dest: "seasonal" },
      { label: "Events", dest: "year_events" },
      { label: "Highlights", dest: "year_highlights" }
    ]
  end

  def add_chrome_component(component_class, **options)
    component = component_class.new(@pdf, @grid, **options)
    component.render
  end
end
```

### 4. DSL Usage Vision

With this architecture, generating a planner becomes declarative:

```ruby
# In PlannerGenerator
def generate_weekly_page(week_num, start_date)
  page = Pages::WeeklyPage.new(@pdf, @grid_system,
    week_num: week_num,
    start_date: start_date,
    total_weeks: @total_weeks,
    year: @year
  )

  page.render
end

def generate_seasonal_calendar
  page = Pages::SeasonalCalendarPage.new(@pdf, @grid_system, year: @year)
  page.render
end

def generate_year_at_glance_events
  page = Pages::YearAtGlancePage.new(@pdf, @grid_system,
    year: @year,
    page_type: :events
  )
  page.render
end
```

Even cleaner with a future DSL builder:

```ruby
# Future vision (not in Plan 05 scope)
planner do
  year 2025

  page :seasonal_calendar do
    layout :with_sidebars
    component :seasonal_calendar
  end

  52.times do |week_num|
    page :weekly, week: week_num + 1 do
      layout :weekly_layout
      component :daily_section, height: "17.5%"
      component :cornell_notes, height: "82.5%"
    end
  end

  page :year_at_glance, type: :events
  page :year_at_glance, type: :highlights
end
```

### 5. Component Base Class Update

Components (Plan 02) will be updated to work with content area constraints:

```ruby
# lib/bujo_pdf/component.rb
class Component
  attr_reader :pdf, :grid, :content_area

  def initialize(pdf, grid_system, content_area: nil, **options)
    @pdf = pdf
    @grid = grid_system
    @content_area = content_area  # Constraints from page
    @options = options

    validate_configuration
  end

  # Main rendering method - must be implemented by subclasses
  def render
    raise NotImplementedError, "#{self.class} must implement #render"
  end

  # Helper: position within content area
  def content_col(offset = 0)
    content_area ? content_area[:col] + offset : offset
  end

  def content_row(offset = 0)
    content_area ? content_area[:row] + offset : offset
  end

  def available_width
    content_area ? content_area[:width_boxes] : 43
  end

  def available_height
    content_area ? content_area[:height_boxes] : 55
  end

  # Factory methods for sub-components (from Plan 04)
  def create_sub_component(klass, **options)
    klass.new(@pdf, @grid, **options)
  end

  def create_week_column(**options)
    create_sub_component(SubComponent::WeekColumn, **options)
  end

  def create_fieldset(**options)
    create_sub_component(SubComponent::Fieldset, **options)
  end

  def create_ruled_lines(**options)
    create_sub_component(SubComponent::RuledLines, **options)
  end

  # ... other factory methods

  protected

  def validate_configuration
    # Override in subclasses to validate required options
  end

  # Convenience delegators to grid_system
  def grid_x(col); @grid.grid_x(col); end
  def grid_y(row); @grid.grid_y(row); end
  def grid_width(boxes); @grid.grid_width(boxes); end
  def grid_height(boxes); @grid.grid_height(boxes); end
  def grid_rect(col, row, w, h); @grid.grid_rect(col, row, w, h); end
end
```

## Implementation Steps

### 1. Create Page Infrastructure

**Files**:
- `lib/bujo_pdf/page.rb` - Base Page class
- `lib/bujo_pdf/layout.rb` - Minimal Layout class
- `lib/bujo_pdf/pages/` - Directory for concrete page classes

**Tasks**:
- 1.1 Define `Page` base class with lifecycle methods
- 1.2 Implement `setup_page`, `render_chrome`, `render_content`, `finalize_page` hooks
- 1.3 Add `content_area` calculation from layout
- 1.4 Implement `add_component` DSL method
- 1.5 Add background and debug grid rendering
- 1.6 Define minimal `Layout` class with factory methods
- 1.7 Create predefined layouts: `full_page`, `with_sidebars`, `weekly_layout`
- 1.8 Add comprehensive YARD documentation

### 2. Create Concrete Page Classes

**Files**:
- `lib/bujo_pdf/pages/weekly_page.rb`
- `lib/bujo_pdf/pages/seasonal_calendar_page.rb`
- `lib/bujo_pdf/pages/year_at_glance_page.rb`
- `lib/bujo_pdf/pages/reference_page.rb`
- `lib/bujo_pdf/pages/blank_dots_page.rb`

**Tasks**:
- 2.1 Implement `WeeklyPage` with chrome and content rendering
- 2.2 Implement `SeasonalCalendarPage`
- 2.3 Implement `YearAtGlancePage` with event/highlight variants
- 2.4 Implement `ReferencePage` for calibration grid
- 2.5 Implement `BlankDotsPage` for blank dot grid template
- 2.6 Add tests for each page class

### 3. Update Component Base Class

**File**: `lib/bujo_pdf/component.rb`

**Tasks**:
- 3.1 Add `content_area` parameter to constructor
- 3.2 Implement helper methods: `content_col`, `content_row`, `available_width`, `available_height`
- 3.3 Update factory methods to remain unchanged
- 3.4 Ensure backward compatibility with components not using content area
- 3.5 Add validation for content area boundaries
- 3.6 Update documentation

### 4. Refactor PlannerGenerator

**File**: `gen.rb` or `lib/bujo_pdf/planner_generator.rb`

**Tasks**:
- 4.1 Update `generate_seasonal_calendar` to use `Pages::SeasonalCalendarPage`
- 4.2 Update `generate_year_at_glance_*` to use `Pages::YearAtGlancePage`
- 4.3 Update `generate_weekly_pages` to use `Pages::WeeklyPage`
- 4.4 Update `generate_reference_page` to use `Pages::ReferencePage`
- 4.5 Update `generate_dots_page` to use `Pages::BlankDotsPage`
- 4.6 Maintain backward compatibility during transition
- 4.7 Add deprecation warnings for old methods (optional)

### 5. Integration with Plan 02 Components

**Context**: This plan establishes the page layer. Plan 02 components will be extracted to work within this system.

**Tasks**:
- 5.1 Ensure Component base class (from Step 3) is compatible with Plan 02 components
- 5.2 Document how components should use `content_area` constraints
- 5.3 Create integration examples showing Page → Component → SubComponent hierarchy
- 5.4 Update Plan 02 to reference this page abstraction

### 6. Testing

**Files**:
- `test/page_test.rb` - Base Page class tests
- `test/layout_test.rb` - Layout class tests
- `test/pages/weekly_page_test.rb`
- `test/pages/seasonal_calendar_page_test.rb`
- `test/pages/year_at_glance_page_test.rb`

**Tasks**:
- 6.1 Write unit tests for `Page` base class
- 6.2 Write unit tests for `Layout` class and factory methods
- 6.3 Write tests for each concrete page class
- 6.4 Test content area constraint calculations
- 6.5 Integration tests: Page → Component → SubComponent rendering
- 6.6 Regression tests: Compare PDF output before/after refactoring

### 7. Documentation

**Files**:
- `docs/pages.md` - Page system guide
- `docs/layouts.md` - Layout system guide (minimal for Plan 05)
- Update `CLAUDE.md` - Reflect new architecture

**Tasks**:
- 7.1 Document Page lifecycle and hooks
- 7.2 Document Layout specification format
- 7.3 Create usage examples for defining custom pages
- 7.4 Document content area constraints and how components use them
- 7.5 Create visual diagrams showing hierarchy
- 7.6 Update project README with new architecture

### 8. Future Layout System Preparation

**Note**: This is preparation work, not full implementation.

**Tasks**:
- 8.1 Document requirements for future comprehensive layout system
- 8.2 Identify additional layout patterns needed (sidebar variations, multi-column, etc.)
- 8.3 Design layout DSL syntax for future plan
- 8.4 Create placeholder for layout persistence/loading (YAML/JSON)

## Testing Strategy

### Unit Tests

- **Page base class**: Lifecycle methods, content area calculation, component registration
- **Layout class**: Factory methods, constraint calculations, validation
- **Concrete pages**: Rendering logic, chrome placement, content positioning

### Integration Tests

- **Page → Component flow**: Verify components receive correct content area constraints
- **Component → SubComponent flow**: Verify sub-components render correctly within constraints
- **Full page rendering**: Generate complete pages and verify output

### Regression Tests

- **PDF comparison**: Generate full planner before/after, compare visually
- **Link functionality**: Verify all navigation links still work
- **Grid alignment**: Ensure all elements still align to dot grid

## Acceptance Criteria

### Functional Requirements

- ✅ Page base class provides complete lifecycle hooks
- ✅ Layout system constrains component rendering to content area
- ✅ All existing page types converted to new Page classes
- ✅ Generated PDFs match previous output exactly
- ✅ Components respect content area boundaries

### Code Quality

- ✅ Clear separation: Page (chrome + background) vs Component (content)
- ✅ Comprehensive test coverage (>85%)
- ✅ YARD documentation for all public APIs
- ✅ No hardcoded layout values (use Layout objects)
- ✅ Backward compatibility maintained during transition

### Documentation

- ✅ Page system guide with examples
- ✅ Layout specification documented
- ✅ Migration guide for existing code
- ✅ Architecture diagrams updated

## Benefits

1. **Clear separation of concerns**: Page (structure) vs Component (content) vs SubComponent (primitives)
2. **Reusable layouts**: Define layout once, apply to multiple page types
3. **Easier testing**: Pages, components, and sub-components can be tested independently
4. **Future-proof**: Enables advanced layout system without major refactoring
5. **Declarative DSL**: Makes page definition intuitive and concise
6. **Constraint propagation**: Components automatically respect layout boundaries
7. **Simplified component logic**: Components think in content area, not full page
8. **Theme integration**: Layout system provides hook for future theming

## Risks and Mitigation

### Risk: Breaking existing PDF generation
**Mitigation**: Maintain parallel legacy methods, comprehensive regression testing, gradual migration

### Risk: Overcomplicated abstraction
**Mitigation**: Keep Layout minimal in Plan 05, only add complexity as needed in future plans

### Risk: Performance overhead
**Mitigation**: Profile PDF generation, optimize hot paths, keep page rendering lightweight

### Risk: Confusion between Page and Component
**Mitigation**: Clear documentation, consistent terminology, code examples

## Integration with Other Plans

### Plan 02: Extract Components

**Updated approach**: Components will now:
- Receive `content_area` parameter from Page
- Position themselves relative to content area, not full page
- Focus purely on content rendering, not chrome/navigation

**Examples**:
- `DailySection` renders within content area provided by `WeeklyPage`
- `SeasonalCalendar` renders within content area provided by `SeasonalCalendarPage`
- `CornellNotes` renders in allocated portion of `WeeklyPage` content area

### Plan 04: Extract Reusable Sub-Components

**No changes needed**: Sub-components remain low-level rendering primitives, unaware of pages or layouts.

**Usage pattern**:
1. Page applies layout, defines content area
2. Component receives content area, positions sub-components
3. Sub-component renders at specified grid coordinates

### Future Layout Management Plan

**Foundation established**: This plan creates the hooks and structure needed for:
- Named layouts persisted in YAML/JSON
- Layout editor/designer tool
- Per-user layout customization
- Dynamic layout selection based on page type
- Responsive layouts for different page sizes

## Migration Path

### Phase 1: Infrastructure (Steps 1, 6.1-6.2)
- Create Page and Layout base classes
- Establish testing framework
- No changes to existing generation code

### Phase 2: One Page Type (Steps 2.1, 4.3)
- Migrate weekly pages to new system
- Run in parallel with legacy code
- Verify output matches

### Phase 3: Remaining Page Types (Steps 2.2-2.5, 4.1-4.2, 4.4-4.5)
- Migrate seasonal calendar, year-at-glance, reference, dots pages
- Replace legacy methods with page classes
- Comprehensive testing

### Phase 4: Component Integration (Steps 3, 5)
- Update Component base class for content area
- Prepare for Plan 02 component extraction
- Integration testing

### Phase 5: Documentation and Cleanup (Steps 7, 8)
- Complete documentation suite
- Remove deprecated legacy methods
- Prepare for future layout system

## Timeline Estimate

### Week 1: Foundation (10-12 hours)
- Page base class: 4 hours
- Layout class: 3 hours
- Testing infrastructure: 3 hours

### Week 2: Page Classes (12-16 hours)
- WeeklyPage: 4 hours
- SeasonalCalendarPage: 3 hours
- YearAtGlancePage: 3 hours
- ReferencePage, BlankDotsPage: 2 hours
- Testing: 4 hours

### Week 3: Integration (10-12 hours)
- Component base class updates: 3 hours
- PlannerGenerator refactoring: 4 hours
- Integration testing: 3 hours
- Regression testing: 2 hours

### Week 4: Documentation (6-8 hours)
- Page system guide: 2 hours
- Layout guide: 2 hours
- Examples and diagrams: 2 hours
- Update project docs: 2 hours

**Total Estimate: 38-48 hours (4-5 weeks at 10 hours/week)**

## Success Metrics

1. **All page types** migrated to new Page classes
2. **Zero visual differences** in generated PDFs
3. **Test coverage** >85% for page and layout code
4. **Documentation** complete with examples
5. **Ready for Plan 02** component extraction with content area support
6. **Foundation for layouts** prepared for future plan

## Next Steps After Completion

0. Update the plan 02 plan with respect to the new page system.
1. **Execute Plan 02** (Extract Components) - Components will use Page's content area system
2. **Plan future layout system** - Comprehensive layout management with persistence, customization
3. **Consider DSL builder** - Fluent interface for declarative planner generation
4. **Explore themes** - Layout system provides hook for theme integration

## Notes

- **Page vs Component**: Page = chrome + content area definition; Component = content rendering within area
- **Layout scope**: Keep minimal in Plan 05, expand in future dedicated layout plan
- **Backward compatibility**: Critical during transition, can remove legacy code after Plan 02 completion
- **Testing discipline**: Each phase must maintain PDF output equivalence
- **Documentation first**: Write docs before implementation to clarify design
