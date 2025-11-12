# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test_unit) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/unit/**/*_test.rb']
  t.verbose = true
end

Rake::TestTask.new(:test_integration) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/integration/**/*_test.rb']
  t.verbose = true
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/unit/**/*_test.rb', 'test/integration/**/*_test.rb']
  t.verbose = true
end

desc 'Run all tests (unit + integration)'
task default: :test

desc 'Generate a test planner PDF'
task :generate, [:year] do |_t, args|
  require_relative 'lib/bujo_pdf'

  year = args[:year] ? args[:year].to_i : Date.today.year
  output_file = "planner_#{year}.pdf"

  puts "Generating planner for #{year}..."
  BujoPdf.generate(year, output_path: output_file)
  puts "Generated: #{output_file}"
end

desc 'Build gem and test installation locally'
task :test_install do
  sh 'gem build bujo-pdf.gemspec'
  gem_file = Dir['bujo-pdf-*.gem'].sort.last
  sh "gem install #{gem_file}"
  puts "\nTesting installed gem:"
  sh 'bujo-pdf --version'
end
