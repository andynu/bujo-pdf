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
        draw_header
        draw_prompt_sections
      end

      private

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
        # Calculate available height for sections
        start_row = 6
        available_rows = 47  # Rows 6-52
        section_height = available_rows / PROMPTS.count

        PROMPTS.each_with_index do |prompt, index|
          row = start_row + (index * section_height)
          draw_prompt_section(prompt, row, section_height - 1)
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
        @pdf.stroke_color 'E5E5E5'
        @pdf.line_width 0.5

        num_rows.times do |i|
          row = start_row + i
          line_y = @grid_system.y(row + 1) + 3

          @pdf.stroke_line [@grid_system.x(2), line_y], [@grid_system.x(41), line_y]
        end

        @pdf.stroke_color '000000'
      end

      # Draw a subtle horizontal divider
      #
      # @param row [Integer] Row for the divider
      # @return [void]
      def draw_section_divider(row)
        line_y = @grid_system.y(row)
        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.5
        @pdf.stroke_line [@grid_system.x(10), line_y], [@grid_system.x(33), line_y]
        @pdf.stroke_color '000000'
      end
    end
  end
end
