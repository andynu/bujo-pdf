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
  # NOTE: Right sidebar now uses grid-based layout (see draw_right_sidebar)
  # - Position: Column 43 (at right edge, beyond last grid column), 1 box wide
  # - Each tab: 3 boxes tall
  # - Top tabs start at row 3, bottom tab positioned from bottom

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
      seasonal_page = pdf.page_number

      generate_year_at_glance_events
      events_page = pdf.page_number

      generate_year_at_glance_highlights
      highlights_page = pdf.page_number

      generate_reference_page
      reference_page = pdf.page_number

      weekly_start_page = pdf.page_number + 1  # Point to first weekly page (next page)
      generate_weekly_pages

      generate_dot_grid_page
      dots_page = pdf.page_number

      # Build PDF outline (table of contents / bookmarks)
      pdf.outline.define do
        section "#{@year} Overview", destination: seasonal_page do
          page destination: seasonal_page, title: 'Seasonal Calendar'
          page destination: events_page, title: 'Year at a Glance - Events'
          page destination: highlights_page, title: 'Year at a Glance - Highlights'
        end

        page destination: weekly_start_page, title: 'Weekly Pages'

        section 'Templates', destination: dots_page do
          page destination: reference_page, title: 'Grid Reference & Calibration'
          page destination: dots_page, title: 'Dot Grid'
        end
      end

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

  # Create a text_box positioned using grid coordinates
  # text: string content to display
  # col, row: top-left corner in grid coordinates
  # width_boxes, height_boxes: size in grid boxes
  # options: hash of additional text_box options (align, valign, size, etc.)
  #
  # Example:
  #   grid_text_box("Hello", 5, 10, 10, 2, align: :center, valign: :center)
  def grid_text_box(text, col, row, width_boxes, height_boxes, **options)
    @pdf.text_box text,
                  at: [grid_x(col), grid_y(row)],
                  width: grid_width(width_boxes),
                  height: grid_height(height_boxes),
                  **options
  end

  # Create a link annotation positioned using grid coordinates
  # col, row: top-left corner in grid coordinates
  # width_boxes, height_boxes: size in grid boxes
  # dest: destination name (e.g., "week_1", "seasonal")
  # options: hash of additional link_annotation options (Border, etc.)
  #
  # Example:
  #   grid_link(5, 10, 10, 2, "week_42")
  def grid_link(col, row, width_boxes, height_boxes, dest, **options)
    left = grid_x(col)
    top = grid_y(row)
    right = grid_x(col + width_boxes)
    bottom = grid_y(row + height_boxes)

    # Default to invisible border
    opts = { Border: [0, 0, 0] }.merge(options)

    @pdf.link_annotation([left, bottom, right, top],
                        Dest: dest,
                        **opts)
  end

  # Apply grid-based padding to a grid_rect result
  # Useful for creating inset content within a grid box
  #
  # rect: result from grid_rect (hash with :x, :y, :width, :height)
  # padding_boxes: inset amount in grid boxes (can be fractional, e.g., 0.5)
  #
  # Returns: new hash with padded coordinates and dimensions
  #
  # Example:
  #   box = grid_rect(5, 10, 20, 15)
  #   padded = grid_inset(box, 0.5)  # 0.5 boxes of padding on all sides
  def grid_inset(rect, padding_boxes)
    padding = grid_width(padding_boxes)  # width and height spacing are equal
    {
      x: rect[:x] + padding,
      y: rect[:y] - padding,
      width: rect[:width] - (padding * 2),
      height: rect[:height] - (padding * 2)
    }
  end

  # Calculate the bottom Y coordinate for a grid box (useful for links)
  # col, row: top-left corner in grid coordinates
  # height_boxes: height of the box in grid boxes
  #
  # Returns: Y coordinate of the bottom edge (in Prawn coordinates)
  #
  # Example:
  #   top = grid_y(10)
  #   bottom = grid_bottom(10, 2)  # 2 boxes tall
  def grid_bottom(row, height_boxes)
    grid_y(row + height_boxes)
  end

  # Draw a right sidebar navigation tab with rotated text and clickable link
  # Creates a cohesive navigation item with text and link properly aligned
  #
  # col, row: top-left corner in grid coordinates
  # height_boxes: height of the tab in grid boxes
  # label: text to display (rotated -90°)
  # dest: destination name for the link
  # align: text alignment (:left or :right within the rotated space)
  # padding_boxes: padding at the top of the tab (default 0.5)
  #
  # Example:
  #   draw_right_nav_tab(42, 3, 3, "Year", "seasonal", align: :left)
  def draw_right_nav_tab(col, row, height_boxes, label, dest, align: :left, padding_boxes: 0.5)
    @pdf.fill_color '888888'
    @pdf.font "Helvetica", size: 8

    # Calculate text area with padding
    # Top padding (becomes left after rotation): padding_boxes at top
    # Right padding (to keep text within box): padding_boxes at right
    text_height_pt = grid_height(height_boxes - padding_boxes)  # Only subtract top padding
    padding_pt = grid_height(padding_boxes)

    # Position for rotated text - rotate around center of tab region
    # Inset from right edge and adjust Y to push text down into box
    tab_x = grid_x(col + 1) - padding_pt  # Inset from right edge by padding amount
    # Adjust Y center down by full padding to push text into the box with proper top margin
    tab_y_center = grid_y(row) - grid_height(height_boxes / 2.0) - padding_pt

    # Draw rotated text centered in the tab
    @pdf.rotate(-90, origin: [tab_x, tab_y_center]) do
      # Calculate text box position in rotated space
      text_x = tab_x - (text_height_pt / 2.0) - padding_pt
      text_y = tab_y_center + (grid_width(1) / 2.0)

      @pdf.text_box label,
                    at: [text_x, text_y],
                    width: text_height_pt,
                    height: grid_width(1),
                    align: align,
                    valign: :center
    end

    # Add clickable link for the entire tab region
    grid_link(col, row, 1, height_boxes, dest)

    # Debug: Draw visible border around link region
    if DEBUG_GRID
      @pdf.stroke_color 'FF0000'
      link_box = grid_rect(col, row, 1, height_boxes)
      @pdf.stroke_rectangle [link_box[:x], link_box[:y]], link_box[:width], link_box[:height]

      @pdf.fill_color 'FF0000'
      @pdf.font "Helvetica", size: 6
      @pdf.text_box "#{label}\nrow #{row}-#{row+height_boxes-1}",
                    at: [link_box[:x] - 30, link_box[:y]],
                    width: 25,
                    height: link_box[:height],
                    align: :right,
                    valign: :center
      @pdf.fill_color '888888'
      @pdf.font "Helvetica", size: 8
      @pdf.stroke_color '000000'
    end

    @pdf.fill_color '000000'
  end

  # Component: Fieldset with legend (like HTML <fieldset> and <legend>)
  # Draws a border box with a text label that sits on top of and breaks the border line
  # The border can be inset from the specified box boundaries (configurable)
  #
  # Parameters:
  #   col, row: top-left corner in grid coordinates (controls legend position)
  #   width_boxes, height_boxes: size in grid boxes
  #   legend: text for the legend label
  #   position: where to place legend - :top_left (default), :top_right, :bottom_left, :bottom_right
  #   legend_padding: space in points on either side of legend text (default: 5)
  #   font_size: size of legend text (default: 12)
  #   border_color: color of border (default: COLOR_BORDERS)
  #   inset_boxes: border inset in grid boxes (default: 0.5 to center on legend text, use 0 for edge alignment)
  #
  # Position behaviors:
  #   :top_left - Text horizontal (left-to-right), top edge, slightly inset from left
  #   :top_right - Text rotated clockwise (-90°), right edge, reads top-to-bottom
  #   :bottom_left - Text horizontal (left-to-right), bottom edge, slightly inset from left
  #   :bottom_right - Text rotated counter-clockwise (+90°), left edge, reads bottom-to-top
  def draw_fieldset(col, row, width_boxes, height_boxes, legend,
                    position: :top_left,
                    legend_padding: 5,
                    font_size: 12,
                    border_color: COLOR_BORDERS,
                    text_color: '000000',
                    inset_boxes: 0.5,
                    legend_offset_x: 0,
                    legend_offset_y: 0)

    # Get the outer box (where legend sits)
    box = grid_rect(col, row, width_boxes, height_boxes)

    # Border is inset by specified amount from the outer box
    inset = grid_width(inset_boxes)
    border_x = box[:x] + inset
    border_y = box[:y] - inset
    border_width = box[:width] - (inset * 2)
    border_height = box[:height] - (inset * 2)

    # Set up font for measuring legend width
    @pdf.font "Helvetica-Bold", size: font_size
    legend_width = @pdf.width_of(legend)
    legend_total_width = legend_width + (legend_padding * 2)

    @pdf.stroke_color border_color

    case position
    when :top_left
      # Draw border with gap for legend on top edge, left side
      legend_x_start = box[:x] + grid_width(1)  # Inset 1 box from left
      legend_y = box[:y]

      # Top edge: left corner to legend start
      @pdf.stroke_line [border_x, border_y], [legend_x_start, border_y]
      # Top edge: legend end to right corner
      @pdf.stroke_line [legend_x_start + legend_total_width, border_y], [border_x + border_width, border_y]
      # Right edge
      @pdf.stroke_line [border_x + border_width, border_y], [border_x + border_width, border_y - border_height]
      # Bottom edge
      @pdf.stroke_line [border_x + border_width, border_y - border_height], [border_x, border_y - border_height]
      # Left edge
      @pdf.stroke_line [border_x, border_y - border_height], [border_x, border_y]

      # Draw legend text
      @pdf.fill_color text_color
      @pdf.text_box legend,
                    at: [legend_x_start + legend_padding, legend_y],
                    width: legend_width,
                    height: font_size + 4,
                    valign: :center

    when :top_right
      # Draw border with gap for legend on right edge, top
      # Legend rotated clockwise (-90°), reads top-to-bottom
      legend_y_start = box[:y] - grid_height(1)  # Inset 1 box from top
      legend_x = box[:x] + box[:width]

      # Top edge
      @pdf.stroke_line [border_x, border_y], [border_x + border_width, border_y]
      # Right edge: top corner to legend start
      @pdf.stroke_line [border_x + border_width, border_y], [border_x + border_width, legend_y_start]
      # Right edge: legend end to bottom corner
      @pdf.stroke_line [border_x + border_width, legend_y_start - legend_total_width], [border_x + border_width, border_y - border_height]
      # Bottom edge
      @pdf.stroke_line [border_x + border_width, border_y - border_height], [border_x, border_y - border_height]
      # Left edge
      @pdf.stroke_line [border_x, border_y - border_height], [border_x, border_y]

      # Draw legend text (rotated clockwise -90°)
      center_x = legend_x
      center_y = legend_y_start - legend_padding - (legend_width / 2)
      @pdf.rotate(-90, origin: [center_x, center_y]) do
        @pdf.fill_color text_color
        @pdf.text_box legend,
                      at: [center_x - (legend_width / 2), center_y + (font_size / 2)],
                      width: legend_width,
                      height: font_size + 4,
                      valign: :center
      end

    when :bottom_left
      # Draw border with gap for legend on bottom edge, left side
      legend_x_start = box[:x] + grid_width(1)  # Inset 1 box from left
      legend_y = box[:y] - box[:height]

      # Top edge
      @pdf.stroke_line [border_x, border_y], [border_x + border_width, border_y]
      # Right edge
      @pdf.stroke_line [border_x + border_width, border_y], [border_x + border_width, border_y - border_height]
      # Bottom edge: right corner to legend end
      @pdf.stroke_line [border_x + border_width, border_y - border_height], [legend_x_start + legend_total_width, border_y - border_height]
      # Bottom edge: legend start to left corner
      @pdf.stroke_line [legend_x_start, border_y - border_height], [border_x, border_y - border_height]
      # Left edge
      @pdf.stroke_line [border_x, border_y - border_height], [border_x, border_y]

      # Draw legend text
      @pdf.fill_color text_color
      @pdf.text_box legend,
                    at: [legend_x_start + legend_padding, legend_y],
                    width: legend_width,
                    height: font_size + 4,
                    valign: :center

    when :bottom_right
      # Draw border with gap for legend on left edge, bottom
      # Legend rotated counter-clockwise (+90°), reads bottom-to-top
      legend_y_start = box[:y] - box[:height] + grid_height(1)  # Inset 1 box from bottom
      legend_x = box[:x] + legend_offset_x

      # Top edge
      @pdf.stroke_line [border_x, border_y], [border_x + border_width, border_y]
      # Right edge
      @pdf.stroke_line [border_x + border_width, border_y], [border_x + border_width, border_y - border_height]
      # Bottom edge
      @pdf.stroke_line [border_x + border_width, border_y - border_height], [border_x, border_y - border_height]
      # Left edge: bottom corner to legend start
      @pdf.stroke_line [border_x, border_y - border_height], [border_x, legend_y_start + legend_offset_y]
      # Left edge: legend end to top corner
      @pdf.stroke_line [border_x, legend_y_start + legend_total_width + legend_offset_y], [border_x, border_y]

      # Draw legend text (rotated counter-clockwise +90°)
      center_x = legend_x
      center_y = legend_y_start + legend_padding + (legend_width / 2) + legend_offset_y
      @pdf.rotate(90, origin: [center_x, center_y]) do
        @pdf.fill_color text_color
        @pdf.text_box legend,
                      at: [center_x - (legend_width / 2), center_y + (font_size / 2)],
                      width: legend_width,
                      height: font_size + 4,
                      valign: :center
      end
    end

    @pdf.stroke_color '000000'
    @pdf.fill_color '000000'
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
    # Need exactly 6 months per column to maintain balance and fit on one page
    # Multiple season labels needed where seasons span columns
    # Left column (6 months): Winter (Jan, Feb) + Spring (Mar, Apr, May, Jun)
    # Right column (6 months): Summer (Jul, Aug) + Fall (Sep, Oct, Nov) + Winter (Dec)
    # Note: June is grouped with Spring even though summer solstice is June 21

    label_offset = 2  # Reserve 2 boxes on left for seasonal labels
    half_width = (GRID_COLS - label_offset) / 2

    # Left column (6 months total)
    # Winter (Jan, Feb): top-left
    winter_left_row = 2
    draw_season_grid({ name: "Winter", months: [1, 2] }, label_offset, winter_left_row, half_width)

    # Spring (Mar, Apr, May, Jun): below Winter on left
    spring_left_row = winter_left_row + calculate_season_height(2)
    draw_season_grid({ name: "Spring", months: [3, 4, 5, 6] }, label_offset, spring_left_row, half_width)

    # Right column (6 months total)
    # Summer (Jul, Aug): top-right
    summer_row = 2
    draw_season_grid({ name: "Summer", months: [7, 8] }, label_offset + half_width, summer_row, half_width)

    # Fall (Sep, Oct, Nov): below Summer
    fall_row = summer_row + calculate_season_height(2)
    draw_season_grid({ name: "Fall", months: [9, 10, 11] }, label_offset + half_width, fall_row, half_width)

    # Winter (Dec): below Fall
    winter_right_row = fall_row + calculate_season_height(3)
    draw_season_grid({ name: "Winter", months: [12] }, label_offset + half_width, winter_right_row, half_width)
  end

  def calculate_season_height(num_months)
    # Each month needs: 1 box for title + 1 box for day headers + 6 boxes for calendar rows = 8
    # Plus 1 box spacing after each month
    (num_months * 8) + (num_months * 1)
  end

  def draw_season_grid(season, start_col, start_row, width_boxes)
    # Calculate season height
    height_boxes = calculate_season_height(season[:months].length)

    # Draw fieldset with legend on top edge (left-to-right reading)
    # Position the fieldset box starting 2 columns to the left (where the label will be)
    # Use inset_boxes: 0 to align border with grid box edges (tight spacing)
    # Offset legend 0.5 boxes to the right for better visual spacing
    # Use gray text color to match borders
    draw_fieldset(start_col, start_row, width_boxes, height_boxes, season[:name],
                  position: :top_left,
                  font_size: 10,
                  border_color: COLOR_BORDERS,
                  text_color: COLOR_BORDERS,
                  inset_boxes: 0,
                  legend_offset_x: grid_width(0.5))

    # Draw months in the content area
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

    # Draw diagnostic grid first (as background when DEBUG_GRID is enabled)
    draw_diagnostic_grid(label_every: 5)

    # Draw sidebars
    draw_week_sidebar(nil, calculate_total_weeks)
    draw_right_sidebar

    draw_year_at_glance("Year #{@year} - Events")
    draw_footer
  end

  def generate_year_at_glance_highlights
    @pdf.start_new_page
    @pdf.add_dest("year_highlights", @pdf.dest_fit)

    # Draw diagnostic grid first (as background when DEBUG_GRID is enabled)
    draw_diagnostic_grid(label_every: 5)

    # Draw sidebars
    draw_week_sidebar(nil, calculate_total_weeks)
    draw_right_sidebar

    draw_year_at_glance("Year #{@year} - Highlights")
    draw_footer
  end

  def draw_year_at_glance(title)
    # Grid-based layout:
    # - Columns 0-2: Left sidebar (3 boxes)
    # - Columns 3-41: Content area (39 boxes)
    # - Column 42: Right sidebar (1 box)
    # - Header: rows 0-1 (2 boxes)
    # - Month headers: row 2 (1 box)
    # - Days: rows 3-52 (50 rows for 31 days ≈ 1.613 rows per day)

    # Content area dimensions
    content_start_col = 3
    content_width_boxes = 39  # Columns 3-41 inclusive

    # Header - rows 0-1 (2 boxes, spans from left sidebar to right sidebar)
    header_box = grid_rect(content_start_col, 0, content_width_boxes, 2)
    @pdf.font "Helvetica-Bold", size: YEAR_TITLE_FONT_SIZE
    @pdf.text_box title,
                  at: [header_box[:x], header_box[:y]],
                  width: header_box[:width],
                  height: header_box[:height],
                  align: :center,
                  valign: :center

    # Calculate month column width (12 months across content area)
    col_width_boxes = content_width_boxes / 12.0  # ≈ 3.25 boxes per month

    # Month headers - row 2
    @pdf.font "Helvetica-Bold", size: YEAR_MONTH_HEADER_SIZE
    12.times do |month_index|
      month_name = @month_names[month_index]

      # Calculate column position (start from content_start_col)
      col_start = content_start_col + (month_index * col_width_boxes)
      cell_x = grid_x(0) + (col_start * DOT_SPACING)
      cell_y = grid_y(2)
      cell_width = col_width_boxes * DOT_SPACING
      cell_height = grid_height(1)

      # Calculate which week contains the 1st of this month
      first_of_month = Date.new(@year, month_index + 1, 1)
      first_day_of_year = Date.new(@year, 1, 1)
      days_back = (first_day_of_year.wday + 6) % 7
      year_start_monday = first_day_of_year - days_back
      days_from_start = (first_of_month - year_start_monday).to_i
      week_num = (days_from_start / 7) + 1

      # Draw month header cell
      @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
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

      # Add clickable link
      link_bottom = cell_y - cell_height
      @pdf.link_annotation([cell_x, link_bottom, cell_x + cell_width, cell_y],
                          Dest: "week_#{week_num}",
                          Border: [0, 0, 0])
    end

    # Days grid - rows 3-52 (50 rows for 31 days)
    # Each day gets 50/31 ≈ 1.613 rows
    day_height_rows = 50.0 / 31.0

    @pdf.font "Helvetica", size: YEAR_DAY_SIZE

    31.times do |day_index|
      day_num = day_index + 1

      # Calculate this day's row position
      day_row_start = 3 + (day_index * day_height_rows)

      12.times do |month_index|
        month = month_index + 1
        days_in_month = Date.new(@year, month, -1).day

        # Calculate cell position (start from content_start_col)
        col_start = content_start_col + (month_index * col_width_boxes)
        cell_x = grid_x(0) + (col_start * DOT_SPACING)
        cell_y = grid_y(0) - (day_row_start * DOT_SPACING)
        cell_width = col_width_boxes * DOT_SPACING
        cell_height = day_height_rows * DOT_SPACING

        # Only draw if this day exists in this month
        if day_num <= days_in_month
          # Draw day cell
          @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
            @pdf.stroke_color COLOR_BORDERS
            @pdf.stroke_bounds
            @pdf.stroke_color '000000'

            # Add day number and abbreviation
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
          @pdf.bounding_box([cell_x, cell_y], width: cell_width, height: cell_height) do
            @pdf.stroke_color COLOR_BORDERS
            @pdf.stroke_bounds
            @pdf.stroke_color '000000'
            @pdf.fill_color 'EEEEEE'
            @pdf.fill_rectangle [0, cell_height], cell_width, cell_height
            @pdf.fill_color '000000'
          end
        end
      end
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
    # Draw diagnostic grid first (as background when DEBUG_GRID is enabled)
    draw_diagnostic_grid(label_every: 5)

    # Grid-based layout:
    # - Columns 0-2: Left sidebar (3 boxes)
    # - Columns 3-41: Content area (39 boxes)
    # - Column 42: Right sidebar (1 box)
    # - Rows 0-1: Top nav/header (2 boxes)
    # - Rows 2-10: Daily section (9 boxes, ~17% of content)
    # - Rows 11-54: Notes section (44 boxes, ~83% of content)
    #   - Rows 11-45: Cues/Notes (35 boxes)
    #   - Rows 46-54: Summary (9 boxes, ~20% of notes section)

    end_date = start_date + 6

    # Content area dimensions
    content_start_col = 3
    content_start_row = 2
    content_width_boxes = 39  # Columns 3-41
    content_height_boxes = 53  # Rows 2-54

    # Section dimensions (in grid boxes)
    header_rows = 0  # Navigation is in row 0-1, content starts at row 2
    daily_rows = 9
    notes_main_rows = 35
    summary_rows = 9

    cues_cols = 10
    notes_cols = 29

    # Draw week sidebar on the left
    draw_week_sidebar(week_num, total_weeks)

    # Draw right sidebar with year page tabs
    draw_right_sidebar

    # Navigation and header - rows 0-1 (2 boxes)
    nav_box = grid_rect(content_start_col, 0, content_width_boxes, 2)

    # Navigation: "< 2025" link on the left (in gray)
    @pdf.font "Helvetica", size: FOOTER_FONT_SIZE
    @pdf.fill_color '888888'
    nav_year_width = grid_width(4)
    @pdf.text_box "< #{@year}",
                  at: [nav_box[:x], nav_box[:y]],
                  width: nav_year_width,
                  height: nav_box[:height],
                  valign: :center
    @pdf.fill_color '000000'
    @pdf.link_annotation([nav_box[:x], nav_box[:y] - nav_box[:height],
                          nav_box[:x] + nav_year_width, nav_box[:y]],
                        Dest: "seasonal",
                        Border: [0, 0, 0])

    # Navigation: "< w41" on the left (if not first week, in gray)
    if week_num > 1
      @pdf.fill_color '888888'
      nav_prev_x = nav_box[:x] + nav_year_width + grid_width(1)
      nav_prev_width = grid_width(3)
      @pdf.text_box "< w#{week_num - 1}",
                    at: [nav_prev_x, nav_box[:y]],
                    width: nav_prev_width,
                    height: nav_box[:height],
                    valign: :center
      @pdf.fill_color '000000'
      @pdf.link_annotation([nav_prev_x, nav_box[:y] - nav_box[:height],
                            nav_prev_x + nav_prev_width, nav_box[:y]],
                          Dest: "week_#{week_num - 1}",
                          Border: [0, 0, 0])
    end

    # Navigation: "w43 >" on the right (if not last week, in gray)
    if week_num < total_weeks
      nav_next_width = grid_width(3)
      nav_next_x = nav_box[:x] + nav_box[:width] - nav_next_width
      @pdf.fill_color '888888'
      @pdf.text_box "w#{week_num + 1} >",
                    at: [nav_next_x, nav_box[:y]],
                    width: nav_next_width,
                    height: nav_box[:height],
                    align: :right,
                    valign: :center
      @pdf.fill_color '000000'
      @pdf.link_annotation([nav_next_x, nav_box[:y] - nav_box[:height],
                            nav_next_x + nav_next_width, nav_box[:y]],
                          Dest: "week_#{week_num + 1}",
                          Border: [0, 0, 0])
    end

    # Title (centered)
    @pdf.font "Helvetica-Bold", size: WEEKLY_TITLE_FONT_SIZE
    title_x = nav_box[:x] + grid_width(8)
    title_width = nav_box[:width] - grid_width(16)
    @pdf.text_box "Week #{week_num}: #{start_date.strftime('%b %-d')} - #{end_date.strftime('%b %-d, %Y')}",
                  at: [title_x, nav_box[:y]],
                  width: title_width,
                  height: nav_box[:height],
                  align: :center,
                  valign: :center

    # Daily section - rows 2-10 (9 rows), 7 columns (Monday through Sunday)
    daily_box = grid_rect(content_start_col, content_start_row, content_width_boxes, daily_rows)
    day_col_width_boxes = content_width_boxes / 7.0  # ~5.57 boxes per day

    # Draw day headers and lines
    @pdf.font "Helvetica-Bold", size: WEEKLY_DAY_HEADER_FONT_SIZE
    7.times do |i|
      date = start_date + i
      day_name = date.strftime('%A')  # Full day name (Monday, Tuesday, etc.)

      day_x = daily_box[:x] + (i * day_col_width_boxes * DOT_SPACING)
      day_width = day_col_width_boxes * DOT_SPACING

      @pdf.bounding_box([day_x, daily_box[:y]], width: day_width, height: daily_box[:height]) do
        # Add subtle background for Saturday (5) and Sunday (6)
        if i == 5 || i == 6  # Saturday and Sunday
          @pdf.fill_color COLOR_WEEKEND_BG
          @pdf.fill_rectangle [0, daily_box[:height]], day_width, daily_box[:height]
          @pdf.fill_color '000000'
        end

        @pdf.stroke_color COLOR_BORDERS
        @pdf.stroke_bounds
        @pdf.stroke_color '000000'

        # Day header
        @pdf.text_box "#{day_name}\n#{date.strftime('%-m/%-d')}",
                     at: [WEEKLY_DAY_HEADER_PADDING, daily_box[:height] - WEEKLY_DAY_HEADER_PADDING],
                     width: day_width - (WEEKLY_DAY_HEADER_PADDING * 2),
                     height: WEEKLY_DAY_HEADER_HEIGHT,
                     align: :center,
                     size: WEEKLY_DAY_DATE_FONT_SIZE

        # Draw evenly-spaced lines for notes
        @pdf.font "Helvetica", size: YEAR_DAY_SIZE
        line_start_y = daily_box[:height] - WEEKLY_DAY_LINES_START
        available_space = daily_box[:height] - WEEKLY_DAY_LINES_PADDING
        line_spacing = available_space / WEEKLY_DAY_LINES_COUNT

        WEEKLY_DAY_LINES_COUNT.to_i.times do |line_num|
          y_pos = line_start_y - (line_num * line_spacing)
          @pdf.stroke_color COLOR_BORDERS
          @pdf.stroke_horizontal_line WEEKLY_DAY_LINE_MARGIN, day_width - WEEKLY_DAY_LINE_MARGIN, at: y_pos
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

    # Cornell notes section - rows 11-54
    # Cues/Notes section: rows 11-45 (35 boxes)
    # Summary section: rows 46-54 (9 boxes)

    notes_start_row = content_start_row + daily_rows
    cues_box = grid_rect(content_start_col, notes_start_row, cues_cols, notes_main_rows)
    notes_box = grid_rect(content_start_col + cues_cols, notes_start_row, notes_cols, notes_main_rows)
    summary_box = grid_rect(content_start_col, notes_start_row + notes_main_rows, content_width_boxes, summary_rows)

    @pdf.font "Helvetica-Bold", size: WEEKLY_NOTES_HEADER_FONT_SIZE

    # Cue column
    @pdf.bounding_box([cues_box[:x], cues_box[:y]],
                     width: cues_box[:width],
                     height: cues_box[:height]) do
      @pdf.stroke_color COLOR_BORDERS
      @pdf.stroke_bounds
      @pdf.stroke_color '000000'
      @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
      @pdf.fill_color COLOR_SECTION_HEADERS
      @pdf.text "Cues/Questions", align: :center, size: WEEKLY_NOTES_LABEL_FONT_SIZE
      @pdf.fill_color '000000'
      draw_dot_grid(cues_box[:width], cues_box[:height])
    end

    # Notes column
    @pdf.bounding_box([notes_box[:x], notes_box[:y]],
                     width: notes_box[:width],
                     height: notes_box[:height]) do
      @pdf.stroke_color COLOR_BORDERS
      @pdf.stroke_bounds
      @pdf.stroke_color '000000'
      @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
      @pdf.fill_color COLOR_SECTION_HEADERS
      @pdf.text "Notes", align: :center, size: WEEKLY_NOTES_LABEL_FONT_SIZE
      @pdf.fill_color '000000'
      draw_dot_grid(notes_box[:width], notes_box[:height])
    end

    # Summary section (spans full width)
    @pdf.bounding_box([summary_box[:x], summary_box[:y]],
                     width: summary_box[:width],
                     height: summary_box[:height]) do
      @pdf.stroke_color COLOR_BORDERS
      @pdf.stroke_bounds
      @pdf.stroke_color '000000'
      @pdf.font "Helvetica-Bold", size: WEEKLY_NOTES_LABEL_FONT_SIZE
      @pdf.move_down WEEKLY_NOTES_HEADER_PADDING
      @pdf.fill_color COLOR_SECTION_HEADERS
      @pdf.text "Summary", align: :center
      @pdf.fill_color '000000'
      draw_dot_grid(summary_box[:width], summary_box[:height])
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
    # Grid-based week sidebar:
    # - Width: 2 boxes (columns 0-1)
    # - Start at row 2 (leaving rows 0-1 for header)
    # - One week per row (53 rows available: rows 2-54)
    # - Internal padding: 0.5 boxes on each side

    sidebar_width_boxes = 2
    sidebar_start_row = 2
    padding_boxes = 0.5

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
      row = sidebar_start_row + i  # One week per row, starting at row 2

      # Get grid coordinates for this week's row
      week_box = grid_rect(0, row, sidebar_width_boxes, 1)

      # Build the display text
      month_letter = week_months[week]
      display_text = month_letter ? "#{month_letter} w#{week}" : "w#{week}"

      if week == current_week_num
        # Current week: bold, no link
        @pdf.font "Helvetica-Bold", size: WEEKLY_SIDEBAR_FONT_SIZE
        @pdf.fill_color '000000'
        @pdf.text_box display_text,
                      at: [week_box[:x] + grid_width(padding_boxes), week_box[:y]],
                      width: week_box[:width] - grid_width(padding_boxes * 2),
                      height: week_box[:height],
                      align: :right,
                      valign: :center
        @pdf.font "Helvetica", size: WEEKLY_SIDEBAR_FONT_SIZE
      else
        # Other weeks: gray, with link
        @pdf.fill_color '888888'
        @pdf.text_box display_text,
                      at: [week_box[:x] + grid_width(padding_boxes), week_box[:y]],
                      width: week_box[:width] - grid_width(padding_boxes * 2),
                      height: week_box[:height],
                      align: :right,
                      valign: :center

        # Link annotation rect: [left, bottom, right, top]
        link_left = week_box[:x]
        link_bottom = week_box[:y] - week_box[:height]
        link_right = week_box[:x] + week_box[:width]
        link_top = week_box[:y]

        @pdf.link_annotation([link_left, link_bottom, link_right, link_top],
                            Dest: "week_#{week}",
                            Border: [0, 0, 0])
        @pdf.fill_color '000000'
      end
    end
  end

  # Draw right sidebar navigation with automatic tab positioning
  # Accepts lists of top-aligned and bottom-aligned menu items
  # Automatically calculates row positions and stacks tabs accordingly
  #
  # top_tabs: array of {label:, dest:} hashes (stack top-to-bottom, left-aligned)
  # bottom_tabs: array of {label:, dest:} hashes (stack bottom-to-top, right-aligned)
  # start_row: starting row for top tabs (default: 1)
  # tab_height: height of each tab in boxes (default: 3)
  # sidebar_col: column position for tabs (default: 42)
  #
  # Example:
  #   draw_right_sidebar_nav(
  #     top_tabs: [
  #       { label: "Year", dest: "seasonal" },
  #       { label: "Events", dest: "year_events" }
  #     ],
  #     bottom_tabs: [
  #       { label: "Dots", dest: "dots" }
  #     ]
  #   )
  def draw_right_sidebar_nav(top_tabs: [], bottom_tabs: [], start_row: 1, tab_height: 3, sidebar_col: 42)
    # Draw top-aligned tabs (stack downward from start_row)
    top_tabs.each_with_index do |tab, idx|
      row = start_row + (idx * tab_height)
      draw_right_nav_tab(sidebar_col, row, tab_height, tab[:label], tab[:dest], align: :left)
    end

    # Draw bottom-aligned tabs (stack upward from bottom)
    bottom_tabs.each_with_index do |tab, idx|
      # Start from bottommost position and work upward
      row = GRID_ROWS - tab_height - (idx * tab_height)
      draw_right_nav_tab(sidebar_col, row, tab_height, tab[:label], tab[:dest], align: :right)
    end
  end

  def draw_right_sidebar
    # Grid-based right sidebar using declarative menu lists
    draw_right_sidebar_nav(
      top_tabs: [
        { label: "Year", dest: "seasonal" },
        { label: "Events", dest: "year_events" },
        { label: "Highlights", dest: "year_highlights" }
      ],
      bottom_tabs: [
        { label: "Dots", dest: "dots" }
      ]
    )
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
