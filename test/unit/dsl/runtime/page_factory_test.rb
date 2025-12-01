# frozen_string_literal: true

require_relative '../../../test_helper'

class TestPageFactory < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = {
      page_key: :test,
      page_number: 1,
      year: 2025
    }
  end

  # ============================================
  # Registry Tests
  # ============================================

  def test_registry_is_accessible
    assert_kind_of Hash, BujoPdf::PageFactory.registry
  end

  def test_registry_contains_registered_pages
    # TestablePage was registered in base_test.rb tests
    # But we'll check for known pages that exist in the codebase
    refute_nil BujoPdf::PageFactory.registry[:seasonal]
  end

  # ============================================
  # Create Tests
  # ============================================

  def test_create_returns_page_instance
    page = BujoPdf::PageFactory.create(:seasonal, @pdf, @context)

    assert_kind_of BujoPdf::Pages::Base, page
    assert_kind_of BujoPdf::Pages::SeasonalCalendar, page
  end

  def test_create_with_render_context
    context = BujoPdf::RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: 2025
    )
    page = BujoPdf::PageFactory.create(:seasonal, @pdf, context)

    assert_kind_of BujoPdf::Pages::SeasonalCalendar, page
  end

  def test_create_raises_for_unknown_page_type
    error = assert_raises(ArgumentError) do
      BujoPdf::PageFactory.create(:unknown_page_type, @pdf, @context)
    end

    assert_match(/Unknown page type/, error.message)
    assert_match(/unknown_page_type/, error.message)
  end

  # ============================================
  # Register Tests
  # ============================================

  def test_register_adds_page_to_registry
    # Create a test page class
    test_class = Class.new(BujoPdf::Pages::Base) do
      def render; end
    end

    BujoPdf::PageFactory.register(:test_factory_page, test_class)

    assert_equal test_class, BujoPdf::PageFactory.registry[:test_factory_page]
  end

  def test_register_can_override_existing_page
    original_class = BujoPdf::PageFactory.registry[:seasonal]

    test_class = Class.new(BujoPdf::Pages::Base) do
      def render; end
    end

    BujoPdf::PageFactory.register(:seasonal, test_class)
    assert_equal test_class, BujoPdf::PageFactory.registry[:seasonal]

    # Restore original
    BujoPdf::PageFactory.register(:seasonal, original_class)
  end

  # ============================================
  # Create Weekly Page Tests
  # ============================================

  def test_create_weekly_page_returns_weekly_page_instance
    context = { year: 2025 }
    page = BujoPdf::PageFactory.create_weekly_page(1, @pdf, context)

    assert_kind_of BujoPdf::Pages::WeeklyPage, page
  end

  def test_create_weekly_page_sets_week_num
    context = { year: 2025 }
    page = BujoPdf::PageFactory.create_weekly_page(42, @pdf, context)

    assert_equal 42, page.context[:week_num]
  end

  def test_create_weekly_page_calculates_week_dates
    context = { year: 2025 }
    page = BujoPdf::PageFactory.create_weekly_page(1, @pdf, context)

    refute_nil page.context[:week_start]
    refute_nil page.context[:week_end]
    assert_kind_of Date, page.context[:week_start]
    assert_kind_of Date, page.context[:week_end]
  end

  def test_create_weekly_page_preserves_base_context
    context = { year: 2025, custom_key: 'custom_value' }
    page = BujoPdf::PageFactory.create_weekly_page(5, @pdf, context)

    assert_equal 2025, page.context[:year]
    assert_equal 'custom_value', page.context[:custom_key]
  end

  def test_create_weekly_page_for_different_weeks
    context = { year: 2025 }

    [1, 26, 52].each do |week_num|
      page = BujoPdf::PageFactory.create_weekly_page(week_num, @pdf, context)

      assert_equal week_num, page.context[:week_num]
      assert page.context[:week_start] < page.context[:week_end]
    end
  end

  # ============================================
  # Create Index Page Tests
  # ============================================

  def test_create_index_page_returns_index_page_instance
    context = { page_number: 1, year: 2025 }
    page = BujoPdf::PageFactory.create_index_page(1, 4, @pdf, context)

    assert_kind_of BujoPdf::Pages::IndexPage, page
  end

  def test_create_index_page_sets_index_page_num
    context = { page_number: 1, year: 2025 }
    page = BujoPdf::PageFactory.create_index_page(2, 4, @pdf, context)

    assert_equal 2, page.context[:index_page_num]
  end

  def test_create_index_page_sets_index_page_count
    context = { page_number: 1, year: 2025 }
    page = BujoPdf::PageFactory.create_index_page(1, 5, @pdf, context)

    assert_equal 5, page.context[:index_page_count]
  end

  def test_create_index_page_sets_page_key
    context = { page_number: 1, year: 2025 }
    page = BujoPdf::PageFactory.create_index_page(3, 4, @pdf, context)

    assert_equal :index_3, page.context[:page_key]
  end

  def test_create_index_page_with_hash_context
    context = { page_number: 1, year: 2025, total_weeks: 52 }
    page = BujoPdf::PageFactory.create_index_page(1, 2, @pdf, context)

    assert_kind_of BujoPdf::Pages::IndexPage, page
    assert_equal 2025, page.context[:year]
  end

  def test_create_index_page_with_render_context
    render_context = BujoPdf::RenderContext.new(
      page_key: :index_1,
      page_number: 1,
      year: 2025
    )
    page = BujoPdf::PageFactory.create_index_page(2, 4, @pdf, render_context)

    assert_kind_of BujoPdf::Pages::IndexPage, page
    assert_equal :index_2, page.context[:page_key]
    assert_equal 2, page.context[:index_page_num]
    assert_equal 4, page.context[:index_page_count]
  end

  def test_create_index_page_for_different_pages
    context = { page_number: 1, year: 2025 }

    [1, 2, 3, 4].each do |page_num|
      page = BujoPdf::PageFactory.create_index_page(page_num, 4, @pdf, context)

      assert_equal page_num, page.context[:index_page_num]
      assert_equal "index_#{page_num}".to_sym, page.context[:page_key]
    end
  end
end

class TestPageFactoryIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_create_and_generate_page
    context = {
      page_key: :seasonal,
      page_number: 1,
      year: 2025
    }
    page = BujoPdf::PageFactory.create(:seasonal, @pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_create_weekly_page_and_generate
    context = { year: 2025, total_weeks: 52 }
    page = BujoPdf::PageFactory.create_weekly_page(10, @pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_create_index_page_and_generate
    context = { page_number: 1, year: 2025 }
    page = BujoPdf::PageFactory.create_index_page(1, 2, @pdf, context)
    page.generate

    assert_equal 1, @pdf.page_count
  end
end
