# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Quarterly planning page for 12-week planning cycles.
    #
    # Inspired by "12 Week Year" methodology, this template provides a
    # quarter-at-a-glance view with goal-setting prompts and a 12-week
    # grid for tracking weekly targets.
    #
    # Design:
    # - Top navigation with prev/next quarter links
    # - Quarter header with date range
    # - Goals section with prompts
    # - 12-week grid with week numbers
    # - Links to corresponding weekly pages
    #
    # Example:
    #   context = RenderContext.new(
    #     page_key: :quarter_1,
    #     quarter: 1,  # Q1 (Jan-Mar)
    #     year: 2025
    #   )
    #   page = QuarterlyPlanning.new(pdf, context)
    #   page.generate
    class QuarterlyPlanning < Base
      register_page :quarterly_planning,
        title: "Q%{quarter} Planning",
        dest: "quarter_%{quarter}"

      # Mixin providing quarterly_planning_page and quarterly_planning_pages verbs.
      module Mixin
        include MixinSupport

        # Generate a single quarterly planning page.
        #
        # @param quarter [Integer] Quarter number (1-4)
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def quarterly_planning_page(quarter:)
          define_page(dest: "quarter_#{quarter}", title: "Q#{quarter} Planning", type: :quarterly_planning,
                      quarter: quarter) do |ctx|
            QuarterlyPlanning.new(@pdf, ctx).generate
          end
        end

        # Generate all quarterly planning pages (4 pages).
        #
        # @return [Array<PageRef>, nil] Array of PageRefs during define phase
        def quarterly_planning_pages
          (1..4).map do |quarter|
            quarterly_planning_page(quarter: quarter)
          end
        end
      end

      NAV_FONT_SIZE = 8
      # Quarter date ranges (start month, end month)
      QUARTER_MONTHS = {
        1 => [1, 3],   # Q1: Jan-Mar
        2 => [4, 6],   # Q2: Apr-Jun
        3 => [7, 9],   # Q3: Jul-Sep
        4 => [10, 12]  # Q4: Oct-Dec
      }.freeze

      # Weeks per quarter (approximately 13, but we show 12 for clean grid)
      WEEKS_PER_QUARTER = 12

      # Layout constants - grid-quantized positions
      HEADER_ROW = 2
      HEADER_HEIGHT = 3

      GOALS_START_ROW = 6
      GOALS_HEADER_HEIGHT = 1
      GOALS_PROMPT_HEIGHT = 2
      GOALS_LINE_HEIGHT = 2
      GOALS_COUNT = 3
      GOALS_NUM_COL_WIDTH = 3

      WEEK_GRID_START_ROW = 16
      WEEK_GRID_HEADER_HEIGHT = 2
      WEEK_LABEL_WIDTH = 6

      def setup
        @quarter = context[:quarter] || 1
        @year = context[:year]

        # Calculate date range for this quarter
        start_month, end_month = QUARTER_MONTHS[@quarter]
        @start_date = Date.new(@year, start_month, 1)
        @end_date = Date.new(@year, end_month, -1)  # Last day of end month

        # Set named destination for this quarter
        set_destination("quarter_#{@quarter}")

        use_layout :full_page
      end

      def render
        draw_navigation
        draw_header
        draw_goals_section
        draw_week_grid
      end

      private

      # Draw the top navigation with prev/next quarter links
      #
      # @return [void]
      def draw_navigation
        require_relative '../themes/theme_registry'
        nav_color = BujoPdf::Themes.current[:colors][:text_gray]
        border_color = BujoPdf::Themes.current[:colors][:borders]

        # Previous quarter link (if not Q1)
        if @quarter > 1
          draw_nav_link(2, "< Q#{@quarter - 1}", "quarter_#{@quarter - 1}", nav_color, border_color)
        end

        # Next quarter link (if not Q4)
        if @quarter < 4
          draw_nav_link(39, "Q#{@quarter + 1} >", "quarter_#{@quarter + 1}", nav_color, border_color)
        end
      end

      # Draw a navigation link with background
      #
      # @param col [Integer] Column position
      # @param link_text [String] Link text
      # @param dest [String] Named destination
      # @param nav_color [String] Text color
      # @param border_color [String] Background color
      # @return [void]
      def draw_nav_link(col, link_text, dest, nav_color, border_color)
        # Draw background using box verb
        box(col, 0, 3, 1, fill: border_color, stroke: nil, opacity: 0.2, radius: 2)

        # Draw text using text verb
        text(col, 0, link_text, size: NAV_FONT_SIZE, color: nav_color, align: :center, width: 3)

        # Link annotation using grid helper
        @grid.link(col, 0, 3, 1, dest)
      end

      # Draw the quarter header with date range
      #
      # @return [void]
      def draw_header
        # Main title: Q1 2025
        text(2, HEADER_ROW, "Q#{@quarter} #{@year}",
             size: 20, style: :bold, height: 2, position: :subscript)

        # Subtitle: date range
        start_month = Date::MONTHNAMES[@start_date.month]
        end_month = Date::MONTHNAMES[@end_date.month]
        text(2, HEADER_ROW + 2, "#{start_month} - #{end_month}",
             size: 12, color: '666666', height: 1, position: :center)
      end

      # Draw the goals section with prompts
      #
      # @return [void]
      def draw_goals_section
        # h1 header for "Quarter Goals"
        h1(2, GOALS_START_ROW, "Quarter Goals", position: :subscript)

        # Prompt text
        prompt_row = GOALS_START_ROW + GOALS_HEADER_HEIGHT
        text(2, prompt_row, "What are the 2-3 most important things to accomplish this quarter?",
             size: 10, style: :italic, color: '999999', height: GOALS_PROMPT_HEIGHT)

        # Goal lines using divide_rows for consistent spacing
        lines_start_row = prompt_row + GOALS_PROMPT_HEIGHT
        lines_height = GOALS_COUNT * GOALS_LINE_HEIGHT

        rows = @grid.divide_rows(row: lines_start_row, height: lines_height, count: GOALS_COUNT)

        rows.each_with_index do |row_info, i|
          draw_goal_line(row_info.row, i + 1)
        end
      end

      # Draw a single goal entry line with number prefix
      #
      # @param row [Integer] Starting row for this line
      # @param number [Integer] Goal number (1, 2, 3...)
      # @return [void]
      def draw_goal_line(row, number)
        # Number prefix (right-aligned)
        text(2, row, "#{number}.", size: 10, color: '999999',
             width: GOALS_NUM_COL_WIDTH, height: GOALS_LINE_HEIGHT,
             align: :right, position: :subscript)

        # Ruled line for writing - single line at bottom of entry area
        line_col = 2 + GOALS_NUM_COL_WIDTH + 1
        line_width = 41 - line_col
        hline(line_col, row + GOALS_LINE_HEIGHT, line_width)
      end

      # Draw the 12-week grid
      #
      # @return [void]
      def draw_week_grid
        # h1 header for "12-Week Focus"
        h1(2, WEEK_GRID_START_ROW, "12-Week Focus", position: :subscript)

        # Calculate first week number of this quarter
        first_week = calculate_first_week_of_quarter

        # Calculate available height for week rows
        weeks_start_row = WEEK_GRID_START_ROW + WEEK_GRID_HEADER_HEIGHT
        available_height = 54 - weeks_start_row  # Use rows to 54 (36 rows for 12 weeks = 3 each)

        # Use divide_rows for consistent week spacing
        rows = @grid.divide_rows(
          row: weeks_start_row,
          height: available_height,
          count: WEEKS_PER_QUARTER
        )

        rows.each_with_index do |row_info, i|
          week_num = first_week + i
          draw_week_row(week_num, row_info.row, row_info.height)
        end
      end

      # Draw a single week row in the grid
      #
      # @param week_num [Integer] Week number in the year
      # @param row [Integer] Grid row
      # @param height [Integer] Row height in grid boxes
      # @return [void]
      def draw_week_row(week_num, row, height)
        # Week label - right-aligned to col 4 (matching goals list indent)
        text(2, row, "Week #{week_num}", size: 9, color: '666666',
             width: GOALS_NUM_COL_WIDTH, height: 1,
             align: :right, position: :center)

        # Ruled line for notes - at bottom of row area, starting at col 6
        line_col = 6
        line_width = 41 - line_col
        hline(line_col, row + height, line_width)

        # Clickable link to weekly page
        total_weeks = context[:total_weeks] || 52
        if week_num >= 1 && week_num <= total_weeks
          @grid_system.link(2, row, 39, height, "week_#{week_num}")
        end
      end

      # Calculate the first week number of this quarter
      #
      # @return [Integer] First week number
      def calculate_first_week_of_quarter
        # Find which week number corresponds to the first day of the quarter
        start_month, = QUARTER_MONTHS[@quarter]
        first_of_quarter = Date.new(@year, start_month, 1)

        # Use the date calculator if available
        if defined?(Utilities::DateCalculator)
          Utilities::DateCalculator.week_number_for_date(@year, first_of_quarter)
        else
          # Fallback calculation
          ((@quarter - 1) * 13) + 1
        end
      end
    end
  end
end
