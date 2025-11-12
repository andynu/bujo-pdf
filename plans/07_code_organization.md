# Plan 07: Code Organization and Constant Separation

## Executive Summary

Refactor the monolithic `gen.rb` file to improve code organization by:
1. Separating constants into logical grouping files
2. Extracting date/week calculation utilities into a dedicated class
3. Reorganizing methods into modules using composition patterns

This refactoring will improve maintainability, testability, and clarity without changing any functionality.

## Current State

All constants (130+ lines), utilities, and generation logic are currently in a single `gen.rb` file (~1480 lines). Constants are grouped by comments but not separated into modules or files. Date calculations are embedded in the main generator class.

## Technical Approach

### 1. Constant Separation Strategy
Extract constants into separate files under a `constants/` directory, each file defining a module that can be included in the main generator.

### 2. Date Calculation Extraction
Create a `DateCalculator` class to encapsulate all week numbering and date range logic, making it testable and reusable.

### 3. Module Organization
Group related utility methods into modules that can be mixed into classes, following single-responsibility principle.

## Implementation Steps

### 1. Create Constants Directory Structure

**1.1 Set up directory**
- Create `constants/` directory in project root
- Each constant file will define a module to be included

**1.2 Create `constants/grid.rb`**
Extract grid system constants:
```ruby
# constants/grid.rb
module PlannerConstants
  module Grid
    # Grid dimensions
    GRID_COLS = 43
    GRID_ROWS = 55
    DOT_SPACING = 14.17323  # 5mm in points

    # Page dimensions
    PAGE_WIDTH = 612
    PAGE_HEIGHT = 792

    # Debug settings
    DEBUG_GRID = false
  end
end
```

**1.3 Create `constants/colors.rb`**
Extract color definitions:
```ruby
# constants/colors.rb
module PlannerConstants
  module Colors
    COLOR_DOT_GRID = 'CCCCCC'
    COLOR_BORDERS = 'E5E5E5'
    COLOR_SECTION_HEADERS = 'AAAAAA'
    COLOR_WEEKEND_BG = 'FAFAFA'
    COLOR_HEADER_GRAY = '808080'
    # ... all other color constants
  end
end
```

**1.4 Create `constants/layout.rb`**
Extract layout dimensions:
```ruby
# constants/layout.rb
module PlannerConstants
  module Layout
    # Seasonal calendar layout
    SEASONAL_LEFT_INSET = 0.5
    SEASONAL_RIGHT_INSET = 1.5
    SEASONAL_TOP_INSET = 1.5
    SEASONAL_BOTTOM_INSET = 0.5

    # Weekly page layout
    WEEKLY_TOP_NAV_HEIGHT_BOXES = 2
    WEEKLY_SIDEBAR_WIDTH_BOXES = 3
    WEEKLY_RIGHT_TAB_WIDTH_BOXES = 1.5

    # ... all other layout constants
  end
end
```

**1.5 Create `constants/typography.rb`**
Extract font sizes and text styling:
```ruby
# constants/typography.rb
module PlannerConstants
  module Typography
    FONT_SIZE_PAGE_TITLE = 16
    FONT_SIZE_SECTION_HEADER = 10
    FONT_SIZE_DAY_HEADER = 9
    FONT_SIZE_MONTH_LABEL = 8
    FONT_SIZE_DAY_NUMBER = 7
    FONT_SIZE_NOTES = 6

    # ... all other typography constants
  end
end
```

**1.6 Update `gen.rb` to require constants**
```ruby
# gen.rb (top of file)
require 'prawn'
require 'date'
require_relative 'constants/grid'
require_relative 'constants/colors'
require_relative 'constants/layout'
require_relative 'constants/typography'

class PlannerGenerator
  include PlannerConstants::Grid
  include PlannerConstants::Colors
  include PlannerConstants::Layout
  include PlannerConstants::Typography

  # ... rest of class
end
```

### 2. Extract Date/Week Calculation Utilities

**2.1 Create `lib/` directory**
- Create `lib/` directory for utility classes
- Place `date_calculator.rb` in this directory

