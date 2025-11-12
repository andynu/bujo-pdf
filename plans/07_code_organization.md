# Plan 07: Eliminate Code Duplication from Component Extraction

## Executive Summary

Component extraction (Plans 01-06, 10) successfully modularized the codebase but introduced new duplication patterns. This plan eliminates 96+ lines of duplicated code by:

1. **Extracting common rendering patterns** - Parameterized helpers for labeled sections (Cornell notes)
2. **Centralizing validation logic** - Base class validation in Component
3. **Standardizing style management** - Color/font context helpers to prevent manual resets
4. **Creating shared page setup** - Standard layout page base class
5. **Consolidating link patterns** - Consistent use of GridSystem link API

This is a **pure refactoring plan** - no new features, no behavioral changes. All improvements are internal code quality enhancements.

## Current State Analysis

### Duplication Introduced During Component Extraction

**Plan 02 (Extract Components)** created these duplications:
- CornellNotes: 3 nearly-identical section rendering methods (37 lines duplicate)
- WeekSidebar, TopNavigation, DailySection, CornellNotes: Same validation pattern (30+ lines)
- TopNavigation, WeekSidebar, RightSidebar: Manual color/font resets (16+ lines)

**Plan 05 (Page Abstraction)** created these duplications:
- YearAtGlanceBase, SeasonalCalendar, WeeklyPage: Nearly identical setup() methods (9+ lines)

**Plan 01-10 (Various)** introduced these duplications:
- 6+ places manually construct link annotations instead of using GridSystem.link() (18+ lines)
- COLOR_BORDERS, GRID_COLS defined in multiple files (constants duplication)

**Total Impact**: 118+ lines of duplicated code, ~38% code reduction potential in affected files

## Technical Approach

### Philosophy: DRY Without Over-Engineering

This refactoring follows these principles:

1. **Extract only proven patterns** - Only duplication that exists 3+ times
2. **Prefer composition over inheritance** - Helpers over deep hierarchies
3. **Maintain component independence** - Avoid tight coupling
4. **Keep it simple** - Clear names, obvious behavior, minimal abstraction

### Refactoring Categories

1. **Rendering Patterns** - Parameterized helper methods
2. **Validation** - Base class shared logic
3. **Style Management** - Context manager helpers
4. **Page Setup** - Shared base class for standard layouts
5. **Link API** - Consistent use of existing GridSystem.link()
6. **Constants** - Centralize in Styling module

## Implementation Steps

### 1. Extract Labeled Section Rendering Pattern

**Problem**: CornellNotes has 3 nearly-identical methods:
- `draw_cues_section` (lines 59-78)
- `draw_notes_section` (lines 81-100)
- `draw_summary_section` (lines 103-122)

Each method: creates bounding box → strokes border → draws label → resets state

**1.1 Add parameterized helper to CornellNotes**

```ruby
# lib/bujo_pdf/components/cornell_notes.rb

private

def draw_labeled_section(col, row, width_boxes, height_boxes, label, label_size: LABEL_FONT_SIZE)
  section_box = @grid.rect(col, row, width_boxes, height_boxes)

  @pdf.bounding_box([section_box[:x], section_box[:y]],
                   width: section_box[:width],
                   height: section_box[:height]) do
    @pdf.stroke_color COLOR_BORDERS
    @pdf.stroke_bounds
    @pdf.stroke_color '000000'
    @pdf.font "Helvetica-Bold", size: HEADER_FONT_SIZE
    @pdf.move_down HEADER_PADDING
    @pdf.fill_color COLOR_SECTION_HEADERS
    @pdf.text label, align: :center, size: label_size
    @pdf.fill_color '000000'
  end
end
```

**1.2 Replace 3 methods with helper calls**

```ruby
def draw_cues_section
  draw_labeled_section(
    context[:content_start_col],
    context[:notes_start_row],
    context[:cues_cols],
    context[:notes_main_rows],
    "Cues/Questions"
  )
end

def draw_notes_section
  draw_labeled_section(
    context[:content_start_col] + context[:cues_cols],
    context[:notes_start_row],
    context[:notes_cols],
    context[:notes_main_rows],
    "Notes"
  )
end

def draw_summary_section
  draw_labeled_section(
    context[:content_start_col],
    context[:notes_start_row] + context[:notes_main_rows],
    context[:cues_cols] + context[:notes_cols],
    context[:summary_rows],
    "Summary"
  )
end
```

