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
  page :seasonal, id: :seasonal, year: year, outline: true

  # Index pages (2 pages with numbered lines for TOC entries)
  2.times do |i|
    page :index, id: :"index_#{i + 1}",
         index_page_num: i + 1,
         index_page_count: 2,
         year: year,
         outline: i.zero?  # Only first page gets outline entry
  end

  # Future log pages (2 pages covering 12 months)
  2.times do |i|
    page :future_log, id: :"future_log_#{i + 1}",
         future_log_page: i + 1,
         future_log_page_count: 2,
         future_log_start_month: (i * 6) + 1,
         year: year,
         outline: i.zero?  # Only first page gets outline entry
  end

  # 2. Year overview pages
  page :year_events, id: :year_events, year: year, outline: true
  page :year_highlights, id: :year_highlights, year: year, outline: true
  page :multi_year, id: :multi_year, year: year, year_count: 4, outline: true

  # 3. Weekly pages with interleaved monthly reviews and quarterly planning
  generated_months = []

  # First outline entry for Quarterly Planning (links to first quarter)
  outline_entry :quarter_1, 'Quarterly Planning'
  # First outline entry for Monthly Reviews (links to first month)
  outline_entry :review_1, 'Monthly Reviews'

  # Pre-calculate first week of each month for outline entries
  first_week_of_month = {}
  weeks_in(year).each do |week|
    if week.in_year?
      month = week.month
      first_week_of_month[month] ||= week.number
    end
  end

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

        # Add month outline entry linking to first week of the month
        month_name = Date::MONTHNAMES[month]
        first_week = first_week_of_month[month]
        outline_entry :"week_#{first_week}", "#{month_name} #{year}"

        generated_months << month
      end
    end

    page :weekly, id: :"week_#{week.number}", week: week
  end

  # 4. Grid pages group with cycling navigation
  # Group's outline entry links to first page; individual pages use registered titles
  group :grids, cycle: true, outline: 'Grid Types Showcase' do
    page :grid_showcase, id: :grid_showcase
    page :grids_overview, id: :grids_overview, outline: true
    page :grid_dot, id: :grid_dot, outline: true
    page :grid_graph, id: :grid_graph, outline: true
    page :grid_lined, id: :grid_lined, outline: true
    page :grid_isometric, id: :grid_isometric, outline: true
    page :grid_perspective, id: :grid_perspective, outline: true
    page :grid_hexagon, id: :grid_hexagon, outline: true
  end

  # 5. Template pages - use outline: true to pull from registered page titles
  page :tracker_example, id: :tracker_example, outline: true
  page :reference, id: :reference, outline: true
  page :daily_wheel, id: :daily_wheel, outline: true
  page :year_wheel, id: :year_wheel, outline: true

  # 6. Collections (user-configured via config/collections.yml)
  BujoPdf::CollectionsConfiguration.load.each do |collection|
    page :collection, id: :"collection_#{collection.id}",
         collection_id: collection.id,
         collection_title: collection.title,
         collection_subtitle: collection.subtitle,
         year: year,
         outline: collection.title
  end
end
