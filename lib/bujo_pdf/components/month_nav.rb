# frozen_string_literal: true

require_relative '../base/component'
require_relative 'link_box'
require_relative 'text'
require_relative '../utilities/styling'
require_relative '../week'

module BujoPdf
  module Components
    # MonthNav renders a month-anchored navigation strip:
    #
    #   [Jan]  FEB  [1][2][3][4]      [Mar]
    #
    # The current month is named in place, its weeks are numbered by position
    # *within the month* rather than by week-of-year, the week you are on is
    # highlighted, and the neighbouring months sit at either end.
    #
    # Anchoring to the month is the point. A window that slides with the
    # current week puts every chip in a different place each time you turn the
    # page, so you have to look before you tap. Here the chips hold still for
    # the whole month: week 3 of February is always the third box, and the
    # next-month target is always in the same spot.
    #
    # Holding still costs a little width. Months carry 4 or 5 weeks, except
    # January in years where a carry-in week joins five in-month weeks (2028,
    # 2033), which makes 6. Slots are reserved for the widest month *in that
    # year*, so the trailing month chip never moves within a planner, and a
    # normal year is not padded for a case it does not contain.
    #
    # @example On a weekly page
    #   MonthNav.new(canvas: canvas, year: 2026, week_num: 19, col: 2, row: 0.15).render
    class MonthNav < Component
      include LinkBox::Mixin
      include Text::Mixin
      include Styling::Colors

      # Upper bound across all years; the reserved slot count is derived per
      # year (see .slots_for) so a typical year does not pay for the rare
      # 6-week January.
      MAX_WEEKS_PER_MONTH = 6

      # Layout, in grid boxes
      MONTH_CHIP_WIDTH = 3
      MONTH_LABEL_WIDTH = 2
      WEEK_CHIP_WIDTH = 2
      CHIP_HEIGHT = 1.7

      MONTH_FONT_SIZE = 8
      LABEL_FONT_SIZE = 8
      WEEK_FONT_SIZE = 8

      class << self
        # Weeks belonging to each month, keyed by month number.
        #
        # Uses Week#interleaving_month, the same grouping the planner recipe
        # uses to sequence month pages, so navigation and page order agree.
        #
        # @param year [Integer]
        # @return [Hash{Integer => Array<Integer>}] month number => week numbers
        def weeks_by_month(year)
          @weeks_by_month ||= {}
          @weeks_by_month[year] ||= Week.all_in(year).each_with_object({}) do |week, acc|
            next unless week.overlaps_year?

            month = week.interleaving_month
            next unless month

            (acc[month] ||= []) << week.number
          end
        end

        # Week-chip slots to reserve for a year: the widest month it contains.
        #
        # @param year [Integer]
        # @return [Integer]
        def slots_for(year)
          weeks_by_month(year).values.map(&:length).max || MAX_WEEKS_PER_MONTH
        end

        # Clear the memoised grouping. Intended for tests.
        def reset_cache!
          @weeks_by_month = nil
        end
      end

      # @param canvas [Canvas] The canvas to render on
      # @param year [Integer] The planner year
      # @param col [Integer, Float] Starting column
      # @param row [Integer, Float] Row position
      # @param week_num [Integer, nil] Current week, highlighted and used to
      #   derive the month when +month+ is not given
      # @param month [Integer, nil] Month to anchor on; defaults to the current
      #   week's month
      def initialize(canvas:, year:, col:, row:, week_num: nil, month: nil)
        super(canvas: canvas)
        @year = year
        @col = col
        @row = row
        @week_num = week_num
        @month = month || month_of(week_num)
      end

      def render
        return unless @month

        draw_prev_month
        draw_month_label
        draw_week_chips
        draw_next_month
      end

      # Total width of the strip, in grid boxes. Constant for every month, so
      # callers can lay out to its right without measuring.
      #
      # @return [Integer, Float]
      def width_boxes
        (MONTH_CHIP_WIDTH * 2) + MONTH_LABEL_WIDTH + (WEEK_CHIP_WIDTH * slots)
      end

      # Week numbers belonging to the anchored month.
      #
      # @return [Array<Integer>]
      def weeks
        self.class.weeks_by_month(@year).fetch(@month, [])
      end

      private

      def month_of(week_num)
        return nil unless week_num

        self.class.weeks_by_month(@year).find { |_m, nums| nums.include?(week_num) }&.first
      end

      def prev_month_col
        @col
      end

      def label_col
        prev_month_col + MONTH_CHIP_WIDTH
      end

      def weeks_col
        label_col + MONTH_LABEL_WIDTH
      end

      def next_month_col
        weeks_col + (WEEK_CHIP_WIDTH * slots)
      end

      def slots
        @slots ||= self.class.slots_for(@year)
      end

      # Draw a chip pointing at a neighbouring month.
      #
      # Links to that month's first week; once month pages exist this is the
      # natural place to point at them instead. Out-of-range months leave the
      # slot empty rather than collapsing it, so the strip keeps its shape.
      def draw_month_chip(month, col)
        return unless (1..12).cover?(month)

        target = self.class.weeks_by_month(@year)[month]&.first
        return unless target

        link_box(col, @row, MONTH_CHIP_WIDTH, CHIP_HEIGHT,
                 Date::ABBR_MONTHNAMES[month],
                 dest: "week_#{target}",
                 font_size: MONTH_FONT_SIZE)
      end

      def draw_prev_month
        draw_month_chip(@month - 1, prev_month_col)
      end

      def draw_next_month
        draw_month_chip(@month + 1, next_month_col)
      end

      # The anchored month, named in place. Drawn as plain bold text rather
      # than a chip: it is where you are, not somewhere to go.
      def draw_month_label
        text(label_col, @row, Date::ABBR_MONTHNAMES[@month].upcase,
             size: LABEL_FONT_SIZE,
             style: :bold,
             width: MONTH_LABEL_WIDTH,
             height: CHIP_HEIGHT,
             align: :center,
             valign: :center)
      end

      # Weeks of the month, numbered 1..n by position within the month.
      def draw_week_chips
        weeks.each_with_index do |week, i|
          link_box(weeks_col + (i * WEEK_CHIP_WIDTH), @row, WEEK_CHIP_WIDTH, CHIP_HEIGHT,
                   (i + 1).to_s,
                   dest: "week_#{week}",
                   current: week == @week_num,
                   font_size: WEEK_FONT_SIZE)
        end
      end
    end
  end
end