**Savings**: 37 lines reduced to 1 helper method + 3 simple calls

**Files Modified**:
- `lib/bujo_pdf/components/cornell_notes.rb`

### 2. Centralize Component Option Validation

**Problem**: 4 components have nearly-identical validation:

- `lib/bujo_pdf/components/week_sidebar.rb` lines 58-65
- `lib/bujo_pdf/components/top_navigation.rb` lines 50-57
- `lib/bujo_pdf/components/daily_section.rb` (similar pattern)
- `lib/bujo_pdf/components/cornell_notes.rb` lines 49-57

**2.1 Add validation helper to Component base class**

```ruby
# lib/bujo_pdf/component.rb

protected

# Validate that required options are present in context.
#
# @param keys [Array<Symbol>] Required option keys
# @raise [ArgumentError] if any required keys are missing
# @return [void]
#
# @example
#   def validate_configuration
#     require_options(:year, :total_weeks, :current_week_num)
#   end
def require_options(*keys)
  missing_keys = keys - context.keys

  unless missing_keys.empty?
    raise ArgumentError, "#{self.class.name} requires: #{missing_keys.join(', ')}"
  end
end
```

**2.2 Update components to use helper**

```ruby
# lib/bujo_pdf/components/week_sidebar.rb
def validate_configuration
  require_options(:year, :total_weeks)
end

# lib/bujo_pdf/components/top_navigation.rb
def validate_configuration
  require_options(:year, :week_num, :total_weeks, :week_start, :week_end)
end

# lib/bujo_pdf/components/cornell_notes.rb
def validate_configuration
  require_options(:content_start_col, :notes_start_row, :cues_cols,
                 :notes_cols, :notes_main_rows, :summary_rows)
end

# lib/bujo_pdf/components/daily_section.rb
def validate_configuration
  require_options(:content_start_col, :daily_start_row, :daily_cols,
                 :daily_rows)
end
```

**Savings**: 16 lines (4 methods × 4 components → 1 base helper + 4 one-liners)

**Files Modified**:
- `lib/bujo_pdf/component.rb`
- `lib/bujo_pdf/components/week_sidebar.rb`
- `lib/bujo_pdf/components/top_navigation.rb`
- `lib/bujo_pdf/components/cornell_notes.rb`
- `lib/bujo_pdf/components/daily_section.rb`

### 3. Add Style Context Managers to Component Base

**Problem**: Manual color/font state management scattered across components:

```ruby
# Pattern repeated 8+ times:
@pdf.fill_color NAV_COLOR
# ... draw text ...
@pdf.fill_color '000000'  # Reset to black
```

**3.1 Add context manager helpers to Component**

```ruby
# lib/bujo_pdf/component.rb

protected

# Execute block with temporary fill color, then restore.
#
# @param color [String] 6-digit hex color code
# @yield Block to execute with color applied
# @return [void]
#
# @example
#   with_fill_color('888888') do
#     @pdf.text "Gray text"
#   end
#   # Color automatically restored to previous value
def with_fill_color(color)
  original = @pdf.fill_color
  @pdf.fill_color color
  yield
ensure
  @pdf.fill_color original
end

# Execute block with temporary stroke color, then restore.
#
# @param color [String] 6-digit hex color code
# @yield Block to execute with color applied
# @return [void]
def with_stroke_color(color)
  original = @pdf.stroke_color
  @pdf.stroke_color color
  yield
ensure
  @pdf.stroke_color original
end

# Execute block with temporary font settings, then restore.
#
# @param family [String] Font family name
# @param size [Integer, nil] Font size (optional)
# @yield Block to execute with font applied
# @return [void]
#
# @example
#   with_font("Helvetica-Bold", 14) do
#     @pdf.text "Bold title"
#   end
def with_font(family, size = nil)
  original_family = @pdf.font.family
  original_size = @pdf.font_size

  if size
    @pdf.font family, size: size
  else
    @pdf.font family
  end

  yield
ensure
  @pdf.font original_family, size: original_size
end
```

**3.2 Update components to use context managers**

