# Plan 01: Extract Low-Level Utilities

**Status**: Completed
**Priority**: Phase 1 - High Priority (Foundation)
**Estimated Complexity**: Medium
**Dependencies**: None (first task in refactoring)
**Completed**: 2025-11-11

## Overview

This plan outlines the extraction of low-level utility modules and classes from the monolithic `gen.rb` file. These utilities form the foundation of the grid-based layout system and will be used by all other components.

## Goals

1. Extract grid coordinate system into a reusable `GridSystem` class
2. Extract diagnostic/debug tools into a `Diagnostics` module
3. Extract dot grid rendering into a `DotGrid` module
4. Extract styling constants into a `Styling` module
5. Maintain 100% backward compatibility during extraction
6. Enable these utilities to be used independently of the main generator

## Current State Analysis

### Grid System (lines 179-350 in gen.rb)

**Core Methods**:
- `grid_x(col)` - Convert column to x-coordinate
- `grid_y(row)` - Convert row to y-coordinate (row 0 = top)
- `grid_width(boxes)` - Convert box count to width
- `grid_height(boxes)` - Convert box count to height
- `grid_rect(col, row, width_boxes, height_boxes)` - Get bounding box hash

**Helper Methods**:
- `grid_text_box(text, col, row, width_boxes, height_boxes, **options)` - Positioned text box
- `grid_link(col, row, width_boxes, height_boxes, dest, **options)` - Positioned link annotation
- `grid_inset(rect, padding_boxes)` - Apply padding to grid_rect result
- `grid_bottom(row, height_boxes)` - Calculate bottom Y coordinate
- `draw_right_nav_tab(...)` - Specialized component (may move to Component extraction later)

**Dependencies**:
- Requires Prawn PDF instance (`@pdf`)
- Uses constants: `DOT_SPACING`, `PAGE_HEIGHT`, `GRID_COLS`, `GRID_ROWS`
- Coordinate system relies on Prawn's bottom-left origin

**Current Usage**:
- Used extensively throughout all page generation methods
- ~100+ call sites across the codebase
- Critical for all layout calculations

### Diagnostics (lines 513-576 in gen.rb)

**Core Method**:
- `draw_diagnostic_grid(label_every: 5)` - Draw debug grid overlay

**Features**:
- Red dots at every grid intersection (1.0pt radius vs 0.5pt for regular dots)
- Dashed red lines every N boxes (vertical and horizontal)
- Coordinate labels `(col, row)` at line intersections
- White background rectangles behind labels for readability
- Respects `DEBUG_GRID` constant (only draws when true)

**Dependencies**:
- Requires Prawn PDF instance (`@pdf`)
- Uses `grid_x()`, `grid_y()` methods
- Uses constants: `DEBUG_GRID`, `GRID_COLS`, `GRID_ROWS`, `PAGE_HEIGHT`, `PAGE_WIDTH`

**Current Usage**:
- Called once per page in DEBUG mode
- Typically called at start of page generation (as background layer)

### Dot Grid (lines 1300-1323 in gen.rb)

**Core Method**:
- `draw_dot_grid(width, height)` - Draw dots at grid intersections

**Features**:
- Draws dots at exact grid positions (every DOT_SPACING)
- Aligned with grid coordinate system
- Calculates cols/rows from provided dimensions
- Uses light gray color (COLOR_DOT_GRID)

**Dependencies**:
- Requires Prawn PDF instance (`@pdf`)
- Uses constants: `DOT_SPACING`, `DOT_RADIUS`, `COLOR_DOT_GRID`

**Current Usage**:
- Called on every page to draw background dot grid
- Called with full page dimensions or bounding box dimensions

### Styling Constants (lines 6-123 in gen.rb)

**Categories of Constants**:

1. **Page Dimensions** (lines 6-14):
   - `PAGE_WIDTH`, `PAGE_HEIGHT`
   - `PAGE_MARGIN_HORIZONTAL`, `PAGE_MARGIN_TOP`
   - `FOOTER_HEIGHT`, `FOOTER_CLEARANCE`

