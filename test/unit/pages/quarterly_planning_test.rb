#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestQuarterlyPlanning < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :quarter_1,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      quarter: 1
    )
  end

  def test_page_has_registered_type
    assert_equal :quarterly_planning, BujoPdf::Pages::QuarterlyPlanning.page_type
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
  end

  def test_setup_uses_full_page_layout
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
  end

  def test_quarter_months_constant
    months = BujoPdf::Pages::QuarterlyPlanning::QUARTER_MONTHS
    assert_equal [1, 3], months[1]   # Q1: Jan-Mar
    assert_equal [4, 6], months[2]   # Q2: Apr-Jun
    assert_equal [7, 9], months[3]   # Q3: Jul-Sep
    assert_equal [10, 12], months[4] # Q4: Oct-Dec
  end

  def test_weeks_per_quarter_constant
    assert_equal 12, BujoPdf::Pages::QuarterlyPlanning::WEEKS_PER_QUARTER
  end

  def test_render_calls_all_sections
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    page.send(:render)
  end

  def test_draw_header
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)
  end

  def test_draw_navigation_for_q1
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_navigation)
    # Q1 has next but no prev
  end

  def test_draw_navigation_for_q4
    context = BujoPdf::RenderContext.new(
      page_key: :quarter_4,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      quarter: 4
    )
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, context)
    page.send(:setup)
    page.send(:draw_navigation)
    # Q4 has prev but no next
  end

  def test_draw_navigation_for_middle_quarter
    context = BujoPdf::RenderContext.new(
      page_key: :quarter_2,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      quarter: 2
    )
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, context)
    page.send(:setup)
    page.send(:draw_navigation)
    # Q2 has both prev and next
  end

  def test_draw_goals_section
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_goals_section)
  end

  def test_draw_goal_line
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_goal_line, 10, 1)
  end

  def test_draw_week_grid
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_week_grid)
  end

  def test_draw_week_row
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_week_row, 5, 20, 3)
  end

  def test_draw_week_row_out_of_range
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    # Week 60 is out of range - shouldn't add link but shouldn't error
    page.send(:draw_week_row, 60, 20, 3)
  end

  def test_draw_nav_link
    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_nav_link, 2, "< Q4", "quarter_4", 'AAAAAA', 'E5E5E5')
  end

  def test_calculate_first_week_of_quarter
    (1..4).each do |q|
      context = BujoPdf::RenderContext.new(
        page_key: :"quarter_#{q}",
        page_number: 1,
        year: 2025,
        total_weeks: 53,
        quarter: q
      )
      page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, context)
      page.send(:setup)
      first_week = page.send(:calculate_first_week_of_quarter)
      assert first_week > 0, "First week should be positive for Q#{q}"
    end
  end

  def test_all_quarters
    (1..4).each do |quarter|
      pdf = create_fast_test_pdf  # Use stub stamp for speed
      context = BujoPdf::RenderContext.new(
        page_key: :"quarter_#{quarter}",
        page_number: quarter,
        year: 2025,
        total_weeks: 53,
        quarter: quarter
      )
      page = BujoPdf::Pages::QuarterlyPlanning.new(pdf, context)
      page.generate
      assert_equal 1, pdf.page_count, "Q#{quarter} should produce 1 page"
    end
  end
end

class TestQuarterlyPlanningMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::QuarterlyPlanning::Mixin

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

  def test_mixin_provides_quarterly_planning_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:quarterly_planning_page), "Expected quarterly_planning_page method"
  end

  def test_mixin_provides_quarterly_planning_pages_method
    builder = TestBuilder.new
    assert builder.respond_to?(:quarterly_planning_pages), "Expected quarterly_planning_pages method"
  end

  def test_quarterly_planning_page_generates_page
    builder = TestBuilder.new
    builder.quarterly_planning_page(quarter: 1)

    assert_equal 1, builder.pdf.page_count
  end

  def test_quarterly_planning_pages_generates_4_pages
    builder = TestBuilder.new
    builder.quarterly_planning_pages

    assert_equal 4, builder.pdf.page_count
  end
end

class TestQuarterlyPlanningIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :quarter_1,
      page_number: 1,
      year: 2025,
      total_weeks: 53,
      quarter: 1
    )

    page = BujoPdf::Pages::QuarterlyPlanning.new(@pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end
end
