# Plan 08: Testing Infrastructure

## Executive Summary

Establish a comprehensive testing infrastructure for the bullet journal PDF generator to ensure reliability, prevent regressions, and enable confident refactoring. This plan covers unit tests for critical calculation and layout logic, integration tests for page generation, and optional visual regression testing for PDF output verification.

**Current State**: No formal test suite exists. The codebase includes experimental test files (`test_*.rb`) for debugging PDF link annotations and coordinate systems, but these are one-off scripts rather than automated tests.

**Goal State**: A robust Minitest-based test suite covering grid system calculations, date logic, component rendering, and full page generation workflows. All tests can be run with a single command and integrated into CI/CD pipelines.

**Priority**: Phase 3 - High Priority (Quality & Maintainability)

**Dependencies**:
- Plan 01 (Extract Low-Level Utilities) - COMPLETED
- Plan 02 (Extract Components) - COMPLETED
- Plan 04 (Extract Reusable Sub-Components) - COMPLETED
- Plan 05 (Page and Layout Abstraction) - COMPLETED
- Plan 06 (RenderContext System) - COMPLETED

## Technical Approach

### Testing Framework: Minitest

**Rationale for Minitest**:
- Ruby standard library (no external dependencies for basic features)
- Simple, straightforward API
- Fast execution
- Excellent for unit and integration testing
- Supports both test/unit style and spec-style syntax

**Alternative Considered**: RSpec
- More expressive DSL but adds dependency overhead
- Better for BDD-style development
- Not necessary for this utility-focused codebase

### Test Organization Structure

```
test/
├── test_helper.rb              # Shared setup, assertions, utilities
├── unit/
│   ├── test_grid_system.rb     # Grid coordinate calculations
│   ├── test_date_calculator.rb # Week numbers, date ranges
│   ├── test_grid_helpers.rb    # Helper methods (grid_rect, grid_inset, etc.)
│   └── test_render_context.rb  # RenderContext state management
├── integration/
│   ├── test_page_generation.rb # Full page rendering workflows
│   ├── test_navigation.rb      # Link annotations, named destinations
│   └── test_pdf_structure.rb   # PDF outline, bookmarks, metadata
└── visual/
    ├── test_visual_regression.rb # Optional: PDF comparison tests
    └── fixtures/
        └── expected_*.pdf        # Known-good PDF outputs
```

### Key Testing Challenges

1. **PDF Output Testing**: PDFs are binary files that change with each generation (timestamps, unique IDs)
   - **Solution**: Test PDF structure via Prawn's internal state or PDF parsing
   - **Alternative**: Visual regression testing with PDF-to-image conversion

2. **Coordinate System Complexity**: Grid coordinates convert to Prawn coordinates (origin bottom-left)
   - **Solution**: Extensive unit tests for edge cases (row 0, row 54, negative values)
   - **Verification**: Use calibration page for visual confirmation

3. **Date Calculations**: Week numbering edge cases (year boundaries, leap years)
   - **Solution**: Test known edge cases (2020, 2021, 2024) with pre-calculated expected values
   - **Coverage**: January 1 on different weekdays, December 31 edge cases

## Implementation Steps

### 1. Foundation Setup

#### 1.1 Install and Configure Minitest
- Add `minitest` to Gemfile (or rely on stdlib version)
- Create `test/test_helper.rb` with shared setup:
  - Require minitest/autorun
  - Require minitest/reporters for better output formatting
  - Load all source files from lib/
  - Define custom assertions (e.g., `assert_grid_position`)

#### 1.2 Create Test Directory Structure
- Create `test/` directory in project root
- Create subdirectories: `unit/`, `integration/`, `visual/` (if visual tests enabled)
- Add `.gitignore` entries for test artifacts: `test/tmp/`, `test/output/`

#### 1.3 Add Test Runner Scripts
- Create `Rakefile` with test tasks:
  ```ruby
  require 'rake/testtask'

  Rake::TestTask.new(:test_unit) do |t|
    t.libs << "test"
    t.test_files = FileList['test/unit/**/*_test.rb']
  end

  Rake::TestTask.new(:test_integration) do |t|
    t.libs << "test"
    t.test_files = FileList['test/integration/**/*_test.rb']
  end

  task test: [:test_unit, :test_integration]
  task default: :test
  ```
- Add `bin/test` script for quick test execution

### 2. Unit Tests for Grid System

