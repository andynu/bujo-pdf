# frozen_string_literal: true

# Project Planner Recipe
#
# A minimal project planner for testing the convention-based outline system.
# This recipe uses inline pages for cover and notes, with 12 MonthlyOverview
# pages in between.
#
# Page structure:
# - Cover page (inline) with outline override: "Year Overview"
# - 12 monthly overview pages (January through December)
#   - Month 6 (June) suppressed from outline with outline: false
# - Notes page (inline) with auto-generated outline title
#
# This recipe demonstrates all three outline behaviors in auto mode:
# 1. Auto-generated titles (most months, notes page)
# 2. Custom override title (cover page: "Year Overview")
# 3. Suppressed entry (June: outline: false)
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
  outline_mode :auto

  # Cover page (inline) - demonstrates outline title override
  # Instead of auto-generating "Cover" from the id, we override with "Year Overview"
  page id: :cover, outline: 'Year Overview' do
    layout :full_page

    body do
      h1(0, 20, "Project Planner", width: 43, align: :center)
      h2(0, 24, year.to_s, width: 43, align: :center)
    end
  end

  # 12 monthly overview pages
  # - Most months use auto-generated titles from the page registry
  # - Month 6 (June) demonstrates suppression with outline: false
  12.times do |i|
    month = i + 1
    if month == 6
      # Suppress June from the outline (demonstrates outline: false in auto mode)
      page :monthly_overview, id: :"month_#{month}", month: month, year: year, outline: false
    else
      # Auto-generate outline title from page registry
      page :monthly_overview, id: :"month_#{month}", month: month, year: year
    end
  end

  # Notes page (inline) - uses auto-generated title "Notes" from id
  page id: :notes do
    layout :full_page
    background :dot_grid

    body do
      h1(2, 2, "Notes", width: 39)
      ruled_lines(2, 5, 39, 48)
    end
  end
end
