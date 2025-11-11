#!/usr/bin/env ruby
# frozen_string_literal: true

# Test runner - runs all test files
Dir.glob(File.join(__dir__, 'test_*.rb')).each do |test_file|
  require test_file
end
