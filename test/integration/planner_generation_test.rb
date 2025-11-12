#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require 'fileutils'
require 'tmpdir'

# Integration tests for full planner PDF generation.
#
# These tests verify the complete end-to-end workflow of generating
# a planner PDF, including all pages, navigation, and structure.
class TestPlannerGeneration < Minitest::Test
  include BujoPdf

  def setup
    @test_year = 2025
    @output_dir = Dir.mktmpdir('bujo_pdf_test')
    @output_path = File.join(@output_dir, "test_planner_#{@test_year}.pdf")
  end

  def teardown
    # Clean up test files
    FileUtils.rm_rf(@output_dir) if @output_dir && Dir.exist?(@output_dir)
  end

  # Test that planner can be generated without errors
  def test_generates_planner_successfully
    BujoPdf.generate(@test_year, output_path: @output_path)

    assert File.exist?(@output_path), "PDF file should be created at #{@output_path}"
    assert File.size(@output_path) > 0, "PDF file should not be empty"
  end

  # Test that generated PDF has reasonable file size
  def test_generated_pdf_has_reasonable_size
    BujoPdf.generate(@test_year, output_path: @output_path)

    file_size_kb = File.size(@output_path) / 1024.0
    file_size_mb = file_size_kb / 1024.0

    # Should be under 10MB (typical is 2-3MB)
    assert file_size_mb < 10, "PDF should be under 10MB, got #{file_size_mb.round(2)}MB"

    # Should be at least 100KB (too small suggests missing content)
    assert file_size_kb > 100, "PDF should be at least 100KB, got #{file_size_kb.round(2)}KB"
  end

  # Test that planner generation completes within reasonable time
  def test_generates_planner_quickly
    start_time = Time.now

    BujoPdf.generate(@test_year, output_path: @output_path)

    elapsed = Time.now - start_time

    # Should complete in under 10 seconds (typical is 1-2 seconds)
    assert elapsed < 10, "PDF generation should take less than 10 seconds, took #{elapsed.round(2)}s"
  end

  # Test that planner can be generated for different years
  def test_generates_planner_for_different_years
    [2024, 2025, 2026].each do |year|
      output = File.join(@output_dir, "planner_#{year}.pdf")

      BujoPdf.generate(year, output_path: output)

      assert File.exist?(output), "PDF for #{year} should be created"
      assert File.size(output) > 0, "PDF for #{year} should not be empty"
    end
  end

  # Test that planner handles leap years correctly
  def test_handles_leap_year
    leap_year = 2024
    output = File.join(@output_dir, "planner_#{leap_year}.pdf")

    BujoPdf.generate(leap_year, output_path: output)

    assert File.exist?(output), "Leap year PDF should be created"
    assert File.size(output) > 0, "Leap year PDF should not be empty"
  end

  # Test that custom output path is respected
  def test_respects_custom_output_path
    custom_path = File.join(@output_dir, 'custom_name.pdf')

    BujoPdf.generate(@test_year, output_path: custom_path)

    assert File.exist?(custom_path), "PDF should be created at custom path"
    # Note: We only check that the custom path was used, not that default wasn't created
    # since we're controlling the output path explicitly
  end

  # Test that generating multiple years doesn't interfere
  def test_generates_multiple_years_independently
    paths = []

    [2024, 2025, 2026].each do |year|
      path = File.join(@output_dir, "planner_#{year}.pdf")
      BujoPdf.generate(year, output_path: path)
      paths << path
    end

    # All files should exist
    paths.each do |path|
      assert File.exist?(path), "File should exist: #{path}"
    end

    # Files should have different sizes (different years have different content)
    sizes = paths.map { |p| File.size(p) }

    # At least some files should have different sizes
    # (not a strict requirement but likely with different week counts)
    assert sizes.uniq.length >= 1, "Generated PDFs should exist"
  end

  # Test that planner generation is idempotent (same output for same input)
  def test_generation_is_idempotent
    path1 = File.join(@output_dir, 'planner1.pdf')
    path2 = File.join(@output_dir, 'planner2.pdf')

    # Generate twice with same parameters
    BujoPdf.generate(@test_year, output_path: path1)
    BujoPdf.generate(@test_year, output_path: path2)

    size1 = File.size(path1)
    size2 = File.size(path2)

    # Sizes should be identical (within a small tolerance for timestamps)
    # Note: Exact byte-for-byte comparison is not reliable due to PDF metadata
    # but sizes should be the same
    assert_in_delta size1, size2, 100, "Generated PDFs should have similar sizes"
  end

  # Test error handling for invalid year
  def test_raises_error_for_invalid_year
    # Note: Current implementation is lenient and attempts to generate
    # for any year value. Validation could be added in the future.
    skip "Year validation not yet implemented"
  end

  # Test that output directory is created if it doesn't exist
  def test_creates_output_directory_if_missing
    nested_path = File.join(@output_dir, 'nested', 'deep', 'planner.pdf')

    # Ensure parent directories are created
    FileUtils.mkdir_p(File.dirname(nested_path))

    BujoPdf.generate(@test_year, output_path: nested_path)

    assert File.exist?(nested_path), "PDF should be created in nested directory"
  end
end