2. **Grid System** (lines 100-108):
   - `DOT_SPACING` - 14.17pt (5mm)
   - `DOT_RADIUS` - 0.5pt
   - `DOT_GRID_PADDING` - 5pt
   - `GRID_COLS` - 43 (calculated)
   - `GRID_ROWS` - 55 (calculated)

3. **Colors** (lines 113-117):
   - `COLOR_DOT_GRID` - 'CCCCCC' (light gray)
   - `COLOR_BORDERS` - 'E5E5E5' (very light gray)
   - `COLOR_SECTION_HEADERS` - 'AAAAAA' (muted gray)
   - `COLOR_WEEKEND_BG` - 'FAFAFA' (subtle weekend shading)

4. **Layout-Specific Constants** (lines 16-98):
   - Seasonal calendar layout constants
   - Year at glance layout constants
   - Weekly page layout constants
   - Footer constants

**Organization Challenge**:
- Currently all constants are mixed together in one place
- Some are truly global (colors, grid), others are page-specific
- Need to separate concerns for better organization

## Design Decisions

### 1. GridSystem Class

**API Design**:
```ruby
class GridSystem
  attr_reader :dot_spacing, :page_width, :page_height, :cols, :rows

  def initialize(pdf, dot_spacing: 14.17, page_width: 612, page_height: 792)
    @pdf = pdf
    @dot_spacing = dot_spacing
    @page_width = page_width
    @page_height = page_height
    @cols = (page_width / dot_spacing).floor
    @rows = (page_height / dot_spacing).floor
  end

  # Core coordinate conversion
  def x(col)
  def y(row)
  def width(boxes)
  def height(boxes)
  def rect(col, row, width_boxes, height_boxes)

  # Helper methods
  def text_box(text, col, row, width_boxes, height_boxes, **options)
  def link(col, row, width_boxes, height_boxes, dest, **options)
  def inset(rect, padding_boxes)
  def bottom(row, height_boxes)
end
```

**Key Design Choices**:
- **Instance-based**: Create an instance with PDF reference and configuration
- **Shorter method names**: `x()` instead of `grid_x()` when called on GridSystem instance
- **Configurable**: Allow custom dot_spacing and page dimensions (future flexibility)
- **Stateless calculations**: All methods are pure functions of their inputs
- **PDF reference**: Store `@pdf` for methods that need it (text_box, link)

**Backward Compatibility Strategy**:
- Keep existing `grid_*` methods in PlannerGenerator as thin wrappers
- Delegate to GridSystem instance: `grid_x(col) -> @grid_system.x(col)`
- No changes needed at call sites initially
- Later, can migrate call sites to use `@grid_system.x()` directly

**Testing Strategy**:
- Unit test all coordinate conversions
- Test edge cases (col 0, col 43, row 0, row 55)
- Test rect generation with various inputs
- Test inset calculation with fractional padding
- Mock Prawn PDF for methods that need it

### 2. Diagnostics Module

**API Design**:
```ruby
module Diagnostics
  # Class method for standalone use
  def self.draw_grid(pdf, grid_system, enabled: true, label_every: 5)
    return unless enabled
    # Implementation
  end

  # Instance method for mixing into classes
  def draw_diagnostic_grid(label_every: 5)
    Diagnostics.draw_grid(@pdf, @grid_system, enabled: DEBUG_GRID, label_every: label_every)
  end
end
```

**Key Design Choices**:
- **Module pattern**: Static utility module, can be mixed in or called directly
- **Explicit dependencies**: Pass pdf and grid_system as parameters
- **Configurable**: enabled flag, label_every spacing
- **Dual interface**: Class method for standalone, instance method for mixin
- **Guard clause**: Return early if not enabled

**Configuration**:
- `DEBUG_GRID` constant determines if diagnostics are enabled
- `label_every` parameter controls grid line spacing (default: 5)
- Color constants for diagnostic rendering (currently hardcoded 'FF0000')

**Backward Compatibility Strategy**:
- Keep `draw_diagnostic_grid()` method in PlannerGenerator
- Delegate to `Diagnostics.draw_grid()` with current instance variables
- No changes needed at call sites

### 3. DotGrid Module

