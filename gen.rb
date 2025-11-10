#!/usr/bin/env ruby
require 'prawn'
require 'date'

class PlannerGenerator
  PAGE_WIDTH = 612    # 8.5 inches
  PAGE_HEIGHT = 792   # 11 inches
  FOOTER_HEIGHT = 25

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
    @pdf.font "Helvetica-Bold", size: 16
    @pdf.text_box title,
                  at: [40, PAGE_HEIGHT - 40],
                  width: PAGE_WIDTH - 80,
                  align: :center

    # Calculate dimensions
    usable_height = PAGE_HEIGHT - 80 - FOOTER_HEIGHT  # Leave space for title and footer
    usable_width = PAGE_WIDTH - 80  # Margins

    # Calculate cell dimensions - 31 rows (max days) + 1 header
    cell_height = usable_height / 32.0
    cell_width = usable_width / 12.0

    start_x = 40
    start_y = PAGE_HEIGHT - 100

    # Draw header row with month names
    @pdf.font "Helvetica-Bold", size: 8
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
        @pdf.stroke_bounds
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
    @pdf.font "Helvetica", size: 6
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
            @pdf.stroke_bounds

            # Add day number in corner
            date = Date.new(@year, month, day_num)
            day_abbrev = date.strftime('%a')[0..1]  # Mo, Tu, We, etc.

            @pdf.text_box "#{day_num}",
                         at: [2, cell_height - 2],
                         width: cell_width - 4,
                         height: cell_height - 4,
                         size: 6,
                         overflow: :shrink_to_fit

            # Add day of week abbreviation
            @pdf.text_box day_abbrev,
                         at: [2, 8],
                         width: cell_width - 4,
                         height: 8,
                         size: 5,
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
            @pdf.stroke_bounds
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
    usable_height = PAGE_HEIGHT - 80 - FOOTER_HEIGHT  # 80pt for title/margins
    daily_section_height = usable_height * 0.35  # 35% for daily section
    notes_section_height = usable_height * 0.65  # 65% for Cornell notes

    sidebar_width = 30
    start_x = 40 + sidebar_width
    start_y = PAGE_HEIGHT - 40
    content_width = PAGE_WIDTH - start_x - 40  # Available width excluding sidebar and right margin

    # Draw week sidebar on the left
    draw_week_sidebar(week_num, total_weeks)

    # Navigation: "< 2025" link on the left (in gray)
    @pdf.font "Helvetica", size: 10
    nav_height = 20
    @pdf.fill_color '888888'
    @pdf.text_box "< #{@year}",
                  at: [start_x, start_y],
                  width: 60,
                  height: nav_height
    @pdf.fill_color '000000'
    # Link rect: [left, bottom, right, top]
    @pdf.link_annotation([start_x, start_y - nav_height, start_x + 60, start_y],
                        Dest: "year_events",
                        Border: [0, 0, 0])

    # Navigation: "< w41" on the left (if not first week, in gray)
    if week_num > 1
      @pdf.fill_color '888888'
      @pdf.text_box "< w#{week_num - 1}",
                    at: [start_x + 70, start_y],
                    width: 60,
                    height: nav_height
      @pdf.fill_color '000000'
      @pdf.link_annotation([start_x + 70, start_y - nav_height, start_x + 130, start_y],
                          Dest: "week_#{week_num - 1}",
                          Border: [0, 0, 0])
    end

    # Navigation: "w43 >" on the right (if not last week, in gray)
    if week_num < total_weeks
      next_x = PAGE_WIDTH - start_x - 60
      @pdf.fill_color '888888'
      @pdf.text_box "w#{week_num + 1} >",
                    at: [next_x, start_y],
                    width: 60,
                    height: nav_height,
                    align: :right
      @pdf.fill_color '000000'
      @pdf.link_annotation([next_x, start_y - nav_height, next_x + 60, start_y],
                          Dest: "week_#{week_num + 1}",
                          Border: [0, 0, 0])
    end

    # Title (centered)
    @pdf.font "Helvetica-Bold", size: 14
    @pdf.text_box "Week #{week_num}: #{start_date.strftime('%b %-d')} - #{end_date.strftime('%b %-d, %Y')}",
                  at: [start_x + 140, start_y],
                  width: content_width - 210,
                  align: :center

    # Daily section - 7 columns (Monday through Sunday)
    column_width = content_width / 7.0
    daily_start_y = start_y - 40

    # Draw day headers and lines
    @pdf.font "Helvetica-Bold", size: 9
    7.times do |i|
      date = start_date + i
      day_name = date.strftime('%A')  # Full day name (Monday, Tuesday, etc.)
      x = start_x + (i * column_width)

      @pdf.bounding_box([x, daily_start_y], width: column_width, height: daily_section_height) do
        @pdf.stroke_bounds

        # Day header
        @pdf.text_box "#{day_name}\n#{date.strftime('%-m/%-d')}",
                     at: [2, daily_section_height - 2],
                     width: column_width - 4,
                     height: 30,
                     align: :center,
                     size: 8

        # Draw 4 evenly-spaced lines for notes
        @pdf.font "Helvetica", size: 6
        line_start_y = daily_section_height - 35
        available_space = daily_section_height - 40
        line_spacing = available_space / 4.0

        4.times do |line_num|
          y_pos = line_start_y - (line_num * line_spacing)
          @pdf.stroke_color 'CCCCCC'
          @pdf.stroke_horizontal_line 3, column_width - 3, at: y_pos
          @pdf.stroke_color '000000'
        end
      end
    end

    # Cornell notes section
    notes_start_y = daily_start_y - daily_section_height - 10

    # Draw Cornell notes layout per spec: 25% cues, 75% notes
    cue_column_width = content_width * 0.25
    notes_column_width = content_width * 0.75
    summary_height = notes_section_height * 0.20  # 20% for summary
    main_notes_height = notes_section_height - summary_height - 5

    @pdf.font "Helvetica-Bold", size: 10

    # Cue column
    @pdf.bounding_box([start_x, notes_start_y],
                     width: cue_column_width,
                     height: main_notes_height) do
      @pdf.stroke_bounds
      @pdf.text "Cues/Questions", align: :center, size: 9
      draw_dot_grid(cue_column_width, main_notes_height)
    end

    # Notes column
    @pdf.bounding_box([start_x + cue_column_width, notes_start_y],
                     width: notes_column_width,
                     height: main_notes_height) do
      @pdf.stroke_bounds
      @pdf.text "Notes", align: :center, size: 9
      draw_dot_grid(notes_column_width, main_notes_height)
    end

    # Summary section (spans full width)
    summary_start_y = notes_start_y - main_notes_height - 5
    @pdf.bounding_box([start_x, summary_start_y],
                     width: cue_column_width + notes_column_width,
                     height: summary_height) do
      @pdf.stroke_bounds
      @pdf.font "Helvetica-Bold", size: 9
      @pdf.text "Summary", align: :center
      draw_dot_grid(cue_column_width + notes_column_width, summary_height)
    end
  end

  def draw_dot_grid(width, height)
    # 5mm in points: 5mm = 5/25.4 inches * 72 points/inch ≈ 14.17 points
    dot_spacing = 14.17
    dot_radius = 0.5  # Small dot radius in points

    @pdf.fill_color 'CCCCCC'

    # Calculate starting positions with padding
    padding = 5
    start_x = padding
    start_y = height - padding

    # Draw dots in a grid pattern
    y = start_y
    while y > padding
      x = start_x
      while x < width - padding
        @pdf.fill_circle [x, y], dot_radius
        x += dot_spacing
      end
      y -= dot_spacing
    end

    @pdf.fill_color '000000'
  end

  def draw_week_sidebar(current_week_num, total_weeks)
    sidebar_x = 40
    sidebar_width = 30
    start_y = PAGE_HEIGHT - 80
    usable_height = PAGE_HEIGHT - 80 - FOOTER_HEIGHT

    # Calculate spacing for all weeks
    line_height = usable_height / total_weeks.to_f

    @pdf.font "Helvetica", size: 7

    total_weeks.times do |i|
      week = i + 1
      y_top = start_y - (i * line_height)  # Top of this week's text box
      y_bottom = y_top - line_height       # Bottom of this week's text box

      if week == current_week_num
        # Current week: bold, no link
        @pdf.font "Helvetica-Bold", size: 7
        @pdf.fill_color '000000'
        @pdf.text_box "w#{week}",
                      at: [sidebar_x, y_top],
                      width: sidebar_width,
                      height: line_height,
                      align: :center,
                      valign: :center
        @pdf.font "Helvetica", size: 7
      else
        # Other weeks: gray, with link
        @pdf.fill_color '888888'
        @pdf.text_box "w#{week}",
                      at: [sidebar_x, y_top],
                      width: sidebar_width,
                      height: line_height,
                      align: :center,
                      valign: :center
        # Link annotation rect using absolute coordinates: [left, bottom, right, top]
        @pdf.link_annotation([sidebar_x, y_bottom, sidebar_x + sidebar_width, y_top],
                            Dest: "week_#{week}",
                            Border: [0, 0, 0])
        @pdf.fill_color '000000'
      end
    end
  end

  def draw_footer
    # Footer with month links at bottom of page
    footer_y = FOOTER_HEIGHT
    link_width = (PAGE_WIDTH - 80) / 12.0
    start_x = 40

    @pdf.bounding_box([0, footer_y], width: PAGE_WIDTH, height: FOOTER_HEIGHT) do
      @pdf.stroke_color 'AAAAAA'
      @pdf.stroke do
        @pdf.horizontal_line 40, PAGE_WIDTH - 40, at: FOOTER_HEIGHT - 2
      end
      @pdf.stroke_color '000000'

      @pdf.font "Helvetica", size: 10

      12.times do |i|
        x = start_x + (i * link_width)
        month_letter = @month_names[i][0]  # First letter of month

        @pdf.bounding_box([x, FOOTER_HEIGHT - 5], width: link_width, height: 15) do
          # Calculate which week contains the first of this month
          first_of_month = Date.new(@year, i + 1, 1)
          first_day_of_year = Date.new(@year, 1, 1)

          # Calculate the Monday that starts the year
          days_back = (first_day_of_year.wday + 6) % 7
          year_start_monday = first_day_of_year - days_back

          # Calculate which week contains this month's first day
          days_from_start = (first_of_month - year_start_monday).to_i
          week_num = (days_from_start / 7) + 1

          # Draw the month letter (links to week)
          @pdf.font "Helvetica", size: 10
          @pdf.text_box month_letter,
                        at: [0, 15],
                        width: link_width * 0.6,
                        height: 15,
                        align: :center

          # Add clickable link to week
          @pdf.link_annotation([0, 0, link_width * 0.6, 15],
                              Dest: "week_#{week_num}",
                              Border: [0, 0, 0])

          # Draw small "Y" link (links to year-at-a-glance)
          @pdf.font "Helvetica", size: 7
          @pdf.text_box "Y",
                        at: [link_width * 0.6, 15],
                        width: link_width * 0.4,
                        height: 15,
                        align: :center

          # Add clickable link to year-at-a-glance
          @pdf.link_annotation([link_width * 0.6, 0, link_width, 15],
                              Dest: "year_events",
                              Border: [0, 0, 0])
        end
      end
    end
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
