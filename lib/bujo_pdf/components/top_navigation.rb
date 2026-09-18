# frozen_string_literal: true

require_relative '../base/component'
require_relative 'link_box'
require_relative 'month_nav'

module BujoPdf
  module Components
    # TopNavigation component for weekly pages.
    #
    # Renders the top navigation bar with:
    #   - Year link on the left (links to seasonal calendar)
    #   - Previous week link (if not first week)
    #   - Centered week title with date range
    #   - Next week link (if not last week)
    #
    # Navigation links use LinkBox for consistent styling with
    # rounded rectangle backgrounds (20% opacity).
    #
    # @example Using WeekContext (preferred)
    #   ctx = WeekContext.new(year: 2025, number: 42)
    #   nav = TopNavigation.new(canvas: canvas, week_context: ctx)
    #   nav.render
    #
    # @example Legacy usage with individual parameters
    #   nav = TopNavigation.new(
    #     canvas: canvas,
    #     year: 2025,
    #     week_num: 42,
    #     total_weeks: 52,
    #     week_start: Date.new(2025, 10, 13),
    #     week_end: Date.new(2025, 10, 19)
    #   )
    #   nav.render
    class TopNavigation < Component
      include LinkBox::Mixin

      NAV_FONT_SIZE = 8
      TITLE_FONT_SIZE = 14

      # Chip strip layout (chips: true mode)
      CHIPS_START_COL = 2
      CHIPS_ROW = 0.15
      TITLE_RIGHT_COL = 42

      # @param canvas [Canvas] The canvas to render on
      # @param week_context [WeekContext, nil] Week context bundling all week data (preferred)
      # @param year [Integer, nil] The planner year (legacy, use week_context instead)
      # @param week_num [Integer, nil] Week number (legacy, use week_context instead)
      # @param total_weeks [Integer, nil] Total weeks in year (legacy, use week_context instead)
      # @param week_start [Date, nil] Week start date (legacy, use week_context instead)
      # @param week_end [Date, nil] Week end date (legacy, use week_context instead)
      # @param content_start_col [Integer] Starting column for content area
      # @param content_width_boxes [Integer] Width of content area in grid boxes
      def initialize(canvas:, week_context: nil, year: nil, week_num: nil, total_weeks: nil,
                     week_start: nil, week_end: nil, content_start_col: 3, content_width_boxes: 39,
                     chips: false)
        super(canvas: canvas)
        @chips = chips
        @week_context = week_context
        @year = year || week_context&.year
        @week_num = week_num || week_context&.number
        @total_weeks = total_weeks || week_context&.total_weeks
        @week_start = week_start || week_context&.start_date
        @week_end = week_end || week_context&.end_date
        @content_start_col = content_start_col
        @content_width_boxes = content_width_boxes
      end

      def render
        nav_box = grid.rect(@content_start_col, 0, @content_width_boxes, 2)

        draw_year_link

        if @chips
          # Chips replace the single-step prev/next links: same job, ~3x the
          # touch area, and they show where the week sits among its neighbours.
          strip = draw_week_chips
          draw_title(nav_box, start_col: CHIPS_START_COL + strip.width_boxes)
        else
          draw_prev_week_link if show_prev?
          draw_next_week_link if show_next?
          draw_title(nav_box)
        end
      end

      private

      def show_prev?
        @week_num > 1
      end

      def show_next?
        @week_num < @total_weeks
      end

      def draw_year_link
        link_box(0, 0, 2, 1, @year.to_s, dest: "seasonal", font_size: NAV_FONT_SIZE)
      end

      def draw_prev_week_link
        link_box(2, 0, 2, 1, "w#{format('%02d', @week_num - 1)}", dest: "week_#{@week_num - 1}", font_size: NAV_FONT_SIZE)
      end

      def draw_next_week_link
        link_box(40, 0, 2, 1, "w#{format('%02d', @week_num + 1)}", dest: "week_#{@week_num + 1}", font_size: NAV_FONT_SIZE)
      end

      def draw_week_chips
        nav = MonthNav.new(
          canvas: canvas,
          year: @year,
          col: CHIPS_START_COL,
          row: CHIPS_ROW,
          week_num: @week_num
        )
        nav.render
        nav
      end

      # @param nav_box [Hash] The navigation bounding box
      # @param start_col [Integer, Float, nil] Left edge of the title area; when
      #   nil the title is centred across the whole nav box minus its margins
      def draw_title(nav_box, start_col: nil)
        pdf.font "Helvetica-Bold", size: TITLE_FONT_SIZE

        if start_col
          title_x = grid.x(start_col)
          title_width = grid.x(TITLE_RIGHT_COL) - title_x
        else
          title_x = nav_box[:x] + grid.width(8)
          title_width = nav_box[:width] - grid.width(16)
        end

        title_text = "Week #{@week_num}: #{@week_start.strftime('%b %-d')} - #{@week_end.strftime('%b %-d, %Y')}"

        pdf.text_box title_text,
                      at: [title_x, nav_box[:y]],
                      width: title_width,
                      height: nav_box[:height],
                      align: :center,
                      valign: :center
      end
    end
  end
end
