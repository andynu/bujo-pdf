# Plan 21: Multi-Tap Navigation Cycling for Right Sidebar

## Executive Summary

Implement a multi-tap navigation system for right sidebar tabs that allows a single tab to cycle through multiple related pages. When tapped repeatedly, the tab will navigate through a sequence of destinations in order, returning to the first page after the last. This enables grouping related pages (e.g., Highlights → Highlights1 → Highlights2 → back to Highlights) under a single tab label.

**Primary Use Case**: A "Highlights" tab that cycles through three variations of the highlights page based on tap count and current page context.

**API Design Goal**: Simple declarative syntax:
```ruby
{ label: "Highlights", dest: [:year_highlights, :year_highlights1, :year_highlights2] }
```

## Technical Approach

### Architecture Decision: Cyclic Navigation vs. Multi-Page Tabs

The core challenge is determining link targets based on:
1. Current page being rendered (RenderContext page_key)
2. Desired navigation sequence (array of destinations)
3. Position in cycle (which page comes next)

**Approach**: Extend the existing `build_top_tabs` method in `StandardWithSidebarsLayout` to accept destination arrays and compute the next destination in the cycle based on current page.

**Key Insight**: Links are statically generated during page rendering. The "next destination" must be computed at render time based on the current page context.

### Navigation Cycle Logic

Given a destination array `[:page_a, :page_b, :page_c]`:

| Current Page | Tab Highlighted? | Link Target | Result When Clicked |
|--------------|------------------|-------------|---------------------|
| :page_a      | Yes (bold)       | :page_b     | Navigate to page_b  |
| :page_b      | Yes (bold)       | :page_c     | Navigate to page_c  |
| :page_c      | Yes (bold)       | :page_a     | Cycle back to page_a|
| :other_page  | No (gray)        | :page_a     | Navigate to page_a  |

**Design Principle**: When not on any page in the cycle, clicking goes to the first page (entry point). When on a page in the cycle, clicking advances to the next page in sequence.

## Implementation Steps

### 1. Extend Tab Data Structure

**1.1 Update StandardWithSidebarsLayout#build_top_tabs**

Modify `lib/bujo_pdf/layouts/standard_with_sidebars_layout.rb` to support destination arrays:

```ruby
def build_top_tabs
  tabs = [
    { label: "Year", dest: "seasonal" },
    { label: "Events", dest: "year_events" },
    { label: "Highlights", dest: [:year_highlights, :year_highlights1, :year_highlights2] }
  ]

  # Transform tabs: resolve dest arrays to single destination based on current page
  tabs.map { |tab| resolve_tab_destination(tab) }
end
```

**1.2 Implement resolve_tab_destination Helper**

Add new private method to compute destination and highlighting:

```ruby
# Resolve tab destination based on current page and cycle position.
#
# For single destinations (string/symbol), returns unchanged with highlighting.
# For destination arrays (multi-tap cycling), computes next destination in cycle.
#
# @param tab [Hash] Tab specification with :label and :dest
# @return [Hash] Resolved tab with :label, :dest (string), :current (boolean)
#
# @example Single destination
#   resolve_tab_destination({ label: "Year", dest: "seasonal" })
#   # => { label: "Year", dest: "seasonal", current: true/false }
#
# @example Multi-destination cycle
#   # When current page is :year_highlights
#   resolve_tab_destination({ label: "Highlights", dest: [:year_highlights, :year_highlights1, :year_highlights2] })
#   # => { label: "Highlights", dest: "year_highlights1", current: true }
#
#   # When current page is :year_highlights2
#   resolve_tab_destination({ label: "Highlights", dest: [:year_highlights, :year_highlights1, :year_highlights2] })
#   # => { label: "Highlights", dest: "year_highlights", current: true }
#
#   # When current page is :other_page
#   resolve_tab_destination({ label: "Highlights", dest: [:year_highlights, :year_highlights1, :year_highlights2] })
#   # => { label: "Highlights", dest: "year_highlights", current: false }
private

def resolve_tab_destination(tab)
  dest = tab[:dest]

  # Single destination: simple pass-through with highlighting
  if dest.is_a?(String) || dest.is_a?(Symbol)
    return {
      label: tab[:label],
      dest: dest.to_s,
      current: current_page?(dest)
    }
  end

  # Multi-destination array: compute cycle
  if dest.is_a?(Array)
    return resolve_cyclic_destination(tab[:label], dest)
  end

  # Unexpected type: raise error
  raise ArgumentError, "Tab destination must be String, Symbol, or Array, got #{dest.class}"
end

def resolve_cyclic_destination(label, dest_array)
  # Find current page in cycle (nil if not in cycle)
  current_index = dest_array.index { |d| current_page?(d) }

  # Determine behavior
  if current_index.nil?
    # Not in cycle: go to first page (entry point), not highlighted
    {
      label: label,
      dest: dest_array.first.to_s,
      current: false
    }
  else
    # In cycle: advance to next page (wrap around), highlighted
    next_index = (current_index + 1) % dest_array.size
    {
      label: label,
      dest: dest_array[next_index].to_s,
      current: true
    }
  end
end

def current_page?(dest)
  page = context[:page] || @pdf  # Page object or fallback
  page.context.current_page?(dest)
end
```

