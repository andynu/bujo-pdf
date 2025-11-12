# Plan 23: Additional Grid Types (Isometric, Perspective, Hexagon)

## Executive Summary

Extend the planner generator to support three additional grid types beyond the current dot grid: **isometric**, **perspective**, and **hexagon**. This feature allows users to generate planner pages with specialized grids suitable for technical drawing, architectural sketching, game mapping, and geometric design work.

The implementation will create a flexible grid system that:
- Maintains the existing 5mm spacing standard where applicable
- Provides configurable grid parameters (angles, sizes, orientations)
- Integrates with the existing grid coordinate system where possible
- Allows page-level or section-level grid type selection

## Technical Approach

### Architecture Decision

Rather than replacing the existing dot grid system, we'll create a **grid type abstraction** that allows different grid rendering strategies:

1. **Grid Renderer Classes** - Separate renderer for each grid type
2. **Grid Configuration** - Per-page or per-section grid type specification
3. **Backward Compatibility** - Existing dot grid remains default
4. **Coordinate System Preservation** - Grid helpers (x/y positioning) remain unchanged

### Grid Type Specifications

#### 1. Isometric Grid
- **Pattern**: 30-60-90° diamond grid (equilateral triangles)
- **Spacing**: 5mm between parallel lines
- **Angles**: 30° from horizontal (both directions)
- **Use Cases**: Technical drawing, 3D object sketching, game maps
- **Rendering**: Three sets of parallel lines at 0°, 60°, 120°

#### 2. Perspective Grid
- **Pattern**: Converging lines toward vanishing points
- **Variants**: 1-point, 2-point, 3-point perspective
- **Spacing**: Horizontal lines at 5mm intervals, vertical lines converge
- **Configuration**: Vanishing point positions (on/off page)
- **Use Cases**: Architecture, scene design, spatial planning
- **Default**: 2-point perspective with vanishing points at page edges

#### 3. Hexagon Grid
- **Pattern**: Tessellating regular hexagons
- **Spacing**: 5mm between parallel edges (flat-top or pointy-top)
- **Orientation**: Configurable (flat-top vs pointy-top)
- **Use Cases**: Game maps (hex-based strategy), organic patterns, chemistry diagrams
- **Rendering**: Calculate hex centers, draw six edges per hex

## Implementation Steps

### 1. Grid System Architecture Refactoring

**1.1 Create Grid Renderer Abstraction**
- Location: `lib/bujo_pdf/utilities/grid_renderers/`
- Create `BaseGridRenderer` abstract class with interface:
  - `initialize(pdf, width, height, options = {})`
  - `render` - Main rendering method
  - `spacing` - Base spacing (default 5mm = 14.17pt)
- Create `DotGridRenderer` by extracting current `draw_dot_grid` logic
- Move `draw_dot_grid` method to use `DotGridRenderer` internally

**1.2 Create Grid Renderer Factory**
- Location: `lib/bujo_pdf/utilities/grid_factory.rb`
- Method: `GridFactory.create(type, pdf, width, height, options = {})`
- Supported types: `:dots`, `:isometric`, `:perspective`, `:hexagon`
- Returns appropriate renderer instance

**1.3 Update GridSystem Utility**
- Add `draw_grid(type, width, height, **options)` method
- Default `type` to `:dots` for backward compatibility
- Delegate to `GridFactory.create(type, ...)`

### 2. Implement Isometric Grid Renderer

**2.1 Create IsometricGridRenderer Class**
- Location: `lib/bujo_pdf/utilities/grid_renderers/isometric_grid_renderer.rb`
- Calculate three sets of parallel lines at 30°, 90°, 150°
- Spacing: 5mm between parallel lines
- Options:
  - `spacing` (default: 14.17pt)
  - `line_color` (default: 'CCCCCC')
  - `line_width` (default: 0.25)

**2.2 Rendering Algorithm**
```ruby
# Pseudo-code for isometric grid
angles = [30, 90, 150]  # degrees from horizontal
angles.each do |angle|
  # Calculate perpendicular spacing between lines
  line_spacing = spacing / sin(60°)  # Adjust for angle

  # Generate lines across page at this angle
  # Starting from bottom-left, increment perpendicular to angle
  # until lines exit page bounds
end
```

**2.3 Optimization: Line Clipping**
- Only draw line segments within page bounds
- Calculate intersection points with page rectangle
- Avoid drawing off-page portions

### 3. Implement Perspective Grid Renderer

**3.1 Create PerspectiveGridRenderer Class**
- Location: `lib/bujo_pdf/utilities/grid_renderers/perspective_grid_renderer.rb`
- Default: 2-point perspective
- Options:
  - `vanishing_points` (array of [x, y] coordinates)
  - `num_points` (1, 2, or 3)
  - `horizon_y` (default: page height / 2)
  - `spacing` (horizontal grid lines, default: 14.17pt)
  - `line_color`, `line_width`

