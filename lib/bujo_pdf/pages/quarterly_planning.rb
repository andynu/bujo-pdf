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
      # @param text [String] Link text
      # @param dest [String] Named destination
      # @param nav_color [String] Text color
      # @param border_color [String] Background color
      # @return [void]
      def draw_nav_link(col, text, dest, nav_color, border_color)
        link_width = @grid_system.width(3)
        link_height = @grid_system.height(1)
        link_x = @grid_system.x(col)
        link_y = @grid_system.y(0)

        # Draw background
        inset = 2
        @pdf.transparent(0.2) do
          @pdf.fill_color border_color
          @pdf.fill_rounded_rectangle(
            [link_x + inset, link_y - inset],
            link_width - (inset * 2),
            link_height - (inset * 2),
            2
          )
        end

        # Draw text
        @pdf.font "Helvetica", size: NAV_FONT_SIZE
        @pdf.fill_color nav_color
        @pdf.text_box text,
                      at: [link_x, link_y],
                      width: link_width,
                      height: link_height,
                      align: :center,
                      valign: :center

        # Link annotation
        @pdf.link_annotation(
          [link_x, link_y - link_height, link_x + link_width, link_y],
          Dest: dest,
          Border: [0, 0, 0]
        )

        # Reset color
        @pdf.fill_color BujoPdf::Themes.current[:colors][:text_black]
      end

      # Draw the quarter header with date range
      #
      # @return [void]
      def draw_header
        header_box = @grid_system.rect(2, 1, 39, 4)

        @pdf.bounding_box([header_box[:x], header_box[:y]],
                          width: header_box[:width],
                          height: header_box[:height]) do
          # Quarter name
          @pdf.text "Q#{@quarter} #{@year}",
                    size: 20,
                    style: :bold,
                    align: :left,
                    valign: :center

          # Date range
          start_month = Date::MONTHNAMES[@start_date.month]
          end_month = Date::MONTHNAMES[@end_date.month]
          @pdf.text "#{start_month} - #{end_month}",
                    size: 12,
                    color: '666666',
                    align: :left,
                    valign: :bottom
        end
      end

      # Draw the goals section with prompts
      #
      # @return [void]
      def draw_goals_section
        # Goals header
        goals_header_box = @grid_system.rect(2, 6, 39, 2)
        @pdf.bounding_box([goals_header_box[:x], goals_header_box[:y]],
                          width: goals_header_box[:width],
                          height: goals_header_box[:height]) do
          @pdf.text "Quarter Goals",
                    size: 14,
                    style: :bold,
                    align: :left,
                    valign: :bottom
        end

        # Prompt text
        prompt_box = @grid_system.rect(2, 8, 39, 2)
        @pdf.bounding_box([prompt_box[:x], prompt_box[:y]],
                          width: prompt_box[:width],
                          height: prompt_box[:height]) do
          @pdf.text "What are the 2-3 most important things to accomplish this quarter?",
                    size: 10,
                    style: :italic,
                    color: '999999',
                    align: :left,
                    valign: :top
        end

        # Goal lines (3 lines)
        draw_goal_lines(10, 3)
      end

      # Draw goal entry lines
      #
      # @param start_row [Integer] Starting row
      # @param count [Integer] Number of lines
      # @return [void]
      def draw_goal_lines(start_row, count)
        @pdf.stroke_color 'E5E5E5'
        @pdf.line_width 0.5

        count.times do |i|
          row = start_row + (i * 2)
          line_y = @grid_system.y(row + 2) + 3

          # Number prefix
          num_box = @grid_system.rect(2, row, 2, 2)
          @pdf.bounding_box([num_box[:x], num_box[:y]],
                            width: num_box[:width],
                            height: num_box[:height]) do
            @pdf.text "#{i + 1}.",
                      size: 10,
                      color: '999999',
                      align: :right,
                      valign: :bottom
          end

          # Line
          @pdf.stroke_line [@grid_system.x(5), line_y], [@grid_system.x(41), line_y]
        end

        @pdf.stroke_color '000000'
      end

      # Draw the 12-week grid
      #
      # @return [void]
      def draw_week_grid
        grid_start_row = 18

        # Week grid header
        header_box = @grid_system.rect(2, grid_start_row, 39, 2)
        @pdf.bounding_box([header_box[:x], header_box[:y]],
                          width: header_box[:width],
                          height: header_box[:height]) do
          @pdf.text "12-Week Focus",
                    size: 14,
                    style: :bold,
                    align: :left,
                    valign: :bottom
        end

        # Calculate first week number of this quarter
        first_week = calculate_first_week_of_quarter

        # Draw week rows (12 weeks, 2.5 rows each = 30 rows total)
        WEEKS_PER_QUARTER.times do |i|
          week_num = first_week + i
          row = grid_start_row + 3 + (i * 2.5).to_i
          draw_week_row(week_num, row)
        end
      end

      # Draw a single week row in the grid
      #
      # @param week_num [Integer] Week number in the year
      # @param row [Integer] Grid row
      # @return [void]
      def draw_week_row(week_num, row)
        # Week label
        label_box = @grid_system.rect(2, row, 6, 2)
        @pdf.bounding_box([label_box[:x], label_box[:y]],
                          width: label_box[:width],
                          height: label_box[:height]) do
          @pdf.text "Week #{week_num}",
                    size: 9,
                    color: '666666',
                    align: :left,
                    valign: :center
        end

        # Line for notes
        line_y = @grid_system.y(row + 1.5)
        @pdf.stroke_color 'E5E5E5'
        @pdf.line_width 0.5
        @pdf.stroke_line [@grid_system.x(8), line_y], [@grid_system.x(41), line_y]
        @pdf.stroke_color '000000'

        # Clickable link to weekly page
        total_weeks = context[:total_weeks] || 52
        if week_num >= 1 && week_num <= total_weeks
          @grid_system.link(2, row, 39, 2, "week_#{week_num}")
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