**1.3 Update RightSidebar to Use Resolved Tabs**

The `RightSidebar` component already expects tabs in the format:
```ruby
{ label: "Events", dest: "year_events", current: true/false }
```

No changes needed to RightSidebar—it receives pre-resolved tabs from the layout.

### 2. Update Page Generation for New Highlights Pages

**2.1 Define New Page Keys**

If `:year_highlights1` and `:year_highlights2` don't exist yet, create them:

```ruby
# In PlannerGenerator or page registry
@pdf.add_dest("year_highlights1", @pdf.dest_xyz(0, @pdf.bounds.top))
@pdf.add_dest("year_highlights2", @pdf.dest_xyz(0, @pdf.bounds.top))
```

**2.2 Create Page Classes (if needed)**

If highlights variations require different rendering:

```ruby
# lib/bujo_pdf/pages/year_highlights1.rb
module BujoPdf
  module Pages
    class YearHighlights1 < YearHighlights
      def setup
        use_layout :standard_with_sidebars,
          highlight_tab: :year_highlights1,
          year: @year,
          total_weeks: @total_weeks
      end

      def render_content(content_area)
        super  # Or custom rendering
        # Add highlights1-specific content
      end
    end
  end
end
```

**2.3 Update Page Context**

Ensure all three pages have correct `page_key` in their RenderContext:
```ruby
RenderContext.new(
  page_key: :year_highlights1,  # Or :year_highlights2
  year: @year,
  # ...
)
```

### 3. Testing Strategy

**3.1 Unit Tests for Cycle Logic**

Test `resolve_cyclic_destination` method:

```ruby
# test/unit/layouts/test_cyclic_navigation.rb
class TestCyclicNavigation < Minitest::Test
  def test_cycle_not_in_sequence_goes_to_first
    layout = create_layout(current_page: :other_page)
    result = layout.send(:resolve_cyclic_destination, "Label", [:a, :b, :c])

    assert_equal "a", result[:dest]
    assert_equal false, result[:current]
  end

  def test_cycle_first_page_goes_to_second
    layout = create_layout(current_page: :a)
    result = layout.send(:resolve_cyclic_destination, "Label", [:a, :b, :c])

    assert_equal "b", result[:dest]
    assert_equal true, result[:current]
  end

  def test_cycle_last_page_wraps_to_first
    layout = create_layout(current_page: :c)
    result = layout.send(:resolve_cyclic_destination, "Label", [:a, :b, :c])

    assert_equal "a", result[:dest]
    assert_equal true, result[:current]
  end
end
```

**3.2 Integration Tests for Tab Rendering**

Generate PDFs and verify:
1. Tab is gray on unrelated pages
2. Tab is bold on pages in cycle
3. Link destinations are correct for each page in cycle
4. Clicking through cycle works (manual testing)

**3.3 PDF Link Verification**

Use PDF inspection tool (Prawn debug or external viewer) to verify:
```bash
# Generate test PDF
ruby gen.rb 2025

# Open in PDF viewer and inspect link annotations
# Verify each page in cycle has correct link destination on Highlights tab
```

### 4. Documentation

**4.1 Update CLAUDE.md**

Add section explaining multi-tap navigation:

```markdown
### Multi-Tap Navigation Cycling

Right sidebar tabs can cycle through multiple related pages using destination arrays:

```ruby
# In StandardWithSidebarsLayout#build_top_tabs
{ label: "Highlights", dest: [:year_highlights, :year_highlights1, :year_highlights2] }
```

**Navigation behavior:**
- When not on any page in the cycle, clicking goes to the first page
- When on a page in the cycle, clicking advances to the next page
- After the last page, clicking cycles back to the first
- Tab is highlighted (bold) when on any page in the cycle
```

