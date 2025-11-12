# BujoPdf

A Ruby gem for generating programmable bullet journal PDFs optimized for digital note-taking apps like Noteshelf and GoodNotes.

## Features

- **Seasonal Calendar** - Year-at-a-glance view organized by seasons with mini month calendars
- **Year-at-a-Glance Pages** - Events and Highlights grids (12 months × 31 days)
- **Weekly Pages** - Daily sections with Cornell notes layout for structured note-taking
- **PDF Navigation** - Internal hyperlinks between pages with clickable week numbers and tabs
- **Dot Grid Backgrounds** - 5mm dot spacing throughout for handwriting guidance
- **Grid-Based Layout** - Precise 43×55 grid system for consistent alignment
- **Component Architecture** - Modular, maintainable code structure

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bujo-pdf'
```

And then execute:

```bash
bundle install
```

Or install directly:

```bash
gem install bujo-pdf
```

## Usage

### Command Line

Generate a planner for the current year:

```bash
bujo-pdf
```

Generate for a specific year:

```bash
bujo-pdf 2025
```

Show version:

```bash
bujo-pdf --version
```

Show help:

```bash
bujo-pdf --help
```

### Ruby API

```ruby
require 'bujo_pdf'

# Generate for current year
BujoPdf.generate

# Generate for specific year
BujoPdf.generate(2025)

# Specify custom output path
BujoPdf.generate(2025, output_path: 'my_planner.pdf')
```

### Output

The generated PDF includes:

1. **Seasonal Calendar** - Overview page with all four seasons
2. **Year Events** - 12×31 grid for tracking events throughout the year
3. **Year Highlights** - 12×31 grid for noting daily highlights
4. **Weekly Pages** (52-53 pages) - One page per week with:
   - Daily section (7 columns for Mon-Sun)
   - Cornell notes section (Cues, Notes, Summary)
   - Navigation links to previous/next week
5. **Reference Page** - Grid calibration and measurement guide
6. **Blank Dot Grid** - Template page for additional notes

Total pages: 57-58 (varies by year)

## Development

After checking out the repo:

```bash
bundle install
rake test              # Run tests
rake generate[2025]    # Generate test PDF
```

To install this gem onto your local machine:

```bash
gem build bujo-pdf.gemspec
gem install bujo-pdf-0.1.0.gem
```

To test local installation:

```bash
rake test_install
```

## Architecture

The gem uses a component-based architecture with:

- **Grid System** - Converts grid coordinates to PDF points
- **Layout System** - Declarative layouts with automatic content area management
- **Components** - Reusable UI elements (sidebars, headers, sections)
- **Pages** - Page classes that compose components
- **Utilities** - Date calculations, dot grids, styling helpers

See `CLAUDE.md` for detailed technical documentation.

## Testing

Run the test suite:

```bash
rake test
```

The test suite includes:
- Grid system tests (coordinate conversion, boundary calculations)
- Date calculation tests (week numbering, edge cases)
- Component rendering tests
- Integration tests

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andynu/bujo-pdf.

This project is intended to be a safe, welcoming space for collaboration. Contributors are expected to adhere to the code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).

## Code of Conduct

Everyone interacting in the BujoPdf project's codebases, issue trackers, chat rooms and mailing lists is expected to follow professional standards of conduct and mutual respect.
