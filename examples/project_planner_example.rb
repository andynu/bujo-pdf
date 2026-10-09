#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# Project Planner Example
# =============================================================================
#
# This example demonstrates the convention-based outline system in bujo-pdf.
# It generates a simple project planner with hierarchical PDF bookmarks that
# showcases all four outline features:
#
#   1. OVERRIDE: Cover page shows "Year Overview" instead of auto-derived title
#   2. SUPPRESS: June is excluded from the outline (outline: false)
#   3. AUTO:     Other months use auto-generated titles from page registry
#   4. HIERARCHY: The `group :months` creates a "Months" section with children
#
# The recipe uses `outline_mode :auto` which automatically generates PDF
# outline entries from page titles, with per-page overrides available.
#
# Usage:
#   bundle exec ruby examples/project_planner_example.rb
#
# After running, open project_planner_2025.pdf and check the PDF outline
# (bookmarks panel) to see the hierarchical structure.
#
# =============================================================================

require_relative '../lib/bujo_pdf'

OUTPUT_FILE = 'project_planner_2025.pdf'

puts "=" * 70
puts "Convention-Based Outline System Demo"
puts "=" * 70
puts

# Load all recipes including the project_planner recipe
puts "Loading recipes..."
BujoPdf::PdfDSL.load_recipes!

# Verify MonthlyOverview page type is available (used by the recipe)
puts "Verifying page types..."
factory_class = BujoPdf::PageFactory.registry[:monthly_overview]
if factory_class
  puts "  -> MonthlyOverview registered: #{factory_class}"
else
  puts "  -> WARNING: MonthlyOverview not found in registry!"
  puts "  -> Available: #{BujoPdf::PageFactory.registry.keys.join(', ')}"
end
puts

# Generate the PDF
puts "Generating project planner for 2025..."
begin
  BujoPdf.generate_from_recipe(:project_planner, year: 2025, output: OUTPUT_FILE)
  puts "Success! Generated: #{OUTPUT_FILE}"
  puts "File size: #{File.size(OUTPUT_FILE)} bytes"
rescue => e
  puts "\nERROR: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  exit 1
end

puts
puts "-" * 70
puts "Expected PDF Outline Structure:"
puts "-" * 70
puts <<~OUTLINE
  - 'Year Overview'      <- Cover page (outline: "Year Overview" override)
  - 'Months'             <- Group section header (links to first child)
      - January 2025     <- Auto-generated from page title
      - February 2025
      - March 2025
      - April 2025
      - May 2025
      (June MISSING)     <- Suppressed with outline: false
      - July 2025
      - August 2025
      - September 2025
      - October 2025
      - November 2025
      - December 2025
  - 'Notes'              <- Auto-generated from page ID
OUTLINE
puts
puts "Open the PDF and verify the outline matches this structure."
puts

# Cleanup: Remove the generated PDF after verification prompt
puts "-" * 70
print "Delete generated PDF? [y/N] "
response = $stdin.gets&.strip&.downcase
if response == 'y'
  File.delete(OUTPUT_FILE) if File.exist?(OUTPUT_FILE)
  puts "Deleted #{OUTPUT_FILE}"
else
  puts "Kept #{OUTPUT_FILE} for inspection"
end
