# frozen_string_literal: true

# Standard Planner Recipe
#
# Defines the standard BujoPdf planner structure that matches
# the output of PlannerGenerator. This recipe validates that
# the PDF DSL can fully replace the existing generator.
#
# Page structure:
# - Index pages (2)
# - Seasonal calendar
# - Year events
# - Year highlights
# - Multi-year overview
# - Future log pages (2)
# - Ritual deck (only with rituals: true)
# - Quarterly planning + Monthly reviews + Weekly pages (interleaved)
# - Grid pages (index, dot, isometric, 1-point and 2-point perspective, graph, lined, hexagon)
# - Tracker example
# - Reference/calibration
# - Daily wheel
# - Year wheel
# - Collection pages (user-configured)
#
# @example Generate a standard planner
#   BujoPdf.generate_from_recipe :standard_planner, year: 2026, output: 'planner_2026.pdf'
#
BujoPdf.define_pdf :standard_planner do |year:, theme: nil, rituals: false|
  metadata do
    title "Planner #{year}"
    author 'BujoPdf'
    creator 'BujoPdf PDF DSL'
    subject "Year planner for #{year}"
  end

  theme theme if theme

  # Every page carries both navs: months on the left (the current month opens
  # to its weeks), sections on the right (the current section opens to its
  # pages). The sections and months are declared at the end, once every page
  # id is known.
  chrome do
    left :calendar_nav
    right :section_nav
  end

  # Ritual deck: pages from assets/ritual_deck, inserted as they are with the
  # nav drawn over them.
  if rituals
    deck = import_pdf(File.expand_path('../../../assets/ritual_deck/manifest.yml', __dir__), prefix: :ritual)
  end

  # 1. Front matter: Index, the year set, Future log. Each nav section is one
  # run of pages, so the year set (seasonal calendar and overviews) stays together.
  # Index pages (2 pages with numbered lines for TOC entries)
  2.times do |i|
    page :index, id: :"index_#{i + 1}",
         index_page_num: i + 1,
         index_page_count: 2,
         year: year,
         outline: i.zero?  # Only first page gets outline entry
  end

  # 2. Year set: seasonal calendar and year overview pages
  page :seasonal, id: :seasonal, year: year, outline: true
  page :year_events, id: :year_events, year: year, outline: true
  page :year_highlights, id: :year_highlights, year: year, outline: true
  page :multi_year, id: :multi_year, year: year, year_count: 4, outline: true

  # Future log pages (2 pages covering 12 months)
  2.times do |i|
    page :future_log, id: :"future_log_#{i + 1}",
         future_log_page: i + 1,
         future_log_page_count: 2,
         future_log_start_month: (i * 6) + 1,
         year: year,
         outline: i.zero?  # Only first page gets outline entry
  end

  if rituals
    group :rituals, outline: 'Rituals' do
      import_pages deck, outline: true
    end
  end

  # 3. Weekly pages with interleaved monthly reviews and quarterly planning
  outline_entry :quarter_1, 'Quarterly Planning'
  outline_entry :review_1, 'Monthly Reviews'

  # Monthly reviews are retrospective ("What Worked" / "What Didn't Work"), so
  # each one is emitted *after* the last week of the month it reviews. That
  # makes a month boundary read: [review of the month just finished] ->
  # [quarterly planning, if a new quarter starts] -> [weeks of the new month].
  # December's review is flushed after the final weekly page.
  generated_months = []
  first_week_of_month = {}
  month_awaiting_review = nil
  # Calendar nav items per month, in PDF order
  month_items = Hash.new { |hash, month| hash[month] = [] }

  emit_monthly_review = lambda do |month|
    page :monthly_review, id: :"review_#{month}", month: month, review_month: month, year: year
    # Listed under the month's own entry, so the label leaves the month name out
    month_items[month] << [:"review_#{month}", 'Review']
  end

  weeks_in(year).each do |week|
    next unless week.overlaps_year?

    # interleaving_month never returns nil for a week in the planner, so
    # cross-year weeks (like week 1) are filed under the month they end in.
    month = week.interleaving_month

    # Insert monthly/quarterly pages at the start of each month
    if month && !generated_months.include?(month)
      # Close out the previous month before opening the new one
      emit_monthly_review.call(month_awaiting_review) if month_awaiting_review

      # Quarterly planning at start of each quarter
      if [1, 4, 7, 10].include?(month)
        quarter = ((month - 1) / 3) + 1
        page :quarterly_planning, id: :"quarter_#{quarter}", quarter: quarter, year: year
        month_items[month] << [:"quarter_#{quarter}", "Q#{quarter}"]
      end

      first_week_of_month[month] ||= week.number

      # Month outline entry
      month_name = Date::MONTHNAMES[month]
      outline_entry :"week_#{first_week_of_month[month]}", "#{month_name} #{year}"

      generated_months << month
      month_awaiting_review = month
    end

    page :weekly, id: :"week_#{week.number}", week: week
    month_items[month] << [:"week_#{week.number}", format('w%02d', week.number)]
  end

  # Final month's review, after its last weekly page
  emit_monthly_review.call(month_awaiting_review) if month_awaiting_review

  # 4. Grid pages, in nav order after the grids index
  # Group's outline entry links to first page; individual pages use registered titles
  group :grids, outline: 'Grids' do
    page :grids_index, id: :grids_index
    page :grid_dot, id: :grid_dot, outline: true
    page :grid_isometric, id: :grid_isometric, outline: true
    page :grid_perspective, id: :grid_perspective, outline: true
    page :grid_perspective_2, id: :grid_perspective_2, outline: true
    page :grid_graph, id: :grid_graph, outline: true
    page :grid_lined, id: :grid_lined, outline: true
    page :grid_hexagon, id: :grid_hexagon, outline: true
  end

  # 5. Template pages - use outline: true to pull from registered page titles
  page :tracker_example, id: :tracker_example, outline: true
  # Its calibration rulers run along the physical left edge, under the calendar nav
  page :reference, id: :reference, outline: true, chrome: { left: false }
  page :daily_wheel, id: :daily_wheel, outline: true
  page :year_wheel, id: :year_wheel, outline: true

  # 6. Collections (user-configured via config/collections.yml)
  collections = BujoPdf::CollectionsConfiguration.load
  collections.each do |collection|
    page :collection, id: :"collection_#{collection.id}",
         collection_id: collection.id,
         collection_title: collection.title,
         collection_subtitle: collection.subtitle,
         year: year,
         outline: collection.title
  end

  # Navigation. Sections are listed in the order they appear in the PDF, and
  # each one is a single run of pages.
  nav_section :index, label: 'Index', items: [[:index_1, 'Index 1'], [:index_2, 'Index 2']]
  nav_section :year, label: 'Year', items: [
    [:seasonal, 'Seasonal'], [:year_events, 'Events'], [:year_highlights, 'Highlights'], [:multi_year, 'Multi']
  ]
  nav_section :future, label: 'Future', items: [[:future_log_1, 'Jan-Jun'], [:future_log_2, 'Jul-Dec']]
  if rituals
    nav_section :rituals, label: 'Rituals',
                          items: deck.pages.map { |entry| [deck.page_id(entry.key), entry.nav || entry.title] }
  end
  nav_section :grids, label: 'Grids', landing: :grids_index, items: [
    [:grid_dot, 'Dot'], [:grid_isometric, 'Iso'], [:grid_perspective, '1pp'], [:grid_perspective_2, '2pp'],
    [:grid_graph, 'Graph'], [:grid_lined, 'Ruled'], [:grid_hexagon, 'Hex']
  ]
  nav_section :templates, label: 'Templates', items: [
    [:tracker_example, 'Tracker'], [:reference, 'Reference'], [:daily_wheel, 'Daily Wheel'], [:year_wheel, 'Year Wheel']
  ]
  nav_section :collections, label: 'Collections',
                            items: collections.map { |collection| [:"collection_#{collection.id}", collection.title] }

  first_week_of_month.each do |month, week_number|
    nav_month month, first_week: :"week_#{week_number}", items: month_items[month]
  end
end