**4.2 Code Comments**

Add YARD documentation to all new methods (see implementation above).

**4.3 Update Layout Documentation**

Document the destination array option in `StandardWithSidebarsLayout` class header.

## Acceptance Criteria

### Functional Requirements

1. **Cycle Navigation Works**
   - ✓ Clicking "Highlights" tab on :year_highlights navigates to :year_highlights1
   - ✓ Clicking "Highlights" tab on :year_highlights1 navigates to :year_highlights2
   - ✓ Clicking "Highlights" tab on :year_highlights2 navigates back to :year_highlights
   - ✓ Clicking "Highlights" tab on any other page navigates to :year_highlights

2. **Visual Highlighting Correct**
   - ✓ Tab is bold/black when current page is any page in the cycle
   - ✓ Tab is gray when current page is not in the cycle
   - ✓ No link annotation rendered when on current page in cycle (existing behavior)

3. **API Simplicity**
   - ✓ Array syntax works: `dest: [:a, :b, :c]`
   - ✓ Single destination syntax still works: `dest: "page"`
   - ✓ Mixed tabs supported (some single, some array)

### Non-Functional Requirements

1. **Backward Compatibility**
   - ✓ Existing single-destination tabs continue working unchanged
   - ✓ No changes required to RightSidebar component
   - ✓ No changes required to pages using standard layout

2. **Code Quality**
   - ✓ No code duplication
   - ✓ Clear separation of concerns (layout computes destinations, component renders)
   - ✓ Comprehensive YARD documentation
   - ✓ Unit test coverage for cycle logic
   - ✓ Integration test coverage for tab rendering

3. **Performance**
   - ✓ No noticeable impact on PDF generation time
   - ✓ Cycle resolution happens once per page (during layout setup)

## Technical Considerations

### Edge Cases

1. **Empty destination array**: Raise ArgumentError
2. **Single-element array**: Works (cycles to itself)
3. **Duplicate destinations in array**: Allowed (implementation doesn't check)
4. **Page key mismatch**: If page_key doesn't match any destination string format, cycle won't detect current page (graceful degradation)

### Limitations

1. **Static Links**: Links are generated at page render time, not dynamically at click time
2. **No Visual Cycle Indicator**: Tab doesn't show which page in cycle (could be added as future enhancement)
3. **Maximum Cycle Length**: No enforced limit, but UX degrades with >5 pages

### Future Enhancements

1. **Visual Cycle Indicator**: Add small dots or numbers to show position in cycle
2. **Named Cycles**: Support `dest: cycle("highlights", [:a, :b, :c])` for self-documenting code
3. **Conditional Cycles**: Support dynamic cycle arrays based on user preferences or content
4. **Reverse Cycle**: Support shift-click or right-click to go backwards in cycle (requires JavaScript/viewer support)

## Dependencies

- **Plan 06 (RenderContext System)**: COMPLETED - Required for `current_page?` method
- **Plan 10 (Declarative Layout System)**: COMPLETED - Required for layout-based tab resolution
- **StandardWithSidebarsLayout**: Exists and working
- **RightSidebar Component**: Exists and working

## Risk Assessment

**Low Risk**: This is an additive change that extends existing functionality without breaking current behavior.

**Key Risks:**
1. **Link Target Errors**: If cycle logic incorrect, links may point to wrong destinations
   - Mitigation: Comprehensive unit tests
2. **Highlighting Logic Errors**: Tab may be highlighted on wrong pages
   - Mitigation: Integration tests with visual PDF verification
3. **API Confusion**: Developers may not understand array vs. single destination
   - Mitigation: Clear documentation and examples

## Implementation Estimate

- **Development**: 2-3 hours
  - Layout changes: 1 hour
  - Testing infrastructure: 1 hour
  - Documentation: 30 minutes
- **Testing**: 1 hour
  - Unit tests: 30 minutes
  - Integration tests: 30 minutes
- **Total**: 3-4 hours

## References

- **Existing Code**:
  - `lib/bujo_pdf/layouts/standard_with_sidebars_layout.rb:114-130` - `build_top_tabs` method
  - `lib/bujo_pdf/components/right_sidebar.rb:73-116` - Tab rendering with `current_page?` check
  - `lib/bujo_pdf/render_context.rb:98-100` - `current_page?` implementation
- **Related Plans**:
  - Plan 06: RenderContext System (context-aware rendering foundation)
  - Plan 10: Declarative Layout System (layout-based tab management)
