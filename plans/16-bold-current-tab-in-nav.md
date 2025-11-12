# Plan #16: Automatic Tab Bolding in Right Navigation Sidebar

## Executive Summary

**Status: ALREADY IMPLEMENTED**

The automatic tab bolding feature requested is already fully implemented in the codebase. The right sidebar navigation tabs automatically bold and highlight the current page using a RenderContext-based system. This plan documents the existing implementation and identifies potential refinements.

## Current Implementation Analysis

### 1. Architecture Overview

The automatic tab highlighting works through three integrated systems:

**A. RenderContext System** (`lib/bujo_pdf/render_context.rb`)
- Tracks current page via `page_key` attribute (e.g., `:seasonal`, `:year_events`, `:week_42`)
- Provides `current_page?(key)` method to check if a given key matches the current page
- Created by `PlannerGenerator` and passed to pages during generation

**B. Component Base Class** (`lib/bujo_pdf/component.rb:170-172`)
- Provides `current_page?(key)` convenience method for all components
- Safely delegates to `context.current_page?(key)` with fallback to `false`
- Works with both RenderContext objects and legacy hash-based contexts

**C. RightSidebar Component** (`lib/bujo_pdf/components/right_sidebar.rb:73-117`)
- Automatically detects current page via `current_page?(dest)` check (line 75)
- Applies bold styling: `"Helvetica-Bold"` vs `"Helvetica"` (line 78)
- Applies color styling: `'000000'` (black) vs `'888888'` (gray) (line 79)
- Disables clickable link for current page tab (line 111)

### 2. How Pages Indicate Their Tab

Pages use a **dual mechanism** to indicate which tab they correspond to:

**Method 1: Destination Name (Current System)**
```ruby
# In year_at_glance_base.rb:41-50
def setup
  set_destination(destination_name)  # e.g., "year_events"

  use_layout :standard_with_sidebars,
    highlight_tab: destination_name  # Symbol matches tab dest
end
```

The `destination_name` method returns the page's identifier, which matches the `dest` field in tab definitions:
- `seasonal` → "Year" tab
- `year_events` → "Events" tab
- `year_highlights` → "Highlights" tab

**Method 2: RenderContext Page Key (Underlying System)**
```ruby
# In planner_generator.rb:97-106
def generate_page(page_key)
  context = RenderContext.new(
    page_key: page_key,  # :seasonal, :year_events, :year_highlights
    page_number: @pdf.page_number,
    year: @year
  )
  page = PageFactory.create(page_key, @pdf, context)
  page.generate
end
```

The `page_key` in RenderContext is what `current_page?(key)` checks against.

### 3. Current Text Styling Implementation

**Location**: `lib/bujo_pdf/components/right_sidebar.rb:73-82`

```ruby
def render_tab(row, label, dest, align:)
  # Check if this tab's destination matches current page
  is_current = current_page?(dest)

  # Use bold font and black color for current page, normal gray for others
  font_style = is_current ? "Helvetica-Bold" : "Helvetica"
  color = is_current ? '000000' : NAV_COLOR  # Black for current, gray for others

  @pdf.fill_color color
  @pdf.font font_style, size: FONT_SIZE
```

**Visual difference:**
- **Current tab**: Black (`'000000'`), Bold (`Helvetica-Bold`), No link
- **Other tabs**: Gray (`'888888'`), Normal (`Helvetica`), Clickable

### 4. The `highlight_tab` Option (Legacy/Redundant System)

The `StandardWithSidebarsLayout` includes a `highlight_tab` option that appears to duplicate functionality:

**Location**: `lib/bujo_pdf/layouts/standard_with_sidebars_layout.rb:114-130`

```ruby
def build_top_tabs
  tabs = [
    { label: "Year", dest: "seasonal" },
    { label: "Events", dest: "year_events" },
    { label: "Highlights", dest: "year_highlights" }
  ]

  # Apply highlighting if specified
  if options[:highlight_tab]
    highlight_dest = options[:highlight_tab].to_s
    tabs.each do |tab|
      tab[:current] = (tab[:dest] == highlight_dest)
    end
  end

  tabs
end
```

