# frozen_string_literal: true

# Project Planner Recipe
#
# A minimal project planner for testing the convention-based outline system.
# This recipe uses inline pages for cover and notes, with 12 MonthlyOverview
# pages in between.
#
# Page structure:
# - Cover page (inline)
# - 12 monthly overview pages (January through December)
# - Notes page (inline)
#
# Note: This recipe intentionally does NOT use `outline:` parameters on pages.
# It serves as a baseline test before adding convention-based outline logic.
#
# @example Generate a project planner
#   BujoPdf.generate_from_recipe :project_planner, year: 2025, output: 'project_planner_2025.pdf'
#
BujoPdf.define_pdf :project_planner do |year:, theme: nil|
  metadata do
    title "Project Planner #{year}"
    author 'BujoPdf'
    creator 'BujoPdf PDF DSL'
    subject "Project planner for #{year}"
  end

  theme theme if theme

  # Cover page (inline)
  page id: :cover do
    layout :full_page

    body do
      h1(0, 20, "Project Planner", width: 43, align: :center)
      h2(0, 24, year.to_s, width: 43, align: :center)
    end
  end

  # 12 monthly overview pages
  12.times do |i|
    month = i + 1
    page :monthly_overview, id: :"month_#{month}", month: month, year: year
  end

  # Notes page (inline)
  page id: :notes do
    layout :full_page
    background :dot_grid

    body do
      h1(2, 2, "Notes", width: 39)
      ruled_lines(2, 5, 39, 48)
    end
  end
end
