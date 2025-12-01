# frozen_string_literal: true

# SimpleCov must be loaded before application code
require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'

  add_group 'Utilities', 'lib/bujo_pdf/utilities'
  add_group 'Components', 'lib/bujo_pdf/components'
  add_group 'Pages', 'lib/bujo_pdf/pages'
  add_group 'Layouts', 'lib/bujo_pdf/layouts'
  add_group 'Core', 'lib/bujo_pdf'

  # Overall coverage target: 80%
  minimum_coverage 80

  # Per-file coverage: lower threshold since some files are presentation layer
  # and harder to test without full PDF generation
  minimum_coverage_by_file 15
end

require 'minitest/autorun'
require 'minitest/reporters'

# Use nicer test output formatting
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

# Test helpers module for common test utilities
module TestHelpers
  # Create a mock PDF for testing
  def mock_pdf
    MockPDF.new
  end
end

# Load all source files from lib/
require_relative '../lib/bujo_pdf'

module Minitest
  class Test
    # Custom assertion: verify grid coordinate calculation
    # @param expected_x [Float] Expected x-coordinate in points
    # @param expected_y [Float] Expected y-coordinate in points
    # @param col [Integer] Grid column
    # @param row [Integer] Grid row
    # @param grid [GridSystem] Grid system instance
    def assert_grid_position(expected_x, expected_y, col, row, grid)
      actual_x = grid.x(col)
      actual_y = grid.y(row)

      assert_in_delta expected_x, actual_x, 0.01,
                      "Expected x(#{col}) to be #{expected_x}, got #{actual_x}"
      assert_in_delta expected_y, actual_y, 0.01,
                      "Expected y(#{row}) to be #{expected_y}, got #{actual_y}"
    end

    # Custom assertion: verify link annotation bounds are in correct order
    # Link bounds format: [left, bottom, right, top]
    # @param bounds [Array<Float>] Link annotation bounds
    def assert_valid_link_bounds(bounds)
      left, bottom, right, top = bounds

      assert left < right, "Link left (#{left}) must be < right (#{right})"
      assert bottom < top, "Link bottom (#{bottom}) must be < top (#{top})"
      assert left >= 0, "Link left (#{left}) must be >= 0"
      assert bottom >= 0, "Link bottom (#{bottom}) must be >= 0"
    end

    # Custom assertion: verify a rectangle contains expected coordinates
    # @param rect [Hash] Rectangle with :x, :y, :width, :height keys
    # @param expected [Hash] Expected values (supports subset checking)
    def assert_rect_equals(rect, expected, delta: 0.01)
      expected.each do |key, value|
        assert rect.key?(key), "Rectangle missing key: #{key}"
        assert_in_delta value, rect[key], delta,
                        "Expected #{key} to be #{value}, got #{rect[key]}"
      end
    end
  end
end

# Mock PDF class for testing without actual PDF generation
class MockPDF
  attr_reader :calls, :current_page_number, :page_count

  def initialize
    @calls = []
    @current_page_number = 1
    @page_count = 1
  end

  # Track all method calls
  def method_missing(method, *args, **kwargs, &block)
    @calls << { method: method, args: args, kwargs: kwargs }

    # Special handling for methods that need specific return values
    case method
    when :width_of
      # Return a reasonable text width (8 points per character as rough estimate)
      text = args.first.to_s
      return text.length * 8.0
    when :font
      # Execute block if given, return self
      yield if block_given?
      return self
    end

    # Return self for chaining
    self
  end

  def respond_to_missing?(method, include_private = false)
    true
  end

  # Simulate page creation
  def start_new_page
    @page_count += 1
    @current_page_number = @page_count
    @calls << { method: :start_new_page, args: [], kwargs: {} }
  end

  # Query method call history
  def called?(method)
    @calls.any? { |call| call[:method] == method }
  end

  def call_count(method)
    @calls.count { |call| call[:method] == method }
  end

  def last_call(method)
    @calls.reverse.find { |call| call[:method] == method }
  end
end

# Mock date config for testing components that use date highlighting
class MockDateConfig
  HighlightedDate = Struct.new(:label, :category, :priority, keyword_init: true)
  CategoryStyle = { 'color' => 'FF6B6B', 'text_color' => 'FFFFFF' }.freeze
  PriorityStyle = { 'bold' => true }.freeze

  def date_for_day(_date)
    HighlightedDate.new(label: "Meeting", category: "work", priority: "high")
  end

  def category_style(_category)
    CategoryStyle
  end

  def priority_style(_priority)
    PriorityStyle
  end
end

# Mock event store that returns events
class MockEventStore
  MockEvent = Struct.new(:color, keyword_init: true) do
    def display_label(include_icon: false)
      "Calendar Event"
    end
  end

  def events_for_date(_date, limit: nil)
    [MockEvent.new(color: '4285F4')]
  end
end

# Mock event store that returns empty results
class MockEventStoreEmpty
  def events_for_date(_date, limit: nil)
    []
  end
end
