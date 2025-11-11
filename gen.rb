#!/usr/bin/env ruby
require 'prawn'
require 'date'

class PlannerGenerator
  # Page dimensions
  PAGE_WIDTH = 612    # 8.5 inches
  PAGE_HEIGHT = 792   # 11 inches

  # Global layout
  PAGE_MARGIN_HORIZONTAL = 40
  PAGE_MARGIN_TOP = 40
  FOOTER_HEIGHT = 25
  FOOTER_CLEARANCE = 10  # Extra space above footer

  # Seasonal Calendar Layout
  SEASONAL_TITLE_FONT_SIZE = 18
  SEASONAL_TITLE_Y_OFFSET = 40
  SEASONAL_GRID_MARGIN = 120
  SEASONAL_GRID_TOP_MARGIN = 140
  SEASONAL_GRID_X_OFFSET = 60
  SEASONAL_GRID_Y_OFFSET = 100
  SEASONAL_SEASON_HEADER_SIZE = 14
  SEASONAL_SEASON_HEADER_HEIGHT = 20
  SEASONAL_SEASON_SPACING = 30
  SEASONAL_MONTH_NAME_SIZE = 10
  SEASONAL_MONTH_NAME_DISPLAY_SIZE = 9
  SEASONAL_MONTH_NAME_X_OFFSET = 5
  SEASONAL_MONTH_NAME_Y_OFFSET = 2
  SEASONAL_MONTH_NAME_HEIGHT = 15
  SEASONAL_CAL_WIDTH_OFFSET = 40
  SEASONAL_CAL_HEIGHT_OFFSET = 20
  SEASONAL_CAL_X_START = 35
  SEASONAL_CAL_Y_HEADER = 17
  SEASONAL_CAL_Y_DAYS = 25
  SEASONAL_DAY_HEADER_SIZE = 6
  SEASONAL_DAY_SIZE = 7

  # Year at Glance Layout
  YEAR_TITLE_FONT_SIZE = 16
  YEAR_TOP_MARGIN = 80
  YEAR_START_Y = 100
  YEAR_MAX_ROWS = 32.0  # 31 days + 1 header
  YEAR_MONTH_HEADER_SIZE = 8
  YEAR_DAY_SIZE = 6
  YEAR_DAY_ABBREV_SIZE = 5
  YEAR_DAY_NUMBER_OFFSET = 2
  YEAR_DAY_ABBREV_HEIGHT = 8

  # Weekly Page - Overall Layout
  WEEKLY_TOP_MARGIN = 5  # Minimal gutter above title (3-4 pixels)
  WEEKLY_DAILY_SECTION_PERCENT = 0.175  # 17.5% of usable height (half of original 35%)
  WEEKLY_NOTES_SECTION_PERCENT = 0.825  # 82.5% of usable height

  # Weekly Page - Sidebar (vertical week navigation with months)
  WEEKLY_SIDEBAR_X = 5  # Distance from left edge of page
  WEEKLY_SIDEBAR_WIDTH = 25  # Width of sidebar (narrowed to save space)
  WEEKLY_SIDEBAR_GAP = 5  # Gap between sidebar and main content
  WEEKLY_SIDEBAR_FONT_SIZE = 7
  WEEKLY_SIDEBAR_MONTH_SPACING = 2  # Space between month letter and week number

  # Weekly Page - Top Navigation Area
  WEEKLY_NAV_HEIGHT = 20
  WEEKLY_NAV_YEAR_WIDTH = 60
  WEEKLY_NAV_YEAR_X_OFFSET = 0  # Offset from content start
  WEEKLY_NAV_PREV_WEEK_WIDTH = 60
  WEEKLY_NAV_PREV_WEEK_X_OFFSET = 70
  WEEKLY_NAV_NEXT_WEEK_WIDTH = 60
  WEEKLY_TITLE_FONT_SIZE = 14
  WEEKLY_TITLE_X_OFFSET = 140  # Space for nav links on left
  WEEKLY_TITLE_X_RESERVED = 210  # Total space reserved for nav (left + right)

  # Weekly Page - Daily Section (top 35%)
  WEEKLY_DAILY_TOP_SPACING = 15  # Space below title to prevent touching columns
  WEEKLY_DAY_HEADER_FONT_SIZE = 9
  WEEKLY_DAY_DATE_FONT_SIZE = 8
  WEEKLY_DAY_HEADER_HEIGHT = 30
  WEEKLY_DAY_HEADER_PADDING = 2
  WEEKLY_DAY_LINES_START = 35  # Y offset where lines start
  WEEKLY_DAY_LINES_PADDING = 40  # Bottom padding for lines
  WEEKLY_DAY_LINES_COUNT = 4.0
  WEEKLY_DAY_LINE_MARGIN = 3

  # Weekly Page - Cornell Notes Section (bottom 65%)
  WEEKLY_NOTES_TOP_GAP = 10  # Gap between daily and notes sections
  WEEKLY_CUES_WIDTH_PERCENT = 0.25  # 25% of width
  WEEKLY_NOTES_WIDTH_PERCENT = 0.75  # 75% of width
  WEEKLY_SUMMARY_HEIGHT_PERCENT = 0.20  # 20% of notes section height
  WEEKLY_SUMMARY_TOP_GAP = 5
  WEEKLY_NOTES_HEADER_FONT_SIZE = 10
  WEEKLY_NOTES_LABEL_FONT_SIZE = 9
  WEEKLY_NOTES_HEADER_PADDING = 3  # Padding below top border for section headers

  # Dot Grid
  DOT_SPACING = 14.17  # 5mm in points
  DOT_RADIUS = 0.5
  DOT_GRID_PADDING = 5

  # Colors
  COLOR_DOT_GRID = 'CCCCCC'  # Light gray for dots
  COLOR_BORDERS = 'E5E5E5'  # Lighter gray for borders (appears similar to dots despite continuous lines)
  COLOR_SECTION_HEADERS = 'AAAAAA'  # Muted gray for section headers

  # Footer
  FOOTER_LINE_Y_OFFSET = 2
  FOOTER_FONT_SIZE = 10
  FOOTER_TEXT_HEIGHT = 15
  FOOTER_TEXT_Y_OFFSET = 5

  def initialize(year)
    @year = year
    @month_names = Date::MONTHNAMES[1..12]
  end

  def generate(filename = "planner_#{@year}.pdf")
    Prawn::Document.generate(filename, page_size: 'LETTER', margin: 0) do |pdf|
      @pdf = pdf

      # Add bookmarks/named destinations
      setup_destinations

      # Generate all pages
      generate_seasonal_calendar
      generate_year_at_glance_events
      generate_year_at_glance_highlights
      generate_weekly_pages

      puts "Generated planner with #{pdf.page_count} pages"
    end
  end

  private

  def setup_destinations
    # We'll add destinations as we create pages
  end

  def generate_seasonal_calendar
    # Don't call start_new_page - Prawn creates the first page automatically
    @pdf.add_dest("seasonal", @pdf.dest_fit)

    draw_seasonal_calendar
    draw_footer
  end

  def draw_seasonal_calendar
    # Title
    @pdf.font "Helvetica-Bold", size: SEASONAL_TITLE_FONT_SIZE
    @pdf.text_box "Year #{@year}",
                  at: [PAGE_MARGIN_HORIZONTAL, PAGE_HEIGHT - SEASONAL_TITLE_Y_OFFSET],
                  width: PAGE_WIDTH - (PAGE_MARGIN_HORIZONTAL * 2),
                  align: :center

    # Define seasons with their months
    seasons = [
      { name: "Winter", months: [1, 2], color: '4A90E2' },
      { name: "Spring", months: [3, 4, 5], color: '7ED321' },
      { name: "Summer", months: [6, 7, 8], color: 'F5A623' },
      { name: "Fall", months: [9, 10, 11, 12], color: 'D0021B' }
    ]

    # Layout: 2x2 grid
    grid_width = (PAGE_WIDTH - SEASONAL_GRID_MARGIN) / 2.0
    grid_height = (PAGE_HEIGHT - SEASONAL_GRID_TOP_MARGIN - FOOTER_HEIGHT) / 2.0

    seasons.each_with_index do |season, idx|
      row = idx / 2
      col = idx % 2

      x = SEASONAL_GRID_X_OFFSET + (col * grid_width)
      y = PAGE_HEIGHT - SEASONAL_GRID_Y_OFFSET - (row * grid_height)

      draw_season_section(season, x, y, grid_width, grid_height)
    end
  end

  def draw_season_section(season, x, y, width, height)
    # Season header
    @pdf.font "Helvetica-Bold", size: SEASONAL_SEASON_HEADER_SIZE
    @pdf.text_box season[:name],
                  at: [x, y],
                  width: width,
                  height: SEASONAL_SEASON_HEADER_HEIGHT,
                  align: :center

    # Draw mini calendars for each month in this season
    month_height = (height - SEASONAL_SEASON_SPACING) / season[:months].length.to_f

    season[:months].each_with_index do |month, idx|
      month_y = y - SEASONAL_SEASON_SPACING - (idx * month_height)
      draw_mini_month_calendar(month, x, month_y, width, month_height)
    end
  end

  def draw_mini_month_calendar(month, x, y, width, height)
    # Month name
    @pdf.font "Helvetica-Bold", size: SEASONAL_MONTH_NAME_SIZE
    month_name = @month_names[month - 1]
    @pdf.text_box month_name,
                  at: [x + SEASONAL_MONTH_NAME_X_OFFSET, y - SEASONAL_MONTH_NAME_Y_OFFSET],
                  width: width - (SEASONAL_MONTH_NAME_X_OFFSET * 2),
                  height: SEASONAL_MONTH_NAME_HEIGHT,
                  size: SEASONAL_MONTH_NAME_DISPLAY_SIZE

    # Get calendar info
    first_day = Date.new(@year, month, 1)
    last_day = Date.new(@year, month, -1)
    days_in_month = last_day.day

    # Starting day of week (0=Sunday, 1=Monday, etc.)
    start_wday = first_day.wday

    # Convert to Monday-based (0=Monday, 6=Sunday)
    start_col = (start_wday + 6) % 7

    # Calculate dimensions
    cal_width = width - SEASONAL_CAL_WIDTH_OFFSET
    cal_height = height - SEASONAL_CAL_HEIGHT_OFFSET
    col_width = cal_width / 7.0
    row_height = cal_height / 6.0  # Max 6 rows needed

    # Draw day headers (M T W T F S S)
    @pdf.font "Helvetica", size: SEASONAL_DAY_HEADER_SIZE
    day_names = ['M', 'T', 'W', 'T', 'F', 'S', 'S']
    day_names.each_with_index do |day, i|
      @pdf.text_box day,
                    at: [x + SEASONAL_CAL_X_START + (i * col_width), y - SEASONAL_CAL_Y_HEADER],
                    width: col_width,
                    height: 10,
                    align: :center,
                    size: SEASONAL_DAY_HEADER_SIZE
    end

    # Draw days
    @pdf.font "Helvetica", size: SEASONAL_DAY_SIZE
    row = 0
    col = start_col

    # Calculate week numbers
    first_day_of_year = Date.new(@year, 1, 1)
    days_back = (first_day_of_year.wday + 6) % 7
    year_start_monday = first_day_of_year - days_back

    1.upto(days_in_month) do |day|
      date = Date.new(@year, month, day)

      # Calculate week number
      days_from_start = (date - year_start_monday).to_i
      week_num = (days_from_start / 7) + 1

      cell_x = x + SEASONAL_CAL_X_START + (col * col_width)
      cell_y = y - SEASONAL_CAL_Y_DAYS - (row * row_height)

      @pdf.text_box day.to_s,
                    at: [cell_x, cell_y],
                    width: col_width,
                    height: row_height,
                    align: :center,
                    valign: :center,
                    size: SEASONAL_DAY_SIZE

      # Add link for this day
      @pdf.link_annotation([cell_x, cell_y - row_height, cell_x + col_width, cell_y],
                          Dest: "week_#{week_num}",
                          Border: [0, 0, 0])

      col += 1
      if col >= 7
        col = 0
        row += 1
      end
    end
  end

  def generate_year_at_glance_events
    @pdf.start_new_page
    @pdf.add_dest("year_events", @pdf.dest_fit)

    draw_year_at_glance("Year #{@year} - Events")
    draw_footer
  end

  def generate_year_at_glance_highlights
    @pdf.start_new_page
    @pdf.add_dest("year_highlights", @pdf.dest_fit)

    draw_year_at_glance("Year #{@year} - Highlights")
    draw_footer
  end

  def draw_year_at_glance(title)
    # Title
    @pdf.font "Helvetica-Bold", size: YEAR_TITLE_FONT_SIZE
    @pdf.text_box title,
                  at: [PAGE_MARGIN_HORIZONTAL, PAGE_HEIGHT - PAGE_MARGIN_TOP],
                  width: PAGE_WIDTH - (PAGE_MARGIN_HORIZONTAL * 2),
                  align: :center

    # Calculate dimensions
    usable_height = PAGE_HEIGHT - YEAR_TOP_MARGIN - FOOTER_HEIGHT  # Leave space for title and footer
    usable_width = PAGE_WIDTH - (PAGE_MARGIN_HORIZONTAL * 2)  # Margins

    # Calculate cell dimensions - 31 rows (max days) + 1 header
    cell_height = usable_height / YEAR_MAX_ROWS
    cell_width = usable_width / 12.0

    start_x = PAGE_MARGIN_HORIZONTAL
    start_y = PAGE_HEIGHT - YEAR_START_Y

    # Draw header row with month names
    @pdf.font "Helvetica-Bold", size: YEAR_MONTH_HEADER_SIZE
    12.times do |i|
      month_name = @month_names[i]
      x = start_x + (i * cell_width)

      # Calculate which week contains the 1st of this month
      first_of_month = Date.new(@year, i + 1, 1)
      first_day_of_year = Date.new(@year, 1, 1)
      days_back = (first_day_of_year.wday + 6) % 7
      year_start_monday = first_day_of_year - days_back
      days_from_start = (first_of_month - year_start_monday).to_i
      week_num = (days_from_start / 7) + 1

      @pdf.bounding_box([x, start_y], width: cell_width, height: cell_height) do
        @pdf.stroke_color COLOR_BORDERS
        @pdf.stroke_bounds
        @pdf.stroke_color '000000'
        @pdf.text_box month_name[0..2],
                      at: [0, cell_height],
                      width: cell_width,
                      height: cell_height,
                      align: :center,
                      valign: :center
      end

      # Add clickable link using absolute coordinates (not inside bounding box)
      y_bottom = start_y - cell_height
      @pdf.link_annotation([x, y_bottom, x + cell_width, start_y],
                          Dest: "week_#{week_num}",
                          Border: [0, 0, 0])
    end

    # Draw day grid
    @pdf.font "Helvetica", size: YEAR_DAY_SIZE
    current_y = start_y - cell_height

    31.times do |day_index|
      day_num = day_index + 1

      12.times do |month_index|
        month = month_index + 1
        days_in_month = Date.new(@year, month, -1).day

        x = start_x + (month_index * cell_width)

        # Only draw if this day exists in this month
        if day_num <= days_in_month
          @pdf.bounding_box([x, current_y], width: cell_width, height: cell_height) do
            @pdf.stroke_color COLOR_BORDERS
            @pdf.stroke_bounds
            @pdf.stroke_color '000000'

            # Add day number in corner
            date = Date.new(@year, month, day_num)
            day_abbrev = date.strftime('%a')[0..1]  # Mo, Tu, We, etc.

            @pdf.text_box "#{day_num}",
                         at: [YEAR_DAY_NUMBER_OFFSET, cell_height - YEAR_DAY_NUMBER_OFFSET],
                         width: cell_width - (YEAR_DAY_NUMBER_OFFSET * 2),
                         height: cell_height - (YEAR_DAY_NUMBER_OFFSET * 2),
                         size: YEAR_DAY_SIZE,
                         overflow: :shrink_to_fit

            # Add day of week abbreviation
            @pdf.text_box day_abbrev,
                         at: [YEAR_DAY_NUMBER_OFFSET, YEAR_DAY_ABBREV_HEIGHT],
                         width: cell_width - (YEAR_DAY_NUMBER_OFFSET * 2),
                         height: YEAR_DAY_ABBREV_HEIGHT,
                         size: YEAR_DAY_ABBREV_SIZE,
                         style: :italic,
                         overflow: :shrink_to_fit

            # Add clickable link to the week containing this date
            first_day_of_year = Date.new(@year, 1, 1)
            days_back = (first_day_of_year.wday + 6) % 7
            year_start_monday = first_day_of_year - days_back
            days_from_start = (date - year_start_monday).to_i
            week_num = (days_from_start / 7) + 1

            @pdf.link_annotation([0, 0, cell_width, cell_height],
                                Dest: "week_#{week_num}",
                                Border: [0, 0, 0])
          end
        else
          # Draw empty cell for days that don't exist
          @pdf.bounding_box([x, current_y], width: cell_width, height: cell_height) do
            @pdf.stroke_color COLOR_BORDERS
            @pdf.stroke_bounds
            @pdf.stroke_color '000000'
            @pdf.fill_color 'EEEEEE'
            @pdf.fill_rectangle [0, cell_height], cell_width, cell_height
            @pdf.fill_color '000000'
          end
        end
      end

      current_y -= cell_height
    end
  end

  def generate_weekly_pages
    # Get all weeks in the year
    first_day = Date.new(@year, 1, 1)
    last_day = Date.new(@year, 12, 31)

    # Start from the Monday on or before January 1
    # wday: 0=Sunday, 1=Monday, ..., 6=Saturday
    # If Jan 1 is Sunday (0), go back 6 days to Monday
    # If Jan 1 is Monday (1), go back 0 days
    # If Jan 1 is Tuesday (2), go back 1 day to Monday, etc.
    days_back = (first_day.wday + 6) % 7  # Convert to: Mon=0, Tue=1, ..., Sun=6
    start_date = first_day - days_back

    # Collect all weeks
    weeks = []
    current_date = start_date
    week_num = 0

    while current_date <= last_day || week_num == 0
      week_num += 1
      weeks << { start_date: current_date, week_num: week_num }
      current_date += 7
    end

    # Generate one page per week
    total_weeks = weeks.length
    weeks.each do |week_info|
      @pdf.start_new_page
      @pdf.add_dest("week_#{week_info[:week_num]}", @pdf.dest_fit)
      draw_weekly_page(week_info[:start_date], week_info[:week_num], total_weeks)
      draw_footer
    end
  end

  def draw_weekly_page(start_date, week_num, total_weeks)
    # Title
    end_date = start_date + 6

    # Calculate dimensions per spec
    footer_clearance = FOOTER_HEIGHT + FOOTER_CLEARANCE  # Extra space above footer
    usable_height = PAGE_HEIGHT - WEEKLY_TOP_MARGIN - footer_clearance
    daily_section_height = usable_height * WEEKLY_DAILY_SECTION_PERCENT
    notes_section_height = usable_height * WEEKLY_NOTES_SECTION_PERCENT

    start_x = WEEKLY_SIDEBAR_X + WEEKLY_SIDEBAR_WIDTH + WEEKLY_SIDEBAR_GAP
    start_y = PAGE_HEIGHT - WEEKLY_TOP_MARGIN
    content_width = PAGE_WIDTH - start_x - PAGE_MARGIN_HORIZONTAL  # Available width excluding sidebar and right margin

    # Draw week sidebar on the left
    draw_week_sidebar(week_num, total_weeks)

    # Navigation: "< 2025" link on the left (in gray)
    @pdf.font "Helvetica", size: FOOTER_FONT_SIZE
    @pdf.fill_color '888888'
    @pdf.text_box "< #{@year}",
                  at: [start_x + WEEKLY_NAV_YEAR_X_OFFSET, start_y],
                  width: WEEKLY_NAV_YEAR_WIDTH,
                  height: WEEKLY_NAV_HEIGHT
    @pdf.fill_color '000000'
    # Link rect: [left, bottom, right, top]
    @pdf.link_annotation([start_x + WEEKLY_NAV_YEAR_X_OFFSET, start_y - WEEKLY_NAV_HEIGHT,
                          start_x + WEEKLY_NAV_YEAR_X_OFFSET + WEEKLY_NAV_YEAR_WIDTH, start_y],
                        Dest: "year_events",
                        Border: [0, 0, 0])

    # Navigation: "< w41" on the left (if not first week, in gray)
    if week_num > 1
      @pdf.fill_color '888888'
      @pdf.text_box "< w#{week_num - 1}",
                    at: [start_x + WEEKLY_NAV_PREV_WEEK_X_OFFSET, start_y],
                    width: WEEKLY_NAV_PREV_WEEK_WIDTH,
                    height: WEEKLY_NAV_HEIGHT
      @pdf.fill_color '000000'
      @pdf.link_annotation([start_x + WEEKLY_NAV_PREV_WEEK_X_OFFSET, start_y - WEEKLY_NAV_HEIGHT,
                            start_x + WEEKLY_NAV_PREV_WEEK_X_OFFSET + WEEKLY_NAV_PREV_WEEK_WIDTH, start_y],
                          Dest: "week_#{week_num - 1}",
                          Border: [0, 0, 0])
    end

    # Navigation: "w43 >" on the right (if not last week, in gray)
    if week_num < total_weeks
      next_x = PAGE_WIDTH - start_x - WEEKLY_NAV_NEXT_WEEK_WIDTH
      @pdf.fill_color '888888'
      @pdf.text_box "w#{week_num + 1} >",
                    at: [next_x, start_y],
                    width: WEEKLY_NAV_NEXT_WEEK_WIDTH,
                    height: WEEKLY_NAV_HEIGHT,
                    align: :right
      @pdf.fill_color '000000'
      @pdf.link_annotation([next_x, start_y - WEEKLY_NAV_HEIGHT, next_x + WEEKLY_NAV_NEXT_WEEK_WIDTH, start_y],
                          Dest: "week_#{week_num + 1}",
                          Border: [0, 0, 0])
    end

    # Title (centered)
    @pdf.font "Helvetica-Bold", size: WEEKLY_TITLE_FONT_SIZE
    @pdf.text_box "Week #{week_num}: #{start_date.strftime('%b %-d')} - #{end_date.strftime('%b %-d, %Y')}",
                  at: [start_x + WEEKLY_TITLE_X_OFFSET, start_y],
                  width: content_width - WEEKLY_TITLE_X_RESERVED,
                  align: :center

    # Daily section - 7 columns (Monday through Sunday)
    column_width = content_width / 7.0
    daily_start_y = start_y - WEEKLY_DAILY_TOP_SPACING

    # Draw day headers and lines
    @pdf.font "Helvetica-Bold", size: WEEKLY_DAY_HEADER_FONT_SIZE
    7.times do |i|
      date = start_date + i
      day_name = date.strftime('%A')  # Full day name (Monday, Tuesday, etc.)
      x = start_x + (i * column_width)

      @pdf.bounding_box([x, daily_start_y], width: column_width, height: daily_section_height) do
        @pdf.stroke_color COLOR_BORDERS
        @pdf.stroke_bounds
        @pdf.stroke_color '000000'

        # Day header
        @pdf.text_box "#{day_name}\n#{date.strftime('%-m/%-d')}",
                     at: [WEEKLY_DAY_HEADER_PADDING, daily_section_height - WEEKLY_DAY_HEADER_PADDING],
                     width: column_width - (WEEKLY_DAY_HEADER_PADDING * 2),
                     height: WEEKLY_DAY_HEADER_HEIGHT,
                     align: :center,
                     size: WEEKLY_DAY_DATE_FONT_SIZE

        # Draw evenly-spaced lines for notes
        @pdf.font "Helvetica", size: YEAR_DAY_SIZE
        line_start_y = daily_section_height - WEEKLY_DAY_LINES_START
        available_space = daily_section_height - WEEKLY_DAY_LINES_PADDING
        line_spacing = available_space / WEEKLY_DAY_LINES_COUNT

        WEEKLY_DAY_LINES_COUNT.to_i.times do |line_num|
          y_pos = line_start_y - (line_num * line_spacing)
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_horizontal_line WEEKLY_DAY_LINE_MARGIN, column_width - WEEKLY_DAY_LINE_MARGIN, at: y_pos
          @pdf.stroke_color '000000'
        end

        # Add time period labels to Monday only
        if i == 0  # Monday is the first column
          labels = ['AM', 'PM', 'EVE']
          @pdf.fill_color COLOR_BORDERS
          @pdf.font "Helvetica", size: 6

          labels.each_with_index do |label, idx|
            # Calculate y position for top of each region
            region_y = line_start_y - (idx * line_spacing) - 2
            @pdf.text_box label,
                         at: [3, region_y],
                         width: 20,
                         height: 10,
                         size: 6
          end
          @pdf.fill_color '000000'
        end
      end
    end

    # Cornell notes section
    notes_start_y = daily_start_y - daily_section_height - WEEKLY_NOTES_TOP_GAP

    # Draw Cornell notes layout per spec: 25% cues, 75% notes
    cue_column_width = content_width * WEEKLY_CUES_WIDTH_PERCENT
    notes_column_width = content_width * WEEKLY_NOTES_WIDTH_PERCENT
    summary_height = notes_section_height * WEEKLY_SUMMARY_HEIGHT_PERCENT
    main_notes_height = notes_section_height - summary_height - WEEKLY_SUMMARY_TOP_GAP

    @pdf.font "Helvetica-Bold", size: WEEKLY_NOTES_HEADER_FONT_SIZE

    # Cue column
    @pdf.bounding_box([start_x, notes_start_y],
                     width: cue_column_width,
                     height: main_notes_height) do
      @pdf.stroke_color COLOR_BORDERS
      @pdf.stroke_bounds
      @pdf.stroke_color '000000'
      @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
      @pdf.fill_color COLOR_SECTION_HEADERS
      @pdf.text "Cues/Questions", align: :center, size: WEEKLY_NOTES_LABEL_FONT_SIZE
      @pdf.fill_color '000000'
      draw_dot_grid(cue_column_width, main_notes_height)
    end

    # Notes column
    @pdf.bounding_box([start_x + cue_column_width, notes_start_y],
                     width: notes_column_width,
                     height: main_notes_height) do
      @pdf.stroke_color COLOR_BORDERS
      @pdf.stroke_bounds
      @pdf.stroke_color '000000'
      @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
      @pdf.fill_color COLOR_SECTION_HEADERS
      @pdf.text "Notes", align: :center, size: WEEKLY_NOTES_LABEL_FONT_SIZE
      @pdf.fill_color '000000'
      draw_dot_grid(notes_column_width, main_notes_height)
    end

    # Summary section (spans full width)
    summary_start_y = notes_start_y - main_notes_height - WEEKLY_SUMMARY_TOP_GAP
    @pdf.bounding_box([start_x, summary_start_y],
                     width: cue_column_width + notes_column_width,
                     height: summary_height) do
      @pdf.stroke_color COLOR_BORDERS
      @pdf.stroke_bounds
      @pdf.stroke_color '000000'
      @pdf.font "Helvetica-Bold", size: WEEKLY_NOTES_LABEL_FONT_SIZE
      @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
      @pdf.fill_color COLOR_SECTION_HEADERS
      @pdf.text "Summary", align: :center
      @pdf.fill_color '000000'
      draw_dot_grid(cue_column_width + notes_column_width, summary_height)
    end
  end

  def draw_dot_grid(width, height)
    @pdf.fill_color COLOR_DOT_GRID

    # Calculate starting positions with padding
    start_x = DOT_GRID_PADDING
    start_y = height - DOT_GRID_PADDING

    # Draw dots in a grid pattern
    y = start_y
    while y > DOT_GRID_PADDING
      x = start_x
      while x < width - DOT_GRID_PADDING
        @pdf.fill_circle [x, y], DOT_RADIUS
        x += DOT_SPACING
      end
      y -= DOT_SPACING
    end

    @pdf.fill_color '000000'
  end

  def draw_week_sidebar(current_week_num, total_weeks)
    start_y = PAGE_HEIGHT - WEEKLY_TOP_MARGIN
    usable_height = PAGE_HEIGHT - WEEKLY_TOP_MARGIN - FOOTER_HEIGHT

    # Calculate spacing for all weeks
    line_height = usable_height / total_weeks.to_f

    # Calculate which week each month starts in
    first_day = Date.new(@year, 1, 1)
    days_back = (first_day.wday + 6) % 7
    year_start_monday = first_day - days_back

    # Build a map of week_num -> month_letter for months that start in that week
    week_months = {}
    12.times do |month_idx|
      month = month_idx + 1
      first_of_month = Date.new(@year, month, 1)

      # Calculate which week contains this month's first day
      days_from_start = (first_of_month - year_start_monday).to_i
      week_num = (days_from_start / 7) + 1

      # Store the month letter for this week
      week_months[week_num] = @month_names[month_idx][0]
    end

    @pdf.font "Helvetica", size: WEEKLY_SIDEBAR_FONT_SIZE

    total_weeks.times do |i|
      week = i + 1
      y_top = start_y - (i * line_height)  # Top of this week's text box
      y_bottom = y_top - line_height       # Bottom of this week's text box

      # Build the display text
      month_letter = week_months[week]
      display_text = month_letter ? "#{month_letter} w#{week}" : "w#{week}"

      if week == current_week_num
        # Current week: bold, no link
        @pdf.font "Helvetica-Bold", size: WEEKLY_SIDEBAR_FONT_SIZE
        @pdf.fill_color '000000'
        @pdf.text_box display_text,
                      at: [WEEKLY_SIDEBAR_X, y_top],
                      width: WEEKLY_SIDEBAR_WIDTH,
                      height: line_height,
                      align: :right,
                      valign: :center
        @pdf.font "Helvetica", size: WEEKLY_SIDEBAR_FONT_SIZE
      else
        # Other weeks: gray, with link
        @pdf.fill_color '888888'
        @pdf.text_box display_text,
                      at: [WEEKLY_SIDEBAR_X, y_top],
                      width: WEEKLY_SIDEBAR_WIDTH,
                      height: line_height,
                      align: :right,
                      valign: :center
        # Link annotation rect using absolute coordinates: [left, bottom, right, top]
        @pdf.link_annotation([WEEKLY_SIDEBAR_X, y_bottom, WEEKLY_SIDEBAR_X + WEEKLY_SIDEBAR_WIDTH, y_top],
                            Dest: "week_#{week}",
                            Border: [0, 0, 0])
        @pdf.fill_color '000000'
      end
    end
  end

  def draw_footer
    # Footer removed - no longer needed
  end
end

# Generate planner for the current year
if __FILE__ == $0
  year = ARGV[0]&.to_i || Date.today.year

  puts "Generating planner for year #{year}..."
  generator = PlannerGenerator.new(year)
  generator.generate("planner_#{year}.pdf")
  puts "Done! Created planner_#{year}.pdf"
end
