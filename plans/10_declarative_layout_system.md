# Plan 10: Declarative Layout System with Automatic Content Area Management

**Status**: Not Started
**Priority**: Phase 3 - High Priority (Architecture & DRY)
**Dependencies**: Plan 01, Plan 02, Plan 04, Plan 05, Plan 06 - ALL COMPLETED
**Estimated Effort**: Medium (8-12 hours)
**Created**: 2025-11-11

## Executive Summary

This plan introduces a **declarative layout system** that eliminates code duplication across page classes by automatically managing navigation sidebars and content area constraints. Currently, all three year-overview pages (`WeeklyPage`, `SeasonalCalendar`, `YearAtGlanceBase`) duplicate sidebar rendering logic and manually position content to respect layout boundaries.

The new system allows pages to **declare their layout intent** rather than implement layout details, leveraging the content_area support already built into the Component architecture (Plan 05). Pages will use simple declarations like `use_layout :standard_with_sidebars` and receive automatic sidebar rendering plus calculated content area constraints.

### Problem Being Solved

**Current State - Significant Duplication:**
```ruby
# REPEATED IN 3 FILES: weekly_page.rb, seasonal_calendar.rb, year_at_glance_base.rb

require_relative '../components/week_sidebar'
require_relative '../components/right_sidebar'

def render
  draw_dot_grid
  draw_diagnostic_grid(label_every: 5)
  draw_week_sidebar        # Duplicated
  draw_right_sidebar       # Duplicated
  # ... page-specific content
end

def draw_week_sidebar     # ~15 lines duplicated
  sidebar = Components::WeekSidebar.new(@pdf, @grid_system,
    year: @year,
    total_weeks: @total_weeks,
    current_week_num: @week_num  # or nil
  )
  sidebar.render
end

def draw_right_sidebar    # ~20 lines duplicated
  sidebar = Components::RightSidebar.new(@pdf, @grid_system,
    top_tabs: [...],        # Slightly different per page
    bottom_tabs: [...]
  )
  sidebar.render
end
```

**Additionally:**
- Pages manually calculate content area (columns 3-41)
- No single source of truth for layout dimensions
- Adding new layouts requires modifying every page
- Changing sidebar behavior requires updating 3 files

**Desired State - Declarative and DRY:**
```ruby
# In page class
def setup
  use_layout :standard_with_sidebars,
    current_week: @week_num,
    highlight_tab: :year_events
  set_destination("year_events")
end

def render
  draw_dot_grid
  # Sidebars rendered automatically by layout!
  draw_header     # Uses content_area from layout
  draw_content    # Uses content_area from layout
end
```

### Key Benefits

1. **DRY Principle**: Single source of truth for layout structure and sidebar rendering
2. **Declarative API**: Pages declare layout intent, not implementation details
3. **Flexible**: Easy to add new layouts (e.g., no sidebars, left-only sidebar, custom configurations)
4. **Consistent**: Layout logic enforced uniformly across all pages
5. **Leverages Existing Work**: Uses content_area support from Plan 05 Component architecture
6. **Maintainable**: Changes to sidebar behavior or layout dimensions in one place
7. **Testable**: Layout logic can be unit tested independently

## Technical Approach

### 1. Architecture Overview

The layout system consists of three layers:

**Layer 1: Layout Classes** (`lib/bujo_pdf/layouts/`)
- Define layout structure and content area boundaries
- Render layout components (sidebars, headers, footers)
- Calculate content area constraints for page content

**Layer 2: Base Page Integration** (`lib/bujo_pdf/pages/base.rb`)
- `use_layout()` method for declarative layout selection
- `content_area` accessor that delegates to layout
- Lifecycle hooks: layout rendering before/after page content

**Layer 3: Page Implementation** (existing page classes)
- Declare layout in `setup()` method
- Use `content_area` when rendering components
- No direct sidebar management

### 2. Layout Class Hierarchy

```
BaseLayout (abstract)
├── StandardWithSidebarsLayout (left + right sidebars)
├── FullPageLayout (no sidebars, full content)
└── [Future layouts...]
```

