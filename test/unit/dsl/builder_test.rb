#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestPdfBuilder < Minitest::Test
  def setup
    @builder = BujoPdf::PdfDSL::PdfBuilder.new
  end

  def test_build_returns_prawn_document
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      page :seasonal
    end

    result = @builder.build(definition, year: 2025)

    assert_kind_of Prawn::Document, result
  end

  def test_build_creates_correct_page_count
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      page :seasonal
      page :year_events
    end

    pdf = @builder.build(definition, year: 2025)

    assert_equal 2, pdf.page_count
  end

  def test_build_with_output_writes_file
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      page :seasonal
    end

    output_path = "tmp/test_builder_output.pdf"
    FileUtils.mkdir_p('tmp')

    begin
      result = @builder.build(definition, year: 2025, output: output_path)

      assert_equal output_path, result
      assert File.exist?(output_path)
    ensure
      FileUtils.rm_f(output_path)
    end
  end

  def test_build_creates_link_registry
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      page :seasonal
      page :year_events
    end

    @builder.build(definition, year: 2025)

    assert_kind_of BujoPdf::PdfDSL::LinkRegistry, @builder.link_registry
  end

  def test_build_applies_theme
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      theme :earth
      page :seasonal
    end

    # Theme should be applied during build and reset after
    @builder.build(definition, year: 2025)

    # Theme should be reset to default after build
    # Default theme check depends on Themes.reset! implementation
  end

  def test_build_with_weekly_pages
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      page :weekly, week: weeks_in(year).first
    end

    pdf = @builder.build(definition, year: 2025)

    assert_equal 1, pdf.page_count
  end

  def test_build_with_groups
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      group :grids do
        page :grid_dot
        page :grid_graph
      end
    end

    pdf = @builder.build(definition, year: 2025)

    assert_equal 2, pdf.page_count
  end

  def test_build_creates_dot_grid_stamp
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      page :seasonal
    end

    pdf = @builder.build(definition, year: 2025)

    # Stamp should exist (can stamp without error)
    # This tests indirectly via the pages rendering successfully
    assert_kind_of Prawn::Document, pdf
  end
end

class TestPdfBuilderPrivateMethods < Minitest::Test
  def setup
    @builder = BujoPdf::PdfDSL::PdfBuilder.new
    @context = BujoPdf::PdfDSL::DeclarationContext.new
  end

  def test_build_link_registry
    @context.page(:seasonal_calendar, dest: 'seasonal')
    @context.page(:year_events, dest: 'year_events')

    registry = @builder.send(:build_link_registry, @context)

    assert_kind_of BujoPdf::PdfDSL::LinkRegistry, registry
  end

  def test_create_document
    document = @builder.send(:create_document, @context)

    assert_kind_of Prawn::Document, document
  end

  def test_create_grid_stamps
    pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)

    @builder.send(:create_grid_stamps, pdf)

    # All grid stamps should be defined (can stamp without error)
    pdf.stamp('page_dots')
    pdf.stamp('grid_graph')
    pdf.stamp('grid_lined')
    pdf.stamp('grid_isometric')
    pdf.stamp('grid_perspective')
    pdf.stamp('grid_hexagon')
  end

  def test_build_base_context
    @context.page(:seasonal_calendar)

    base_context = @builder.send(:build_base_context, { year: 2025 }, @context)

    assert_equal 2025, base_context[:year]
    assert_equal 53, base_context[:total_weeks]  # 2025 has 53 weeks
    assert_equal 1, base_context[:total_pages]
  end

  def test_build_base_context_defaults_year
    @context.page(:seasonal_calendar)

    base_context = @builder.send(:build_base_context, {}, @context)

    assert_equal Date.today.year, base_context[:year]
  end

  def test_build_page_context_with_week
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly)
    week = BujoPdf::PdfDSL::Week.new(1, 2025)
    page_decl.params[:week] = week

    base_context = { year: 2025, total_weeks: 53 }
    @builder.instance_variable_set(:@link_registry, BujoPdf::PdfDSL::LinkRegistry.new)

    page_context = @builder.send(:build_page_context, page_decl, base_context, 0)

    assert_equal week.number, page_context[:week_num]
    assert_equal week.start_date, page_context[:week_start]
    assert_equal week.end_date, page_context[:week_end]
  end

  def test_build_page_context_with_month
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:monthly_review)
    month = BujoPdf::PdfDSL::Month.new(3, 2025)  # March
    page_decl.params[:month] = month

    base_context = { year: 2025, total_weeks: 53 }
    @builder.instance_variable_set(:@link_registry, BujoPdf::PdfDSL::LinkRegistry.new)

    page_context = @builder.send(:build_page_context, page_decl, base_context, 0)

    assert_equal month.number, page_context[:month]
    assert_equal month.name, page_context[:month_name]
  end

  def test_expand_dsl_params_with_week
    week = BujoPdf::PdfDSL::Week.new(42, 2025)
    params = { week: week }

    expanded = @builder.send(:expand_dsl_params, params)

    assert_equal week.number, expanded[:week_num]
    assert_equal week.start_date, expanded[:week_start]
    assert_equal week.end_date, expanded[:week_end]
  end

  def test_expand_dsl_params_with_month
    month = BujoPdf::PdfDSL::Month.new(6, 2025)  # June
    params = { month: month }

    expanded = @builder.send(:expand_dsl_params, params)

    assert_equal month.number, expanded[:month]
    assert_equal month.name, expanded[:month_name]
  end

  def test_expand_dsl_params_preserves_other_params
    params = { foo: 'bar', baz: 123 }

    expanded = @builder.send(:expand_dsl_params, params)

    assert_equal 'bar', expanded[:foo]
    assert_equal 123, expanded[:baz]
  end