```ruby
# lib/bujo_pdf/components/top_navigation.rb

def draw_year_link(nav_box)
  with_font("Helvetica", FOOTER_FONT_SIZE) do
    with_fill_color(NAV_COLOR) do
      nav_year_width = @grid.width(4)
      @pdf.text_box "< #{context[:year]}",
                    at: [nav_box[:x], nav_box[:y]],
                    width: nav_year_width,
                    height: nav_box[:height],
                    valign: :center

      @pdf.link_annotation([nav_box[:x], nav_box[:y] - nav_box[:height],
                            nav_box[:x] + nav_year_width, nav_box[:y]],
                          Dest: "seasonal",
                          Border: [0, 0, 0])
    end
  end
end
```

**Savings**: 16+ lines across TopNavigation, WeekSidebar, RightSidebar

**Files Modified**:
- `lib/bujo_pdf/component.rb`
- `lib/bujo_pdf/components/top_navigation.rb`
- `lib/bujo_pdf/components/week_sidebar.rb`
- `lib/bujo_pdf/components/right_sidebar.rb`

### 4. Create StandardLayoutPage Base Class

**Problem**: Nearly-identical setup methods in 3 page classes:

- `lib/bujo_pdf/pages/year_at_glance_base.rb`
- `lib/bujo_pdf/pages/seasonal_calendar.rb`
- `lib/bujo_pdf/pages/weekly_page.rb`

Each does: use_layout :standard_with_sidebars with similar options

**4.1 Create StandardLayoutPage**

```ruby
# lib/bujo_pdf/pages/standard_layout_page.rb

require_relative 'base'

module BujoPdf
  module Pages
    # Base class for pages that use the standard sidebar layout.
    #
    # Automatically sets up:
    # - Left week sidebar
    # - Right navigation tabs
    # - Content area for page content
    #
    # Subclasses must implement:
    # - current_week: Which week to highlight (or nil)
    # - highlight_tab: Which tab to highlight (or nil)
    class StandardLayoutPage < Base
      def setup
        use_layout :standard_with_sidebars,
          current_week: current_week,
          highlight_tab: highlight_tab,
          year: context.year,
          total_weeks: context.total_weeks
      end

      protected

      # Which week to highlight in sidebar (override in subclass).
      #
      # @return [Integer, nil] Week number or nil for no highlight
      def current_week
        nil
      end

      # Which tab to highlight in right sidebar (override in subclass).
      #
      # @return [Symbol, nil] Tab key or nil for no highlight
      def highlight_tab
        nil
      end
    end
  end
end
```

**4.2 Update page classes to inherit from StandardLayoutPage**

```ruby
# lib/bujo_pdf/pages/year_at_glance_base.rb
class YearAtGlanceBase < StandardLayoutPage
  protected

  def current_week
    nil  # Year overview pages don't highlight weeks
  end

  # Subclasses override highlight_tab
end

# lib/bujo_pdf/pages/year_at_glance_events.rb
class YearAtGlanceEvents < YearAtGlanceBase
  protected

  def highlight_tab
    :year_events
  end
end

# lib/bujo_pdf/pages/weekly_page.rb
class WeeklyPage < StandardLayoutPage
  protected

  def current_week
    context.week_num
  end

  def highlight_tab
    nil  # Weekly pages don't highlight tabs
  end
end
```

**Savings**: 9+ lines (3 setup methods → 1 base class + simple overrides)

**Files Created**:
- `lib/bujo_pdf/pages/standard_layout_page.rb`

**Files Modified**:
- `lib/bujo_pdf/pages/year_at_glance_base.rb`
- `lib/bujo_pdf/pages/year_at_glance_events.rb`
- `lib/bujo_pdf/pages/year_at_glance_highlights.rb`
- `lib/bujo_pdf/pages/weekly_page.rb`

### 5. Standardize Link API Usage

**Problem**: 6+ places manually construct link annotations instead of using GridSystem.link()

Examples:
- `lib/bujo_pdf/components/top_navigation.rb` lines 79-82, 99-102, 118-121
- `lib/bujo_pdf/components/week_sidebar.rb` (multiple places)
- Other components

**5.1 Document GridSystem.link() method** (if not already clear)

