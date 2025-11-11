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

  # Weekly Page - Right Sidebar (tabs to year pages)
  WEEKLY_RIGHT_SIDEBAR_LINK_X = 597  # Position for clickable link boxes
  WEEKLY_RIGHT_SIDEBAR_TEXT_X = 607  # Position for text (farther right)
  WEEKLY_RIGHT_SIDEBAR_WIDTH = 50  # Height when rotated (extends down the page)
  WEEKLY_RIGHT_SIDEBAR_FONT_SIZE = 8
  WEEKLY_RIGHT_SIDEBAR_SPACING = 10  # Space between tab labels

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

  # Grid-based Layout System
  # Calculate total grid boxes available on page
  GRID_COLS = (PAGE_WIDTH / DOT_SPACING).floor   # 43 boxes wide
  GRID_ROWS = (PAGE_HEIGHT / DOT_SPACING).floor  # 55 boxes tall

  # Debug mode - set to true to show diagnostic grid overlay
  DEBUG_GRID = true

  # Colors
  COLOR_DOT_GRID = 'CCCCCC'  # Light gray for dots
  COLOR_BORDERS = 'E5E5E5'  # Lighter gray for borders (appears similar to dots despite continuous lines)
  COLOR_SECTION_HEADERS = 'AAAAAA'  # Muted gray for section headers
  COLOR_WEEKEND_BG = 'FAFAFA'  # Extremely subtle gray for Saturday/Sunday background

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
      generate_reference_page
      generate_weekly_pages
      generate_dot_grid_page

      puts "Generated planner with #{pdf.page_count} pages"
    end
  end

  private

  # Grid coordinate system helpers
  # Convert grid column (0-based) to x coordinate in points
  def grid_x(col)
    col * DOT_SPACING
  end

  # Convert grid row (0-based from TOP) to y coordinate in points
  # Row 0 is at the top of the page, row increases downward
  def grid_y(row)
    PAGE_HEIGHT - (row * DOT_SPACING)
  end

  # Get width in points for a given number of grid boxes
  def grid_width(boxes)
    boxes * DOT_SPACING
  end

  # Get height in points for a given number of grid boxes
  def grid_height(boxes)
    boxes * DOT_SPACING
  end

  # Draw a rectangle at grid coordinates
  # col, row: top-left corner in grid coordinates (row 0 = top)
  # width_boxes, height_boxes: size in grid boxes
  def grid_rect(col, row, width_boxes, height_boxes)
    x = grid_x(col)
    y = grid_y(row)
    width = grid_width(width_boxes)
    height = grid_height(height_boxes)

    # Return as [x, y, width, height] for use in bounding_box or other operations
    { x: x, y: y, width: width, height: height }
  end

  # Diagnostic grid overlay - draws red dots at grid intersections with numbered labels
  # Call this after drawing page content to overlay a diagnostic grid
  # Set DEBUG_GRID = false to disable all diagnostic grids
  def draw_diagnostic_grid(label_every: 5)
    return unless DEBUG_GRID

    # Draw red dots at every grid intersection
    @pdf.fill_color 'FF0000'
    (0..GRID_ROWS).each do |row|
      y = grid_y(row)
      (0..GRID_COLS).each do |col|
        x = grid_x(col)
        @pdf.fill_circle [x, y], 1.0  # Slightly larger than regular dots
      end
    end

    # Draw grid lines every label_every boxes
    @pdf.stroke_color 'FF0000'
    @pdf.line_width 0.25
    @pdf.dash(1, space: 2)

    # Vertical lines
    (0..GRID_COLS).step(label_every).each do |col|
      x = grid_x(col)
      @pdf.stroke_line [x, 0], [x, PAGE_HEIGHT]
    end

    # Horizontal lines
    (0..GRID_ROWS).step(label_every).each do |row|
      y = grid_y(row)
      @pdf.stroke_line [0, y], [PAGE_WIDTH, y]
    end

    @pdf.undash
    @pdf.line_width 1

    # Add labels at intersections
    @pdf.fill_color 'FF0000'
    @pdf.font "Helvetica", size: 6

    (0..GRID_ROWS).step(label_every).each do |row|
      y = grid_y(row)
      (0..GRID_COLS).step(label_every).each do |col|
        x = grid_x(col)

        # Draw label with white background for readability
        label = "(#{col},#{row})"
        label_width = 25
        label_height = 10

        @pdf.fill_color 'FFFFFF'
        @pdf.fill_rectangle [x + 2, y - 2], label_width, label_height

        @pdf.fill_color 'FF0000'
        @pdf.text_box label,
                      at: [x + 2, y - 2],
                      width: label_width,
                      height: label_height,
                      size: 6,
                      overflow: :shrink_to_fit
      end
    end

    # Reset colors
    @pdf.fill_color '000000'
    @pdf.stroke_color '000000'
  end

  def setup_destinations
    # We'll add destinations as we create pages
  end

  def generate_seasonal_calendar
    # Don't call start_new_page - Prawn creates the first page automatically
    @pdf.add_dest("seasonal", @pdf.dest_fit)

    # Draw diagnostic grid first (as background when DEBUG_GRID is enabled)
    draw_diagnostic_grid(label_every: 5)

    # Draw sidebars
    draw_week_sidebar(nil, calculate_total_weeks)
    draw_right_sidebar

    draw_seasonal_calendar
    draw_footer
  end

  def draw_seasonal_calendar
    # Grid-based layout:
    # - Header: rows 0-1 (2 boxes), full width
    # - Seasons start at row 2 (no gutter)
    # - 1 box spacing between months

    # Header (rows 0-1, full width)
    header = grid_rect(0, 0, GRID_COLS, 2)
    @pdf.font "Helvetica-Bold", size: 18
    @pdf.text_box "Year #{@year}",
                  at: [header[:x], header[:y]],
                  width: header[:width],
                  height: header[:height],
                  align: :center,
                  valign: :center

    # Define seasons with their months
    # Each season will have: label column (1 box) + content
    seasons = [
      { name: "Winter", months: [1, 2, 3] },     # Jan, Feb, Mar
      { name: "Spring", months: [4, 5, 6] },     # Apr, May, Jun
      { name: "Summer", months: [7, 8, 9] },     # Jul, Aug, Sep
      { name: "Fall", months: [10, 11, 12] }     # Oct, Nov, Dec
    ]

    # Calculate layout: 2 columns, chronological order
    # Shift everything 2 boxes to the right for seasonal labels
    # Left column: Jan-Jun (Winter + Spring)
    # Right column: Jul-Dec (Summer + Fall)
    label_offset = 2  # Reserve 2 boxes on left for seasonal labels
    half_width = (GRID_COLS - label_offset) / 2

    # Winter: top-left (Jan-Mar)
    winter_row = 2
    draw_season_grid(seasons[0], label_offset, winter_row, half_width)

    # Spring: bottom-left (Apr-Jun, after Winter)
    spring_row = winter_row + calculate_season_height(seasons[0][:months].length)
    draw_season_grid(seasons[1], label_offset, spring_row, half_width)

    # Summer: top-right (Jul-Sep)
    summer_row = 2
    draw_season_grid(seasons[2], label_offset + half_width, summer_row, half_width)

    # Fall: bottom-right (Oct-Dec, after Summer)
    fall_row = summer_row + calculate_season_height(seasons[2][:months].length)
    draw_season_grid(seasons[3], label_offset + half_width, fall_row, half_width)
  end

  def calculate_season_height(num_months)
    # Each month needs: 1 box for title + 1 box for day headers + 6 boxes for calendar rows = 8
    # Plus 1 box spacing after each month
    (num_months * 8) + (num_months * 1)
  end

  def draw_season_grid(season, start_col, start_row, width_boxes)
    # Season box - no background, just border (includes the content area, not the label)
    height_boxes = calculate_season_height(season[:months].length)
    season_box = grid_rect(start_col, start_row, width_boxes, height_boxes)

    # Draw border around entire season content area
    @pdf.stroke_color COLOR_BORDERS
    @pdf.stroke_rectangle [season_box[:x], season_box[:y]], season_box[:width], season_box[:height]
    @pdf.stroke_color '000000'

    # Rotated season label in reserved column (to the left of content)
    # Use start_col - 2 to place label in the leftmost reserved column
    label_box = grid_rect(start_col - 2, start_row, 1, height_boxes)

    # Calculate center point for rotation
    center_x = label_box[:x] + grid_width(0.5)
    center_y = label_box[:y] - (label_box[:height] / 2)

    # Rotate +90 degrees (counter-clockwise) so text reads bottom-to-top when page is upright
    @pdf.rotate(90, origin: [center_x, center_y]) do
      @pdf.font "Helvetica-Bold", size: 12
      @pdf.fill_color '000000'
      @pdf.text_box season[:name],
                    at: [center_x - (label_box[:height] / 2), center_y],
                    width: label_box[:height],
                    height: grid_width(1),
                    align: :center,
                    valign: :center
    end

    # Draw months in the content area (no additional offset needed now)
    current_row = start_row
    season[:months].each do |month|
      draw_month_grid(month, start_col, current_row, width_boxes)
      current_row += 8  # 1 title + 1 headers + 6 calendar rows
      current_row += 1  # 1 box gutter after each month
    end
  end

  def draw_month_grid(month, start_col, start_row, width_boxes)
    # Month title (1 box high)
    title_box = grid_rect(start_col, start_row, width_boxes, 1)
    @pdf.font "Helvetica-Bold", size: 10
    @pdf.text_box @month_names[month - 1],
                  at: [title_box[:x], title_box[:y]],
                  width: title_box[:width],
                  height: title_box[:height],
                  align: :center,
                  valign: :center

    # Day headers (1 box high): M T W T F S S
    headers_row = start_row + 1
    day_names = ['M', 'T', 'W', 'T', 'F', 'S', 'S']
    col_width_boxes = width_boxes / 7.0

    day_names.each_with_index do |day, i|
      col_x = grid_x(start_col) + (i * grid_width(col_width_boxes))
      @pdf.font "Helvetica", size: 7
      @pdf.text_box day,
                    at: [col_x, grid_y(headers_row)],
                    width: grid_width(col_width_boxes),
                    height: grid_height(1),
                    align: :center,
                    valign: :center
    end

    # Calendar days (6 rows of 1 box each)
    first_day = Date.new(@year, month, 1)
    last_day = Date.new(@year, month, -1)
    days_in_month = last_day.day
    start_wday = first_day.wday
    start_col_offset = (start_wday + 6) % 7  # Convert to Monday-based

    # Calculate week numbers
    first_day_of_year = Date.new(@year, 1, 1)
    days_back = (first_day_of_year.wday + 6) % 7
    year_start_monday = first_day_of_year - days_back

    @pdf.font "Helvetica", size: 7
    row = 0
    col = start_col_offset

    1.upto(days_in_month) do |day|
      date = Date.new(@year, month, day)
      days_from_start = (date - year_start_monday).to_i
      week_num = (days_from_start / 7) + 1

      cal_row = headers_row + 1 + row
      cell_x = grid_x(start_col) + (col * grid_width(col_width_boxes))
      cell_y = grid_y(cal_row)

      @pdf.text_box day.to_s,
                    at: [cell_x, cell_y],
                    width: grid_width(col_width_boxes),
                    height: grid_height(1),
                    align: :center,
                    valign: :center

      # Add clickable link
      link_bottom = cell_y - grid_height(1)
      @pdf.link_annotation([cell_x, link_bottom, cell_x + grid_width(col_width_boxes), cell_y],
                          Dest: "week_#{week_num}",
                          Border: [0, 0, 0])

      col += 1
      if col >= 7
        col = 0
        row += 1
      end
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

    # Draw sidebars
    draw_week_sidebar(nil, calculate_total_weeks)
    draw_right_sidebar

    draw_year_at_glance("Year #{@year} - Events")
    draw_footer
  end

  def generate_year_at_glance_highlights
    @pdf.start_new_page
    @pdf.add_dest("year_highlights", @pdf.dest_fit)

    # Draw sidebars
    draw_week_sidebar(nil, calculate_total_weeks)
    draw_right_sidebar

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

  def calculate_total_weeks
    # Get all weeks in the year
    first_day = Date.new(@year, 1, 1)
    last_day = Date.new(@year, 12, 31)

    # Start from the Monday on or before January 1
    days_back = (first_day.wday + 6) % 7  # Convert to: Mon=0, Tue=1, ..., Sun=6
    start_date = first_day - days_back

    # Count weeks
    current_date = start_date
    week_num = 0

    while current_date <= last_day || week_num == 0
      week_num += 1
      current_date += 7
    end

    week_num
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

    # Draw right sidebar with year page tabs
    draw_right_sidebar

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
                        Dest: "seasonal",
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
        # Add subtle background for Saturday (5) and Sunday (6)
        if i == 5 || i == 6  # Saturday and Sunday
          @pdf.fill_color COLOR_WEEKEND_BG
          @pdf.fill_rectangle [0, daily_section_height], column_width, daily_section_height
          @pdf.fill_color '000000'
        end

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

    # Align with grid coordinate system: start at (0, height) which corresponds to
    # grid position (0, 0) - top-left corner
    # Draw dots at every grid intersection point
    start_x = 0
    start_y = height

    # Calculate how many dots fit in the given dimensions
    cols = (width / DOT_SPACING).floor
    rows = (height / DOT_SPACING).floor

    # Draw dots at exact grid positions
    (0..rows).each do |row|
      y = start_y - (row * DOT_SPACING)
      (0..cols).each do |col|
        x = start_x + (col * DOT_SPACING)
        @pdf.fill_circle [x, y], DOT_RADIUS
      end
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

  def draw_right_sidebar
    # Define tabs for year pages (top-aligned)
    tabs = [
      { label: "Year", dest: "seasonal" },
      { label: "Events", dest: "year_events" },
      { label: "Highlights", dest: "year_highlights" }
    ]

    @pdf.fill_color '888888'
    @pdf.font "Helvetica", size: WEEKLY_RIGHT_SIDEBAR_FONT_SIZE

    # Start from top of page
    current_y = PAGE_HEIGHT - 50

    tabs.each do |tab|
      # Rotate text 90 degrees clockwise (text flows down when page is upright)
      @pdf.rotate(-90, origin: [WEEKLY_RIGHT_SIDEBAR_TEXT_X, current_y]) do
        @pdf.text_box tab[:label],
                      at: [WEEKLY_RIGHT_SIDEBAR_TEXT_X, current_y],
                      width: WEEKLY_RIGHT_SIDEBAR_WIDTH,
                      height: 20,
                      align: :left

        # Add clickable link area (positioned to the left of text)
        # When rotated -90, the text flows from right to left in rotated space
        @pdf.link_annotation([WEEKLY_RIGHT_SIDEBAR_LINK_X, current_y - 20,
                              WEEKLY_RIGHT_SIDEBAR_LINK_X + WEEKLY_RIGHT_SIDEBAR_WIDTH, current_y],
                            Dest: tab[:dest],
                            Border: [0, 0, 0])
      end

      # Move down for next tab
      current_y -= (WEEKLY_RIGHT_SIDEBAR_WIDTH + WEEKLY_RIGHT_SIDEBAR_SPACING)
    end

    # Add "Dots" tab at bottom (right-aligned within rotated space)
    bottom_y = FOOTER_HEIGHT + 50

    # Draw text rotated with right alignment
    @pdf.rotate(-90, origin: [WEEKLY_RIGHT_SIDEBAR_TEXT_X, bottom_y]) do
      @pdf.text_box "Dots",
                    at: [WEEKLY_RIGHT_SIDEBAR_TEXT_X, bottom_y],
                    width: WEEKLY_RIGHT_SIDEBAR_WIDTH,
                    height: 20,
                    align: :right

      # Add clickable link area in rotated space
      # In rotated coords: need to SUBTRACT from Y to move down the page
      # Link box should be tall (along Y in rotated space) and narrow (along X)
      link_offset = -30  # Negative to move DOWN the page in rotated space
      text_width = 25  # Approximate width of "Dots" text
      @pdf.link_annotation([WEEKLY_RIGHT_SIDEBAR_LINK_X, bottom_y + link_offset - text_width,
                            WEEKLY_RIGHT_SIDEBAR_LINK_X + 20, bottom_y + link_offset],
                          Dest: "dots",
                          Border: [0, 0, 0])
    end

    @pdf.fill_color '000000'
  end

  def generate_reference_page
    @pdf.start_new_page
    @pdf.add_dest("reference", @pdf.dest_fit)

    # Draw diagnostic grid first (as background when DEBUG_GRID is enabled)
    draw_diagnostic_grid(label_every: 5)

    # Draw dot grid
    draw_dot_grid(PAGE_WIDTH, PAGE_HEIGHT)

    # Draw reference/calibration elements on top
    draw_reference_calibration
  end

  def draw_reference_calibration
    # Calculate page dimensions
    center_x = PAGE_WIDTH / 2.0
    center_y = PAGE_HEIGHT / 2.0

    # 1. Draw very faint X through center
    @pdf.stroke_color 'EEEEEE'
    @pdf.stroke do
      @pdf.line [0, 0], [PAGE_WIDTH, PAGE_HEIGHT]
      @pdf.line [0, PAGE_HEIGHT], [PAGE_WIDTH, 0]
    end

    # 2. Draw faint solid line for halves
    @pdf.stroke_color 'EEEEEE'
    @pdf.stroke do
      @pdf.horizontal_line 0, PAGE_WIDTH, at: center_y
      @pdf.vertical_line 0, PAGE_HEIGHT, at: center_x
    end

    # 3. Draw dotted lines for thirds
    @pdf.stroke_color 'CCCCCC'
    @pdf.dash(2, space: 3)
    third_x = PAGE_WIDTH / 3.0
    third_y = PAGE_HEIGHT / 3.0
    @pdf.stroke do
      @pdf.vertical_line 0, PAGE_HEIGHT, at: third_x
      @pdf.vertical_line 0, PAGE_HEIGHT, at: third_x * 2
      @pdf.horizontal_line 0, PAGE_WIDTH, at: third_y
      @pdf.horizontal_line 0, PAGE_WIDTH, at: third_y * 2
    end
    @pdf.undash

    # 4. Draw circle with radius = 1/4 page width
    circle_radius = PAGE_WIDTH / 4.0
    @pdf.stroke_color 'CCCCCC'
    @pdf.stroke do
      @pdf.circle [center_x, center_y], circle_radius
    end

    # 5. Draw centimeter markings
    # 1 cm = 28.35 points (approximately)
    cm_in_points = 28.35
    @pdf.fill_color '888888'
    @pdf.font "Helvetica", size: 6

    # Top horizontal centimeter markings
    num_cm_horizontal = (PAGE_WIDTH / cm_in_points).floor
    (0..num_cm_horizontal).each do |cm|
      x = cm * cm_in_points
      @pdf.stroke_color 'AAAAAA'
      @pdf.stroke_line [x, PAGE_HEIGHT - 5], [x, PAGE_HEIGHT - 15]
      @pdf.text_box cm.to_s,
                    at: [x - 5, PAGE_HEIGHT - 2],
                    width: 10,
                    height: 8,
                    size: 5,
                    align: :center
    end

    # Left vertical centimeter markings
    num_cm_vertical = (PAGE_HEIGHT / cm_in_points).floor
    (0..num_cm_vertical).each do |cm|
      y = cm * cm_in_points
      @pdf.stroke_color 'AAAAAA'
      @pdf.stroke_line [5, y], [15, y]
      @pdf.text_box cm.to_s,
                    at: [2, y - 2],
                    width: 10,
                    height: 8,
                    size: 5
    end

    # 6. Calculate and display dot grid box counts
    # Dots are spaced at DOT_SPACING (14.17 points ≈ 5mm)
    boxes_per_width = (PAGE_WIDTH / DOT_SPACING).floor
    boxes_per_height = (PAGE_HEIGHT / DOT_SPACING).floor

    # Display measurements in center
    @pdf.fill_color '000000'
    @pdf.font "Helvetica", size: 8

    measurements = [
      "Page: #{PAGE_WIDTH}pt × #{PAGE_HEIGHT}pt",
      "Page: #{(PAGE_WIDTH / cm_in_points).round(1)}cm × #{(PAGE_HEIGHT / cm_in_points).round(1)}cm",
      "",
      "Dot Grid Boxes:",
      "  Full: #{boxes_per_width} × #{boxes_per_height}",
      "  Half: #{(boxes_per_width/2).round} × #{(boxes_per_height/2).round}",
      "  Third: #{(boxes_per_width/3).round} × #{(boxes_per_height/3).round}",
      "  Quarter: #{(boxes_per_width/4).round} × #{(boxes_per_height/4).round}"
    ]

    y_pos = center_y + 50
    measurements.each do |text|
      @pdf.text_box text,
                    at: [center_x - 80, y_pos],
                    width: 160,
                    height: 15,
                    size: 8,
                    align: :center
      y_pos -= 12
    end

    # 6b. Draw a sample grid-based box at top (row 0-1, full width)
    # This demonstrates the grid system in action
    header_box = grid_rect(0, 0, GRID_COLS, 2)
    @pdf.stroke_color 'FF0000'  # Red to make it visible
    @pdf.stroke_rectangle [header_box[:x], header_box[:y]], header_box[:width], header_box[:height]

    @pdf.fill_color '000000'
    @pdf.font "Helvetica", size: 8
    @pdf.text_box "GRID DEMO: Row 0-1 (2 boxes tall), Cols 0-#{GRID_COLS-1} (full width)",
                  at: [header_box[:x] + 5, header_box[:y] - 5],
                  width: header_box[:width] - 10,
                  height: header_box[:height] - 10,
                  align: :center,
                  valign: :center
    @pdf.stroke_color '000000'

    # 7. Add Prawn coordinate system reference in bottom-right area
    # Position in bottom third, right third of page
    ref_x = (PAGE_WIDTH * 2.0 / 3.0) + 10  # Right third, with padding
    ref_y = (PAGE_HEIGHT / 3.0) + 100      # Bottom third, moved up to avoid cutoff
    ref_width = (PAGE_WIDTH / 3.0) - 20    # Width of right third minus padding

    @pdf.fill_color '000000'
    @pdf.font "Helvetica-Bold", size: 7
    @pdf.text_box "PRAWN COORDINATE REFERENCE",
                  at: [ref_x, ref_y],
                  width: ref_width,
                  height: 12,
                  size: 7

    @pdf.font "Helvetica", size: 6
    ref_content = [
      "",
      "GRID LAYOUT SYSTEM:",
      "  Grid: #{GRID_COLS} cols x #{GRID_ROWS} rows",
      "  Box size: #{DOT_SPACING.round(2)}pt (5mm)",
      "  Row 0 = top, Col 0 = left",
      "",
      "Grid Methods:",
      "  grid_x(col) -> x in points",
      "  grid_y(row) -> y in points",
      "  grid_width(boxes) -> width",
      "  grid_height(boxes) -> height",
      "  grid_rect(col,row,w,h) ->",
      "    {x:, y:, width:, height:}",
      "",
      "Coordinate System:",
      "  Origin: Bottom-left (0, 0)",
      "  +X: Right, +Y: Up",
      "  Page: 612pt × 792pt",
      "",
      "Text Positioning:",
      "  text_box at: [x, y]",
      "  (x, y) = top-left corner",
      "",
      "Link Annotations:",
      "  [left, bottom, right, top]",
      "",
      "Bounding Boxes:",
      "  Set local origin to [x, y]",
      "  Coords inside are relative"
    ]

    ref_y_pos = ref_y - 15
    ref_content.each do |line|
      @pdf.text_box line,
                    at: [ref_x, ref_y_pos],
                    width: ref_width,
                    height: 10,
                    size: 6,
                    overflow: :shrink_to_fit
      ref_y_pos -= 8
    end

    @pdf.fill_color '000000'
    @pdf.stroke_color '000000'
  end

  def generate_dot_grid_page
    @pdf.start_new_page
    @pdf.add_dest("dots", @pdf.dest_fit)

    # Draw full page dot grid
    draw_dot_grid(PAGE_WIDTH, PAGE_HEIGHT)
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
