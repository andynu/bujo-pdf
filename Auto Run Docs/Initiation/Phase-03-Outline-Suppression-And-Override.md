# Phase 03: Outline Suppression and Override

This phase adds the "smart defaults with overrides" capability. Users can suppress automatic outline entries with `outline: false` or provide custom titles with `outline: "Custom Title"`. This completes the outline control API.

## Tasks

- [x] Add tests for outline suppression and override behavior:
  - Create `test/unit/dsl/auto_outline_test.rb`
  - Test case: `outline_mode :auto` generates entries for pages with registered titles
  - Test case: `outline: false` suppresses auto-generation for that page
  - Test case: `outline: "Custom"` overrides the auto-generated title
  - Test case: `outline_mode :manual` (default) requires explicit `outline:` params
  - Test case: `outline_mode :none` generates no outline entries at all
  - Use inline recipe definitions for isolation

  **Completed:** Created `test/unit/dsl/auto_outline_test.rb` with 12 comprehensive tests covering all outline modes and behaviors. All tests pass.

- [x] Implement suppression logic in `create_standard_page`:
  - Check for explicit `outline: false` BEFORE checking auto mode
  - If `outline == false`, do not add any outline entry (even in auto mode)
  - Document this behavior with a code comment

  **Completed:** Added explicit `outline == false` check at line 411-414 in `lib/bujo_pdf/dsl/context.rb` with explanatory comment about precedence.

- [x] Implement suppression logic in `create_inline_page`:
  - Same pattern: check for explicit `outline: false` first
  - Skip entry generation if false, regardless of outline mode

  **Completed:** Added explicit `outline == false` check at lines 461-465 in `lib/bujo_pdf/dsl/context.rb` with matching comment about the precedence chain: `:none mode > explicit false > auto mode > default`.

- [x] Update the project planner to demonstrate overrides:
  - Keep `outline_mode :auto` enabled
  - Add `outline: false` to one monthly page (e.g., month 6) to suppress it
  - Add `outline: "Year Overview"` to the cover page to override the auto title
  - This demonstrates all three behaviors: auto, suppress, override

  **Completed:** Updated `lib/bujo_pdf/pdfs/project_planner.rb` to demonstrate all three behaviors:
  1. Override: Cover page uses `outline: 'Year Overview'` instead of auto-derived 'Cover'
  2. Suppress: Month 6 (June) uses `outline: false` and does not appear in outline
  3. Auto: Other months and Notes page use auto-generated titles

- [x] Run tests and verify the test script:
  - Execute `bundle exec rake test` to run the new tests
  - Execute `bundle exec ruby test_project_planner.rb`
  - Verify: Cover shows "Year Overview", month 6 is NOT in outline, other months appear with auto titles
  - Fix any failing tests before proceeding

  **Completed:** All 12 new auto_outline tests pass. All 21 declaration_context tests pass. The test_project_planner.rb script successfully generates the PDF with 13 outline entries (not 14 - June is suppressed). Pre-existing failures in standard_planner tests are unrelated to this phase.
