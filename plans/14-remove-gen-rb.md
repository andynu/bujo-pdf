# Plan #14: Remove gen.rb and Standardize on bin/bujo-pdf

## Overview
Remove the legacy `gen.rb` script and standardize all documentation, examples, and workflows to use the proper gem executable `bin/bujo-pdf`. This cleanup eliminates confusion between the old development script and the official gem interface.

## Current State

The project currently has two ways to generate planners:
1. **Legacy**: `ruby gen.rb [year]` - Original development script
2. **Official**: `bin/bujo-pdf generate [year]` or `bujo-pdf generate [year]` (when installed as gem)

The gem structure (Plan 09) established `bin/bujo-pdf` as the official interface, but `gen.rb` remains as a legacy artifact that creates confusion about which command to use.

## Files Requiring Changes

### Files to Delete
1. **`gen.rb`** - Legacy generator script (replaced by bin/bujo-pdf)

### Documentation to Update
1. **`README.md`** - Update all usage examples to use `bin/bujo-pdf`
2. **`CLAUDE.md`** - Update development commands section
3. **`CLAUDE.local.md`** - Update any references to gen.rb
4. **`plans/*.md`** - Update any plan files that reference gen.rb
5. **Test files** - Ensure integration tests don't rely on gen.rb

### Search for References
Use grep to find all references to `gen.rb`:
```bash
grep -r "gen\.rb" --exclude-dir=.git --exclude-dir=coverage
```

## Implementation Steps

### Step 1: Search for All References
```bash
# Find all references to gen.rb
grep -r "gen\.rb" --exclude-dir=.git --exclude-dir=coverage .

# Check if any code depends on gen.rb
grep -r "require.*gen" lib/ test/
```

### Step 2: Update Documentation Files
Update all documentation to use `bin/bujo-pdf` instead of `ruby gen.rb`:

**README.md:**
```bash
# Before
ruby gen.rb 2025

# After
bin/bujo-pdf generate 2025
# Or if installed as gem:
bujo-pdf generate 2025
```

**CLAUDE.md - Development Commands:**
```markdown
### Generate Planner
```bash
# Generate for current year
bin/bujo-pdf generate

# Generate for specific year
bin/bujo-pdf generate 2025

# Install dependencies first if needed
bundle install
```
```

### Step 3: Verify Tests Don't Depend on gen.rb
Check integration tests to ensure they use the library API, not the script:
```ruby
# tests should use:
require 'bujo_pdf'
generator = BujoPdf::PlannerGenerator.new(2025)
generator.generate('output.pdf')

# NOT:
system("ruby gen.rb 2025")
```

### Step 4: Remove gen.rb
Once all references are updated:
```bash
git rm gen.rb
```

### Step 5: Update Plans Index
Add note about gen.rb removal to this plan's completion entry.

## Migration Guide for Users

For anyone using the old `gen.rb` script:

**Old workflow:**
```bash
ruby gen.rb 2025
```

**New workflow (local development):**
```bash
bin/bujo-pdf generate 2025
```

**New workflow (installed gem):**
```bash
gem install bujo_pdf
bujo-pdf generate 2025
```

## Benefits

1. **Single source of truth**: Only one way to run the generator
2. **Matches gem conventions**: Users install and use `bujo-pdf` command
3. **Cleaner project structure**: Removes legacy development artifact
4. **Better documentation**: Clear, consistent examples throughout
5. **Aligns with Plan 09**: Completes the gem structure migration

## Edge Cases to Consider

1. **Existing workflows**: Check if CI/CD or scripts reference gen.rb
2. **Git history**: gen.rb removal will be tracked in git history if needed
3. **Development patterns**: Ensure local development workflow is clear in README
4. **Examples in issues**: Update any example commands in GitHub issues (if applicable)

## Testing After Removal

1. Verify `bin/bujo-pdf generate 2025` works
2. Verify `bin/bujo-pdf --help` shows correct usage
3. Run full test suite to ensure no hidden dependencies
4. Generate a planner to confirm end-to-end functionality
5. Check that README installation instructions work for new users

## Dependencies

- Plan 09 (Gem Structure and Distribution) - COMPLETED

## Completion Criteria

- [x] All documentation updated to use `bin/bujo-pdf`
- [x] No references to `gen.rb` remain in codebase (excluding git history)
- [x] Tests pass without gen.rb present (98 tests, 2428 assertions, 0 failures)
- [x] README provides clear usage examples with `bin/bujo-pdf`
- [x] `gen.rb` deleted and removal committed

## Results

All criteria met successfully:

1. **Documentation updated**: CLAUDE.md, CLAUDE.local.md, plans/*.md, REFACTORING_PLAN.md all updated
2. **README already correct**: README.md already using `bujo-pdf` command exclusively
3. **No code dependencies**: Grep search confirmed no references in test/ or lib/
4. **Tests pass**: Full test suite passes (98 tests, 2428 assertions, 0 failures, 0 errors)
5. **gen.rb removed**: `git rm gen.rb` executed successfully

The codebase now has a single, clear entry point via `bin/bujo-pdf` (or `bujo-pdf` when installed as gem).