**BaseLayout Interface:**
```ruby
class BaseLayout
  # Initialize with PDF, grid system, and layout-specific options
  def initialize(pdf, grid_system, **options)

  # Calculate content area boundaries (must override)
  def content_area
    raise NotImplementedError
  end

  # Render layout components before page content (optional override)
  def render_before(page)
    # Override to render sidebars, backgrounds, etc.
  end

  # Render layout components after page content (optional override)
  def render_after(page)
    # Override for overlays, borders, etc.
  end
end
```

### 3. Content Area Calculation

Layouts define content area using grid coordinates:

```ruby
# StandardWithSidebarsLayout content area
{
  col: 3,              # Start at column 3 (after left sidebar)
  row: 0,              # Start at row 0 (top)
  width_boxes: 39,     # Columns 3-41 inclusive (39 boxes)
  height_boxes: 55,    # Full page height
  x: 42.51,            # Calculated: grid_x(3)
  y: 792.0,            # Calculated: grid_y(0)
  width_pt: 552.63,    # Calculated: grid_width(39)
  height_pt: 779.35    # Calculated: grid_height(55)
}
```

Components already support content_area (Plan 05), so they automatically position themselves within these constraints.

### 4. Page Lifecycle with Layout

```
Page.generate() called
  ├─> pdf.start_new_page
  ├─> setup()                    # Page declares layout
  │     └─> use_layout(:standard_with_sidebars, options)
  │           └─> @layout = LayoutFactory.create(...)
  ├─> @layout.render_before(self)  # Layout renders sidebars
  ├─> render()                     # Page renders content
  │     ├─> draw_header()          # Uses content_area
  │     └─> draw_content()         # Uses content_area
  └─> @layout.render_after(self)   # Layout post-rendering
```

### 5. Sidebar Configuration Patterns

**Week Sidebar Configuration:**
```ruby
# No current week highlighting (year overview pages)
current_week: nil

# Highlight specific week (weekly pages)
current_week: 42
```

**Right Sidebar Configuration:**
```ruby
# Highlight specific tab
highlight_tab: :year_events

# No highlighting (weekly pages)
highlight_tab: nil
```

## Implementation Steps

### Phase 1: Layout Infrastructure (Foundation)

#### 1.1 Create Layout Module Structure
```
lib/bujo_pdf/layouts/
├── base_layout.rb
├── standard_with_sidebars_layout.rb
├── full_page_layout.rb
└── layout_factory.rb
```

**Files to create:**
- `lib/bujo_pdf/layouts/base_layout.rb` - Abstract base class
- `lib/bujo_pdf/layouts/layout_factory.rb` - Factory for creating layouts by name
- `lib/bujo_pdf.rb` - Add require for layouts module

**Acceptance:**
- ✓ Layout module structure exists
- ✓ BaseLayout defines abstract interface
- ✓ LayoutFactory can create layouts by symbol name

#### 1.2 Implement BaseLayout Abstract Class

**File**: `lib/bujo_pdf/layouts/base_layout.rb`

**Responsibilities:**
- Define layout interface contract
- Store PDF and grid system references
- Provide default implementations where appropriate
- Document layout lifecycle

**Interface:**
```ruby
module BujoPdf
  module Layouts
    class BaseLayout
      attr_reader :pdf, :grid_system, :options

      def initialize(pdf, grid_system, **options)
        @pdf = pdf
        @grid_system = grid_system
        @options = options
      end

      # Content area boundaries (must override)
      def content_area
        raise NotImplementedError, "#{self.class} must implement #content_area"
      end

      # Render layout components before page content (optional override)
      def render_before(page)
        # Default: no-op, subclasses can override
      end

      # Render layout components after page content (optional override)
      def render_after(page)
        # Default: no-op, subclasses can override
      end

      protected

      # Helper: Access page context
      def page_context(page)
        page.context
      end
    end
  end
end
```

**Acceptance:**
- ✓ BaseLayout class exists
- ✓ Abstract interface defined and documented
- ✓ Raises NotImplementedError for abstract methods
- ✓ Provides sensible defaults for optional methods

#### 1.3 Implement FullPageLayout

**File**: `lib/bujo_pdf/layouts/full_page_layout.rb`

**Purpose**: Layout with no sidebars, full content area (for reference page, blank dots)

