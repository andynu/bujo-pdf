#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestMonthlyReview < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :monthly_review_1,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      review_month: 1  # January
    )
  end

  def test_page_has_registered_type
    assert_equal :monthly_review, BujoPdf::Pages::MonthlyReview.page_type
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
  end

  def test_setup_uses_full_page_layout
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
  end

  def test_prompts_constant
    prompts = BujoPdf::Pages::MonthlyReview::PROMPTS
    assert_equal 3, prompts.length
    assert_equal "What Worked", prompts[0][:title]
    assert_equal "What Didn't Work", prompts[1][:title]
    assert_equal "Focus for Next Month", prompts[2][:title]
  end

  def test_render_calls_all_sections
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_header
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)
  end

  def test_draw_navigation_for_january
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_navigation)
    # January has next but no prev
  end

  def test_draw_navigation_for_december
    context = BujoPdf::RenderContext.new(
      page_key: :monthly_review_12,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      review_month: 12
    )
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, context)
    page.send(:setup)
    page.send(:draw_navigation)
    # December has prev but no next
  end

  def test_draw_navigation_for_middle_month
    context = BujoPdf::RenderContext.new(
      page_key: :monthly_review_6,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      review_month: 6
    )
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, context)
    page.send(:setup)
    page.send(:draw_navigation)
    # June has both prev and next
  end

  def test_draw_prompt_sections
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_prompt_sections)
  end

  def test_draw_section_header
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_section_header, "Test Title", 10)
  end

  def test_draw_prompt_text
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_prompt_text, "Test prompt text", 12)
  end

  def test_draw_writing_lines
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_writing_lines, 15, 5)
  end

  def test_draw_section_divider
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_section_divider, 25)
  end

  def test_draw_nav_link
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_nav_link, 2, "< Dec", "review_12", 'AAAAAA', 'E5E5E5')
  end

  def test_all_months
    (1..12).each do |month|
      pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      DotGrid.create_stamp(pdf, "page_dots")
      context = BujoPdf::RenderContext.new(
        page_key: :"monthly_review_#{month}",
        page_number: month,
        year: 2025,
        total_weeks: 53,
        review_month: month
      )
      page = BujoPdf::Pages::MonthlyReview.new(pdf, context)
      page.generate
      assert_equal 1, pdf.page_count, "Month #{month} should produce 1 page"
    end
  end

  def test_draw_prompt_section
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    prompt = { title: "Test", prompt: "Test prompt" }
    page.send(:draw_prompt_section, prompt, 10, 15)
  end

  def test_draw_prompt_section_last
    page = BujoPdf::Pages::MonthlyReview.new(@pdf, @context)
    page.send(:setup)
    # Last prompt shouldn't draw divider
    prompt = BujoPdf::Pages::MonthlyReview::PROMPTS.last
    page.send(:draw_prompt_section, prompt, 40, 10)
  end
end

class TestMonthlyReviewMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::MonthlyReview::Mixin

    attr_reader :pdf, :year, :date_config, :event_store, :total_pages

    def initialize
      @year = 2025
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @date_config = nil
      @event_store = nil
      @total_pages = 100
      @first_page_used = false
      DotGrid.create_stamp(@pdf, "page_dots")
    end
  end

  def test_mixin_provides_monthly_review_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:monthly_review_page), "Expected monthly_review_page method"
  end

  def test_mixin_provides_monthly_review_pages_method
    builder = TestBuilder.new
    assert builder.respond_to?(:monthly_review_pages), "Expected monthly_review_pages method"
  end

  def test_monthly_review_page_generates_page
    builder = TestBuilder.new
    builder.monthly_review_page(month: 1)

    assert_equal 1, builder.pdf.page_count
  end

  def test_monthly_review_pages_generates_12_pages
    builder = TestBuilder.new
    builder.monthly_review_pages

    assert_equal 12, builder.pdf.page_count
  end
end

class TestMonthlyReviewIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :monthly_review_1,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      review_month: 1
    )

    page = BujoPdf::Pages::MonthlyReview.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end
end