#### 2.1 Test `grid_x(col)` Method
- **File**: `test/unit/test_grid_system.rb`
- Test cases:
  - Column 0 returns 0 (left edge)
  - Column 21 returns center x-coordinate (≈297.57)
  - Column 42 returns rightmost x-coordinate (≈595.14)
  - Negative columns (error handling)
  - Fractional columns (e.g., 10.5 for half-box offset)

#### 2.2 Test `grid_y(row)` Method
- Test cases:
  - Row 0 returns PAGE_HEIGHT (792, top edge)
  - Row 27 returns center y-coordinate (≈409.41)
  - Row 54 returns near-bottom y-coordinate (≈27.18)
  - Row 55 edge case (bottom edge exactly)
  - Negative rows (error handling)
  - Fractional rows

#### 2.3 Test `grid_width(boxes)` and `grid_height(boxes)`
- Test cases:
  - Single box (1) returns DOT_SPACING (14.17)
  - Full width (43 boxes) returns expected width
  - Full height (55 boxes) returns expected height
  - Zero boxes returns 0
  - Negative boxes (error handling)
  - Fractional boxes (e.g., 0.5 for half-box spacing)

#### 2.4 Test `grid_rect(col, row, width_boxes, height_boxes)`
- Test cases:
  - Full-page rect (0, 0, 43, 55) returns correct bounds
  - Header rect (0, 0, 43, 2) validates top-left alignment
  - Sidebar rect (0, 0, 3, 55) validates left edge
  - Center rect validates both x and y calculations
  - Edge cases: zero-width, zero-height, out-of-bounds

#### 2.5 Test `grid_inset(rect, padding_boxes)`
- Test cases:
  - 0.5 box padding reduces width/height by 1 box (2 × 0.5)
  - 1 box padding on small rect
  - Padding larger than rect (error handling)
  - Negative padding (error handling)
  - Fractional padding (e.g., 0.25 boxes)

#### 2.6 Test `grid_bottom(row, height_boxes)`
- Test cases:
  - Row 0 with 2-box height returns grid_y(2)
  - Row 10 with 5-box height returns grid_y(15)
  - Row 50 with 5-box height (near page bottom)
  - Consistency: `grid_bottom(r, h) == grid_y(r + h)`

#### 2.7 Test Helper Methods (`grid_text_box`, `grid_link`)
- `grid_text_box`: Verify correct coordinate translation to text_box parameters
- `grid_link`: Verify link annotation bounds [left, bottom, right, top]
  - Test that bottom < top (coordinate ordering)
  - Test that bounds match grid coordinates

### 3. Unit Tests for Date Calculations

#### 3.1 Test Week Number Calculation
- **File**: `test/unit/test_date_calculator.rb`
- Test cases for various years:
  - **2024** (leap year, Monday Jan 1): Week 1 starts Jan 1
  - **2025** (Wednesday Jan 1): Week 1 starts Dec 30, 2024
  - **2021** (Friday Jan 1): Week 1 starts Dec 28, 2020
  - **2026** (Thursday Jan 1): Week 1 starts Dec 29, 2025
- Edge cases:
  - December 31 of year (should be week 52 or 53)
  - First few days of January (may be week 52/53 of previous year)
  - Leap year February 29

#### 3.2 Test `year_start_monday` Calculation
- Test that January 1 falls on correct week 1 Monday:
  - If Jan 1 is Monday, week starts Jan 1
  - If Jan 1 is Tuesday, week starts Dec 31
  - If Jan 1 is Sunday, week starts Dec 26 (6 days back)
- Verify formula: `days_back = (first_day.wday + 6) % 7`

#### 3.3 Test Week Date Range Generation
- For each week number, verify:
  - Start date (Monday)
  - End date (Sunday)
  - All 7 days are sequential
  - No gaps between weeks
  - Week 52/53 ends on or before Dec 31

#### 3.4 Test Month Calendar Generation
- For each month:
  - Correct number of days (28/29/30/31)
  - First day of month falls on correct weekday
  - Leap year February has 29 days
  - Non-leap year February has 28 days

### 4. Unit Tests for RenderContext

#### 4.1 Test RenderContext Initialization
- **File**: `test/unit/test_render_context.rb`
- Verify default state (no current page)
- Verify custom initial state

#### 4.2 Test `current_page=` and `current_page` Accessors
- Set current page, verify retrieval
- Update current page multiple times

#### 4.3 Test `on_current_page?(page)` Method
- Returns true when page matches current_page
- Returns false when page differs
- Handles nil current_page