**Implementation:**
```ruby
module BujoPdf
  module Layouts
    # Full page layout with no sidebars or navigation.
    #
    # Provides maximum content area (all 43×55 boxes).
    # Used for reference/calibration page, blank dot grid page.
    #
    # Example:
    #   use_layout :full_page
    class FullPageLayout < BaseLayout
      def content_area
        {
          col: 0,
          row: 0,
          width_boxes: 43,
          height_boxes: 55,
          x: @grid_system.x(0),
          y: @grid_system.y(0),
          width_pt: @grid_system.width(43),
          height_pt: @grid_system.height(55)
        }
      end

      # No layout components to render
      def render_before(page)
        # No-op: full page has no sidebars
      end
    end
  end
end
```

**Acceptance:**
- ✓ FullPageLayout provides full 43×55 content area
- ✓ No sidebar rendering
- ✓ Can be instantiated and used

#### 1.4 Implement LayoutFactory

**File**: `lib/bujo_pdf/layouts/layout_factory.rb`

**Purpose**: Create layout instances by symbolic name

**Implementation:**
```ruby
module BujoPdf
  module Layouts
    class LayoutFactory
      LAYOUTS = {
        full_page: FullPageLayout,
        standard_with_sidebars: StandardWithSidebarsLayout
      }.freeze

      # Create a layout instance by name
      #
      # @param name [Symbol] Layout name (:full_page, :standard_with_sidebars)
      # @param pdf [Prawn::Document] PDF document
      # @param grid_system [Utilities::GridSystem] Grid system
      # @param options [Hash] Layout-specific options
      # @return [BaseLayout] Layout instance
      def self.create(name, pdf, grid_system, **options)
        layout_class = LAYOUTS[name]
        raise ArgumentError, "Unknown layout: #{name}" unless layout_class

        layout_class.new(pdf, grid_system, **options)
      end

      # Get available layout names
      def self.available_layouts
        LAYOUTS.keys
      end
    end
  end
end
```

**Acceptance:**
- ✓ Can create layouts by symbol name
- ✓ Raises clear error for unknown layouts
- ✓ Can list available layouts

### Phase 2: StandardWithSidebarsLayout Implementation

#### 2.1 Implement StandardWithSidebarsLayout Class

**File**: `lib/bujo_pdf/layouts/standard_with_sidebars_layout.rb`

**Purpose**: Layout with left week sidebar + right year/nav tabs sidebar

**Content Area:**
- Left sidebar: columns 0-2 (3 boxes)
- Content: columns 3-41 (39 boxes)
- Right sidebar: column 42 (1 box)

**Implementation:**
```ruby
module BujoPdf
  module Layouts
    # Standard layout with left week sidebar and right navigation tabs.
    #
    # Layout structure:
    #   - Left sidebar (columns 0-2): Week list with month indicators
    #   - Content area (columns 3-41): Page content
    #   - Right sidebar (column 42): Year page tabs
    #
    # Options:
    #   - :current_week [Integer, nil] - Week number to highlight (nil for no highlight)
    #   - :highlight_tab [Symbol, nil] - Tab to highlight (:seasonal, :year_events, :year_highlights, nil)
    #   - :year [Integer] - Year for sidebar rendering (from page context)
    #   - :total_weeks [Integer] - Total weeks in year (from page context)
    #
    # Example:
    #   use_layout :standard_with_sidebars, current_week: 42, highlight_tab: nil
    class StandardWithSidebarsLayout < BaseLayout
      def content_area
        {
          col: 3,
          row: 0,
          width_boxes: 39,
          height_boxes: 55,
          x: @grid_system.x(3),
          y: @grid_system.y(0),
          width_pt: @grid_system.width(39),
          height_pt: @grid_system.height(55)
        }
      end

      def render_before(page)
        render_week_sidebar(page)
        render_right_sidebar(page)
      end

      private

      def render_week_sidebar(page)
        require_relative '../components/week_sidebar'

        sidebar = Components::WeekSidebar.new(
          @pdf,
          @grid_system,
          year: options[:year] || page.context[:year],
          total_weeks: options[:total_weeks] || page.context[:total_weeks],
          current_week_num: options[:current_week]
        )
        sidebar.render
      end

      def render_right_sidebar(page)
        require_relative '../components/right_sidebar'

        # Build tabs with highlighting
        top_tabs = [
          { label: "Year", dest: "seasonal" },
          { label: "Events", dest: "year_events" },
          { label: "Highlights", dest: "year_highlights" }
        ]

        # Apply highlighting if specified
        if options[:highlight_tab]
          tab_dest = "#{options[:highlight_tab]}"
          top_tabs.each do |tab|
            tab[:current] = (tab[:dest] == tab_dest)
          end
        end

        sidebar = Components::RightSidebar.new(
          @pdf,
          @grid_system,
          top_tabs: top_tabs,
          bottom_tabs: [
            { label: "Dots", dest: "dots" }
          ]
        )
        sidebar.render
      end
    end
  end
end
```