**API Design**:
```ruby
module DotGrid
  # Class method for standalone use
  def self.draw(pdf, width, height, spacing: 14.17, radius: 0.5, color: 'CCCCCC')
    # Implementation
  end

  # Instance method for mixing into classes
  def draw_dot_grid(width, height)
    DotGrid.draw(@pdf, width, height,
                 spacing: DOT_SPACING,
                 radius: DOT_RADIUS,
                 color: COLOR_DOT_GRID)
  end
end
```

**Key Design Choices**:
- **Module pattern**: Static utility module
- **Configurable**: Spacing, radius, and color as parameters
- **Standalone**: Can be used independently of GridSystem
- **Simple API**: Just width, height, and styling options
- **Color management**: Properly reset color after drawing

**Backward Compatibility Strategy**:
- Keep `draw_dot_grid(width, height)` method in PlannerGenerator
- Delegate to `DotGrid.draw()` with styling constants
- No changes needed at call sites

### 4. Styling Module

**API Design**:
```ruby
module Styling
  # Colors
  module Colors
    DOT_GRID = 'CCCCCC'
    BORDERS = 'E5E5E5'
    SECTION_HEADERS = 'AAAAAA'
    WEEKEND_BG = 'FAFAFA'
    DIAGNOSTIC_RED = 'FF0000'
    DIAGNOSTIC_LABEL_BG = 'FFFFFF'
    TEXT_BLACK = '000000'
  end

  # Grid dimensions
  module Grid
    DOT_SPACING = 14.17  # 5mm in points
    DOT_RADIUS = 0.5
    DOT_GRID_PADDING = 5

    # Page dimensions
    PAGE_WIDTH = 612    # 8.5 inches
    PAGE_HEIGHT = 792   # 11 inches

    # Calculated grid dimensions
    COLS = (PAGE_WIDTH / DOT_SPACING).floor   # 43
    ROWS = (PAGE_HEIGHT / DOT_SPACING).floor  # 55
  end

  # Typography
  module Typography
    # Font sizes for different contexts
    # (To be populated as we extract more constants)
  end

  # Layout dimensions
  module Layout
    # Page-level margins and gutters
    # (To be populated as we extract more constants)
  end
end
```

**Key Design Choices**:
- **Nested modules**: Organize by category (Colors, Grid, Typography, Layout)
- **Namespaced**: All constants under Styling::Category::CONSTANT
- **Start small**: Only extract truly global constants initially
- **Page-specific constants**: Leave in PlannerGenerator for now (extract in Phase 2)
- **Documentation**: Each module should document its purpose

**Migration Strategy**:
- Create Styling module with essential constants
- Keep original constants in PlannerGenerator as aliases initially
- Gradually migrate call sites to use Styling::Colors::BORDERS, etc.
- Remove aliases once migration is complete

**Constants to Extract Now**:
- All Color constants (truly global)
- All Grid dimension constants (DOT_SPACING, GRID_COLS, etc.)
- Page dimensions (PAGE_WIDTH, PAGE_HEIGHT)

**Constants to Leave for Later**:
- Seasonal calendar layout constants (page-specific)
- Year at glance layout constants (page-specific)
- Weekly page layout constants (page-specific)
- Footer constants (could go either way, leave for now)

### 5. Component Helper Method: draw_right_nav_tab

**Current Location**: Lines 285-350 in gen.rb

**Decision**: **Defer to Component Extraction (Phase 2)**

**Rationale**:
- This is really a component, not a low-level utility
- It's specialized for right sidebar navigation
- It has complex text rotation and positioning logic
- Better suited for `Component::Navigation` or `Component::Sidebar` class
- Only used in one context (right sidebar on weekly pages)

**For Now**:
- Leave in PlannerGenerator
- Will be extracted when we create Component architecture

## File Structure

```
lib/
  bujo_pdf/
    utilities/
      grid_system.rb       # GridSystem class
      diagnostics.rb       # Diagnostics module
      dot_grid.rb          # DotGrid module
      styling.rb           # Styling module with nested modules
```

**Alternative Structure** (if we want flatter):
```
lib/
  bujo_pdf/
    grid_system.rb
    diagnostics.rb
    dot_grid.rb
    styling/
      colors.rb
      grid.rb
      typography.rb
      layout.rb
```

