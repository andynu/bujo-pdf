# Phase 01: Convention-Based Outline Prototype

This phase creates a minimal "project planner" recipe as a test bed for the convention-based outline system. By the end, you'll have a new PDF recipe that generates a working PDF with automatic outline entries derived from page registrations. The standard planner remains untouched.

## Tasks

- [x] Create the project planner recipe file at `lib/bujo_pdf/pdfs/project_planner.rb`:
  - Define a new recipe `:project_planner` using `BujoPdf.define_pdf`
  - Include minimal pages: cover (inline page), 12 monthly pages, and a notes section (inline page)
  - Use `layout: :full_page` to avoid sidebar complexity
  - Do NOT add any `outline:` parameters to pages yet - this tests the "no outline by default" baseline
  - The recipe should accept `year:` as a parameter
  - Use simple inline pages for cover and notes since we don't need new page classes

  **Completed:** Created `lib/bujo_pdf/pdfs/project_planner.rb` with cover page, 12 monthly_overview pages, and notes page. Recipe accepts `year:` and optional `theme:` parameters.

- [x] Create a simple MonthlyOverview page class at `lib/bujo_pdf/pages/monthly_overview.rb`:
  - Inherit from `Pages::Base`
  - Register with `register_page :monthly_overview, title: "%{month_name} Overview", dest: "month_%{month}"`
  - Accept `month:` and `year:` in context
  - Use `layout: :full_page` in setup
  - Render a simple page with: month name header, mini calendar for the month, and ruled lines for notes
  - This gives us a page type with a registered title for testing automatic outline generation

  **Completed:** Created `lib/bujo_pdf/pages/monthly_overview.rb` with registered page type, title interpolation, centered mini calendar, and notes section with ruled lines.

- [x] Wire up the MonthlyOverview page class:
  - Add require statement to `lib/bujo_pdf.rb` (after other page requires, before `pages/all.rb`)
  - Verify it's registered in PageFactory by checking the registry

  **Completed:** Added require statement in `lib/bujo_pdf.rb` at line 97. Verified registration in PageFactory.

- [x] Create a test script at `test_project_planner.rb` in the project root:
  - Load the bujo_pdf library
  - Call `BujoPdf::PdfDSL.load_recipes!` to load recipes
  - Generate the project planner: `BujoPdf.generate_from_recipe(:project_planner, year: 2025, output: 'project_planner_2025.pdf')`
  - Print success message with output filename

  **Completed:** Created `test_project_planner.rb` with recipe loading, PageFactory verification, and PDF generation.

- [x] Run the test script and verify the PDF generates:
  - Execute `bundle exec ruby test_project_planner.rb`
  - Open the generated PDF and verify: cover page exists, 12 monthly pages exist, notes page exists
  - Verify the PDF outline/bookmarks - it should be empty or minimal (no automatic entries yet)
  - This confirms the baseline works before adding convention-based outline logic

  **Completed:** PDF generates successfully (14 pages: 1 cover + 12 months + 1 notes). File size: 5.5MB. PDF has no outline entries as expected for baseline test.