**Acceptance:**
- ✓ Provides content area columns 3-41
- ✓ Renders week sidebar with optional current week highlighting
- ✓ Renders right sidebar with optional tab highlighting
- ✓ Extracts year and total_weeks from page context when not in options

### Phase 3: Base Page Integration

#### 3.1 Add Layout Support to Pages::Base

**File**: `lib/bujo_pdf/pages/base.rb`

**Changes:**
1. Add layout instance variable and accessor
2. Implement `use_layout()` method
3. Implement `content_area` accessor
4. Update `generate()` to call layout lifecycle methods
5. Provide default layout (FullPageLayout)

**Implementation:**
```ruby
# In Pages::Base class

attr_reader :layout

def initialize(pdf, context)
  @pdf = pdf
  @context = context
  @grid_system = Utilities::GridSystem.new
  @layout = nil  # Set in setup() via use_layout()
end

# Declare which layout to use for this page.
#
# Should be called in setup() method of subclasses.
# If not called, defaults to FullPageLayout.
#
# @param layout_name [Symbol] Layout name (:full_page, :standard_with_sidebars)
# @param options [Hash] Layout-specific options
#
# @example
#   def setup
#     use_layout :standard_with_sidebars, current_week: @week_num
#   end
def use_layout(layout_name, **options)
  require_relative '../layouts/layout_factory'
  @layout = Layouts::LayoutFactory.create(
    layout_name,
    @pdf,
    @grid_system,
    **options.merge(
      year: context[:year],
      total_weeks: context[:total_weeks]
    )
  )
end

# Get content area constraints from layout.
#
# Returns a hash with grid coordinates and point dimensions:
# {
#   col: 3, row: 0, width_boxes: 39, height_boxes: 55,
#   x: 42.51, y: 792.0, width_pt: 552.63, height_pt: 779.35
# }
#
# Components use this to position themselves within layout boundaries.
#
# @return [Hash] Content area constraints
def content_area
  @layout&.content_area
end

def generate
  @pdf.start_new_page
  setup

  # Default to full page layout if none specified
  @layout ||= begin
    require_relative '../layouts/layout_factory'
    Layouts::LayoutFactory.create(:full_page, @pdf, @grid_system)
  end

  @layout.render_before(self)
  render
  @layout.render_after(self)
end
```

**Acceptance:**
- ✓ Pages can call `use_layout(:layout_name, options)`
- ✓ `content_area` accessor returns layout's content area
- ✓ Default layout is FullPageLayout if not specified
- ✓ Layout lifecycle methods called in correct order
- ✓ Page context passed to layout when needed

### Phase 4: Page Migration

#### 4.1 Update WeeklyPage to Use Layout System

**File**: `lib/bujo_pdf/pages/weekly_page.rb`

**Changes:**
1. Remove sidebar require statements
2. Add `use_layout()` call in `setup()`
3. Remove `draw_week_sidebar()` method
4. Remove `draw_right_sidebar()` method
5. Remove sidebar calls from `render()`

**Before:**
```ruby
require_relative '../components/week_sidebar'
require_relative '../components/right_sidebar'

def setup
  @week_num = context[:week_num]
  # ...
  set_destination("week_#{@week_num}")
end

def render
  draw_dot_grid
  draw_diagnostic_grid(label_every: 5)
  draw_week_sidebar      # REMOVE
  draw_right_sidebar     # REMOVE
  draw_navigation
  draw_daily_section
  draw_cornell_notes
end

def draw_week_sidebar    # REMOVE entire method
  sidebar = Components::WeekSidebar.new(...)
  sidebar.render
end

def draw_right_sidebar   # REMOVE entire method
  sidebar = Components::RightSidebar.new(...)
  sidebar.render
end
```

