# frozen_string_literal: true

# Standard Planner Recipe
#
# Defines the standard BujoPdf planner structure that matches
# the output of PlannerGenerator. This recipe validates that
# the PDF DSL can fully replace the existing generator.
#
# Page structure:
# - Seasonal calendar
# - Index pages (2)
# - Future log pages (2)
# - Year events
# - Year highlights
# - Multi-year overview
# - Quarterly planning + Monthly reviews + Weekly pages (interleaved)
# - Grid pages (showcase, overview, dot, graph, lined, isometric, perspective, hexagon)
# - Tracker example
# - Reference/calibration
# - Daily wheel
# - Year wheel
# - Collection pages (user-configured)
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

  # 1. Front matter: Seasonal calendar, Index, Future log
  page :seasonal, id: :seasonal, year: year

  # Index pages (2 pages with numbered lines for TOC entries)
  2.times do |i|
    page :index, id: :"index_#{i + 1}",
         index_page_num: i + 1,
         index_page_count: 2,
         year: year
  end

  # Future log pages (2 pages covering 12 months)
  2.times do |i|
    page :future_log, id: :"future_log_#{i + 1}",
         future_log_page: i + 1,
         future_log_page_count: 2,
         future_log_start_month: (i * 6) + 1,
         year: year
  end

  # 2. Year overview pages
  page :year_events, id: :year_events, year: year
  page :year_highlights, id: :year_highlights, year: year
  page :multi_year, id: :multi_year, year: year, year_count: 4

  # 3. Weekly pages with interleaved monthly reviews and quarterly planning
  generated_months = []

  weeks_in(year).each do |week|
    # Insert interleaved pages for weeks that start in the target year
    if week.in_year?
      month = week.month

      unless generated_months.include?(month)
        # Quarterly planning at start of each quarter (months 1, 4, 7, 10)
        if [1, 4, 7, 10].include?(month)
          quarter = ((month - 1) / 3) + 1
          page :quarterly_planning, id: :"quarter_#{quarter}",
               quarter: quarter,
               year: year
        end

        # Monthly review for this month
        page :monthly_review, id: :"review_#{month}",
             month: month,
             review_month: month,
             year: year

        generated_months << month
      end
    end

    page :weekly, id: :"week_#{week.number}", week: week
  end

  # 4. Grid pages group with cycling navigation
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

  # 5. Template pages
  page :tracker_example, id: :tracker_example
  page :reference, id: :reference
  page :daily_wheel, id: :daily_wheel
  page :year_wheel, id: :year_wheel

  # 6. Collections (user-configured via config/collections.yml)
  # Load collections configuration if available
  collections_path = 'config/collections.yml'
  if File.exist?(collections_path)
    require 'yaml'
    config = YAML.safe_load(File.read(collections_path), permitted_classes: [Symbol]) || {}
    collections = config['collections'] || []

    collections.each do |collection|
      # Handle both string and symbol keys
      id = collection['id'] || collection[:id]
      title = collection['title'] || collection[:title]
      subtitle = collection['subtitle'] || collection[:subtitle]

      page :collection, id: :"collection_#{id}",
           collection_id: id,
           collection_title: title,
           collection_subtitle: subtitle,
           year: year
    end
  end
end
