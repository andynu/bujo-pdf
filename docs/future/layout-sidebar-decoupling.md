---
type: note
title: Layout and Sidebar Decoupling
created: 2026-01-08
tags:
  - future-work
  - layout-system
  - dsl-evolution
related:
  - "[[Convention-Based-Outline]]"
---

# Layout and Sidebar Decoupling

This document captures context and potential approaches for decoupling the sidebar system from the standard planner, enabling the DSL to support diverse PDF types.

## Problem Statement

The current layout system is tightly coupled to the standard bullet journal planner:

1. **Week Sidebar Hardcoded**: `StandardWithSidebarsLayout` renders a week sidebar with 53 weeks, month indicators, and week-to-week navigation. This is only meaningful for year planners.

2. **Navigation Tabs Fixed**: The right sidebar contains tabs for Year, Future, Events, Highlights, Multi-Year, and Grids -- all specific to the planner use case.

3. **Layout Choice is Binary**: The DSL offers `:full_page` (no sidebars) or `:standard_with_sidebars` (full planner chrome). There's no middle ground for custom navigation.

4. **Content Area Implicit**: The 40-column content area (columns 2-41) is hardcoded based on the fixed sidebar widths.

This limits the DSL's flexibility. A project planner, recipe book, or study guide might want navigation chrome, but not the week/month structure of a bullet journal.

## Current Architecture

```
Layouts/
  base_layout.rb              # Abstract base
  full_page_layout.rb         # No sidebars (43 cols content)
  standard_with_sidebars_layout.rb  # Week sidebar + nav tabs
  daily_with_sidebars_layout.rb     # Variant for daily pages

Components/
  week_sidebar.rb             # Hardcoded 53-week navigation
  right_sidebar.rb            # Hardcoded tab structure
```

Pages declare layout intent, but can't customize what sidebars contain:

```ruby
class MyPage < Pages::Base
  def setup
    use_layout :standard_with_sidebars, current_week: @week_num
  end
end
```

## Goal

Enable parameterized or composable layouts where:

1. **Sidebars are Optional**: Pages can opt into left, right, or no sidebars
2. **Sidebar Content is Configurable**: DSL users define what navigation appears
3. **Navigation Structure is Flexible**: Support arbitrary page groupings, not just weeks/months
4. **Content Area Adapts**: Content column calculations adjust to sidebar configuration

## Potential Approaches

### Approach A: Parameterized Layout Factory

Pass sidebar configuration to the layout system:

```ruby
use_layout :with_sidebars,
  left: { type: :section_nav, sections: [:chapter_1, :chapter_2, :chapter_3] },
  right: { type: :tabs, tabs: [{ label: "TOC", dest: :toc }] }
```

**Pros**: Single flexible layout class; configuration-driven
**Cons**: Complex options hash; may become unwieldy

### Approach B: Composable Sidebar Components

Separate sidebar declaration from layout:

```ruby
def setup
  use_layout :content_with_margins, left: 3, right: 2
  render_sidebar :left, SectionNavigator.new(sections: @sections)
  render_sidebar :right, TabBar.new(tabs: @tabs)
end
```

**Pros**: Maximum flexibility; sidebar components reusable
**Cons**: More verbose; pages must manage sidebar rendering

### Approach C: Layout DSL Block

Add a layout configuration block:

```ruby
BujoPdf.define_pdf :project_planner do |year:|
  configure_layout do
    left_sidebar width: 3 do
      section_links @sections
    end
    right_sidebar width: 2 do
      tab :toc, dest: :table_of_contents
      tab :index, dest: :index
    end
  end

  page :project_overview
  # ...
end
```

**Pros**: Declarative; fits DSL style; recipe-level configuration
**Cons**: New DSL surface area; potential complexity

### Approach D: Layout Variants via Inheritance

Create specific layout subclasses for different use cases:

```ruby
class ProjectSidebarLayout < BaseLayout
  def initialize(sections:, tabs:)
    @sections = sections
    @tabs = tabs
  end

  def render_before(page)
    render_section_nav(page)
    render_tabs(page)
  end
end
```

**Pros**: Clean separation; type safety; explicit contracts
**Cons**: Class proliferation; less dynamic

## Recommended Direction

**Approach C (Layout DSL Block)** aligns best with the existing declarative style. Implementation could:

1. Add `configure_layout` method to `DeclarationContext`
2. Create `LayoutConfiguration` class to capture sidebar specs
3. Extend `LayoutFactory` to build layouts from configuration
4. Provide default sidebar components (section nav, tab bar, week nav)
5. Allow custom sidebar components via blocks or classes

This preserves backward compatibility (`:standard_with_sidebars` continues to work) while enabling new use cases.

## Migration Path

1. Keep existing layouts working unchanged
2. Introduce `configure_layout` as optional enhancement
3. Refactor `StandardWithSidebarsLayout` to use the new system internally
4. Document patterns for common sidebar configurations
5. Consider extracting planner-specific sidebars to a "planner theme" module

## Open Questions

- Should sidebar configuration be per-recipe or per-page?
- How to handle sidebar overrides (current `set_sidebar_dest`) in the new model?
- Should sidebars participate in the outline system?
- Performance implications of dynamic sidebar rendering?

## Related Work

- Convention-based outline system provides a model for implicit-with-override behavior
- Group hierarchy in outlines suggests similar patterns for navigation structure