#### 4.4 Test Context-Aware Rendering
- Integration test: Render sidebar with RenderContext
- Verify bold styling applied to current page link
- Verify normal styling for other page links

### 5. Integration Tests for Page Generation

#### 5.1 Test Seasonal Calendar Generation
- **File**: `test/integration/test_page_generation.rb`
- Verify page is created
- Verify named destination "seasonal" exists
- Verify four season sections are rendered
- Verify month mini-calendars are present (12 calendars)
- Verify clickable date cells (sample check, not exhaustive)

#### 5.2 Test Year-at-a-Glance Pages
- Test Events page:
  - Named destination "year_events" exists
  - 12 columns for months
  - 31 rows for days
  - Day numbers rendered
  - Day-of-week abbreviations present
- Test Highlights page:
  - Named destination "year_highlights" exists
  - Same structure as Events page

#### 5.3 Test Weekly Page Generation
- Generate weekly pages for test year
- Verify correct number of pages (52 or 53)
- Sample checks for specific weeks:
  - Week 1: Verify date range, Monday header
  - Week 26 (mid-year): Verify correct dates
  - Week 52/53 (year-end): Verify end-of-year handling
- Verify sections present:
  - Navigation header (prev/next/year links)
  - Daily section (7 columns)
  - Cornell notes section (cues, notes, summary)

#### 5.4 Test Reference and Template Pages
- Reference page:
  - Named destination "reference" exists
  - Grid demo box rendered
  - Centimeter markings present
- Blank template page:
  - Named destination "dots" exists
  - Dot grid rendered

### 6. Integration Tests for Navigation System

#### 6.1 Test Named Destinations
- **File**: `test/integration/test_navigation.rb`
- Verify all named destinations are registered:
  - "seasonal"
  - "year_events"
  - "year_highlights"
  - "week_1" through "week_52" (or 53)
  - "reference"
  - "dots"
