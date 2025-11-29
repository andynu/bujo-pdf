# Proposal: Page Definition DSL

## Overview

A declarative DSL for defining page layouts that abstracts away Prawn internals while preserving full flexibility. Page definitions become composable, testable, and readable specifications rather than imperative drawing code.

## Current State

Pages are currently Ruby classes that directly manipulate a Prawn document:

```ruby
class WeeklyPage < BasePage
  def render
    draw_sidebar
    draw_day_columns
    draw_cornell_section
    # ... lots of Prawn calls
  end
end
```

This works but couples layout logic to rendering, making pages harder to compose, test, and extend.

## Design Principles: Grid-Centric

The DSL keeps the 43x55 grid as the central mental model, not an implementation detail to abstract away.

**Key principles:**
- Sizes and positions expressed in **grid units** by default (not arbitrary pixels or abstract "flex")
- **Quantization preferred** - align to dot grid intersections when possible
- **Packing is fine** - vertical/horizontal flow within a region
- **Proportional splits allowed** - when math requires it (e.g., 7 columns in 35 boxes = 5 each)
- The DSL makes grid math **easier**, not invisible

```ruby
# Grid units, not abstract sizes
sidebar width: 3              # 3 grid boxes
section :daily, height: 10    # 10 grid rows
columns 7, width: 35          # 35 boxes / 7 = 5 boxes each (quantized!)

# NOT this - too abstract, loses grid alignment
sidebar width: :narrow        # What does this mean in grid terms?
section :daily, flex: 0.2     # Might not land on grid boundaries
```

The grid is what makes the planner feel coherent - dot grid boxes, ruled lines, and layout regions all share the same rhythm. The DSL should reinforce this, not obscure it.

**Intentional deviations**: Some elements (like text stacking in navigation) don't fit box quantization. Sub-grid gaps are a conscious design choice in those cases, not an inconsistency.

**Flex quantization rule**: When flex can't divide evenly, quantize and give the extra box to one side. No fractional boxes.

## Page Identity and Linking

Pages get deterministic IDs generated from:
- **Page type** (`:weekly`, `:seasonal`, etc.)
- **Date granularity** - could be year, year+month, or full date
- **Incremental index** - for repeats with same type+date params

This makes linking predictable without explicit registration:
```ruby
# These generate predictable IDs
page :weekly, week: week      # -> weekly_2025_w12
page :dot_grid                # -> dot_grid_1, dot_grid_2, ...
page :monthly_review, month: march  # -> monthly_review_2025_03

# Explicit override when needed
page :dot_grid, id: :notes_scratch
```

## Proposed DSL

### Basic Structure

```ruby
BujoPdf.define_page :weekly do |week:|
  sidebar width: 3 do
    nav_link :prev_week, week: week - 1
    nav_link :next_week, week: week + 1
    nav_link :year_events
  end

  header height: 2 do
    text "Week #{week.number}", style: :title
    text week.date_range, style: :subtitle
  end

  columns 7, gap: 0.5 do |index|
    day = week.days[index]

    header do
      text day.name, style: :day_header
      text day.date, style: :day_date
    end

    field :tasks, flex: 1
  end

  section :cornell, height: 20 do
    columns [8, 35] do |col|
      case col
      when 0 then field :cues
      when 1 then field :notes
      end
    end

    footer height: 3 do
      field :summary
    end
  end
end
```

### Layout Primitives

**Containers** divide space and manage flow:

```ruby
sidebar width: 3 do ... end           # Fixed-width vertical strip
header height: 2 do ... end           # Fixed-height horizontal strip
footer height: 3 do ... end           # Fixed-height at bottom
section :name, height: 20 do ... end  # Named vertical section
columns 7 do |i| ... end              # Equal-width columns
columns [8, 35] do |i| ... end        # Specified widths
rows 4 do |i| ... end                 # Equal-height rows
grid 7, 5 do |col, row| ... end       # 2D grid
```

**Content** fills container space:

```ruby
text "Hello", style: :title           # Styled text
field :notes                          # Empty writable area
field :tasks, lines: 5                # Lined field
dot_grid spacing: 5                   # Dot pattern fill
graph_grid spacing: 5                 # Line pattern fill
```

**Navigation** creates cross-references:

```ruby
nav_link :year_events                 # Link to named page
nav_link :weekly, week: 12            # Link with params
nav_group :grids, cycle: true         # Tab-cycling group
```

### Flex Layout

Containers can use fixed sizes or flex to fill remaining space:

```ruby
section :top, height: 10 do ... end   # Fixed 10 grid units
section :middle, flex: 1 do ... end   # Takes remaining space
section :bottom, height: 5 do ... end # Fixed 5 grid units
```

When multiple flex items exist, they share space proportionally:

```ruby
columns 3 do |i|
  field :day, flex: 1      # Each gets 1/3
end

# Or weighted:
columns [1, 2, 1] do |i|   # 25%, 50%, 25%
  field :content, flex: 1
end
```

### Conditionals and Loops

Pages can include logic:

```ruby
BujoPdf.define_page :weekly do |week:|
  columns 7 do |index|
    day = week.days[index]

    header do
      text day.name
      text day.date
      if day.holiday?
        text day.holiday_name, style: :holiday
      end
    end

    if day.weekend?
      dot_grid spacing: 5
    else
      field :tasks, lines: 8
    end
  end
end
```

### Styles and Themes

Styles are referenced by name:

```ruby
text "Title", style: :title
text "Body", style: :body
field :notes, style: :lined
```

Themes define what those names mean:

```ruby
BujoPdf.define_theme :earth do
  style :title, font_size: 14, font_weight: :bold, color: "4A4A4A"
  style :subtitle, font_size: 10, color: "6B6B6B"
  style :day_header, font_size: 9, font_weight: :bold
  style :holiday, font_size: 8, color: "C75050"

  style :lined, line_color: "E0E0E0", line_spacing: 5
  style :dot_grid, dot_color: "CCCCCC", dot_radius: 0.5

  background_color "F5F0E8"
  dot_grid_color "D4C9B8"
end
```

### Reusable Components

Extract repeated patterns:

```ruby
BujoPdf.define_component :day_header do |day:|
  header height: 2 do
    text day.name, style: :day_header
    text day.date, style: :day_date
    if day.events.any?
      text day.events.first.name, style: :event
    end
  end
end

BujoPdf.define_page :weekly do |week:|
  columns 7 do |index|
    component :day_header, day: week.days[index]
    field :tasks, flex: 1
  end
end
```

### Full Example: Cornell Weekly

```ruby
BujoPdf.define_page :weekly do |week:|
  # Left sidebar with navigation
  sidebar width: 3 do
    nav_link :prev_week, week: week - 1, icon: "<-"
    spacer flex: 1
    nav_group :grids, cycle: true
    spacer flex: 1
    nav_link :next_week, week: week + 1, icon: "->"
  end

  # Main content area
  content do
    # Week header
    header height: 2 do
      text "Week #{week.number}", style: :title
      text week.date_range, style: :subtitle
    end

    # Seven day columns
    columns 7, gap: 0.5, height: 25 do |index|
      day = week.days[index]

      component :day_header, day: day
      field :tasks, flex: 1, style: :dot_grid
    end

    # Cornell notes section
    section :cornell, flex: 1 do
      columns [8, 35], gap: 0.5 do |index|
        case index
        when 0
          header height: 1 do
            text "Cues", style: :section_label
          end
          field :cues, flex: 1
        when 1
          header height: 1 do
            text "Notes", style: :section_label
          end
          field :notes, flex: 1, style: :dot_grid
        end
      end

      footer height: 3 do
        divider
        text "Summary", style: :section_label
        field :summary, flex: 1
      end
    end
  end
end
```

## Implementation Approach

### Phase 1: Layout Engine

Build a layout tree that computes bounding boxes:

```ruby
class LayoutNode
  attr_reader :children, :bounds, :constraints

  def compute_bounds(available_rect)
    # Resolve flex, apply constraints, recurse to children
  end
end
```

Page definitions create layout trees. A separate renderer walks the tree and issues Prawn calls.

### Phase 2: Component Registry

```ruby
module BujoPdf
  class ComponentRegistry
    def define_component(name, &block)
      @components[name] = ComponentDefinition.new(name, &block)
    end

    def instantiate(name, **params)
      @components[name].build(**params)
    end
  end
end
```

### Phase 3: Style Resolution

Styles cascade like CSS:

```ruby
class StyleResolver
  def resolve(element, theme)
    base = theme.default_styles
    element_style = theme.styles[element.style_name]
    inline = element.inline_styles

    base.merge(element_style).merge(inline)
  end
end
```

## Migration Path

1. Build DSL alongside existing page classes
2. Reimplement one simple page (e.g., reference page) using DSL
3. Validate output matches
4. Gradually migrate remaining pages
5. Deprecate direct Prawn usage in page classes

## Testing Strategy

Layout trees are testable without rendering:

```ruby
def test_weekly_layout
  page = BujoPdf.build_page(:weekly, week: Week.new(1, 2025))

  assert_equal 7, page.find(:columns).children.count
  assert page.find(:sidebar).width == 3
  assert page.find(:cornell).constraints[:flex] == 1
end
```

Snapshot testing for visual regression:

```ruby
def test_weekly_renders_correctly
  pdf = BujoPdf.render_page(:weekly, week: Week.new(1, 2025))
  assert_snapshot_matches "weekly_page", pdf
end
```

## Open Questions

1. **How deep should nesting go?** Arbitrary nesting is flexible but complex. Maybe cap at 3-4 levels?

2. **How to handle page-specific logic?** Some pages need calculations (date math, event lookups). Keep in page definition or separate?

3. **Should components accept blocks?** E.g., `component :card do ... end` for wrapper components?

4. **Grid coordinates vs. flex units?** Current system uses grid coordinates. DSL could abstract to flex units and compute grid positions internally.

## Benefits

- **Readability**: Page structure is immediately apparent
- **Testability**: Layout logic separable from rendering
- **Extensibility**: Users define custom pages without Prawn knowledge
- **Consistency**: Shared primitives enforce design system
- **Iteration speed**: Change layouts without debugging coordinate math