**Critical Finding**: The `:current` key set here is **NOT USED** by `RightSidebar`. The component ignores `tab[:current]` and instead calls `current_page?(dest)` directly, which checks the RenderContext.

## Analysis: Why This Works (and Potential Issues)

### How the System Actually Works

1. **Generator creates RenderContext** with `page_key: :seasonal` (for example)
2. **Page receives context** and calls `use_layout :standard_with_sidebars, highlight_tab: :seasonal`
3. **Layout builds tabs** and sets `tab[:current] = true` for matching tab (UNUSED)
4. **RightSidebar renders** and calls `current_page?(dest)` which checks `context.page_key == dest.to_sym`
5. **Tab gets bolded** because RenderContext confirms current page

### The Redundancy Issue

The `highlight_tab` option is redundant because:
- Pages already have `page_key` in their RenderContext
- `RightSidebar` uses `current_page?(dest)` which checks RenderContext
- The `tab[:current]` flag set by `build_top_tabs` is never read

**However**, the `highlight_tab` option serves as **documentation** - it makes explicit which tab should be highlighted when reading page code.

### Potential Bug: String vs Symbol Mismatch

The current implementation may have a subtle bug:

```ruby
# RightSidebar checks (line 75):
is_current = current_page?(dest)  # dest is a string: "seasonal"

# current_page? implementation (render_context.rb:98-100):
def current_page?(key)
  @page_key == key.to_sym  # Converts string to symbol
end

# So it checks:
@page_key == "seasonal".to_sym  # => :seasonal == :seasonal ✓
```

This works correctly because `current_page?` converts the string to a symbol. No bug here.

## Recommendations

### Option A: No Changes Required (RECOMMENDED)

**Rationale**: The system works correctly as-is. The automatic tab bolding:
- ✓ Correctly identifies the current page via RenderContext
- ✓ Applies appropriate styling (bold + black)
- ✓ Removes links from current tab
- ✓ Requires no manual intervention from page authors

**Action**: Document the existing behavior and close the request.

### Option B: Remove Redundant `highlight_tab` Option

**Changes needed**:
1. Remove `highlight_tab` parameter from layout options
2. Remove `build_top_tabs` logic that sets `tab[:current]`
3. Update page `setup` methods to remove `highlight_tab: destination_name`
4. Update documentation to clarify that bolding is automatic

**Trade-off**: Loses the self-documenting aspect of `highlight_tab` in page code.

### Option C: Use `tab[:current]` Flag (Refactoring for Clarity)

Make the `highlight_tab` option actually meaningful by having `RightSidebar` respect it:

**Changes**:
1. Modify `RightSidebar.render_tab` to accept tab hash instead of label/dest
2. Check `tab[:current]` first, fall back to `current_page?(dest)`
3. Keep `highlight_tab` option for explicit control

**Benefit**: Provides override mechanism for special cases where RenderContext page_key doesn't match tab destination.

### Option D: Add Tests for Current Behavior

**Recommended addition** to any option:

Create test coverage for the tab highlighting behavior:
```ruby
# test/components/right_sidebar_test.rb
describe RightSidebar do
  it "bolds the tab matching current page_key" do
    context = RenderContext.new(page_key: :year_events, year: 2025, page_number: 1)
    # Assert Events tab is bold, others are not
  end

  it "does not render link for current page tab" do
    # Assert no link annotation for current tab
  end
end
```

## Conclusion

The automatic tab bolding feature is **already fully functional**. The implementation uses RenderContext to automatically detect the current page and apply appropriate styling to the right sidebar tabs. No code changes are required unless you want to:

1. **Remove redundancy** by eliminating the unused `highlight_tab` option
2. **Add tests** to prevent regressions
3. **Improve documentation** to clarify the automatic behavior

**Recommended action**: Document the existing behavior and mark as complete. The `highlight_tab` option, while technically redundant, serves as useful self-documentation in page setup methods.