**3.2 Rendering Algorithm**

**For 1-point perspective:**
- Single vanishing point at page center
- Horizontal lines parallel to page bottom (5mm spacing)
- Vertical lines converge to vanishing point
- Grid density: N vertical lines from each edge

**For 2-point perspective:**
- Two vanishing points on horizon line (left/right of page)
- Horizontal lines parallel to page bottom
- Converging lines from grid points to vanishing points
- Left and right sets of converging lines

**For 3-point perspective:**
- Two vanishing points on horizon
- Third vanishing point above/below page center
- Vertical lines also converge (upward or downward)

**3.3 Default Configuration**
```ruby
# 2-point perspective defaults
horizon_y = page_height / 2
vanishing_points = [
  [-page_width * 2, horizon_y],      # Left VP (off-page)
  [page_width * 3, horizon_y]         # Right VP (off-page)
]
```

### 4. Implement Hexagon Grid Renderer

**4.1 Create HexagonGridRenderer Class**
- Location: `lib/bujo_pdf/utilities/grid_renderers/hexagon_grid_renderer.rb`
- Calculate hex tessellation across page
- Options:
  - `spacing` (edge-to-edge distance, default: 14.17pt)
  - `orientation` (`:flat_top` or `:pointy_top`, default: `:flat_top`)
  - `line_color`, `line_width`

**4.2 Hexagon Math**
```ruby
# For flat-top hexagons:
hex_width = spacing * 2
hex_height = spacing * sqrt(3)
horizontal_spacing = hex_width * 0.75  # Center-to-center
vertical_spacing = hex_height          # Center-to-center

# For pointy-top hexagons:
hex_width = spacing * sqrt(3)
hex_height = spacing * 2
horizontal_spacing = hex_width          # Center-to-center
vertical_spacing = hex_height * 0.75    # Center-to-center
```

**4.3 Rendering Algorithm**
```ruby
# Calculate hex grid dimensions
rows = (height / vertical_spacing).ceil + 1
cols = (width / horizontal_spacing).ceil + 1

rows.times do |row|
  cols.times do |col|
    # Offset even rows for tessellation
    x_offset = (row.even? ? 0 : horizontal_spacing / 2)
    center_x = col * horizontal_spacing + x_offset
    center_y = row * vertical_spacing

    # Draw hexagon at (center_x, center_y)
    draw_hexagon(center_x, center_y, spacing, orientation)
  end
end
```

**4.4 Hexagon Drawing Helper**
```ruby
def draw_hexagon(cx, cy, size, orientation)
  # Calculate six vertices
  vertices = 6.times.map do |i|
    angle = (orientation == :flat_top ? 0 : 30) + (i * 60)
    angle_rad = angle * Math::PI / 180
    [
      cx + size * Math.cos(angle_rad),
      cy + size * Math.sin(angle_rad)
    ]
  end

  # Draw polygon
  @pdf.stroke_polygon(vertices)
end
```

### 5. Page Integration

**5.1 Add Grid Type to Page Configuration**
- Extend `Pages::Base` to accept `grid_type` parameter
- Default to `:dots` for backward compatibility
- Pass grid type to `draw_dot_grid` calls

**5.2 Create Grid Sampler/Showcase Page**
- New page type: `Pages::GridShowcase`
- Location: `lib/bujo_pdf/pages/grid_showcase.rb`
- Layout: 2×2 grid showing all four grid types
- Each quadrant demonstrates one grid type with label
- Purpose: Visual reference and testing

**5.3 Update Blank Template Page**
- Modify `Pages::BlankDots` to accept grid type option
- Generate multiple template pages (one per grid type)
- Named destinations: `dots`, `isometric`, `perspective`, `hexagon`

### 6. Configuration and User Interface

**6.1 CLI Arguments**
- Add `--grid-types` flag to `bin/bujo-pdf generate`
- Syntax: `--grid-types dots,isometric,perspective,hexagon`
- Default: `dots` only (backward compatible)
- Multiple types generate multiple template pages

**6.2 Configuration File Support** (Future)
- YAML config: `config/planner.yml`
- Per-page grid type specification:
```yaml
template_pages:
  - type: dots
  - type: isometric
  - type: perspective
    options:
      num_points: 2
      horizon_y: 0.5
  - type: hexagon
    options:
      orientation: flat_top
```

### 7. Testing Strategy

**7.1 Unit Tests**
- Location: `test/utilities/grid_renderers/`
- Test each renderer class independently
- Mock PDF object to verify method calls
- Test boundary conditions (empty page, full page coverage)

**7.2 Visual Regression Tests**
- Generate sample PDFs with each grid type
- Visual inspection for:
  - Correct geometry (angles, spacing, tessellation)
  - Line density (not too sparse/crowded)
  - Alignment with page edges
  - No rendering artifacts

