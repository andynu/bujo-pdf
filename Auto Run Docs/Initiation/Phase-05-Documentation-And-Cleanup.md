# Phase 05: Documentation and Cleanup

This phase documents the new convention-based outline system, cleans up the test artifacts, and notes the layout refactoring work for future implementation. The experiment is complete and ready for potential adoption in the standard planner.

## Tasks

- [x] Update the CLAUDE.md project documentation:
  - Add a "Convention-Based Outline" section under the DSL documentation
  - Document `outline_mode :auto | :manual | :none` with examples
  - Document the override mechanism: `outline: false`, `outline: "Custom Title"`
  - Document how groups create hierarchical outline entries in auto mode
  - Note that `:manual` is the default (backward compatible with existing recipes)

  **Completed:** Added comprehensive "Convention-Based Outline System" section to CLAUDE.md covering:
  - Outline modes (`:manual`, `:auto`, `:none`) with example usage
  - Per-page override mechanisms (`outline: false`, `outline: "Title"`, `outline: true`)
  - Group hierarchy behavior in auto mode with examples
  - Manual `outline_section` usage for fine-grained control

- [ ] Add inline documentation to the modified files:
  - In `lib/bujo_pdf/dsl/context.rb`: Add YARD docs to `outline_mode` method
  - Document the auto-outline resolution logic in `create_standard_page` and `create_inline_page`
  - Document the group hierarchy behavior in the `group` method

- [ ] Clean up the test script:
  - Move `test_project_planner.rb` to `examples/project_planner_example.rb`
  - Update the script to include comments explaining what it demonstrates
  - Add it to `.gitignore` if example outputs shouldn't be committed, OR
  - Add a cleanup step that removes the generated PDF after verification

- [ ] Create a future work note for layout refactoring:
  - Create `docs/future/layout-sidebar-decoupling.md` with front matter:
    ```yaml
    ---
    type: note
    title: Layout and Sidebar Decoupling
    created: <today's date>
    tags:
      - future-work
      - layout-system
      - dsl-evolution
    related:
      - "[[Convention-Based-Outline]]"
    ---
    ```
  - Document the problem: sidebars are specific to standard planner
  - Document the goal: parameterized/composable layouts
  - List potential approaches discussed in the conversation
  - This captures the context for when this work is tackled later

- [ ] Run final verification:
  - Execute `bundle exec rake test` - all tests should pass
  - Execute `bundle exec ruby examples/project_planner_example.rb`
  - Generate the standard planner: `bundle exec bin/bujo-pdf 2025`
  - Verify standard planner is unchanged (still uses manual outline mode by default)
  - Commit all changes with message: "Add convention-based outline system for PDF DSL"