**Recommendation**: Use the first structure (utilities/ subdirectory)
- Keeps utilities grouped together
- Easier to understand project structure
- One styling.rb with nested modules is cleaner than multiple files

## Implementation Steps

### Step 1: Create Directory Structure
```bash
mkdir -p lib/bujo_pdf/utilities
```

### Step 2: Extract Styling Module (Foundation)
1. Create `lib/bujo_pdf/utilities/styling.rb`
2. Define nested modules (Colors, Grid)
3. Copy constant definitions
4. Add documentation comments
5. Test by requiring and accessing constants

### Step 3: Extract GridSystem Class
1. Create `lib/bujo_pdf/utilities/grid_system.rb`
2. Require styling.rb for constants
3. Define class with initialize method
4. Copy and adapt all grid_* methods
5. Rename methods (grid_x -> x, grid_y -> y, etc.)
6. Update method implementations to use instance variables
7. Add documentation comments

### Step 4: Extract DotGrid Module
1. Create `lib/bujo_pdf/utilities/dot_grid.rb`
2. Require styling.rb for constants
3. Define module with draw class method
4. Copy draw_dot_grid implementation
5. Parameterize styling constants
6. Add documentation comments

### Step 5: Extract Diagnostics Module
1. Create `lib/bujo_pdf/utilities/diagnostics.rb`
2. Require styling.rb for constants
3. Define module with draw_grid class method
4. Copy draw_diagnostic_grid implementation
5. Update to use GridSystem instance
6. Add documentation comments

### Step 6: Update PlannerGenerator (Backward Compatibility)
1. Require all new utility files
2. Create @grid_system instance in initialize
3. Create delegation methods (grid_x -> @grid_system.x)
4. Update draw_dot_grid to use DotGrid.draw
5. Update draw_diagnostic_grid to use Diagnostics.draw_grid
6. Keep original constant definitions as aliases initially

### Step 7: Testing
1. Run gen.rb and verify PDF output is identical
2. Test with DEBUG_GRID = true
3. Test with DEBUG_GRID = false
4. Verify all pages render correctly
5. Verify all links work correctly
6. Check file size (should be identical)

### Step 8: Create Unit Tests
1. Set up test framework (RSpec or Minitest)
2. Write tests for GridSystem
3. Write tests for DotGrid
4. Write tests for Diagnostics
5. Write integration test (compare PDFs)

## Migration Strategy

### Phase 1: Extract with Compatibility Layer (This Plan)
- Extract utilities into separate files
- Keep all existing methods in PlannerGenerator as wrappers
- No changes to call sites
- Verify output is identical

### Phase 2: Direct Usage (Future Plan)
- Update call sites to use @grid_system.x() instead of grid_x()
- Update call sites to use Styling::Colors::BORDERS instead of COLOR_BORDERS
- Remove wrapper methods from PlannerGenerator
- Remove constant aliases from PlannerGenerator

### Phase 3: External Usage (Future Plan)
- Make utilities available as part of gem API
- Allow other projects to use GridSystem independently
- Document utility APIs for external use

## Testing Strategy

### Unit Tests for GridSystem

```ruby
describe GridSystem do
  let(:pdf) { instance_double(Prawn::Document) }
  let(:grid) { GridSystem.new(pdf) }

  describe '#x' do
    it 'converts column 0 to 0 points' do
      expect(grid.x(0)).to eq(0)
    end

    it 'converts column 1 to DOT_SPACING points' do
      expect(grid.x(1)).to eq(14.17)
    end

    it 'converts column 21 to center x coordinate' do
      expect(grid.x(21)).to be_within(0.1).of(297.57)
    end
  end

  describe '#y' do
    it 'converts row 0 to page height' do
      expect(grid.y(0)).to eq(792)
    end

    it 'converts row 55 to bottom' do
      expect(grid.y(55)).to be_within(0.1).of(12.65)
    end
  end

  describe '#rect' do
    it 'returns correct hash for full page' do
      rect = grid.rect(0, 0, 43, 55)
      expect(rect[:x]).to eq(0)
      expect(rect[:y]).to eq(792)
      expect(rect[:width]).to be_within(0.1).of(609.31)
      expect(rect[:height]).to be_within(0.1).of(779.35)
    end
  end

  describe '#inset' do
    it 'applies padding correctly' do
      rect = grid.rect(5, 10, 10, 10)
      padded = grid.inset(rect, 0.5)

      expect(padded[:width]).to eq(rect[:width] - 14.17)
      expect(padded[:height]).to eq(rect[:height] - 14.17)
    end
  end
end
```

