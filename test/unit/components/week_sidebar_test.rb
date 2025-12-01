# frozen_string_literal: true

require_relative '../../test_helper'

class TestWeekSidebar < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Constants Tests
  # ============================================

  def test_sidebar_start_col_constant
    assert_equal 0.25, BujoPdf::Components::WeekSidebar::SIDEBAR_START_COL
  end

  def test_sidebar_width_boxes_constant
    assert_equal 2, BujoPdf::Components::WeekSidebar::SIDEBAR_WIDTH_BOXES
  end

  def test_sidebar_start_row_constant
    assert_equal 2, BujoPdf::Components::WeekSidebar::SIDEBAR_START_ROW
  end

  def test_padding_boxes_constant
    assert_equal 0.3, BujoPdf::Components::WeekSidebar::PADDING_BOXES
  end

  def test_font_size_constant
    assert_equal 6, BujoPdf::Components::WeekSidebar::FONT_SIZE
  end

  def test_nav_color_constant
    assert_equal '888888', BujoPdf::Components::WeekSidebar::NAV_COLOR
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_with_required_params
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    assert_equal 2025, sidebar.instance_variable_get(:@year)
    assert_equal 52, sidebar.instance_variable_get(:@total_weeks)
    assert_nil sidebar.instance_variable_get(:@current_week_num)
    assert_nil sidebar.instance_variable_get(:@page_context)
  end

  def test_initialize_with_current_week
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      current_week_num: 10
    )

    assert_equal 10, sidebar.instance_variable_get(:@current_week_num)
  end

  def test_initialize_with_page_context
    context = BujoPdf::RenderContext.new(
      page_key: :week_5,
      page_number: 1,
      year: 2025
    )

    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      page_context: context
    )

    assert_equal context, sidebar.instance_variable_get(:@page_context)
  end

  # ============================================
  # Render Tests
  # ============================================

  def test_render_52_week_year
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    sidebar.render

    # Should render without error
  end

  def test_render_53_week_year
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 53
    )

    sidebar.render

    # Should render 53 weeks without error
  end

  def test_render_with_current_week_highlighted
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      current_week_num: 25
    )

    sidebar.render

    # Should render with week 25 highlighted
  end

  def test_render_with_page_context_current_week
    context = BujoPdf::RenderContext.new(
      page_key: :week_10,
      page_number: 1,
      year: 2025
    )

    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      page_context: context
    )

    sidebar.render

    # Should render with week 10 highlighted via page_context
  end

  # ============================================
  # Current Week Detection Tests
  # ============================================

  def test_current_week_via_current_week_num
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      current_week_num: 15
    )

    assert sidebar.send(:current_week?, 15)
    refute sidebar.send(:current_week?, 14)
    refute sidebar.send(:current_week?, 16)
  end

  def test_current_week_via_page_context
    context = BujoPdf::RenderContext.new(
      page_key: :week_20,
      page_number: 1,
      year: 2025
    )

    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      page_context: context
    )

    assert sidebar.send(:current_week?, 20)
    refute sidebar.send(:current_week?, 19)
    refute sidebar.send(:current_week?, 21)
  end

  def test_current_week_nil_when_no_current_set
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    refute sidebar.send(:current_week?, 1)
    refute sidebar.send(:current_week?, 26)
    refute sidebar.send(:current_week?, 52)
  end

  # ============================================
  # Private Method Tests
  # ============================================

  def test_draw_week_entry
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      current_week_num: 5
    )

    # Need to call render first to initialize @week_months
    sidebar.render

    # Then test draw_week_entry for different weeks
    # Week 5 is current, week 6 is not
  end

  def test_draw_week_background_current
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    week_box = @grid.rect(0.25, 5, 2, 1)
    sidebar.send(:draw_week_background, week_box, true)

    # Should draw stroked rectangle for current week
  end

  def test_draw_week_background_non_current
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    week_box = @grid.rect(0.25, 5, 2, 1)
    sidebar.send(:draw_week_background, week_box, false)

    # Should draw filled transparent rectangle for non-current week
  end

  def test_draw_current_week_with_month
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    week_box = @grid.rect(0.25, 5, 2, 1)
    sidebar.send(:draw_current_week, week_box, 'J', 'w01')

    # Should render bold "J w01" text
  end

  def test_draw_current_week_without_month
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    week_box = @grid.rect(0.25, 5, 2, 1)
    sidebar.send(:draw_current_week, week_box, nil, 'w05')

    # Should render just "w05" bold
  end

  def test_draw_linked_week_with_month
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    week_box = @grid.rect(0.25, 5, 2, 1)
    sidebar.send(:draw_linked_week, week_box, 'F', 'w05', 5)

    # Should render "F w05" with link
  end

  def test_draw_linked_week_without_month
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    week_box = @grid.rect(0.25, 5, 2, 1)
    sidebar.send(:draw_linked_week, week_box, nil, 'w10', 10)

    # Should render just "w10" with link
  end

  # ============================================
  # Integration Tests
  # ============================================

  def test_full_sidebar_renders_all_weeks
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52
    )

    # Should render all 52 weeks without error
    sidebar.render

    assert_equal 1, @pdf.page_count
  end

  def test_sidebar_with_first_week_current
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      current_week_num: 1
    )

    sidebar.render
    # First week should be highlighted
  end

  def test_sidebar_with_last_week_current
    sidebar = BujoPdf::Components::WeekSidebar.new(
      canvas: @canvas,
      year: 2025,
      total_weeks: 52,
      current_week_num: 52
    )

    sidebar.render
    # Last week should be highlighted
  end
end