**2.2 Implement `DateCalculator` class**
```ruby
# lib/date_calculator.rb
class DateCalculator
  attr_reader :year

  def initialize(year)
    @year = year
  end

  # Calculate the Monday of week 1 (on or before January 1)
  def year_start_monday
    @year_start_monday ||= begin
      first_day = Date.new(@year, 1, 1)
      days_back = (first_day.wday + 6) % 7  # Convert to Monday-based
      first_day - days_back
    end
  end

  # Calculate week number for a given date
  def week_number(date)
    days_from_start = (date - year_start_monday).to_i
    (days_from_start / 7) + 1
  end

  # Get total number of weeks in the year
  def total_weeks
    @total_weeks ||= begin
      last_day = Date.new(@year, 12, 31)
      week_number(last_day)
    end
  end

  # Get date range for a specific week number
  def week_range(week_num)
    start_date = year_start_monday + ((week_num - 1) * 7)
    end_date = start_date + 6
    [start_date, end_date]
  end

  # Get the Monday of a specific week
  def week_start(week_num)
    year_start_monday + ((week_num - 1) * 7)
  end

  # Check if a date falls within the calendar year
  def in_year?(date)
    date.year == @year
  end

  # Get all weeks that overlap with a specific month
  def weeks_for_month(month)
    first_of_month = Date.new(@year, month, 1)
    last_of_month = Date.new(@year, month, -1)

    first_week = week_number(first_of_month)
    last_week = week_number(last_of_month)

    (first_week..last_week).to_a
  end
end
```

**2.3 Update `PlannerGenerator` to use `DateCalculator`**
Replace all date calculation logic with calls to `DateCalculator`:

```ruby
class PlannerGenerator
  def initialize(year)
    @year = year
    @date_calc = DateCalculator.new(year)
    @pdf = Prawn::Document.new(page_size: 'LETTER')
  end

  # Replace inline calculations with @date_calc methods
  def generate_weekly_pages
    (1..@date_calc.total_weeks).each do |week_num|
      # ...
    end
  end

  # ... other methods updated similarly
end
```

### 3. Improve Method Organization

**3.1 Create `modules/grid_helpers.rb`**
Extract grid calculation methods into a module:
```ruby
# modules/grid_helpers.rb
module GridHelpers
  def grid_x(col)
    col * DOT_SPACING
  end

  def grid_y(row)
    PAGE_HEIGHT - (row * DOT_SPACING)
  end

  def grid_width(boxes)
    boxes * DOT_SPACING
  end

  def grid_height(boxes)
    boxes * DOT_SPACING
  end

  def grid_rect(col, row, width_boxes, height_boxes)
    {
      x: grid_x(col),
      y: grid_y(row),
      width: grid_width(width_boxes),
      height: grid_height(height_boxes)
    }
  end

  # ... other grid helper methods
end
```

**3.2 Create `modules/drawing_helpers.rb`**
Extract drawing utility methods:
```ruby
# modules/drawing_helpers.rb
module DrawingHelpers
  def draw_dot_grid(width, height)
    # ... existing implementation
  end

  def draw_diagnostic_grid(label_every: 5)
    # ... existing implementation
  end

  def draw_fieldset(position:, legend_label:, border_inset: 0.5, legend_offset: 0)
    # ... existing implementation
  end
end
```

**3.3 Create `modules/link_helpers.rb`**
Extract navigation and link methods:
```ruby
# modules/link_helpers.rb
module LinkHelpers
  def grid_link(col, row, width_boxes, height_boxes, dest, **options)
    # ... existing implementation
  end

  def setup_named_destinations
    # ... existing implementation
  end
end
```

**3.4 Update `gen.rb` to include modules**
```ruby
require_relative 'modules/grid_helpers'
require_relative 'modules/drawing_helpers'
require_relative 'modules/link_helpers'

class PlannerGenerator
  include GridHelpers
  include DrawingHelpers
  include LinkHelpers

  # ... rest of class contains only page generation logic
end
```

### 4. Refactor Directory Structure

**4.1 Final directory layout**
```
bujo-pdf/
├── gen.rb                    # Main generator (orchestration only)
├── lib/
│   └── date_calculator.rb    # Date/week calculations
├── modules/
│   ├── grid_helpers.rb       # Grid coordinate methods
│   ├── drawing_helpers.rb    # Drawing utility methods
│   └── link_helpers.rb       # Navigation/link methods
├── constants/
│   ├── grid.rb              # Grid system constants
│   ├── colors.rb            # Color definitions
│   ├── layout.rb            # Layout dimensions
│   └── typography.rb        # Font sizes
└── components/               # Existing component classes
    ├── base_page.rb
    ├── render_context.rb
    └── ...
```