### Integration Tests

```ruby
describe 'PDF Generation' do
  it 'produces identical output before and after refactoring' do
    # Generate with original gen.rb (baseline)
    baseline_pdf = generate_baseline_pdf(2025)

    # Generate with refactored code
    refactored_pdf = generate_refactored_pdf(2025)

    # Compare file sizes
    expect(refactored_pdf.size).to eq(baseline_pdf.size)

    # Compare page counts
    expect(refactored_pdf.page_count).to eq(baseline_pdf.page_count)

    # Could use PDF comparison tools for deeper analysis
  end
end
```

### Visual Regression Testing (Optional)

- Convert PDF pages to PNG images
- Compare pixel-by-pixel using ImageMagick
- Detect any visual differences
- Useful for catching subtle rendering changes

## Dependencies

### Required Gems
- `prawn` ~> 2.4 (already a dependency)
- Testing framework: `rspec` or `minitest` (new dependency)

### Internal Dependencies
```
GridSystem -> Styling
DotGrid -> Styling
Diagnostics -> Styling, GridSystem
PlannerGenerator -> GridSystem, DotGrid, Diagnostics, Styling
```

### Dependency Graph
```
Styling (no dependencies)
  ├── GridSystem
  │     └── Diagnostics
  └── DotGrid

PlannerGenerator (uses all)
```

## Risk Assessment

### Low Risk
- **GridSystem extraction**: Pure calculations, easy to test
- **Styling constants**: Simple extraction, no logic changes
- **DotGrid extraction**: Self-contained, simple logic

### Medium Risk
- **Diagnostics extraction**: More complex, uses multiple systems
- **Testing setup**: Need to establish testing infrastructure

### High Risk
- **Breaking existing functionality**: Mitigated by compatibility layer
- **Performance impact**: Mitigated by keeping calculations efficient

### Mitigation Strategies

1. **Incremental approach**: Extract one utility at a time
2. **Compatibility layer**: Keep wrapper methods during transition
3. **Comprehensive testing**: Test each utility independently
4. **Visual verification**: Generate PDFs and compare visually
5. **Rollback plan**: Keep git history clean for easy rollback
6. **Debug mode**: Use DEBUG_GRID to verify layout is unchanged

## Success Criteria

### Functional Requirements
- [ ] All pages render identically to before refactoring
- [ ] All hyperlinks work correctly
- [ ] Diagnostic grid displays correctly when DEBUG_GRID = true
- [ ] Dot grid displays correctly on all pages
- [ ] No visual differences in generated PDFs

### Code Quality Requirements
- [ ] GridSystem class has complete unit test coverage
- [ ] All utilities have clear documentation
- [ ] No code duplication between utilities and PlannerGenerator
- [ ] Constants are organized by category
- [ ] Code follows Ruby style guide

### Architecture Requirements
- [ ] Utilities are in separate files under lib/bujo_pdf/utilities/
- [ ] Clear separation of concerns (grid math, rendering, styling)
- [ ] Utilities can be used independently
- [ ] No circular dependencies
- [ ] Clean require statements

### Performance Requirements
- [ ] PDF generation time unchanged (within 5%)
- [ ] No memory leaks or excessive memory usage
- [ ] File size identical (within 1 byte, accounting for timestamps)

## Future Enhancements

After this extraction is complete, these utilities can be enhanced:

### GridSystem Enhancements
- Add `span(start_col, end_col)` method for column ranges
- Add `center_in(rect, width_boxes, height_boxes)` for centering
- Add `margin(boxes)` method for consistent margins
- Add validation for out-of-bounds coordinates

