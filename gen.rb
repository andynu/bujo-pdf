#!/usr/bin/env ruby

# Planner generator using component-based architecture
require_relative 'lib/bujo_pdf'

year = ARGV[0]&.to_i || Date.today.year
generator = BujoPdf::PlannerGenerator.new(year)
generator.generate("planner_#{year}.pdf")

puts "Generated planner_#{year}.pdf"