**After:**
```ruby
def setup
  @week_num = context[:week_num]
  @week_start = context[:week_start]
  @week_end = context[:week_end]
  @year = context[:year]
  @total_weeks = Utilities::DateCalculator.total_weeks(@year)

  use_layout :standard_with_sidebars,
    current_week: @week_num,
    highlight_tab: nil  # No tab highlighting on weekly pages

  set_destination("week_#{@week_num}")
end

def render
  draw_dot_grid
  draw_diagnostic_grid(label_every: 5)
  # Sidebars rendered automatically by layout!
  draw_navigation
  draw_daily_section
  draw_cornell_notes
end
```

**Acceptance:**
- ✓ WeeklyPage uses layout system
- ✓ Sidebar code removed
- ✓ Current week highlighted in week sidebar
- ✓ No tab highlighting in right sidebar
- ✓ Generated PDF matches original output

#### 4.2 Update SeasonalCalendar to Use Layout System

**File**: `lib/bujo_pdf/pages/seasonal_calendar.rb`

**Changes:**
1. Remove sidebar require statements
2. Add `use_layout()` call in `setup()`
3. Remove `draw_week_sidebar()` method
4. Remove `draw_right_sidebar()` method
5. Remove sidebar calls from `render()`

**After:**
```ruby
def setup
  set_destination('seasonal')
  @year = context[:year]
  @total_weeks = Utilities::DateCalculator.total_weeks(@year)

  use_layout :standard_with_sidebars,
    current_week: nil,              # No week highlighting
    highlight_tab: :seasonal        # Highlight "Year" tab
end

def render
  draw_dot_grid
  draw_diagnostic_grid(label_every: 5)
  # Sidebars rendered automatically by layout!
  draw_header
  draw_seasons
end
```

**Acceptance:**
- ✓ SeasonalCalendar uses layout system
- ✓ Sidebar code removed
- ✓ No week highlighting
- ✓ "Year" tab highlighted in right sidebar
- ✓ Generated PDF matches original output

#### 4.3 Update YearAtGlanceBase to Use Layout System

**File**: `lib/bujo_pdf/pages/year_at_glance_base.rb`

**Changes:**
1. Remove sidebar require statements
2. Add `use_layout()` call in `setup()`
3. Remove `draw_week_sidebar()` method
4. Remove `draw_right_sidebar()` method
5. Remove sidebar calls from `render()`
6. Use `destination_name` for dynamic tab highlighting

**After:**
```ruby
def setup
  set_destination(destination_name)
  @year = context[:year]
  @total_weeks = Utilities::DateCalculator.total_weeks(@year)

  use_layout :standard_with_sidebars,
    current_week: nil,                  # No week highlighting
    highlight_tab: destination_name     # Dynamic: :year_events or :year_highlights
end

def render
  draw_dot_grid
  draw_diagnostic_grid(label_every: 5)
  # Sidebars rendered automatically by layout!
  draw_header
  draw_month_headers
  draw_days_grid
end
```

**Subclasses** (`YearAtGlanceEvents`, `YearAtGlanceHighlights`):
- No changes needed! They inherit layout behavior from base class
- `destination_name` method already returns correct symbol for tab highlighting

**Acceptance:**
- ✓ YearAtGlanceBase uses layout system
- ✓ Sidebar code removed
- ✓ No week highlighting
- ✓ Correct tab highlighted (Events or Highlights)
- ✓ Generated PDFs match original output

#### 4.4 Update ReferenceCalibration to Explicitly Use FullPageLayout

**File**: `lib/bujo_pdf/pages/reference_calibration.rb`

**Changes:**
Add explicit layout declaration for clarity (optional, but documents intent)

```ruby
def setup
  set_destination('reference')
  use_layout :full_page  # Explicit: no sidebars for reference page
end
```

**Acceptance:**
- ✓ ReferenceCalibration explicitly declares full page layout
- ✓ No sidebars rendered
- ✓ Full page content area available

