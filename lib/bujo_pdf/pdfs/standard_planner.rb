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

  # Default chrome configuration for all pages
  # Pages inherit these sidebars unless they opt out with chrome: false
  chrome do
    left :week_sidebar
    right :tab_sidebar do
      tab "Year", dest: :seasonal
      tab "Future", dest: [:future_log_1, :future_log_2]
      tab "Events", dest: :year_events
      tab "Highlights", dest: :year_highlights
      tab "Multi", dest: :multi_year
      tab "Grids", dest: [:grid_showcase, :grids_overview, :grid_dot, :grid_graph, :grid_lined, :grid_isometric, :grid_perspective, :grid_hexagon]
    end
  end

  # 1. Front matter: Seasonal calendar, Index, Future log
  page :seasonal, id: :seasonal, year: year, outline: true

  # Index pages (2 pages with numbered lines for TOC entries)
  # Full page layout - no sidebars
  2.times do |i|
    page :index, id: :"index_#{i + 1}",
         index_page_num: i + 1,
         index_page_count: 2,
         year: year,
         chrome: false,
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
  outline_entry :quarter_1, 'Quarterly Planning'
  outline_entry :review_1, 'Monthly Reviews'

  generated_months = []
  first_week_of_month = {}

  weeks_in(year).each do |week|
    next unless week.overlaps_year?

    # Use primary_month for interleaving - nil for cross-year weeks (like week 1)
    month = week.primary_month

    # Insert monthly/quarterly pages at start of each month
    # Skip for weeks with nil primary_month (cross-year boundary weeks)
    if month && !generated_months.include?(month)
      first_week_of_month[month] ||= week.number

      # Quarterly planning at start of each quarter (full page - no sidebars)
      if [1, 4, 7, 10].include?(month)
        quarter = ((month - 1) / 3) + 1
        page :quarterly_planning, id: :"quarter_#{quarter}", quarter: quarter, year: year, chrome: false
      end

      # Monthly review (full page - no sidebars)
      page :monthly_review, id: :"review_#{month}", month: month, review_month: month, year: year, chrome: false

      # Month outline entry
      month_name = Date::MONTHNAMES[month]
      outline_entry :"week_#{first_week_of_month[month]}", "#{month_name} #{year}"

      generated_months << month
    end

    page :weekly, id: :"week_#{week.number}", week: week
  end

  # 4. Grid pages group with cycling navigation
  # Group's outline entry links to first page; individual pages use registered titles
  # Grid pages use full page layout (chrome: false) except grids_overview which has sidebars
  group :grids, cycle: true, outline: 'Grid Types Showcase' do
    page :grid_showcase, id: :grid_showcase, chrome: false
    page :grids_overview, id: :grids_overview, outline: true
    page :grid_dot, id: :grid_dot, outline: true, chrome: false
    page :grid_graph, id: :grid_graph, outline: true, chrome: false
    page :grid_lined, id: :grid_lined, outline: true, chrome: false
    page :grid_isometric, id: :grid_isometric, outline: true, chrome: false
    page :grid_perspective, id: :grid_perspective, outline: true, chrome: false
    page :grid_hexagon, id: :grid_hexagon, outline: true, chrome: false
  end

  # 5. Template pages - use outline: true to pull from registered page titles
  # All template pages use full page layout (no sidebars)
  page :tracker_example, id: :tracker_example, outline: true, chrome: false
  page :reference, id: :reference, outline: true, chrome: false
  page :daily_wheel, id: :daily_wheel, outline: true, chrome: false
  page :year_wheel, id: :year_wheel, outline: true, chrome: false

  # 6. Collections (user-configured via config/collections.yml)
  # Collection pages use full page layout (no sidebars)
  BujoPdf::CollectionsConfiguration.load.each do |collection|
    page :collection, id: :"collection_#{collection.id}",
         collection_id: collection.id,
         collection_title: collection.title,
         collection_subtitle: collection.subtitle,
         year: year,
         chrome: false,
         outline: collection.title
  end
end
