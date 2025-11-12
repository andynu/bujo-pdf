# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/andynu/bujo-pdf/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/andynu/bujo-pdf/releases/tag/v0.1.0