#### 4.5 Update BlankDotGrid to Explicitly Use FullPageLayout

**File**: `lib/bujo_pdf/pages/blank_dot_grid.rb`

**Changes:**
Add explicit layout declaration for clarity

```ruby
def setup
  set_destination('dots')
  use_layout :full_page  # Explicit: no sidebars for blank dot grid
end
```

**Acceptance:**
- ✓ BlankDotGrid explicitly declares full page layout
- ✓ No sidebars rendered
- ✓ Full page content area available

### Phase 5: Testing and Validation

#### 5.1 Visual Verification Testing

**Test**: Generate PDF and verify all pages render correctly

```bash
ruby gen_new.rb 2025
```

**Verification Checklist:**
- ✓ Seasonal calendar: Week sidebar + "Year" tab highlighted
- ✓ Year Events: Week sidebar + "Events" tab highlighted
- ✓ Year Highlights: Week sidebar + "Highlights" tab highlighted
- ✓ Weekly pages (all 52-53): Week sidebar with current week bold + year tabs (no highlight)
- ✓ Reference page: No sidebars, full content area
- ✓ Blank dot grid: No sidebars, full content area
- ✓ All navigation links work correctly
- ✓ Content positioning unchanged from previous version

#### 5.2 Compare Generated PDFs

**Test**: Byte-for-byte or visual comparison

```bash
# Generate with old system
ruby gen.rb 2025
mv planner_2025.pdf planner_2025_old.pdf

# Generate with new system
ruby gen_new.rb 2025

# Visual diff (if tools available)
# diff-pdf planner_2025_old.pdf planner_2025_new.pdf
```

**Expected**: Visually identical output (minor metadata differences acceptable)

#### 5.3 Code Review Checklist

- ✓ No duplicated sidebar rendering code in page classes
- ✓ All pages declare layout explicitly
- ✓ Layout classes follow single responsibility principle
- ✓ Factory pattern implemented correctly
- ✓ Base class provides sensible defaults
- ✓ YARD documentation complete
- ✓ Code follows project style conventions

### Phase 6: Cleanup and Documentation

#### 6.1 Remove Dead Code

**Verify and remove:**
- Any orphaned sidebar rendering methods in page classes
- Unused require statements for sidebar components in page files
- Debug/test code from implementation process

#### 6.2 Update Documentation

**Files to update:**
1. `CLAUDE.md` - Document layout system architecture
2. `REFACTORING_PLAN.md` - Mark Plan 10 as completed
3. `plans/index.md` - Update plan status

**CLAUDE.md additions:**
```markdown
### Layout System

The planner uses a declarative layout system where pages declare their layout
intent rather than implementing layout details.

**Available Layouts:**
- `:standard_with_sidebars` - Left week sidebar + right year tabs (most pages)
- `:full_page` - No sidebars, full content area (reference, blank dots)

**Usage:**
```ruby
class MyPage < Pages::Base
  def setup
    use_layout :standard_with_sidebars,
      current_week: @week_num,
      highlight_tab: :year_events
  end
end
```

**Layout automatically:**
- Renders navigation sidebars
- Calculates content area boundaries
- Provides content_area to components
```

#### 6.3 YARD Documentation

Add YARD documentation to all layout classes:
- Class-level documentation with purpose and usage examples
- Method documentation with parameter descriptions
- Example blocks showing typical usage patterns

**Example:**
```ruby
# Standard layout with left week sidebar and right navigation tabs.
#
# This layout provides the standard planner page structure used by most pages:
# left week list, center content area, right year navigation tabs.
#
# @example Highlight current week but not tabs (weekly pages)
#   use_layout :standard_with_sidebars, current_week: 42, highlight_tab: nil
#
# @example Highlight specific tab (year overview pages)
#   use_layout :standard_with_sidebars, current_week: nil, highlight_tab: :year_events
class StandardWithSidebarsLayout < BaseLayout
  # ...
end
```

## Testing Strategy

### Manual Testing

**Test 1: Generate Complete Planner**
```bash
ruby gen_new.rb 2025
```
- Verify 58 pages generated
- Check file size reasonable (~2-3MB)
- Spot check pages visually

