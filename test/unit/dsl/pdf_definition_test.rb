#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

class TestPdfDefinition < Minitest::Test
  def test_basic_creation
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test_planner) do |year:|
      page :seasonal_calendar, year: year
    end

    assert_equal :test_planner, definition.name
    refute_nil definition.block
  end

  def test_evaluate_with_parameters
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:, theme: :light|
      page :seasonal_calendar, year: year
      theme(theme)
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    definition.evaluate(context, year: 2025, theme: :earth)

    assert_equal 1, context.pages.length
    assert_equal 2025, context.pages.first.params[:year]
    assert_equal :earth, context.theme_name
  end

  def test_evaluate_with_iteration
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      weeks_in(year).first(3).each do |week|
        page :weekly, week: week
      end
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    definition.evaluate(context, year: 2025)

    assert_equal 3, context.pages.length
    context.pages.each { |p| assert_equal :weekly, p.type }
  end

  def test_evaluate_with_groups
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      group :grids, cycle: true do
        page :grid_dot
        page :grid_graph
      end
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    definition.evaluate(context, year: 2025)

    assert_equal 1, context.groups.length
    assert_equal 2, context.groups.first.pages.length
    assert_equal 2, context.pages.length
  end

  def test_evaluate_with_metadata
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:|
      metadata do
        title "Planner #{year}"
        author "Test"
      end
    end

    context = BujoPdf::PdfDSL::DeclarationContext.new
    definition.evaluate(context, year: 2025)

    info = context.prawn_metadata
    assert_equal "Planner 2025", info[:Title]
  end

  def test_evaluate_with_conditional_pages
    definition = BujoPdf::PdfDSL::PdfDefinition.new(:test) do |year:, include_grids: false|
      page :seasonal_calendar, year: year

      if include_grids
        page :grid_dot
        page :grid_graph
      end
    end

    # Without grids
    context1 = BujoPdf::PdfDSL::DeclarationContext.new
    definition.evaluate(context1, year: 2025, include_grids: false)
    assert_equal 1, context1.pages.length

    # With grids
    context2 = BujoPdf::PdfDSL::DeclarationContext.new
    definition.evaluate(context2, year: 2025, include_grids: true)
    assert_equal 3, context2.pages.length
  end
end
