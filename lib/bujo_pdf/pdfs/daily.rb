# frozen_string_literal: true

# Daily Planner Recipe
#
# A planner with a dedicated page for each day of the year.
# Perfect for detailed daily planning and journaling.
#
# Page structure:
# - Seasonal calendar
# - Index pages (2)
# - Future log pages (2)
# - Year events
# - Year highlights
# - Multi-year overview
# - Daily pages (365/366 pages, one per day)
# - Grid pages
# - Template pages
# - Collection pages
#
# @example Generate a daily planner
#   BujoPdf.generate_from_recipe :daily, year: 2025, output: 'daily_2025.pdf'
#
BujoPdf.define_pdf :daily do |year:, theme: nil|
  metadata do
    title "Daily Planner #{year}"
    author 'BujoPdf'
    creator 'BujoPdf PDF DSL'
    subject "Daily planner for #{year}"
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

  # 3. Daily pages - one per day of the year
  outline_entry :"day_#{Date.new(year, 1, 1).strftime('%Y%m%d')}", 'Daily Pages'

  start_date = Date.new(year, 1, 1)
  end_date = Date.new(year, 12, 31)
  
  (start_date..end_date).each do |date|
    day_id = date.strftime('%Y%m%d')
    day_title = date.strftime('%B %-d, %Y')
    day_name = date.strftime('%A')
    
    page id: :"day_#{day_id}", outline: day_title do
      layout :daily_with_sidebars, year: year
      background :dot_grid

      body do
        # Header with date
        h1(2, 1, day_title, width: 38)
        h2(2, 2, day_name, width: 38)
        
        # Tasks section
        # Fieldset: col=2, row=4, width=38, height=12
        # Border inset: 0.5 boxes, so border at col=2.5, row=4.5, width=37, height=11
        # Legend at top (row 4.0) takes ~1 row, so content starts at row 6
        # Available height: 12 - 0.5 (top) - 1 (legend) - 0.5 (bottom) = 10 rows
        # Each entry is 2 rows, so max 5 entries fit
        fieldset(2, 4, 38, 12, legend: 'Tasks')
        # Position: col=3 (0.5 inside border at 2.5), row=6 (below legend), width=36 (fits inside border)
        ruled_list(3, 6, 36, entries: 5, show_page_box: false)
        
        # Notes section
        # Fieldset: col=2, row=17, width=38, height=20
        # Border: col=2.5, row=17.5, width=37, height=19
        # Content starts below legend at row 19
        fieldset(2, 17, 38, 20, legend: 'Notes')
        ruled_lines(3, 19, 36, 17)
        
        # Events/Appointments section
        # Fieldset: col=2, row=38, width=38, height=8
        # Border: col=2.5, row=38.5, width=37, height=7
        # Content starts below legend at row 40
        fieldset(2, 38, 38, 8, legend: 'Events')
        ruled_lines(3, 40, 36, 5)
        
        # Reflection section
        # Fieldset: col=2, row=47, width=38, height=6
        # Border: col=2.5, row=47.5, width=37, height=5
        # Content starts below legend at row 49
        fieldset(2, 47, 38, 6, legend: 'Reflection')
        ruled_lines(3, 49, 36, 3)
      end
    end
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