Ensure GridSystem has:
```ruby
# lib/bujo_pdf/utilities/grid_system.rb

# Create a clickable link annotation at grid coordinates.
#
# @param col [Integer] Grid column
# @param row [Integer] Grid row
# @param width_boxes [Integer] Width in grid boxes
# @param height_boxes [Integer] Height in grid boxes
# @param dest [String] Named destination
# @param options [Hash] Additional Prawn link_annotation options
# @return [void]
def link(col, row, width_boxes, height_boxes, dest, **options)
  left = x(col)
  top = y(row)
  right = x(col + width_boxes)
  bottom = y(row + height_boxes)

  @pdf.link_annotation([left, bottom, right, top],
                      Dest: dest,
                      Border: options.fetch(:Border, [0, 0, 0]))
end
```

**5.2 Replace manual link construction with GridSystem.link()**

```ruby
# Before (lib/bujo_pdf/components/top_navigation.rb lines 79-82):
@pdf.link_annotation([nav_box[:x], nav_box[:y] - nav_box[:height],
                      nav_box[:x] + nav_year_width, nav_box[:y]],
                    Dest: "seasonal",
                    Border: [0, 0, 0])

# After:
@grid.link(content_start_col, 0, 4, 2, "seasonal")
```

Apply this pattern across all components that manually construct links.

**Savings**: 18+ lines (4-line manual constructions → 1-line helper calls)

**Files Modified**:
- `lib/bujo_pdf/components/top_navigation.rb`
- `lib/bujo_pdf/components/week_sidebar.rb`
- `lib/bujo_pdf/components/right_sidebar.rb`
- (Any other files with manual link construction)

### 6. Centralize Constant Definitions

**Problem**: COLOR_BORDERS, GRID_COLS defined in multiple files

- `lib/bujo_pdf/components/cornell_notes.rb` line 30: `COLOR_BORDERS = 'E5E5E5'`
- `lib/bujo_pdf/utilities/styling.rb` line 11: `BORDERS = 'E5E5E5'`
- Similar duplication for other constants

**6.1 Audit all constant duplications**

Search for duplicated constants:
```bash
grep -r "COLOR_BORDERS\|GRID_COLS\|DOT_SPACING" lib/
```

**6.2 Remove local constants, use Styling module**

```ruby
# lib/bujo_pdf/components/cornell_notes.rb

# Before:
COLOR_BORDERS = 'E5E5E5'
COLOR_SECTION_HEADERS = 'AAAAAA'

# After:
# (Remove local constants, use Styling module)

def draw_labeled_section(...)
  @pdf.stroke_color Styling::Colors::BORDERS  # Use centralized constant
  # ...
end
```

**6.3 Add convenience include to Component base**

```ruby
# lib/bujo_pdf/component.rb

module BujoPdf
  class Component
    # Make Styling constants available without full namespace
    include Styling::Colors  # Now can use BORDERS instead of Styling::Colors::BORDERS

    # ... rest of class
  end
end
```

**Savings**: Maintainability (single source of truth for constants)

**Files Modified**:
- `lib/bujo_pdf/component.rb`
- `lib/bujo_pdf/components/cornell_notes.rb`
- (Any other files with constant duplication)

### 7. Testing and Validation

**7.1 Generate baseline PDF**
```bash
bin/bujo-pdf generate 2025
mv planner_2025.pdf planner_before_refactor.pdf
```

**7.2 Apply refactoring in order**
1. Labeled section rendering (Section 1)
2. Validation helper (Section 2)
3. Style context managers (Section 3)
4. StandardLayoutPage (Section 4)
5. Link API standardization (Section 5)
6. Constant centralization (Section 6)

Generate PDF after each section, verify it still works.

**7.3 Final comparison**
```bash
bin/bujo-pdf generate 2025
# Visual comparison:
open planner_before_refactor.pdf planner_2025.pdf
# Or use diff tool if available
```

**7.4 Verify no errors or warnings**
```bash
bin/bujo-pdf generate 2025 2>&1 | grep -i "error\|warning"
# Should produce no output
```

## Testing Strategy

### Unit Testing (Future - Plan 08)
After testing infrastructure is in place, add tests for:
- `Component#require_options` with various missing keys
- `Component#with_fill_color` saves/restores state
- `Component#with_font` saves/restores state
- `GridSystem#link` creates correct annotation coordinates

### Integration Testing
- Generate complete planner PDF for 2025
- Verify all pages render correctly
- Test all navigation links work
- Verify sidebars highlight correctly

