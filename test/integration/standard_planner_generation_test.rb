#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require 'bujo_pdf'
require 'bujo_pdf/pdf_dsl'
require 'tempfile'
require 'fileutils'

class TestStandardPlannerGeneration < Minitest::Test
  def setup
    BujoPdf::PdfDSL.clear_recipes!
    BujoPdf::PdfDSL.load_recipes!
    Prawn::Fonts::AFM.hide_m17n_warning = true
  end

  def teardown
    BujoPdf::PdfDSL.clear_recipes!
  end

  # Full PDF generation test

  def test_generates_pdf_file
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'test_planner.pdf')

      result = BujoPdf.generate_from_recipe(:standard_planner, year: 2025, output: output_path)

      assert_equal output_path, result
      assert File.exist?(output_path), "PDF file should exist"
      assert File.size(output_path) > 0, "PDF file should not be empty"
    end
  end

  def test_generates_similar_page_count_to_original
    Dir.mktmpdir do |dir|
      dsl_path = File.join(dir, 'dsl_planner.pdf')
      original_path = File.join(dir, 'original_planner.pdf')

      # Generate with DSL
      BujoPdf.generate_from_recipe(:standard_planner, year: 2025, output: dsl_path)

      # Generate with original
      generator = BujoPdf::PlannerGenerator.new(2025)
      generator.generate(original_path)

      # Compare file sizes (should be within 5%)
      dsl_size = File.size(dsl_path)
      original_size = File.size(original_path)

      ratio = dsl_size.to_f / original_size
      assert_in_delta 1.0, ratio, 0.05, "DSL output size should be within 5% of original"
    end
  end

  def test_generates_with_different_themes
    Dir.mktmpdir do |dir|
      [:light, :earth, :dark].each do |theme|
        output_path = File.join(dir, "planner_#{theme}.pdf")

        result = BujoPdf.generate_from_recipe(
          :standard_planner,
          year: 2025,
          theme: theme,
          output: output_path
        )

        assert File.exist?(output_path), "PDF with #{theme} theme should exist"
        assert File.size(output_path) > 1_000_000, "PDF should be substantial (>1MB)"
      end
    end
  end

  def test_generates_for_multiple_years
    Dir.mktmpdir do |dir|
      [2024, 2025, 2026].each do |year|
        output_path = File.join(dir, "planner_#{year}.pdf")

        result = BujoPdf.generate_from_recipe(
          :standard_planner,
          year: year,
          output: output_path
        )

        assert File.exist?(output_path), "PDF for year #{year} should exist"

        # Total weeks varies by year
        total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(year)
        expected_pages = 4 + total_weeks + 8 + 3  # overview + weeks + grids + templates

        # Verify file size is proportional to page count
        # A rough estimate is ~70KB per page
        min_expected_size = expected_pages * 50_000
        max_expected_size = expected_pages * 100_000

        actual_size = File.size(output_path)
        assert actual_size > min_expected_size,
          "PDF for #{year} should be > #{min_expected_size / 1_000_000.0}MB, got #{actual_size / 1_000_000.0}MB"
      end
    end
  end

  def test_returns_prawn_document_without_output_path
    pdf = BujoPdf.generate_from_recipe(:standard_planner, year: 2025)

    assert_instance_of Prawn::Document, pdf
  end
end
