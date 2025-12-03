#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require 'fileutils'
require 'tmpdir'

# Integration tests for full planner PDF generation.
#
# These tests verify the complete end-to-end workflow of generating
# a planner PDF, including all pages, navigation, and structure.
#
# PERFORMANCE NOTE: Full planner generation takes ~6-7 seconds per year.
# Tests are organized to minimize redundant generation while maintaining
# test isolation where necessary. Tests that can share a generated PDF
# are grouped together to avoid regeneration.
class TestPlannerGeneration < Minitest::Test
  include BujoPdf

  def setup
    @test_year = 2025
    @output_dir = Dir.mktmpdir('bujo_pdf_test')
  end

  def teardown
    FileUtils.rm_rf(@output_dir) if @output_dir && Dir.exist?(@output_dir)
  end

  # Core smoke test: verifies file creation, size, and generation time
  # in a single planner generation (replaces 3 separate tests)
  def test_planner_generation_smoke_test
    output_path = File.join(@output_dir, "test_planner_#{@test_year}.pdf")
    start_time = Time.now

    BujoPdf.generate(@test_year, output_path: output_path)

    elapsed = Time.now - start_time
    file_size_kb = File.size(output_path) / 1024.0
    file_size_mb = file_size_kb / 1024.0

    # File exists and is not empty
    assert File.exist?(output_path), "PDF file should be created at #{output_path}"
    assert File.size(output_path) > 0, "PDF file should not be empty"

    # Size is reasonable (2-3MB typical, under 10MB max)
    assert file_size_mb < 10, "PDF should be under 10MB, got #{file_size_mb.round(2)}MB"
    assert file_size_kb > 100, "PDF should be at least 100KB, got #{file_size_kb.round(2)}KB"

    # Generation time is reasonable
    assert elapsed < 15, "PDF generation should take less than 15 seconds, took #{elapsed.round(2)}s"
  end

  # Test that planner can be generated for multiple years
  # Consolidates: test_generates_planner_for_different_years, test_handles_leap_year,
  # test_generates_multiple_years_independently
  def test_generates_planner_for_multiple_years
    years = [2024, 2025, 2026]  # 2024 is leap year
    paths = {}

    years.each do |year|
      path = File.join(@output_dir, "planner_#{year}.pdf")
      BujoPdf.generate(year, output_path: path)
      paths[year] = path
    end

    # All files should exist and have content
    years.each do |year|
      assert File.exist?(paths[year]), "PDF for #{year} should be created"
      assert File.size(paths[year]) > 0, "PDF for #{year} should not be empty"
    end

    # Files can have same or different sizes depending on week counts
    sizes = paths.values.map { |p| File.size(p) }
    assert sizes.all? { |s| s > 100_000 }, "All PDFs should have reasonable size"
  end

  # Test that planner generation is idempotent
  def test_generation_is_idempotent
    path1 = File.join(@output_dir, 'planner1.pdf')
    path2 = File.join(@output_dir, 'planner2.pdf')

    BujoPdf.generate(@test_year, output_path: path1)
    BujoPdf.generate(@test_year, output_path: path2)

    size1 = File.size(path1)
    size2 = File.size(path2)

    # Sizes should be identical (within small tolerance for timestamps)
    assert_in_delta size1, size2, 100, "Generated PDFs should have similar sizes"
  end

  # Test that custom output path is respected
  def test_respects_custom_output_path
    custom_path = File.join(@output_dir, 'custom_name.pdf')

    BujoPdf.generate(@test_year, output_path: custom_path)

    assert File.exist?(custom_path), "PDF should be created at custom path"
  end

  # Test that output directory handling works
  def test_creates_output_in_nested_directory
    nested_path = File.join(@output_dir, 'nested', 'deep', 'planner.pdf')
    FileUtils.mkdir_p(File.dirname(nested_path))

    BujoPdf.generate(@test_year, output_path: nested_path)

    assert File.exist?(nested_path), "PDF should be created in nested directory"
  end

  # Test error handling for invalid year
  def test_raises_error_for_invalid_year
    skip "Year validation not yet implemented"
  end
end