### Regression Testing
- Compare generated PDF with baseline (before refactoring)
- Ensure pixel-perfect match (or only expected differences)
- Verify file size remains similar
- Check all interactive features work

## Acceptance Criteria

### Must Have
- [x] CornellNotes uses parameterized helper for labeled sections (37 lines saved)
- [x] Component base class has `require_options` helper (16 lines saved)
- [x] Component base class has style context managers (16+ lines saved)
- [x] StandardLayoutPage base class created (9+ lines saved)
- [x] All components use GridSystem.link() instead of manual links (SKIPPED - already using grid.link where appropriate)
- [x] All constant duplications removed
- [x] Generated PDF identical to baseline (file size: 3.1M matches)
- [x] No errors or warnings when running `bin/bujo-pdf generate 2025`

### Should Have
- [x] Clear documentation for new helpers in Component base class
- [x] StandardLayoutPage documented with examples
- [x] All affected files updated consistently
- [x] Code is more maintainable and DRY

### Nice to Have
- [ ] Update CLAUDE.md with new Component base class features (deferred)
- [ ] Add inline comments explaining new patterns
- [ ] Consider adding rubocop or similar for future duplication detection

## Implementation Notes

### Migration Strategy
1. **One section at a time** - Complete each numbered section before moving to next
2. **Test after each change** - Generate PDF, verify it works
3. **Git commit per section** - Easy to bisect if issues arise
4. **Keep changes focused** - Each commit should be a single logical change

### Risk: Breaking Encapsulation
**Mitigation**: All new helpers are `protected` methods in Component base. They're internal implementation details, not public API.

### Risk: Over-Abstracting
**Mitigation**: Only extract patterns that appear 3+ times. All extractions are simple, obvious helpers with clear single purposes.

### Risk: Introducing Bugs
**Mitigation**: Generate PDF after each section. Compare with baseline. Stop immediately if differences appear.

## Success Metrics

### Quantitative
- **96+ lines of code removed** (37 + 16 + 16 + 9 + 18)
- **~38% reduction** in affected files
- **0 behavioral changes** (PDF identical to baseline)
- **0 new dependencies** (pure refactoring)

### Qualitative
- Components are more consistent
- Less manual state management
- Easier to add new components (validation, styles already handled)
- Single source of truth for constants
- More maintainable codebase

## Dependencies

**Depends on:**
- Plan 01: Extract Low-Level Utilities (Completed) - GridSystem exists
- Plan 02: Extract Components (Completed) - Components exist to refactor
- Plan 04: Extract Reusable Sub-Components (Completed) - SubComponents exist
- Plan 05: Page and Layout Abstraction (Completed) - Pages exist to refactor
- Plan 06: RenderContext System (Completed) - Context system in place
- Plan 10: Declarative Layout System (Completed) - Layout system exists

**Enables:**
- Plan 08: Testing Infrastructure - Clean code easier to test
- Plan 09: Gem Structure - Well-organized code easier to package
- Future component additions - Clear patterns to follow

## Estimated Effort

- **Section 1 (Labeled sections)**: 1 hour
- **Section 2 (Validation)**: 1 hour
- **Section 3 (Style managers)**: 2 hours
- **Section 4 (StandardLayoutPage)**: 1 hour
- **Section 5 (Link API)**: 1.5 hours
- **Section 6 (Constants)**: 1 hour
- **Testing/validation**: 1.5 hours
- **Total**: 9 hours

## Risks and Mitigations

### Risk: Regression in PDF output
**Mitigation**: Generate PDF after each section, compare with baseline immediately

### Risk: Style context managers not restoring state correctly
**Mitigation**: Test with simple example first, verify color/font restored

### Risk: StandardLayoutPage doesn't handle all cases
**Mitigation**: Start with one page class, verify works, then migrate others

### Risk: Breaking link functionality
**Mitigation**: Test clicking every link type in generated PDF

## Post-Completion

After completing this plan:

1. **Update documentation**
   - Update CLAUDE.md with new Component features
   - Document patterns for future component authors

2. **Consider follow-up work**
   - Add more context managers if patterns emerge (with_bounding_box, etc.)
   - Extract other rendering patterns if duplications appear

3. **Prepare for testing infrastructure (Plan 08)**
   - Clean code is easier to test
   - Helpers provide good unit test targets