**7.3 Integration Tests**
- Generate full planner with all grid types
- Verify named destinations work for each template page
- Test CLI argument parsing for `--grid-types`

### 8. Documentation Updates

**8.1 CLAUDE.md Updates**
- Document new grid types and use cases
- Add grid renderer architecture section
- Example usage for each grid type

**8.2 README Updates**
- Add grid type examples with screenshots
- Document CLI usage: `--grid-types` flag
- Show configuration options for each grid type

**8.3 Code Comments**
- YARD documentation for all renderer classes
- Explain mathematical basis for each grid type
- Document configuration options and defaults

## Acceptance Criteria

### Functional Requirements
- [ ] Four grid types render correctly: dots, isometric, perspective, hexagon
- [ ] CLI accepts `--grid-types` argument to select grid types
- [ ] Each grid type maintains ~5mm spacing standard
- [ ] Grid showcase page demonstrates all grid types
- [ ] Backward compatibility: existing code defaults to dot grid

### Quality Requirements
- [ ] All unit tests pass (target: 100% coverage for renderers)
- [ ] Visual inspection confirms correct geometry for each grid type
- [ ] No performance degradation (generation time < 10 seconds)
- [ ] Documentation complete (CLAUDE.md, README, YARD comments)

### User Experience Requirements
- [ ] Grid types clearly labeled on showcase page
- [ ] Template pages for each grid type accessible via named destinations
- [ ] Navigation sidebar includes links to all template pages
- [ ] Configuration options documented with examples

## Edge Cases and Considerations

### 1. Coordinate System Compatibility
- Isometric/hexagon grids don't align with rectangular grid system
- Grid helper methods (`grid_x`, `grid_y`) remain for positioning, but grid pattern is independent
- Document that coordinate helpers work for positioning bounding boxes, not grid pattern alignment

### 2. Performance Optimization
- Isometric grid requires many line calculations
- Hexagon grid requires polygon rendering per hex
- **Optimization**: Pre-calculate line endpoints, use `stroke_polyline` for batch rendering
- **Target**: Generation time increase < 1 second per grid type

### 3. Print Quality
- Ensure line weights (0.25pt default) are visible when printed
- Test with actual printer/plotter output
- Consider heavier line weights for perspective grid (0.5pt)

### 4. File Size Impact
- Each additional grid type adds geometric data to PDF
- **Mitigation**: Only generate requested grid types (via CLI flag)
- **Monitor**: PDF file size should remain under 5MB for full planner + all templates

### 5. Accessibility
- Grid showcase page should include text descriptions
- Named destinations for screen readers
- High contrast option for low-vision users (darker grid lines)

## Future Enhancements

### Phase 2 Features (Not in Initial Implementation)
- **Custom grid spacing** - User-configurable spacing per grid type
- **Grid color schemes** - Themed color palettes (blueprint, sepia, high-contrast)
- **Hybrid grids** - Combine grid types (e.g., dots with perspective overlay)
- **Engineering grids** - Logarithmic, polar, triangular coordinate systems
- **Grid rotation** - Rotate grid pattern independent of page orientation
- **Smart grid density** - Adjust line density based on page size/zoom level

### Integration with Existing Features
- **Seasonal calendar with hex grid** - Could be interesting for creative layouts
- **Weekly pages with perspective grid** - Useful for architectural planning
- **Year-at-a-glance with isometric** - Unique visual style

## Dependencies

- **Prawn gem** - Verify support for `stroke_polygon`, angled line rendering
- **Math helpers** - Ruby's `Math` module for trigonometry (sin, cos, sqrt)
- **No new dependencies required** - Pure Ruby implementation

## Migration Path

Since this is a new feature (not replacing existing functionality):
1. **No breaking changes** - Existing code continues to work
2. **Opt-in feature** - Users explicitly request new grid types via CLI
3. **Gradual rollout** - Can ship one grid type at a time
4. **Feature flag** - Could gate behind `ENABLE_ADVANCED_GRIDS` environment variable for beta testing

## Estimated Effort

- **Grid renderer abstraction**: 2-3 hours
- **Isometric grid implementation**: 3-4 hours
- **Perspective grid implementation**: 4-6 hours (complex math)
- **Hexagon grid implementation**: 3-4 hours
- **Page integration & CLI**: 2-3 hours
- **Testing**: 4-5 hours
- **Documentation**: 2-3 hours
- **Total**: 20-28 hours (3-4 days of focused work)

## Success Metrics

- All four grid types render correctly and match expected geometry
- PDF generation time remains under 10 seconds for full planner + all grids
- User feedback confirms grids are useful for intended use cases (technical drawing, game design)
- Code coverage for grid renderers exceeds 90%
- Documentation is clear enough for users to select and configure grid types without support
