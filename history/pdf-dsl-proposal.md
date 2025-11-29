# Proposal: PDF Definition DSL

## Overview

A declarative DSL for composing complete PDFs from page definitions. This sits above the Page DSL and handles document-level concerns: page ordering, cross-reference resolution, metadata, and reusable "recipes" for common planner configurations.

## Current State

PDF generation is currently imperative:

```ruby
class PlannerGenerator
  def generate(year)
    @pdf = Prawn::Document.new(...)

    SeasonalCalendarPage.new(@pdf, year).render
    YearEventsPage.new(@pdf, year).render
    # ...
    52.times do |week_num|
      WeeklyPage.new(@pdf, year, week_num).render
    end
    # ...

    @pdf.render_file(output_path)
  end
end
```

This works but embeds document structure in procedural code, making it hard to offer variations or let users define custom planners.

## Proposed DSL

### Basic Structure

```ruby
BujoPdf.define_pdf :standard_planner do |year:, theme: :light|
  metadata do
    title "Planner #{year}"
    author "BujoPdf"
    subject "Digital Bullet Journal"
  end

  theme theme

  page :seasonal_calendar, year: year
  page :year_events, year: year
  page :year_highlights, year: year
  page :multi_year_overview, start_year: year

  weeks_in(year).each do |week|
    page :weekly, week: week
  end

  page :grids_showcase
  page :dot_grid
  page :graph_grid
  page :isometric_grid
  page :hexagon_grid

  page :reference
  page :daily_wheel
  page :year_wheel, year: year
end
```

### Invocation

```ruby
# Generate using a defined recipe
BujoPdf.generate :standard_planner, year: 2025, theme: :earth

# Or inline for one-offs
BujoPdf.generate year: 2025 do
  page :seasonal_calendar, year: 2025

  weeks_in(2025).each do |week|
    page :weekly, week: week
  end
end

# With output options
BujoPdf.generate :standard_planner,
  year: 2025,
  output: "my_planner.pdf",
  optimize: true
```

### Page Groups

Organize related pages:

```ruby
BujoPdf.define_pdf :standard_planner do |year:|
  group :front_matter do
    page :seasonal_calendar, year: year
    page :year_events, year: year
    page :year_highlights, year: year
  end

  group :weeks do
    weeks_in(year).each do |week|
      page :weekly, week: week
    end
  end

  group :grids, cycle: true do  # cycle: true enables tab navigation
    page :dot_grid
    page :graph_grid
    page :isometric_grid
    page :hexagon_grid
  end

  group :reference do
    page :reference
    page :daily_wheel
    page :year_wheel, year: year
  end
end
```

Groups serve multiple purposes:
- Logical organization
- Navigation scoping (e.g., cycling within grids)
- Conditional inclusion
- Potential for separate output files

### Conditional Pages

```ruby
BujoPdf.define_pdf :configurable_planner do |year:, include_grids: true, include_wheels: true|
  page :seasonal_calendar, year: year

  weeks_in(year).each do |week|
    page :weekly, week: week
  end

  if include_grids
    group :grids, cycle: true do
      page :dot_grid
      page :graph_grid
    end
  end

  if include_wheels
    page :daily_wheel
    page :year_wheel, year: year
  end
end
```

### Repeating Patterns

Helper methods for common patterns:

```ruby
BujoPdf.define_pdf :project_planner do |year:|
  # Monthly pattern
  months_in(year).each do |month|
    page :monthly_overview, month: month

    weeks_in(month).each do |week|
      page :weekly, week: week
    end

    page :monthly_review, month: month
  end
end

# Or with a helper:
BujoPdf.define_pdf :project_planner do |year:|
  each_month(year) do |month|
    page :monthly_overview, month: month
    each_week(month) do |week|
      page :weekly, week: week
    end
    page :monthly_review, month: month
  end
end
```

### Cross-Reference Resolution

The DSL must handle links between pages that reference each other:

```ruby
BujoPdf.define_pdf :linked_planner do |year:|
  # This page links to weekly pages
  page :year_events, year: year  # clicking a day goes to that week

  # These pages link back to year_events and to each other
  weeks_in(year).each do |week|
    page :weekly, week: week  # has prev/next week links
  end
end
```

This requires two passes:
1. **Declaration pass**: Collect all pages, assign identifiers, build destination map
2. **Render pass**: Generate pages with resolved link targets

```ruby
class PdfBuilder
  def build(definition, **params)
    # Pass 1: Collect declarations
    context = DeclarationContext.new
    definition.evaluate(context, **params)

    # Build link registry
    registry = LinkRegistry.new(context.pages)

    # Pass 2: Render
    render_context = RenderContext.new(registry)
    context.pages.each do |page_decl|
      page_decl.render(render_context)
    end

    render_context.document
  end
end
```

### Link Registry

```ruby
class LinkRegistry
  def initialize(page_declarations)
    @destinations = {}

    page_declarations.each_with_index do |decl, index|
      key = destination_key(decl.type, decl.params)
      @destinations[key] = {
        page_number: index + 1,
        anchor: "page_#{index + 1}"
      }
    end
  end

  def destination_for(page_type, **params)
    key = destination_key(page_type, params)
    @destinations[key] || raise("Unknown destination: #{key}")
  end

  private

  def destination_key(type, params)
    [type, params.sort].flatten.join("_")
  end
end
```

### Composing Recipes

Recipes can include other recipes:

```ruby
BujoPdf.define_pdf :weekly_essentials do |year:|
  page :seasonal_calendar, year: year

  weeks_in(year).each do |week|
    page :weekly, week: week
  end
end

BujoPdf.define_pdf :full_planner do |year:|
  include_recipe :weekly_essentials, year: year

  group :grids, cycle: true do
    page :dot_grid
    page :graph_grid
  end

  page :reference
end
```

### Output Options

```ruby
BujoPdf.define_pdf :standard_planner do |year:|
  output do
    filename "planner_#{year}.pdf"
    compress true
    optimize_for :digital  # or :print

    # PDF metadata
    title "Planner #{year}"
    author "BujoPdf"
    keywords ["planner", "bullet journal", year.to_s]
  end

  # ... pages
end
```

### Full Example: Minimal Weekly Planner

```ruby
BujoPdf.define_pdf :minimal_weekly do |year:, theme: :light|
  metadata do
    title "Weekly Planner #{year}"
  end

  theme theme

  # Just a year overview and weeks - nothing else
  page :year_events, year: year

  weeks_in(year).each do |week|
    page :weekly, week: week
  end
end

# Generate
BujoPdf.generate :minimal_weekly, year: 2025, theme: :dark
```

### Full Example: Quarterly Business Planner

```ruby
BujoPdf.define_pdf :quarterly_planner do |year:, quarter:|
  metadata do
    title "Q#{quarter} #{year} Planner"
  end

  theme :earth

  # Quarter overview
  page :quarter_overview, year: year, quarter: quarter

  # Three months
  months_in_quarter(year, quarter).each do |month|
    page :monthly_goals, month: month

    weeks_in(month).each do |week|
      page :weekly, week: week
    end

    page :monthly_review, month: month
  end

  # Quarter review
  page :quarter_review, year: year, quarter: quarter

  # Appendix
  group :appendix do
    page :dot_grid
    page :notes, count: 5
  end
end
```

## Implementation Approach

### Phase 1: Core DSL and Builder

```ruby
module BujoPdf
  class PdfDefinition
    attr_reader :name, :block

    def initialize(name, &block)
      @name = name
      @block = block
    end

    def evaluate(context, **params)
      context.instance_exec(**params, &@block)
    end
  end

  class DeclarationContext
    attr_reader :pages, :groups, :metadata

    def page(type, **params)
      @pages << PageDeclaration.new(type, params)
    end

    def group(name, **options, &block)
      @groups << GroupDeclaration.new(name, options, &block)
    end

    def metadata(&block)
      @metadata = MetadataBuilder.new(&block)
    end

    # Helpers
    def weeks_in(year_or_month)
      DateCalculator.weeks_in(year_or_month)
    end
  end
end
```