- Verify destinations point to correct pages (via Prawn's internal state)

#### 6.2 Test Link Annotations
- **Challenge**: Testing clickable regions in PDF
- **Approach**: Verify link_annotation calls were made (via Prawn mocking or internal tracking)
- Test sample links:
  - Seasonal calendar date cell links to week
  - Year-at-a-glance cell links to week
  - Weekly page navigation links (prev/next/year)

#### 6.3 Test PDF Outline/Bookmarks
- Verify PDF outline structure:
  - Top-level sections (Seasonal, Year-at-a-Glance, Weeks, Templates)
  - Nested items (e.g., individual weeks under "Weeks")
  - Correct page references

### 7. Visual Regression Tests (Optional)

#### 7.1 Setup Visual Testing Infrastructure
- **File**: `test/visual/test_visual_regression.rb`
- Dependencies:
  - `pdf-reader` gem for parsing PDF structure
  - `mini_magick` or `rmagick` for PDF-to-image conversion
  - `chunky_png` for pixel-level image comparison
- Create `test/visual/fixtures/` directory for reference PDFs

#### 7.2 Generate Reference PDFs
- Generate PDFs for known years (e.g., 2024, 2025)
- Store in `test/visual/fixtures/expected_2024.pdf`
- Commit to version control (if file size acceptable)
- Alternative: Store checksums or structural fingerprints

#### 7.3 Implement Visual Comparison Tests
- Generate test PDF for target year
- Convert both PDFs to images (page by page)
- Compare images pixel by pixel (with tolerance for anti-aliasing)
- Report differences as % of pixels changed
- Fail test if difference exceeds threshold (e.g., 0.1%)

#### 7.4 Structural PDF Comparison (Lightweight Alternative)
- Instead of pixel comparison, verify PDF structure:
  - Page count matches
  - Named destinations match
  - Text content matches (extracted via pdf-reader)
  - Metadata matches (author, title, subject)
- Much faster than visual comparison
- Catches most regressions without image rendering

### 8. Test Utilities and Helpers

#### 8.1 Custom Assertions
- **File**: `test/test_helper.rb`
- `assert_grid_position(expected_x, expected_y, col, row)`: Verify grid coordinate calculation
- `assert_within_epsilon(expected, actual, epsilon)`: Float comparison with tolerance
- `assert_pdf_has_destination(pdf, dest_name)`: Verify named destination exists
- `assert_link_bounds(link, expected_bounds)`: Verify link annotation coordinates

#### 8.2 Test Fixtures
- **Directory**: `test/fixtures/`
- Fixture data:
  - Known date ranges for specific weeks/years
  - Expected grid coordinate mappings
  - Sample PDF outputs for regression testing

#### 8.3 PDF Inspection Utilities
- `extract_named_destinations(pdf)`: List all named destinations in PDF
- `extract_page_text(pdf, page_num)`: Extract text from specific page
- `count_link_annotations(pdf, page_num)`: Count clickable links on page

### 9. Continuous Integration Setup

#### 9.1 Add CI Configuration
- **File**: `.github/workflows/test.yml` (GitHub Actions example)
- Run tests on:
  - Push to main branch
  - Pull request creation/update
  - Multiple Ruby versions (2.7, 3.0, 3.1, 3.2)
- Steps:
  1. Checkout code
  2. Setup Ruby
  3. Install dependencies (`bundle install`)
  4. Run tests (`rake test`)
  5. Upload test artifacts (generated PDFs for inspection)

#### 9.2 Test Coverage Reporting
- Add `simplecov` gem for code coverage tracking
- Configure in `test/test_helper.rb`:
  ```ruby
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
    add_group 'Grid System', 'lib/grid'
    add_group 'Components', 'lib/components'
    add_group 'Pages', 'lib/pages'
  end
  ```
- Set coverage threshold (e.g., 80% minimum)
- Fail CI if coverage drops below threshold

#### 9.3 Performance Benchmarking
- Add `benchmark-ips` gem for performance testing
- Create `test/benchmark/` directory
- Benchmark critical paths:
  - Full PDF generation (target: <5 seconds)
  - Single page generation (target: <100ms)
  - Grid coordinate calculations (target: <1μs)

## Testing Strategy

### Unit Test Philosophy
- **Isolation**: Test individual methods in isolation
- **Coverage**: Aim for 90%+ coverage of utility methods
- **Edge Cases**: Test boundary conditions, error cases
- **Fast Execution**: Unit tests should run in <1 second total

### Integration Test Philosophy
- **End-to-End Workflows**: Test complete page generation
- **Realistic Scenarios**: Use actual years (2024, 2025, 2026)
- **Critical Paths**: Focus on user-facing functionality (navigation, layout)
- **Moderate Speed**: Integration tests can take 5-10 seconds

### Test Execution Workflow
1. **Local Development**: Run `rake test` before committing
2. **Pre-Commit Hook**: Optionally run unit tests automatically
3. **CI Pipeline**: Run full test suite on push/PR
4. **Visual Regression**: Run periodically or on layout changes only

### Test Maintenance
- Update reference PDFs when layout intentionally changes
- Review failing visual tests manually before updating fixtures
- Keep test coverage above 80% (enforce in CI)
- Refactor tests when code is refactored (parallel structure)

## Acceptance Criteria

### Minimum Viable Test Suite (MVP)
- [ ] Minitest installed and configured
- [ ] Test directory structure created (`test/unit/`, `test/integration/`)
- [ ] `test_helper.rb` with shared setup
- [ ] Unit tests for all grid system methods (grid_x, grid_y, grid_rect, etc.)
- [ ] Unit tests for date calculation (week numbers, year start)
- [ ] Integration test for weekly page generation
- [ ] All tests passing (`rake test` exits 0)
- [ ] Test execution time <10 seconds

### Full Test Suite (Complete)
- [ ] All MVP criteria met
- [ ] Unit tests for RenderContext
- [ ] Integration tests for all page types (seasonal, year-at-a-glance, weekly, reference)
- [ ] Integration tests for navigation system (named destinations, links)
- [ ] Test coverage ≥80% (measured by SimpleCov)
- [ ] CI pipeline configured (GitHub Actions or equivalent)
- [ ] Documentation: README section on running tests
- [ ] Rakefile tasks: `rake test:unit`, `rake test:integration`, `rake test`

### Optional Enhancements
- [ ] Visual regression tests implemented
- [ ] PDF structural comparison tests
- [ ] Performance benchmarks established
- [ ] Pre-commit hook for running unit tests
- [ ] Coverage badge in README
- [ ] Mutation testing (mutant gem) for test quality verification

## Dependencies and Prerequisites

### Gems Required
- **minitest** (~> 5.0): Core testing framework (stdlib, but add to Gemfile for version pinning)
- **minitest-reporters** (~> 1.5): Better test output formatting
- **rake** (~> 13.0): Test task runner
- **simplecov** (~> 0.22): Code coverage reporting (optional but recommended)

### Optional Gems
- **pdf-reader** (~> 2.11): Parse PDF structure for validation
- **mini_magick** (~> 4.12): PDF-to-image conversion (requires ImageMagick)
- **chunky_png** (~> 1.4): Image comparison for visual regression
- **benchmark-ips** (~> 2.12): Performance benchmarking

### External Tools (for visual tests)
- **ImageMagick**: PDF-to-PNG conversion (`brew install imagemagick`)
- **Ghostscript**: PDF rendering engine (usually bundled with ImageMagick)

## Implementation Order

1. **Phase 1 - Foundation** (1-2 hours)
   - Install Minitest, create directory structure
   - Set up `test_helper.rb` and Rakefile
   - Write first test (e.g., `test_grid_x`)

2. **Phase 2 - Unit Tests** (3-4 hours)
   - Grid system tests (comprehensive)
   - Date calculation tests (edge cases)
   - RenderContext tests

3. **Phase 3 - Integration Tests** (2-3 hours)
   - Page generation tests (weekly, seasonal, year-at-a-glance)
   - Navigation system tests
   - PDF structure validation

4. **Phase 4 - CI and Coverage** (1-2 hours)
   - SimpleCov integration
   - GitHub Actions workflow
   - Documentation updates

5. **Phase 5 - Optional Enhancements** (4-6 hours)
   - Visual regression testing setup
   - Performance benchmarking
   - Mutation testing

**Total Estimated Time**: 10-15 hours (core), +4-6 hours (optional enhancements)

## Risk Mitigation

### Risk: PDF Output Non-Determinism
- **Issue**: PDFs include timestamps, unique IDs that change on each generation
- **Mitigation**: Test structure and content, not byte-for-byte equality
- **Alternative**: Freeze timestamps in test environment

### Risk: Visual Regression Test Brittleness
- **Issue**: Minor rendering differences cause false positives (anti-aliasing, font metrics)
- **Mitigation**: Use tolerance thresholds (0.1-1% pixel difference acceptable)
- **Alternative**: Focus on structural PDF tests instead of pixel-perfect comparison

### Risk: Test Suite Performance
- **Issue**: Generating PDFs in tests is slow, hundreds of tests could take minutes
- **Mitigation**: Mock Prawn PDF object for unit tests (test logic, not rendering)
- **Mitigation**: Use shared fixtures (generate PDF once, test multiple aspects)

### Risk: Floating Point Precision
- **Issue**: Grid calculations involve floats (14.17pt), exact equality fails
- **Mitigation**: Use `assert_in_delta` with epsilon (0.01pt tolerance)
- **Mitigation**: Document floating point behavior in test comments

## Future Enhancements

1. **Property-Based Testing** (Rantly or PropCheck gem)
   - Generate random grid coordinates, verify invariants
   - Example: `grid_x(col) + grid_width(w) == grid_x(col + w)`

2. **Snapshot Testing** (RSpec snapshot matchers)
   - Capture PDF structure as JSON snapshot
   - Detect unintentional changes in output structure

3. **Interactive Test Report**
   - Generate HTML report with embedded PDF previews
   - Side-by-side comparison of expected vs. actual PDFs
   - Click to view diff regions highlighted

4. **Test Data Generators**
   - Factory pattern for common test scenarios
   - Generate years with specific characteristics (leap year, Mon Jan 1, etc.)

5. **Fuzz Testing**
   - Test with extreme inputs (year 1900, year 9999)
   - Verify graceful error handling for invalid inputs

## References

- Minitest Documentation: https://docs.seattlerb.org/minitest/
- Prawn PDF Testing Examples: https://github.com/prawnpdf/prawn/tree/master/spec
- SimpleCov Configuration: https://github.com/simplecov-ruby/simplecov
- GitHub Actions Ruby Setup: https://github.com/ruby/setup-ruby

## Notes

- **Existing Test Files**: The project has `test_*.rb` files (test_links.rb, test_coords.rb, etc.) which are experiments for debugging PDF coordinates. These should be:
  - Reviewed for useful patterns
  - Migrated to proper test cases if they cover unique scenarios
  - Moved to `test/experiments/` or deleted if obsolete

- **Test-Driven Refactoring**: As we extract more classes (per Plans 01-07), write tests BEFORE refactoring to ensure behavior preservation

- **Documentation**: All test files should include comments explaining WHAT is being tested and WHY that case matters (especially for edge cases)
