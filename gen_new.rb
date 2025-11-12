#!/usr/bin/env ruby

# New planner generator using page architecture
require_relative 'lib/bujo_pdf'

year = ARGV[0]&.to_i || Date.today.year
generator = BujoPdf::PlannerGenerator.new(year)
generator.generate("planner_#{year}_new.pdf")

puts "Generated planner_#{year}_new.pdf"
