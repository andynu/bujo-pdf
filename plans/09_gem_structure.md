# Plan 09: Gem Structure and Distribution

## Executive Summary

Convert the bujo-pdf project from a standalone Ruby script into a properly structured Ruby gem that can be distributed via RubyGems. This transformation will enable easy installation, version management, and reuse across different projects while maintaining all current functionality.

**Goal**: Package the planner generator as a distributable gem with a clean CLI interface, proper dependency management, and standard Ruby gem conventions.

**Estimated Effort**: 4-6 hours

**Dependencies**: Plans 01-06 completed (all core refactoring done)

## Current State

The project currently has:
- Well-structured `lib/bujo_pdf/` directory with modular components
- Main generator in `gen.rb` (standalone script)
- Manual dependency installation via `bundle install`
- Direct Ruby execution (`ruby gen.rb [year]`)
- No version management or distribution mechanism

## Target State

A fully-fledged Ruby gem with:
- Standard gem directory structure
- Proper gemspec with metadata and dependencies
- CLI executable accessible via `bujo-pdf` command
- Version management following semantic versioning
- Autoloading of all library files
- Ready for RubyGems publication
- Backward compatibility with current `gen.rb` workflow

## Technical Approach

### 1. Gem Structure Strategy

Follow standard Ruby gem conventions as outlined in the [RubyGems Guide](https://guides.rubygems.org/):

```
bujo-pdf/
├── bin/
│   └── bujo-pdf              # Executable CLI entry point
├── lib/
│   ├── bujo_pdf.rb           # Main require file (autoloader)
│   ├── bujo_pdf/
│   │   ├── version.rb        # Version constant
│   │   ├── cli.rb            # CLI argument parsing
│   │   └── [existing files]  # All current lib/ files
├── test/                      # Test files (existing)
├── bujo-pdf.gemspec          # Gem specification
├── Gemfile                    # Development dependencies
├── Rakefile                   # Build tasks
├── README.md                  # User-facing documentation
├── CHANGELOG.md               # Version history
└── LICENSE                    # Software license
```

### 2. Autoloading Strategy

Use explicit requires in `lib/bujo_pdf.rb` to load all library files in dependency order:
- Load utilities first (GridSystem, Styling, DotGrid, Diagnostics)
- Load base classes (Component, Page)
- Load shared classes (RenderContext, Layout, PageFactory)
- Load components and pages
- Load main generator (PlannerGenerator)

This ensures all dependencies are available when classes are instantiated.

### 3. CLI Design

Create a simple, intuitive CLI interface:

```bash
# Generate planner for current year
bujo-pdf

# Generate planner for specific year
bujo-pdf 2025

# Show version
bujo-pdf --version

# Show help
bujo-pdf --help
```

### 4. Version Management

Use semantic versioning (SemVer):
- **0.1.0** - Initial gem release
- **0.x.y** - Pre-1.0 development versions
- **1.0.0** - First stable release (after testing in production)

## Implementation Steps

### 1. Create Gem Specification File

**1.1 Create `bujo-pdf.gemspec`**

Define gem metadata, dependencies, and file manifest:

```ruby
# frozen_string_literal: true

require_relative 'lib/bujo_pdf/version'

Gem::Specification.new do |spec|
  spec.name          = 'bujo-pdf'
  spec.version       = BujoPdf::VERSION
  spec.authors       = ['Author Name']
  spec.email         = ['author@example.com']

  spec.summary       = 'Generate programmable bullet journal PDFs'
  spec.description   = 'A Ruby-based PDF planner generator that creates ...'
  spec.homepage      = 'https://github.com/username/bujo-pdf'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir['lib/**/*.rb', 'bin/*', 'README.md', 'LICENSE', 'CHANGELOG.md']
  spec.bindir = 'bin'
  spec.executables = ['bujo-pdf']
  spec.require_paths = ['lib']

  spec.add_dependency 'prawn', '~> 2.4'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
```

**1.2 Update Gemfile**

Convert from app-style to gem-style Gemfile:

```ruby
source 'https://rubygems.org'

# Specify dependencies from gemspec
gemspec

# Development tools (optional)
group :development do
  gem 'yard', '~> 0.9'      # Documentation generation
  gem 'rubocop', '~> 1.0'   # Code linting
end
```

**Files to create/modify**:
- Create `bujo-pdf.gemspec`
- Update `Gemfile` to use `gemspec`

### 2. Version Management

**2.1 Create `lib/bujo_pdf/version.rb`**

Define the version constant:

```ruby
# frozen_string_literal: true

module BujoPdf
  VERSION = '0.1.0'
end
```

**2.2 Create `CHANGELOG.md`**

Track version history following [Keep a Changelog](https://keepachangelog.com/):

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - YYYY-MM-DD

### Added
- Initial gem release
- Grid-based layout system
- Component-based architecture
- Weekly page generation
- Seasonal calendar and year-at-a-glance pages
- PDF hyperlink navigation
- Dot grid backgrounds
- CLI executable
```

**Files to create**:
- Create `lib/bujo_pdf/version.rb`
- Create `CHANGELOG.md`

### 3. Main Library Entry Point

**3.1 Create `lib/bujo_pdf.rb`**

Main require file that loads all library components in dependency order:

```ruby
# frozen_string_literal: true

# Load version first
require_relative 'bujo_pdf/version'

# Load utilities (no dependencies)
require_relative 'bujo_pdf/utilities/styling'
require_relative 'bujo_pdf/utilities/grid_system'
require_relative 'bujo_pdf/utilities/dot_grid'
require_relative 'bujo_pdf/utilities/diagnostics'

# Load base classes and shared infrastructure
require_relative 'bujo_pdf/render_context'
require_relative 'bujo_pdf/layout'
require_relative 'bujo_pdf/component_context'
require_relative 'bujo_pdf/component'

# Load sub-components (used by components)
require_relative 'bujo_pdf/sub_components/base'
require_relative 'bujo_pdf/sub_components/fieldset'
require_relative 'bujo_pdf/sub_components/week_column'
require_relative 'bujo_pdf/sub_components/ruled_lines'
require_relative 'bujo_pdf/sub_components/day_header'

# Load components
require_relative 'bujo_pdf/components/top_navigation'
require_relative 'bujo_pdf/components/week_sidebar'
require_relative 'bujo_pdf/components/right_sidebar'
require_relative 'bujo_pdf/components/daily_section'
require_relative 'bujo_pdf/components/cornell_notes'

# Load page base and factory
require_relative 'bujo_pdf/pages/base'
require_relative 'bujo_pdf/page_factory'

# Load concrete page classes
require_relative 'bujo_pdf/pages/seasonal_calendar'
require_relative 'bujo_pdf/pages/year_at_glance_base'
require_relative 'bujo_pdf/pages/year_at_glance_events'
require_relative 'bujo_pdf/pages/year_at_glance_highlights'
require_relative 'bujo_pdf/pages/weekly_page'
require_relative 'bujo_pdf/pages/reference_calibration'
require_relative 'bujo_pdf/pages/blank_dot_grid'

# Load main generator (depends on everything above)
require_relative 'bujo_pdf/planner_generator'

# Module for namespace
module BujoPdf
  class Error < StandardError; end

  # Convenience method for generating planners
  def self.generate(year = Date.today.year, output_path: nil)
    output_path ||= "planner_#{year}.pdf"
    generator = PlannerGenerator.new(year, output_path)
    generator.generate
    output_path
  end
end
```

**Files to create**:
- Create `lib/bujo_pdf.rb`

**Note**: This replaces the need to manually require files. Users can just `require 'bujo_pdf'`.

### 4. CLI Executable

**4.1 Create `bin/bujo-pdf`**

Command-line interface for the gem:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/bujo_pdf'

# Simple CLI implementation
module BujoPdf
  class CLI
    def self.run(args = ARGV)
      case args.first
      when '--version', '-v'
        puts "bujo-pdf version #{BujoPdf::VERSION}"
        exit 0
      when '--help', '-h', 'help'
        show_help
        exit 0
      when nil
        # No arguments - generate for current year
        year = Date.today.year
      else
        # First argument is the year
        year = args.first.to_i
        if year < 1900 || year > 2100
          warn "Error: Invalid year '#{args.first}'"
          warn "Year must be between 1900 and 2100"
          exit 1
        end
      end

      output_file = "planner_#{year}.pdf"
      puts "Generating planner for #{year}..."

      begin
        BujoPdf.generate(year, output_path: output_file)
        puts "✓ Generated: #{output_file}"
      rescue StandardError => e
        warn "Error generating planner: #{e.message}"
        warn e.backtrace.join("\n") if ENV['DEBUG']
        exit 1
      end
    end

    def self.show_help
      puts <<~HELP
        bujo-pdf - Generate programmable bullet journal PDFs

        Usage:
          bujo-pdf [YEAR] [OPTIONS]

        Arguments:
          YEAR          Year to generate planner for (default: current year)

        Options:
          --version, -v Show version
          --help, -h    Show this help message

        Examples:
          bujo-pdf              # Generate planner for current year
          bujo-pdf 2025         # Generate planner for 2025
          bujo-pdf --version    # Show version number

        Output:
          Creates planner_YEAR.pdf in the current directory
      HELP
    end
  end
end

# Run CLI
BujoPdf::CLI.run if __FILE__ == $PROGRAM_NAME
```

**4.2 Make executable**

```bash
chmod +x bin/bujo-pdf
```

**Files to create**:
- Create `bin/bujo-pdf` (executable)
- Set executable permissions

### 5. Rakefile for Build Tasks

**5.1 Create `Rakefile`**

Standard gem build and test tasks:

```ruby
# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

desc 'Run tests'
task default: :test

desc 'Generate a test planner PDF'
task :generate, [:year] do |_t, args|
  require_relative 'lib/bujo_pdf'

  year = args[:year] ? args[:year].to_i : Date.today.year
  output_file = "planner_#{year}.pdf"

  puts "Generating planner for #{year}..."
  BujoPdf.generate(year, output_path: output_file)
  puts "Generated: #{output_file}"
end

desc 'Build gem and test installation locally'
task :test_install do
  sh 'gem build bujo-pdf.gemspec'
  gem_file = Dir['bujo-pdf-*.gem'].sort.last
  sh "gem install #{gem_file}"
  puts "\nTesting installed gem:"
  sh 'bujo-pdf --version'
end
```

**Files to create**:
- Create `Rakefile`

### 6. License and Documentation

**6.1 Create `LICENSE`**

Add MIT license (or chosen license):

```
MIT License

Copyright (c) [YEAR] [AUTHOR NAME]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

[... standard MIT license text ...]
```

**6.2 Update `README.md`**

Transform into gem-focused README:

```markdown
# BujoPdf

A Ruby gem for generating programmable bullet journal PDFs optimized for digital note-taking apps.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bujo-pdf'
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

### Ruby API

```ruby
require 'bujo_pdf'

# Generate for current year
BujoPdf.generate

# Generate for specific year
BujoPdf.generate(2025)

# Specify output path
BujoPdf.generate(2025, output_path: 'my_planner.pdf')
```

## Features

- **Seasonal calendar** - Year-at-a-glance organized by seasons
- **Year-at-a-glance pages** - Events and Highlights grids
- **Weekly pages** - Daily sections with Cornell notes
- **Navigation system** - Internal PDF hyperlinks
- **Dot grid backgrounds** - 5mm spacing for handwriting
- **Grid-based layout** - Precise 43×55 grid system

## Development

After checking out the repo:

```bash
bundle install
rake test              # Run tests
rake generate[2025]    # Generate test PDF
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [repository URL].

## License

The gem is available as open source under the [MIT License](LICENSE).
```

**Files to create/update**:
- Create `LICENSE`
- Update `README.md` with gem-focused content

### 7. Backward Compatibility

**7.1 Update `gen.rb` to use gem**

Convert standalone script to thin wrapper around gem:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Legacy entry point - now uses gem infrastructure
require_relative 'lib/bujo_pdf'

year = ARGV[0] ? ARGV[0].to_i : Date.today.year
output_file = "planner_#{year}.pdf"

puts "Generating planner for #{year} using BujoPdf gem..."
BujoPdf.generate(year, output_path: output_file)
puts "Generated: #{output_file}"
```

**Files to modify**:
- Update `gen.rb` to delegate to gem

### 8. Testing and Validation

**8.1 Test local gem installation**

```bash
# Build gem
gem build bujo-pdf.gemspec

# Install locally
gem install bujo-pdf-0.1.0.gem

# Test CLI
bujo-pdf --version
bujo-pdf 2025

# Verify PDF output
open planner_2025.pdf
```

**8.2 Test programmatic usage**

Create test script `test_gem.rb`:

```ruby
require 'bujo_pdf'

# Test convenience method
BujoPdf.generate(2025)

# Test direct instantiation
generator = BujoPdf::PlannerGenerator.new(2025, 'test_planner.pdf')
generator.generate

puts "Tests passed!"
```

**8.3 Verify all existing tests still pass**

```bash
rake test
```

**Files to create**:
- Create `test_gem.rb` (temporary test script)

### 9. Git Ignore Updates

**9.1 Update `.gitignore`**

Add gem build artifacts:

```
# Gem build artifacts
*.gem
pkg/
Gemfile.lock

# Test output
planner_*.pdf
test_planner.pdf
```

**Files to modify**:
- Update `.gitignore`

### 10. Build and Distribution Preparation

**10.1 Pre-release checklist**

Before publishing to RubyGems:

- [ ] All tests passing
- [ ] README complete and accurate
- [ ] CHANGELOG updated with release date
- [ ] Version number set in `version.rb`
- [ ] LICENSE file present
- [ ] Gemspec metadata accurate (author, email, homepage)
- [ ] Clean git status (all changes committed)
- [ ] Git tag for version (e.g., `v0.1.0`)

**10.2 Build and publish commands**

```bash
# Build gem
gem build bujo-pdf.gemspec

# Test installation locally first
gem install bujo-pdf-0.1.0.gem

# Push to RubyGems (when ready)
gem push bujo-pdf-0.1.0.gem
```

**Note**: Defer actual RubyGems publication until after thorough testing.

## Testing Strategy

### Unit Tests

**Existing tests should continue to pass**:
- Grid system tests (20 tests in `test/grid_system_test.rb`)
- All assertions should pass without modification

### Integration Tests

**Add new gem-specific tests**:

1. **Require test** - Verify `require 'bujo_pdf'` loads all classes
2. **API test** - Verify `BujoPdf.generate(year)` works
3. **CLI test** - Verify executable works and handles arguments
4. **Version test** - Verify `BujoPdf::VERSION` is accessible

Create `test/gem_integration_test.rb`:

```ruby
require 'minitest/autorun'
require_relative '../lib/bujo_pdf'

class GemIntegrationTest < Minitest::Test
  def test_require_loads_all_classes
    assert defined?(BujoPdf::PlannerGenerator)
    assert defined?(BujoPdf::GridSystem)
    assert defined?(BujoPdf::Component)
    assert defined?(BujoPdf::Pages::WeeklyPage)
  end

  def test_version_constant_exists
    assert_match(/\d+\.\d+\.\d+/, BujoPdf::VERSION)
  end

  def test_convenience_method
    output_file = BujoPdf.generate(2025, output_path: 'test_output.pdf')
    assert File.exist?(output_file)
  ensure
    File.delete('test_output.pdf') if File.exist?('test_output.pdf')
  end
end
```

### Manual Verification

1. **PDF generation** - Generate planners for multiple years
2. **PDF validation** - Open in PDF reader and verify:
   - All pages present (58 pages)
   - Links work correctly
   - Layout intact
   - No visual regressions
3. **CLI functionality** - Test all CLI options
4. **Error handling** - Test invalid inputs

## Acceptance Criteria

### Must Have

- [ ] Gemspec file created with correct metadata
- [ ] Version management in place (`lib/bujo_pdf/version.rb`)
- [ ] Main library entry point (`lib/bujo_pdf.rb`) loads all files
- [ ] CLI executable (`bin/bujo-pdf`) works with all options
- [ ] Gem builds successfully (`gem build`)
- [ ] Gem installs locally without errors
- [ ] CLI accessible after installation (`bujo-pdf` command works)
- [ ] Generated PDFs identical to pre-gem version
- [ ] All existing tests pass
- [ ] README updated with installation and usage instructions
- [ ] LICENSE file present
- [ ] CHANGELOG.md created with initial version
- [ ] `.gitignore` updated for gem artifacts

### Should Have

- [ ] Rakefile with build and test tasks
- [ ] Gem integration tests passing
- [ ] Backward compatibility via `gen.rb` wrapper
- [ ] Helpful CLI error messages
- [ ] CLI help text (`--help` option)
- [ ] Version display (`--version` option)

### Nice to Have

- [ ] CI/CD configuration for automated testing
- [ ] YARD documentation comments
- [ ] Code coverage reports
- [ ] Performance benchmarks
- [ ] Example projects/demos

## Migration Path

### For Existing Users

**Option 1: Install gem globally**
```bash
gem install bujo-pdf
bujo-pdf 2025
```

**Option 2: Continue using git clone**
```bash
git clone [repo]
cd bujo-pdf
bundle install
ruby gen.rb 2025  # Still works via wrapper
```

**Option 3: Use in project Gemfile**
```ruby
# Gemfile
gem 'bujo-pdf', git: 'https://github.com/username/bujo-pdf'
```

### For New Users

**Simple installation**:
```bash
gem install bujo-pdf
bujo-pdf
```

## Risks and Mitigation

### Risk: Breaking existing functionality

**Mitigation**:
- Keep `gen.rb` as wrapper for backward compatibility
- Run full test suite before and after
- Visual comparison of generated PDFs
- Test with multiple years (edge cases)

### Risk: Require loading order issues

**Mitigation**:
- Explicit, ordered requires in `lib/bujo_pdf.rb`
- Document dependency graph
- Test that `require 'bujo_pdf'` is sufficient

### Risk: Gem installation conflicts

**Mitigation**:
- Use conservative version constraints (`~> 2.4`)
- Test on fresh Ruby installation
- Document Ruby version requirements

### Risk: CLI argument parsing edge cases

**Mitigation**:
- Validate year input (1900-2100 range)
- Provide helpful error messages
- Test with various invalid inputs

## Future Enhancements

After initial gem release (v0.1.0), consider:

1. **Configuration file support** - Allow customization via YAML config
2. **Output format options** - PDF size (A4 vs Letter), orientation
3. **Theme support** - Color schemes, fonts
4. **Plugin system** - Custom page types via gems
5. **Web interface** - Simple web UI for non-technical users
6. **RubyGems publication** - Official release on rubygems.org

## References

- [RubyGems Guides](https://guides.rubygems.org/)
- [Bundler Gem Development](https://bundler.io/guides/creating_gem.html)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

## Notes

- Use `frozen_string_literal: true` in all new Ruby files
- Follow existing code style and conventions
- Test on Ruby 2.7+ (minimum supported version)
- Gem name: `bujo-pdf` (hyphenated for CLI, `BujoPdf` for module)
- Initial version: 0.1.0 (pre-stable, signals development status)