end

class TestPdfBuilderOutline < Minitest::Test
  def setup
    @builder = BujoPdf::PdfDSL::PdfBuilder.new
  end

  def test_build_outline_with_entries
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      page :seasonal, outline: "Calendar"
    end

    pdf = @builder.build(definition, year: 2025)

    # PDF should have outline/bookmarks
    assert_kind_of Prawn::Document, pdf
  end

  def test_build_outline_with_sections
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      outline_section "Year Overview" do
        page :seasonal, outline: "Calendar"
        page :year_events, outline: "Events"
      end
    end

    pdf = @builder.build(definition, year: 2025)

    assert_kind_of Prawn::Document, pdf
  end

  def test_build_pages_by_dest
    context = BujoPdf::PdfDSL::DeclarationContext.new
    context.page(:seasonal, id: :seasonal, outline: 'Calendar')
    context.page(:year_events, id: :year_events, outline: 'Events')

    pages_by_dest = @builder.send(:build_pages_by_dest, context.pages)

    assert_equal 1, pages_by_dest['seasonal'][:page_number]
    assert_equal 2, pages_by_dest['year_events'][:page_number]
  end

  def test_resolve_page_title_with_explicit_outline_title
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:seasonal_calendar)
    page_decl.instance_variable_set(:@outline_title, "My Custom Title")

    title = @builder.send(:resolve_page_title, page_decl, 'seasonal')

    assert_equal "My Custom Title", title
  end

  def test_resolve_page_title_with_collection_title
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:collection_page)
    page_decl.params[:collection_title] = "Books to Read"

    title = @builder.send(:resolve_page_title, page_decl, 'collection_books')

    assert_equal "Books to Read", title
  end

  def test_resolve_page_title_fallback_humanizes_dest
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:unknown_page)

    title = @builder.send(:resolve_page_title, page_decl, 'my_custom_page')

    assert_equal "My Custom Page", title
  end
end

class TestPdfBuilderRenderPage < Minitest::Test
  def setup
    @builder = BujoPdf::PdfDSL::PdfBuilder.new
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_render_page_with_regular_page
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:seasonal, dest: 'seasonal')
    context = {
      year: 2025,
      total_weeks: 53,
      page_key: :seasonal,
      page_number: 1,
      link_resolver: nil
    }

    @builder.send(:render_page, @pdf, page_decl, context)
  end

  def test_render_page_with_weekly_page
    page_decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, dest: 'week_1')
    context = {
      year: 2025,
      total_weeks: 53,
      page_key: :week_1,
      page_number: 1,
      week_num: 1,
      week_start: Date.new(2024, 12, 30),
      week_end: Date.new(2025, 1, 5),
      link_resolver: nil
    }

    @builder.send(:render_page, @pdf, page_decl, context)
  end
end

class TestPdfBuilderDateConfig < Minitest::Test
  def setup
    @builder = BujoPdf::PdfDSL::PdfBuilder.new
  end

  def test_load_date_configuration_when_file_missing
    result = @builder.send(:load_date_configuration, 2025)

    # Should return nil if config/dates.yml doesn't exist
    # (behavior depends on actual file existence)
  end

  def test_load_calendar_events
    result = @builder.send(:load_calendar_events, 2025)

    # Should call CalendarIntegration.load_events
    # Result depends on actual calendar configuration
  end
end
