#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'

# Unit tests for RenderContext - structured rendering context with typed access
class TestRenderContext < Minitest::Test
  include BujoPdf

  def setup
    @year = 2025
    @week_num = 42
    @week_start = Date.new(2025, 10, 13)
    @week_end = Date.new(2025, 10, 19)
    @total_weeks = 53
  end

  # Test initialization with minimal parameters
  def test_initializes_with_minimal_parameters
    context = RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: @year
    )

    assert_equal :seasonal, context.page_key
    assert_equal 1, context.page_number
    assert_equal @year, context.year
    assert_nil context.week_num
    assert_nil context.week_start
    assert_nil context.week_end
    assert_nil context.total_weeks
    assert_nil context.total_pages
  end

  # Test initialization with all parameters
  def test_initializes_with_all_parameters
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year,
      week_num: @week_num,
      week_start: @week_start,
      week_end: @week_end,
      total_weeks: @total_weeks,
      total_pages: 55
    )

    assert_equal :week_42, context.page_key
    assert_equal 10, context.page_number
    assert_equal @year, context.year
    assert_equal @week_num, context.week_num
    assert_equal @week_start, context.week_start
    assert_equal @week_end, context.week_end
    assert_equal @total_weeks, context.total_weeks
    assert_equal 55, context.total_pages
  end

  # Test initialization with additional data
  def test_initializes_with_additional_data
    context = RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: @year,
      custom_field: 'value',
      another_field: 123
    )

    assert_equal 'value', context.data[:custom_field]
    assert_equal 123, context.data[:another_field]
  end

  # Test current_page? with symbol keys
  def test_current_page_with_symbol_keys
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year
    )

    assert context.current_page?(:week_42)
    refute context.current_page?(:week_1)
    refute context.current_page?(:seasonal)
    refute context.current_page?(:year_events)
  end

  # Test current_page? with string keys
  def test_current_page_with_string_keys
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year
    )

    assert context.current_page?('week_42')
    refute context.current_page?('week_1')
    refute context.current_page?('seasonal')
  end

  # Test current_page? for overview pages
  def test_current_page_for_overview_pages
    seasonal = RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: @year
    )

    assert seasonal.current_page?(:seasonal)
    refute seasonal.current_page?(:year_events)

    year_events = RenderContext.new(
      page_key: :year_events,
      page_number: 2,
      year: @year
    )

    assert year_events.current_page?(:year_events)
    refute year_events.current_page?(:seasonal)
    refute year_events.current_page?(:year_highlights)
  end

  # Test weekly_page? for weekly pages
  def test_weekly_page_returns_true_for_weekly_pages
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year,
      week_num: @week_num,
      week_start: @week_start,
      week_end: @week_end
    )

    assert context.weekly_page?
  end

  # Test weekly_page? for overview pages
  def test_weekly_page_returns_false_for_overview_pages
    context = RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: @year
    )

    refute context.weekly_page?
  end

  # Test destination returns string format
  def test_destination_returns_string
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year
    )

    assert_equal 'week_42', context.destination
    assert_instance_of String, context.destination
  end

  # Test destination for various page types
  def test_destination_for_various_page_types
    seasonal = RenderContext.new(page_key: :seasonal, page_number: 1, year: @year)
    assert_equal 'seasonal', seasonal.destination

    year_events = RenderContext.new(page_key: :year_events, page_number: 2, year: @year)
    assert_equal 'year_events', year_events.destination

    reference = RenderContext.new(page_key: :reference, page_number: 54, year: @year)
    assert_equal 'reference', reference.destination
  end

  # Test [] accessor for primary attributes
  def test_bracket_accessor_for_primary_attributes
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year,
      week_num: @week_num,
      week_start: @week_start,
      week_end: @week_end,
      total_weeks: @total_weeks,
      total_pages: 55
    )

    assert_equal :week_42, context[:page_key]
    assert_equal 10, context[:page_number]
    assert_equal @year, context[:year]
    assert_equal @week_num, context[:week_num]
    assert_equal @week_start, context[:week_start]
    assert_equal @week_end, context[:week_end]
    assert_equal @total_weeks, context[:total_weeks]
    assert_equal 55, context[:total_pages]
  end

  # Test [] accessor for additional data
  def test_bracket_accessor_for_additional_data
    context = RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: @year,
      custom_field: 'value',
      another_field: 123,
      nested_data: { key: 'nested_value' }
    )

    assert_equal 'value', context[:custom_field]
    assert_equal 123, context[:another_field]
    assert_equal({ key: 'nested_value' }, context[:nested_data])
  end

  # Test [] accessor returns nil for unknown keys
  def test_bracket_accessor_returns_nil_for_unknown_keys
    context = RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: @year
    )

    assert_nil context[:nonexistent_key]
    assert_nil context[:unknown_field]
  end

  # Test to_h conversion
  def test_to_h_conversion
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year,
      week_num: @week_num,
      week_start: @week_start,
      week_end: @week_end,
      total_weeks: @total_weeks,
      total_pages: 55
    )

    hash = context.to_h

    assert_instance_of Hash, hash
    assert_equal :week_42, hash[:page_key]
    assert_equal 10, hash[:page_number]
    assert_equal @year, hash[:year]
    assert_equal @week_num, hash[:week_num]
    assert_equal @week_start, hash[:week_start]
    assert_equal @week_end, hash[:week_end]
    assert_equal @total_weeks, hash[:total_weeks]
    assert_equal 55, hash[:total_pages]
  end

  # Test to_h includes additional data
  def test_to_h_includes_additional_data
    context = RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: @year,
      custom_field: 'value',
      another_field: 123
    )

    hash = context.to_h

    assert_equal 'value', hash[:custom_field]
    assert_equal 123, hash[:another_field]
  end

  # Test to_h includes nil values for unset optional parameters
  def test_to_h_includes_nil_for_unset_parameters
    context = RenderContext.new(
      page_key: :seasonal,
      page_number: 1,
      year: @year
    )

    hash = context.to_h

    assert_nil hash[:week_num]
    assert_nil hash[:week_start]
    assert_nil hash[:week_end]
    assert_nil hash[:total_weeks]
    assert_nil hash[:total_pages]
  end

  # Test immutability of attributes (read-only)
  def test_attributes_are_read_only
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year
    )

    # Verify no setter methods exist
    refute_respond_to context, :page_key=
    refute_respond_to context, :page_number=
    refute_respond_to context, :year=
    refute_respond_to context, :week_num=
  end

  # Test context for first week of year
  def test_context_for_first_week
    context = RenderContext.new(
      page_key: :week_1,
      page_number: 5,
      year: @year,
      week_num: 1,
      week_start: Date.new(2024, 12, 30), # Week 1 may start in previous year
      week_end: Date.new(2025, 1, 5),
      total_weeks: 53
    )

    assert_equal :week_1, context.page_key
    assert_equal 1, context.week_num
    assert context.weekly_page?
    assert context.current_page?(:week_1)
    refute context.current_page?(:week_2)

    # Verify week spans year boundary
    assert_equal 2024, context.week_start.year
    assert_equal 2025, context.week_end.year
  end

  # Test context for last week of year
  def test_context_for_last_week
    context = RenderContext.new(
      page_key: :week_53,
      page_number: 57,
      year: @year,
      week_num: 53,
      week_start: Date.new(2025, 12, 29),
      week_end: Date.new(2026, 1, 4), # Last week may extend into next year
      total_weeks: 53
    )

    assert_equal :week_53, context.page_key
    assert_equal 53, context.week_num
    assert context.weekly_page?
    assert context.current_page?(:week_53)

    # Verify week spans year boundary
    assert_equal 2025, context.week_start.year
    assert_equal 2026, context.week_end.year
  end

  # Test context serialization and deserialization
  def test_context_can_be_serialized_via_to_h
    original = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year,
      week_num: @week_num,
      week_start: @week_start,
      week_end: @week_end,
      total_weeks: @total_weeks,
      custom_field: 'value'
    )

    hash = original.to_h
    reconstructed = RenderContext.new(**hash)

    assert_equal original.page_key, reconstructed.page_key
    assert_equal original.page_number, reconstructed.page_number
    assert_equal original.year, reconstructed.year
    assert_equal original.week_num, reconstructed.week_num
    assert_equal original.week_start, reconstructed.week_start
    assert_equal original.week_end, reconstructed.week_end
    assert_equal original.total_weeks, reconstructed.total_weeks
    assert_equal original[:custom_field], reconstructed[:custom_field]
  end

  # Test context-aware component rendering pattern
  def test_context_aware_rendering_pattern
    contexts = [
      RenderContext.new(page_key: :seasonal, page_number: 1, year: @year),
      RenderContext.new(page_key: :week_1, page_number: 5, year: @year, week_num: 1),
      RenderContext.new(page_key: :week_2, page_number: 6, year: @year, week_num: 2)
    ]

    # Simulate component that highlights current page
    contexts.each do |context|
      if context.current_page?(:week_1)
        # This context should be the second one
        assert_equal 5, context.page_number
        assert_equal 1, context.week_num
      end
    end
  end

  # Test accessor methods are consistent with bracket accessor
  def test_accessor_methods_consistent_with_bracket_accessor
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year,
      week_num: @week_num
    )

    # Method accessors and bracket accessor should return same values
    assert_equal context.page_key, context[:page_key]
    assert_equal context.page_number, context[:page_number]
    assert_equal context.year, context[:year]
    assert_equal context.week_num, context[:week_num]
  end

  # Test edge case: page_key as string gets converted to symbol
  def test_string_page_key_in_current_page_check
    context = RenderContext.new(
      page_key: :week_42,
      page_number: 10,
      year: @year
    )

    # Both string and symbol should work for current_page?
    assert context.current_page?(:week_42)
    assert context.current_page?('week_42')

    # But actual page_key is always a symbol
    assert_equal :week_42, context.page_key
    assert_instance_of Symbol, context.page_key
  end
end