**Test 2: Navigation Verification**
- Click week numbers in left sidebar → navigate to correct week
- Click year tabs → navigate to correct year overview page
- Click "Dots" tab → navigate to blank dot grid
- Click dates in calendars → navigate to correct week

**Test 3: Layout Consistency**
- All weekly pages have identical layout structure
- Year overview pages have consistent sidebar rendering
- Reference and blank pages use full width

**Test 4: Highlighting Verification**
- Weekly page 15: Week 15 should be bold in sidebar
- Seasonal calendar: "Year" tab should be highlighted
- Events page: "Events" tab should be highlighted
- Highlights page: "Highlights" tab should be highlighted

### Automated Testing (Future)

When Plan 08 (Testing Infrastructure) is implemented, add:
- Unit tests for layout classes
- Unit tests for LayoutFactory
- Integration tests for page+layout rendering
- Regression tests comparing output with reference PDFs

## Success Criteria

### Functional Requirements
- ✓ All pages render correctly with appropriate layout
- ✓ Sidebars appear on correct pages with correct highlighting
- ✓ Content area constraints properly applied
- ✓ All navigation links functional
- ✓ Generated PDF visually identical to previous version

### Code Quality Requirements
- ✓ Zero duplicated sidebar rendering code in page classes
- ✓ Single source of truth for layout dimensions
- ✓ Clear separation of concerns (layout vs. page content)
- ✓ Extensible design (easy to add new layouts)
- ✓ YARD documentation complete

### Maintainability Requirements
- ✓ Changing sidebar behavior requires editing only layout class
- ✓ Adding new layout requires only new layout class (no page changes)
- ✓ Layout configuration consolidated in page setup()
- ✓ Layout system architecture documented

## Future Enhancements

Once layout system is proven:

1. **Additional Layouts:**
   - `:left_sidebar_only` - Week sidebar but no right tabs
   - `:minimal` - No sidebars but reserved header/footer areas
   - `:custom` - Page provides custom layout configuration

2. **Layout Options:**
   - Configurable sidebar widths
   - Optional header/footer areas
   - Custom background rendering

3. **Advanced Features:**
   - Layout composition (combine layout fragments)
   - Conditional layout selection based on page type
   - Layout caching for performance

4. **Component Enhancement:**
   - Components automatically adapt to available content area
   - Proportional sizing based on content area dimensions
   - Overflow handling

## Dependencies

**Required (must be completed first):**
- Plan 01: Extract Low-Level Utilities ✅ COMPLETED
- Plan 02: Extract Components ✅ COMPLETED
- Plan 04: Extract Reusable Sub-Components ✅ COMPLETED
- Plan 05: Page and Layout Abstraction ✅ COMPLETED (provides content_area support)
- Plan 06: RenderContext System ✅ COMPLETED

**Beneficial (enhances but not required):**
- Plan 08: Testing Infrastructure - Would enable automated layout testing

**Blocks:**
- None - This plan can be implemented independently

## Risks and Mitigations

### Risk 1: Breaking Changes to Page Rendering
**Likelihood**: Medium
**Impact**: High
**Mitigation**:
- Implement default layout (FullPageLayout) for backward compatibility
- Migrate pages incrementally
- Visual comparison testing before/after
- Keep gen.rb working until new system proven

### Risk 2: Performance Regression
**Likelihood**: Low
**Impact**: Low
**Mitigation**:
- Layout objects are lightweight
- No additional PDF operations (just reorganization)
- Benchmark if concerned (expect neutral performance)

### Risk 3: Complexity for Future Developers
**Likelihood**: Low
**Impact**: Medium
**Mitigation**:
- Clear documentation in CLAUDE.md
- YARD documentation on all layout classes
- Simple, declarative API (`use_layout :name`)
- Comprehensive examples in plan and code

### Risk 4: Inflexibility for Edge Cases
**Likelihood**: Low
**Impact**: Low
**Mitigation**:
- Layout system designed for extensibility
- Pages can still manually render components if needed
- Option to implement custom layout classes
- FullPageLayout provides escape hatch

## Notes

- This plan builds directly on Plan 05's content_area support in Components
- Layout system is optional: pages default to FullPageLayout if no layout declared
- Existing gen.rb remains functional during migration
- Consider this as foundation for future layout enhancements (headers, footers, backgrounds)
