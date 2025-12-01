# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Monthly review page for reflection and planning.
    #
    # A prompt-based template for monthly reflection with structured
    # sections for what worked, what didn't, and focus for next month.
    # Provides minimal structure while guiding the reflection process.
    #
    # Design:
    # - Top navigation with prev/next month links
    # - Month header with year
    # - Three reflection sections with prompts
    # - Space for writing under each prompt
    # - One page per month (12 pages total)
    #
    # Example:
    #   context = RenderContext.new(
    #     page_key: :monthly_review_1,
    #     review_month: 1,  # January
    #     year: 2025
    #   )
    #   page = MonthlyReview.new(pdf, context)
    #   page.generate
    class MonthlyReview < Base
      register_page :monthly_review,
        title: ->(p) { Date::MONTHNAMES[p[:review_month] || p[:month]] },
        dest: "review_%{month}"

      # Mixin providing monthly_review_page and monthly_review_pages verbs.
      module Mixin
        include MixinSupport

        # Generate a single monthly review page.
        #
        # @param month [Integer] Month number (1-12)
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def monthly_review_page(month:)
          month_name = Date::MONTHNAMES[month]
          define_page(dest: "review_#{month}", title: month_name, type: :monthly_review,
                      review_month: month) do |ctx|
            MonthlyReview.new(@pdf, ctx).generate
          end
        end

        # Generate all monthly review pages (12 pages).
        #
        # @return [Array<PageRef>, nil] Array of PageRefs during define phase
        def monthly_review_pages
          (1..12).map do |month|
            monthly_review_page(month: month)
          end
        end
      end

      NAV_FONT_SIZE = 8
      # Reflection prompts for each section
      PROMPTS = [
        {
          title: "What Worked",
          prompt: "Wins, successes, and things to keep doing"
        },
        {
          title: "What Didn't Work",
          prompt: "Challenges, obstacles, and things to change"
        },
        {
          title: "Focus for Next Month",
          prompt: "Priorities, goals, and intentions"
        }
      ].freeze

      def setup
        @review_month = context[:review_month] || 1
        @year = context[:year]

        # Set named destination for this review page
        set_destination("review_#{@review_month}")

        use_layout :full_page
      end

      def render
        draw_navigation
        draw_header
        draw_prompt_sections
      end

      private

      # Draw the top navigation with prev/next month links
      #
      # @return [void]
      def draw_navigation
        require_relative '../themes/theme_registry'
        nav_color = BujoPdf::Themes.current[:colors][:text_gray]
        border_color = BujoPdf::Themes.current[:colors][:borders]

        # Previous month link (if not January)
        if @review_month > 1
          prev_month = Date::ABBR_MONTHNAMES[@review_month - 1]
          draw_nav_link(2, "< #{prev_month}", "review_#{@review_month - 1}", nav_color, border_color)
        end

        # Next month link (if not December)
        if @review_month < 12
          next_month = Date::ABBR_MONTHNAMES[@review_month + 1]
          draw_nav_link(39, "#{next_month} >", "review_#{@review_month + 1}", nav_color, border_color)
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
        bounds = GridRect.new(col, 0, 3, 1)

        # Draw background using box verb with splatted GridRect
        box(*bounds, fill: border_color, stroke: nil, opacity: 0.2, radius: 2)

        # Draw text
        text(bounds.col, bounds.row, link_text, size: NAV_FONT_SIZE, color: nav_color, align: :center, width: bounds.width)

        # Link annotation using grid helper
        @grid.link(*bounds, dest)
      end

      # Draw the page header with month and year
      #
      # @return [void]
      def draw_header
        header_box = @grid_system.rect(2, 1, 39, 4)
        month_name = Date::MONTHNAMES[@review_month]

        @pdf.bounding_box([header_box[:x], header_box[:y]],
                          width: header_box[:width],
                          height: header_box[:height]) do
          @pdf.text "#{month_name} #{@year}",
                    size: 20,
                    style: :bold,
                    align: :left,
                    valign: :center

          # Subtitle
          @pdf.text "Monthly Review",
                    size: 12,
                    color: '666666',
                    align: :left,
                    valign: :bottom
        end
      end

      # Draw all three prompt sections
      #
      # @return [void]
      def draw_prompt_sections
        sections = @grid.divide_rows(row: 6, height: 47, count: PROMPTS.count)

        PROMPTS.zip(sections).each do |prompt, section|
          draw_prompt_section(prompt, section.row, section.height - 1)
        end
      end

      # Draw a single prompt section
      #
      # @param prompt [Hash] Prompt with :title and :prompt keys
      # @param start_row [Integer] Starting row for this section
      # @param height [Integer] Height in grid boxes
      # @return [void]
      def draw_prompt_section(prompt, start_row, height)
        # Section header
        draw_section_header(prompt[:title], start_row)

        # Prompt text
        draw_prompt_text(prompt[:prompt], start_row + 2)

        # Ruled lines for writing
        draw_writing_lines(start_row + 4, height - 4)

        # Section divider (except for last section)
        unless prompt == PROMPTS.last
          draw_section_divider(start_row + height + 1)
        end
      end

      # Draw section header (bold title)
      #
      # @param title [String] Section title
      # @param row [Integer] Row for the header
      # @return [void]
      def draw_section_header(title, row)
        header_box = @grid_system.rect(2, row, 39, 2)

        @pdf.bounding_box([header_box[:x], header_box[:y]],
                          width: header_box[:width],
                          height: header_box[:height]) do
          @pdf.text title,
                    size: 14,
                    style: :bold,
                    align: :left,
                    valign: :bottom
        end
      end

      # Draw the prompt text (lighter color, italic)
      #
      # @param prompt [String] Prompt text
      # @param row [Integer] Row for the prompt
      # @return [void]
      def draw_prompt_text(prompt, row)
        prompt_box = @grid_system.rect(2, row, 39, 2)

        @pdf.bounding_box([prompt_box[:x], prompt_box[:y]],
                          width: prompt_box[:width],
                          height: prompt_box[:height]) do
          @pdf.text prompt,
                    size: 10,
                    style: :italic,
                    color: '999999',
                    align: :left,
                    valign: :top
        end
      end

      # Draw ruled lines for writing
      #
      # @param start_row [Integer] Starting row
      # @param num_rows [Integer] Number of lines
      # @return [void]
      def draw_writing_lines(start_row, num_rows)
        num_rows.times do |i|
          # Offset by 3pt (~0.2 boxes) within each row for better text baseline alignment
          hline(2, start_row + i + 1 + 0.2, 39, color: 'E5E5E5', stroke: 0.5)
        end
      end

      # Draw a subtle horizontal divider
      #
      # @param row [Integer] Row for the divider
      # @return [void]
      def draw_section_divider(row)
        hline(10, row, 23, color: 'CCCCCC', stroke: 0.5)
      end
    end
  end
end