**4.2 Update require statements**
Ensure all files are properly required in the correct order:
1. Constants first
2. Utility classes (DateCalculator)
3. Modules (helpers)
4. Components
5. Main generator

### 5. Testing and Validation

**5.1 Verify no behavioral changes**
- Generate planner before refactoring: `ruby gen.rb 2025 && mv planner_2025.pdf planner_before.pdf`
- Perform refactoring
- Generate planner after refactoring: `ruby gen.rb 2025`
- Compare PDFs byte-by-byte or visually

**5.2 Test DateCalculator independently**
Create a simple test script to verify date calculations:
```ruby
# test_date_calculator.rb
require_relative 'lib/date_calculator'

calc = DateCalculator.new(2025)
puts "Year start Monday: #{calc.year_start_monday}"
puts "Total weeks: #{calc.total_weeks}"
puts "Week 1 range: #{calc.week_range(1)}"
puts "Weeks in March: #{calc.weeks_for_month(3)}"
```

**5.3 Verify all constants accessible**
Check that no constant reference errors occur when running generator.

## Testing Strategy

### Unit Testing
- Test `DateCalculator` methods with known dates and edge cases
- Verify week number calculations for year boundaries
- Test month-to-week mappings

### Integration Testing
- Generate complete planner PDF
- Verify all pages render correctly
- Test navigation links work properly
- Check that constants are properly accessible

### Regression Testing
- Compare generated PDF with previous version
- Ensure no visual differences
- Verify file size remains similar
- Check all interactive features (links, bookmarks)

## Acceptance Criteria

### Must Have
- [ ] All constants separated into logical files under `constants/`
- [ ] `DateCalculator` class created and working
- [ ] All grid helper methods in `GridHelpers` module
- [ ] All drawing methods in `DrawingHelpers` module
- [ ] All link methods in `LinkHelpers` module
- [ ] Generated PDF identical to previous version
- [ ] No errors when running `ruby gen.rb 2025`

### Should Have
- [ ] Clean directory structure with `lib/`, `modules/`, `constants/`
- [ ] All require statements properly organized
- [ ] Code is more readable and maintainable
- [ ] Methods grouped by responsibility

### Nice to Have
- [ ] Simple test script for `DateCalculator`
- [ ] Comments documenting module purposes
- [ ] Update CLAUDE.md with new file structure

## Implementation Notes

### Migration Strategy
1. Create all new files first (constants, modules, lib)
2. Test that includes/requires work before removing from gen.rb
3. Remove code from gen.rb only after verifying it works in new location
4. Generate PDF at each step to catch regressions early

### Backwards Compatibility
Since this is a standalone generator (not a library), backwards compatibility is not a concern. Focus on clean organization.

### Future Considerations
This refactoring sets the foundation for:
- Converting to a Ruby gem (Phase 3)
- Adding comprehensive test suite
- Making components more reusable
- Adding configuration files for customization

## Dependencies

**Depends on:**
- Plan 01: Extract Low-Level Utilities (Completed)
- Plan 02: Extract Components (Completed)
- Plan 05: Page and Layout Abstraction (Completed)
- Plan 06: RenderContext System (Completed)

**Blocks:**
- Future gem structure work
- Comprehensive testing infrastructure
- Configuration system

## Estimated Effort

- **Constant separation**: 1-2 hours
- **DateCalculator extraction**: 1-2 hours
- **Module organization**: 2-3 hours
- **Testing and validation**: 1 hour
- **Total**: 5-8 hours

## Risks and Mitigations

### Risk: Breaking existing functionality
**Mitigation**: Generate PDF after each major change, compare with baseline

### Risk: Circular dependency issues with requires
**Mitigation**: Keep dependency graph simple - constants → utils → modules → components → generator

### Risk: Constant scope issues with modules
**Mitigation**: Use explicit `include` statements, test thoroughly

## Success Metrics

- Generator runs without errors
- Generated PDF matches previous version exactly
- Code is organized into logical files/modules
- Constants are easy to find and modify
- Date calculations are isolated and testable
