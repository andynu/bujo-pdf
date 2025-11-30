# Layout DSL (Removed)

**Status:** Removed November 2025
**Decision:** Not integrated - global coordinate system is simpler for this use case

## What It Was

A declarative domain-specific language for defining page layouts using a tree of layout nodes with automatic flex-based bounds computation.

### Key Files (Now Deleted)

```
lib/bujo_pdf/dsl.rb              # Entry point, build_layout method
lib/bujo_pdf/dsl/
  layout_node.rb                 # Base class with constraint system
  container_node.rb              # Vertical/horizontal layout containers
  section_node.rb                # SectionNode, SidebarNode, HeaderNode, FooterNode
  columns_node.rb                # ColumnsNode, RowsNode, GridNode
  content_node.rb                # TextNode, FieldNode, DotGridNode, RuledLinesNode, etc.
  navigation_node.rb             # NavLinkNode, NavGroupNode, TabNode
  component_definition.rb        # ComponentRegistry for reusable components
  layout_builder.rb              # DSL interface (sidebar, header, columns, text, etc.)
  style_resolver.rb              # Theme-based style system
  layout_renderer.rb             # Converts layout trees to Prawn PDF calls
```

## How It Worked

### 1. Build a Layout Tree

```ruby
layout = BujoPdf::DSL.build_layout do
  sidebar width: 3 do
    nav_link dest: :year_events, label: "Year"
  end

  section name: :content, flex: 1 do
    header height: 2 do
      text "Week 42", style: :title
    end

    columns count: 7 do |col|
      text "Day #{col}"
    end
  end
end
```

### 2. Compute Bounds Automatically

```ruby
BujoPdf::DSL.compute_layout(layout, cols: 43, rows: 55)
```

The layout algorithm distributed space according to constraints:
- **Fixed sizes:** `width: 10` or `height: 3` (in grid boxes)
- **Flex weights:** `flex: 1` takes proportional remaining space
- **Min/max:** `min_width: 5`, `max_height: 20`

### 3. Render to PDF

```ruby
renderer = LayoutRenderer.new(pdf, theme: my_theme, grid_system: grid)
renderer.render(layout)
```

## Node Types

| Node | Purpose |
|------|---------|
| `ContainerNode` | Arranges children vertically or horizontally |
| `SectionNode` | Named region with children |
| `SidebarNode` | Fixed-width vertical strip |
| `HeaderNode` | Fixed-height horizontal strip at top |
| `FooterNode` | Fixed-height horizontal strip at bottom |
| `ColumnsNode` | Equal-width or specified-width columns |
| `RowsNode` | Equal-height or specified-height rows |
| `GridNode` | 2D grid of cells |
| `TextNode` | Text content with styling |
| `FieldNode` | Writable area with optional ruled lines |
| `DotGridNode` | Dot grid background |
| `GraphGridNode` | Square grid lines |
| `RuledLinesNode` | Horizontal ruled lines |
| `NavLinkNode` | Clickable navigation link |
| `TabNode` | Rotated tab with link |
| `CustomNode` | Escape hatch for raw Prawn drawing |

## Design Principles

1. **Grid-centric:** All sizes in grid boxes (not points), aligned to 5mm dot grid
2. **Layout tree:** Nodes compute bounds based on constraints and available space
3. **Separation:** Layout specification is separate from rendering
4. **Theming:** StyleResolver applied consistent visual treatment

## Why It Was Removed

### The Problem It Solved

Automatic flex-based layout computation - useful when you don't know sizes ahead of time (responsive UIs, variable content).

### Why That Didn't Fit Here

The planner is a **fixed 43x55 grid** where sizes are known at design time:

1. **Global coordinates are simpler:** "Put this at column 5, row 10" is easier to reason about than nested flex containers

2. **Visually debuggable:** You can open the PDF, count grid boxes, and verify positions directly

3. **No flex needs:** Page layouts are fixed - headers are always 3 rows, sidebars are always 3 columns

4. **Current approach works well:** The existing system with:
   - `@grid.divide_grid()` and `@grid.divide_columns()` for layout math
   - Component verbs (`h2()`, `ruled_lines()`, etc.) for rendering
   - Layout classes (`use_layout :standard_with_sidebars`) for page chrome

   ...already provides the right level of abstraction.

### The Tradeoff

| Aspect | Layout DSL | Global Coordinates |
|--------|------------|-------------------|
| Mental model | Nested containers, local coords | Flat page, absolute coords |
| Flex layouts | Built-in | Not needed |
| Debugging | Inspect computed bounds | Count grid boxes visually |
| Learning curve | New tree-based API | Direct, explicit |

For a bullet journal PDF generator, the global coordinate approach wins on simplicity.

## Lessons Learned

1. **Don't solve problems you don't have.** The Layout DSL was well-architected but solved automatic flex computation - unnecessary for fixed-layout PDFs.

2. **Explicit beats implicit** for visual design. Being able to say "column 5, row 10" and verify it by counting dots is more valuable than automatic layout.

3. **The right abstraction level matters.** The existing grid helpers + component verbs hit the sweet spot - high enough to avoid repetition, low enough to stay explicit.

## If You Want to Resurrect It

The code was fully functional with tests. If a future use case requires:
- Complex nested layouts with proportional sizing
- Dynamic content where sizes aren't known ahead of time
- Reusable page templates with parameterized structure

...consider retrieving this from git history. The commit that removed it documents the full file list.

## Related

- `lib/bujo_pdf/pdf_dsl/` - Document-level DSL (what pages, in what order) - **still in use**
- `lib/bujo_pdf/layouts/` - Page chrome system (sidebars, navigation) - **still in use**
- `lib/bujo_pdf/components/` - Component verb system - **still in use**
