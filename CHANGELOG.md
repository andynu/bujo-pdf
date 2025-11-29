# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-11-29

### Added
- **Theme System**: Light, Earth, and Dark color themes with `--theme` CLI option
- **Grid Types**: Full-page templates for all grid types
  - Dot grid (5mm)
  - Graph/square grid (5mm)
  - Ruled lines (10mm)
  - Isometric grid (30-60-90 degree)
  - Perspective grid (1-point with guide rectangles)
  - Hexagon grid (tessellating flat-top)
- **Grid Showcase Page**: Visual reference showing all grid types in quadrants
- **Grids Overview Page**: Entry point with clickable grid samples
- **Multi-tap Navigation**: Grids tab cycles through all 8 grid pages
- **Calendar Integration**: iCal URL support for importing events
- **Date Configuration**: YAML-based date highlighting with categories and priorities
- **Multi-year Overview**: 4-year calendar spread with navigation
- **Daily Wheel**: Circular daily planning template
- **Year Wheel**: Circular year-at-a-glance visualization
- **Grid Renderers**: Modular renderer classes for each grid type via GridFactory
- **WeekGrid Component**: Quantized 7-column layouts aligned to dot grid
- **generate-examples script**: Generates planners for current+next year in all themes

### Changed
- Grids tab now starts with Grid Showcase (was Grids Overview)
- Navigation cycle includes all grid types (8 pages total)
- Improved right sidebar with rounded tab backgrounds
- Updated page count to 68 pages (was 61-62)

### Removed
- Redundant "Dots" bottom navigation tab (covered by Grids cycle)
- Duplicate blank dot grid page (consolidated with grid_dot)

### Technical
- GridFactory pattern for creating grid renderers
- BaseGridRenderer abstract class for grid implementations
- Styling module with theme-aware color methods
- Calendar integration with recurring event expansion

## [0.1.0] - 2025-11-11

### Added
- Initial gem release with complete planner generator functionality
- Grid-based layout system with 43×55 grid (5mm dot spacing)
- Component-based architecture for maintainable code organization
- Weekly page generation with daily sections and Cornell notes layout
- Seasonal calendar page with four seasons and mini month calendars
- Year-at-a-glance pages (Events and Highlights grids)
- Reference/calibration page with grid system documentation
- Blank dot grid template page
- PDF hyperlink navigation system with named destinations
- Navigation sidebars (week list and year tabs)
- Dot grid backgrounds throughout all pages
- CLI executable (`bujo-pdf` command)
- Convenience API (`BujoPdf.generate` method)
- Comprehensive documentation in CLAUDE.md and README.md
- Testing infrastructure with Minitest

### Technical Details
- Declarative layout system with automatic content area management
- Render context system for context-aware component rendering
- Modular utilities (GridSystem, DateCalculator, Styling, DotGrid, Diagnostics)
- Base classes for components, pages, and layouts
- Page factory pattern for clean page generation
- Automatic page numbering from Prawn
- Centralized constant definitions
- Style context managers for PDF rendering

[Unreleased]: https://github.com/andynu/bujo-pdf/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/andynu/bujo-pdf/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/andynu/bujo-pdf/releases/tag/v0.1.0
