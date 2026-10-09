# frozen_string_literal: true

# Monthly Planner Recipe
#
# A simplified planner focused on monthly planning without weekly pages.
# Includes monthly reviews and quarterly planning, but no weekly spreads.
#
# Page structure:
# - Seasonal calendar
# - Index pages (2)
# - Future log pages (2)
# - Year events
# - Year highlights
# - Multi-year overview
# - Quarterly planning + Monthly reviews (interleaved)
# - Grid pages
# - Template pages
# - Collection pages
#
# @example Generate a monthly planner
#   BujoPdf.generate_from_recipe :monthly, year: 2025, output: 'monthly_2025.pdf'
#
BujoPdf.define_pdf :monthly do |year:, theme: nil|
  metadata do
    title "Monthly Planner #{year}"
    author 'BujoPdf'
    creator 'BujoPdf PDF DSL'
    subject "Monthly planner for #{year}"
  end

  theme theme if theme

  # 1. Front matter: Seasonal calendar, Index, Future log
  page :seasonal, id: :seasonal, year: year, outline: true

  2.times do |i|
    page :index, id: :"index_#{i + 1}",
         index_page_num: i + 1,
         index_page_count: 2,
         year: year,
         outline: i.zero?
  end

  2.times do |i|
    page :future_log, id: :"future_log_#{i + 1}",
         future_log_page: i + 1,
         future_log_page_count: 2,
         future_log_start_month: (i * 6) + 1,
         year: year,
         outline: i.zero?
  end

  # 2. Year overview pages
  page :year_events, id: :year_events, year: year, outline: true
  page :year_highlights, id: :year_highlights, year: year, outline: true
  page :multi_year, id: :multi_year, year: year, year_count: 4, outline: true

  # 3. Monthly pages with quarterly planning
  outline_entry :quarter_1, 'Quarterly Planning'
  outline_entry :review_1, 'Monthly Reviews'

  months_in(year).each do |month|
    # Quarterly planning at start of each quarter
    if [1, 4, 7, 10].include?(month.number)
      quarter = ((month.number - 1) / 3) + 1
      page :quarterly_planning, id: :"quarter_#{quarter}",
           quarter: quarter,
           year: year
    end

    # Monthly review
    page :monthly_review, id: :"review_#{month.number}",
         month: month.number,
         review_month: month.number,
         year: year,
         outline: "#{month.name} #{year}"
  end

  # 4. Grid pages
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

  # 5. Template pages
  page :tracker_example, id: :tracker_example, outline: true
  page :reference, id: :reference, outline: true
  page :daily_wheel, id: :daily_wheel, outline: true
  page :year_wheel, id: :year_wheel, outline: true

  # 6. Collections
  BujoPdf::CollectionsConfiguration.load.each do |collection|
    page :collection, id: :"collection_#{collection.id}",
         collection_id: collection.id,
         collection_title: collection.title,
         collection_subtitle: collection.subtitle,
         year: year,
         outline: collection.title
  end
end


