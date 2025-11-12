#!/usr/bin/env ruby
# frozen_string_literal: true

# Legacy entry point - now uses gem infrastructure
require_relative 'lib/bujo_pdf'

year = ARGV[0] ? ARGV[0].to_i : Date.today.year
output_file = "planner_#{year}.pdf"

puts "Generating planner for #{year} using BujoPdf gem..."
BujoPdf.generate(year, output_path: output_file)
puts "Generated: #{output_file}"
