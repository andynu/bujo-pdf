# Phase 02: Automatic Outline Generation

This phase implements the core convention-based outline system. Pages will automatically generate outline entries based on their registered titles. The key insight is that `PageRegistry` already has `generate_title(params)` - we just need the builder to use it automatically.

## Tasks

- [x] Add an `outline_mode` DSL method to `DeclarationContext` (`lib/bujo_pdf/dsl/context.rb`):
  - Add `@outline_mode` instance variable, defaulting to `:manual` (current behavior)
  - Add `attr_reader :outline_mode`
  - Add `def outline_mode(mode)` method that sets `@outline_mode = mode`
  - Supported modes: `:manual` (current behavior), `:auto` (generate from page registry), `:none` (no outline)
  - This allows recipes to opt into automatic outline generation
  - **Completed**: Added `@current_outline_mode` instance variable with `attr_reader :current_outline_mode`, and `outline_mode(mode)` method with validation for `:manual`, `:auto`, `:none` modes.

- [x] Modify `create_standard_page` in `DeclarationContext` to support auto-outline:
  - After creating the `PageDeclaration`, check if `@outline_mode == :auto` AND `outline` param was not explicitly provided
  - If so, resolve the title from `PageFactory.registry[type]&.generate_title(params)`
  - If a title is resolved, add it as an outline entry (same as if `outline: true` was passed)
  - If `outline: false` was explicitly passed, skip adding entry regardless of mode
  - This makes pages "opt-out" instead of "opt-in" when auto mode is enabled
  - **Completed**: Updated `create_standard_page` to handle `:none` mode (no outline entries), `:auto` mode (treats nil as true), and respects explicit `outline: false`.

- [x] Modify `create_inline_page` in `DeclarationContext` to support auto-outline:
  - When `@outline_mode == :auto` and no explicit `outline:` param, use the `id:` to generate a title
  - Convert id to title: `id.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')`
  - Example: `id: :project_notes` becomes "Project Notes"
  - If `outline: false` was explicitly passed, skip adding entry
  - **Completed**: Updated `create_inline_page` with same mode logic - `:none` suppresses all, `:auto` auto-generates from id.

- [x] Update the project planner recipe to use auto outline mode:
  - Add `outline_mode :auto` at the top of the recipe block (after metadata/theme)
  - Remove any explicit `outline:` params that were added for testing (if any)
  - The monthly overview pages should now automatically appear in the outline
  - The inline cover and notes pages should also appear (using their id-derived titles)
  - **Completed**: Added `outline_mode :auto` to `lib/bujo_pdf/pdfs/project_planner.rb` and updated documentation.
  - **Note**: Also fixed `MonthlyOverview` page registration to use a Proc for title generation since it receives `month:` (integer) not `month_name:`.

- [x] Run the test script and verify automatic outline generation:
  - Execute `bundle exec ruby test_project_planner.rb`
  - Open the generated PDF and check the outline/bookmarks panel
  - Verify: Cover page, all 12 months (by name), and Notes page appear in outline
  - The entries should be flat (no hierarchy) - that's expected for this phase
  - **Completed**: Test script runs successfully. Verified 14 outline entries are generated:
    - Cover -> cover
    - January Overview -> month_1
    - February Overview -> month_2
    - ... (all 12 months)
    - Notes -> notes
  - Added 9 new unit tests for outline_mode functionality - all pass.
