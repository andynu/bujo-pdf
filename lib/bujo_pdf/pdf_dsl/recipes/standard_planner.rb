# frozen_string_literal: true

# Standard Planner Recipe
#
# Defines the standard BujoPdf planner structure that matches
# the output of PlannerGenerator. This recipe validates that
# the PDF DSL can fully replace the existing generator.
#
# Page structure:
# - Seasonal calendar
# - Year events
# - Year highlights
# - Multi-year overview (4 years)
# - Weekly pages (52-53 depending on year)
# - Grid showcase
# - Grid pages (overview, dot, graph, lined, isometric, perspective, hexagon)
# - Reference/calibration
# - Daily wheel
# - Year wheel
#
# @example Generate a standard planner
#   BujoPdf.generate_from_recipe :standard_planner, year: 2025, output: 'planner_2025.pdf'
#
BujoPdf.define_pdf :standard_planner do |year:, theme: nil|
  metadata do
    title "Planner #{year}"
    author 'BujoPdf'
    creator 'BujoPdf PDF DSL'
    subject "Year planner for #{year}"
  end

  theme theme if theme

  # Year overview pages
  page :seasonal, id: :seasonal, year: year
  page :year_events, id: :year_events, year: year
  page :year_highlights, id: :year_highlights, year: year
  page :multi_year, id: :multi_year, year: year, year_count: 4

  # Weekly pages
  weeks_in(year).each do |week|
    page :weekly, id: :"week_#{week.number}", week: week
  end

  # Grid pages group with cycling navigation
  group :grids, cycle: true do
    page :grid_showcase, id: :grid_showcase
    page :grids_overview, id: :grids_overview
    page :grid_dot, id: :grid_dot
    page :grid_graph, id: :grid_graph
    page :grid_lined, id: :grid_lined
    page :grid_isometric, id: :grid_isometric
    page :grid_perspective, id: :grid_perspective
    page :grid_hexagon, id: :grid_hexagon
  end

  # Template pages
  page :reference, id: :reference
  page :daily_wheel, id: :daily_wheel
  page :year_wheel, id: :year_wheel
end