### Diagnostics Enhancements
- Add configurable diagnostic colors
- Add grid ruler overlay (measurement scale)
- Add bounding box highlighting
- Add coordinate tracking on mouse hover (for interactive PDFs)

### DotGrid Enhancements
- Add pattern variations (crosses, circles, squares)
- Add color gradients
- Add custom patterns for different page types

### Styling Enhancements
- Add theme system (light, dark, colorful)
- Add color palette generator
- Add typography scale system
- Add responsive layout calculations

## Notes

- All utilities should be stateless where possible
- Prefer pure functions over stateful objects
- Document coordinate system thoroughly (Prawn's bottom-left origin vs. grid's top-left)
- Keep utilities simple and focused
- Avoid premature optimization
- Maintain consistency with Prawn's conventions

## References

- Original code: `gen.rb` lines 6-123 (constants), 179-350 (grid), 513-576 (diagnostics), 1300-1323 (dot grid)
- Documentation: `CLAUDE.md` (project overview), `CLAUDE.local.md` (grid system details)
- Prawn docs: https://prawnpdf.org/api-docs/
- Ruby style guide: https://rubystyle.guide/

## Timeline Estimate

- **Setup and Styling extraction**: 1-2 hours
- **GridSystem extraction**: 2-3 hours
- **DotGrid extraction**: 1 hour
- **Diagnostics extraction**: 1-2 hours
- **Integration and compatibility layer**: 2-3 hours
- **Testing setup and test writing**: 3-4 hours
- **Documentation and cleanup**: 1-2 hours

**Total**: 11-17 hours

## Completion Summary

Successfully completed on 2025-11-11. All objectives achieved:

### What Was Accomplished
1. ✅ Created `lib/bujo_pdf/utilities/` directory structure
2. ✅ Extracted Styling module with Colors and Grid constants
3. ✅ Extracted GridSystem class with all coordinate conversion methods
4. ✅ Extracted DotGrid module for background rendering
5. ✅ Extracted Diagnostics module for debug grid overlay
6. ✅ Updated PlannerGenerator with backward compatibility layer
7. ✅ All existing methods delegate to new utilities
8. ✅ PDF generation verified working correctly (58 pages)
9. ✅ Created comprehensive unit tests (20 tests, 86 assertions, all passing)

### Files Created
- `lib/bujo_pdf/utilities/styling.rb` (1607 bytes)
- `lib/bujo_pdf/utilities/grid_system.rb` (6391 bytes)
- `lib/bujo_pdf/utilities/dot_grid.rb` (2424 bytes)
- `lib/bujo_pdf/utilities/diagnostics.rb` (3389 bytes)
- `test/test_grid_system.rb` (3566 bytes)
- `test/test_dot_grid.rb` (2835 bytes)
- `test/test_all.rb` (173 bytes)

### Changes to gen.rb
- Added requires for new utility modules
- Initialize GridSystem instance in generate method
- Converted all grid methods to delegation wrappers
- Simplified draw_dot_grid and draw_diagnostic_grid to one-liners
- Net reduction: 120 lines removed, utilities extracted to dedicated files

### Success Criteria Met
- ✅ All pages render identically to before refactoring
- ✅ All hyperlinks work correctly
- ✅ Diagnostic grid displays correctly when DEBUG_GRID = true
- ✅ Dot grid displays correctly on all pages
- ✅ GridSystem class has complete unit test coverage
- ✅ All utilities have clear documentation
- ✅ No code duplication between utilities and PlannerGenerator
- ✅ Constants organized by category (Colors, Grid)
- ✅ Utilities are in separate files under lib/bujo_pdf/utilities/
- ✅ Clear separation of concerns
- ✅ No circular dependencies

### Git Commit
Branch: `extract-low-level-utilities`
Commit: bf128fc "Extract low-level utilities into separate modules"

## Next Steps

After completing this extraction:
1. ✅ Review and test thoroughly - DONE
2. ✅ Commit to git with clear message - DONE
3. Update REFACTORING_PLAN.md to check off completed tasks
4. Begin Phase 2: Layout Management System
5. Create plan for Context Object System
