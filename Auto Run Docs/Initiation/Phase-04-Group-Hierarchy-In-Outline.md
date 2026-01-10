# Phase 04: Group Hierarchy in Outline

This phase makes groups create hierarchical outline entries. When a group contains pages and `outline_mode :auto` is enabled, the group's pages become children of a parent entry. This creates natural nesting without explicit `outline_section` calls.

## Tasks

- [x] Add tests for group outline hierarchy:
  - Add test cases to `test/unit/dsl/auto_outline_test.rb`
  - Test case: Group with `outline_mode :auto` creates parent entry from group name
  - Test case: Pages inside group become children of the group's outline entry
  - Test case: Group with explicit `outline: "Title"` uses that title as parent
  - Test case: Group with `outline: false` suppresses the group entry (pages still appear at root level)
  - Test case: Nested groups create nested outline hierarchy

  **Completed:** Added 8 new test cases covering all scenarios:
  - `test_group_with_auto_mode_creates_parent_entry_from_group_name`
  - `test_pages_inside_group_become_children_of_group_outline_entry`
  - `test_group_with_explicit_outline_uses_that_title_as_parent`
  - `test_group_with_outline_false_suppresses_group_entry`
  - `test_nested_groups_create_nested_outline_hierarchy`
  - `test_group_section_destination_is_first_page`
  - `test_group_in_manual_mode_does_not_auto_generate_section`
  - `test_group_with_explicit_outline_in_manual_mode_creates_section`

- [x] Modify group outline handling in `DeclarationContext#group`:
  - When `@outline_mode == :auto` and no explicit `outline:` param, derive title from group name
  - Convert name to title: `name.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')`
  - Example: `:monthly_pages` becomes "Monthly Pages"
  - Store the derived/explicit outline title for later use

  **Completed:** Added `determine_group_outline_title` helper method that handles:
  - `outline: false` -> no section created
  - `outline: "Title"` -> uses explicit title
  - `outline: nil` + auto mode -> derives title from group name
  - `outline: nil` + manual mode -> no section created

- [x] Create group outline sections automatically in `DeclarationContext#group`:
  - When group has an outline title (derived or explicit), create an `OutlineDeclaration` section
  - Set `@current_section` to this section before evaluating the group block
  - Pages declared inside the group will automatically become children (existing logic in `add_outline_entry`)
  - Restore `@current_section` after the block (existing logic handles this)
  - The section's destination should be the first page in the group

  **Completed:** Rewrote `group` method to leverage existing `outline_section` with `dest: :first` option. This reuses the proven section nesting logic and automatically links the section header to the first child's destination.

- [x] Update the project planner to use a group:
  - Wrap the 12 monthly pages in a `group :months do ... end` block
  - With `outline_mode :auto`, this should create: "Months" parent with 12 month children
  - The cover and notes pages remain at root level (outside the group)

  **Completed:** Updated `lib/bujo_pdf/pdfs/project_planner.rb` to wrap the 12 monthly pages in a `group :months` block. Also updated documentation and `test_project_planner.rb` to reflect the new hierarchical structure.

- [x] Run tests and verify hierarchical outline:
  - Execute `bundle exec rake test`
  - Execute `bundle exec ruby test_project_planner.rb`
  - Open PDF and verify outline structure:
    - "Year Overview" (cover) at root
    - "Months" section with 12 month children indented
    - "Notes" at root
  - Fix any issues before proceeding

  **Completed:** All 20 auto_outline_test.rb tests pass (57 assertions). Project planner generates successfully. Full test suite shows 4 pre-existing failures unrelated to this feature (standard_planner page count issues that existed before these changes).