### Phase 2: Link Resolution

```ruby
class LinkResolver
  def initialize(declarations)
    @map = build_destination_map(declarations)
  end

  def resolve(page_type, **params)
    @map.fetch(key_for(page_type, params)) do
      raise UnknownDestinationError, "No page #{page_type} with #{params}"
    end
  end

  private

  def build_destination_map(declarations)
    declarations.each_with_object({}).with_index do |(decl, map), index|
      map[key_for(decl.type, decl.params)] = index + 1
    end
  end
end
```

### Phase 3: Recipe Registry

```ruby
module BujoPdf
  @recipes = {}

  def self.define_pdf(name, &block)
    @recipes[name] = PdfDefinition.new(name, &block)
  end

  def self.generate(name = nil, **params, &block)
    definition = if block_given?
      PdfDefinition.new(:inline, &block)
    else
      @recipes.fetch(name) { raise "Unknown recipe: #{name}" }
    end

    PdfBuilder.new.build(definition, **params)
  end
end
```

## Migration Path

1. Create DSL infrastructure alongside existing generator
2. Define `:standard_planner` recipe that produces identical output
3. Validate with snapshot testing
4. Expose recipe system to users via config files or Ruby API
5. Deprecate direct generator usage

## User-Defined Recipes

Users can define their own recipes:

```ruby
# In user's project or config
BujoPdf.define_pdf :my_planner do |year:|
  page :seasonal_calendar, year: year

  weeks_in(year).each do |week|
    page :weekly, week: week
  end

  # My custom pages
  page :habit_tracker_template
  page :gratitude_log

  5.times do
    page :dot_grid
  end
end

BujoPdf.generate :my_planner, year: 2025
```

Or via YAML for non-programmers:

```yaml
# my_planner.yml
name: my_planner
theme: earth
pages:
  - type: seasonal_calendar
  - type: weekly
    repeat: weeks_in_year
  - type: dot_grid
    count: 5
```

## Relationship to Page DSL

The PDF DSL and Page DSL are complementary:

```
+-----------------------------------------------------------+
|                     PDF Definition                         |
|  BujoPdf.define_pdf :planner do                           |
|    page :weekly, week: week    <----------------------+   |
|  end                                                  |   |
+-------------------------------------------------------+---+
                                                        |
+-------------------------------------------------------+---+
|                    Page Definition                    |   |
|  BujoPdf.define_page :weekly do |week:|         <-----+   |
|    sidebar width: 3 do ... end                            |
|    columns 7 do |i| ... end                               |
|  end                                                      |
+-----------------------------------------------------------+
```

- **PDF DSL**: What pages, in what order, with what parameters
- **Page DSL**: How each page type is laid out

They can be developed independently. The PDF DSL can work with existing page classes initially, then migrate to Page DSL definitions over time.

## Open Questions

1. **YAML vs Ruby for user recipes?** Ruby is more powerful but requires programming. YAML is accessible but limited. Support both?

2. **How to handle page-numbering in links?** Pages need to know their number for footers, but numbers aren't assigned until declaration pass is complete.

3. **Should groups affect output structure?** Could groups become separate PDFs, bookmarks, or just logical organization?

4. **How to preview single pages during development?** Need a way to render one page type in isolation with mock data.

5. **Validation?** Should the DSL validate that referenced pages exist, required params are provided, etc. before rendering?

## Benefits

- **Declarative structure**: PDF contents are readable specifications
- **Reusable recipes**: Standard configurations as named, parameterized recipes
- **User customization**: Users define planners without modifying gem internals
- **Testability**: Recipe definitions can be inspected and validated
- **Separation of concerns**: Document structure separate from page layout
- **Incremental adoption**: Works with existing page classes
