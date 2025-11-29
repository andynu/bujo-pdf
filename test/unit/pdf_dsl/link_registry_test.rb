#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'
require 'bujo_pdf/pdf_dsl/link_registry'

class TestLinkRegistry < Minitest::Test
  def setup
    @registry = BujoPdf::PdfDSL::LinkRegistry.new
  end

  # Basic registration and resolution

  def test_register_simple_page
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:year_events)
    info = @registry.register(decl, page_number: 1)

    assert_equal 'year_events', info.destination_key
    assert_equal 1, info.page_number
    assert_equal :year_events, info.page_type
  end

  def test_register_page_with_params
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: 12)
    info = @registry.register(decl, page_number: 15)

    assert_equal 'weekly_week_num_12', info.destination_key
    assert_equal 15, info.page_number
    assert_equal :weekly, info.page_type
    assert_equal({ week_num: 12 }, info.params)
  end

  def test_resolve_simple_page
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:year_events)
    @registry.register(decl, page_number: 1)

    info = @registry.resolve(:year_events)

    assert_equal 'year_events', info.destination
    assert_equal 1, info.page_number
  end

  def test_resolve_page_with_params
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: 12)
    @registry.register(decl, page_number: 15)

    info = @registry.resolve(:weekly, week_num: 12)

    assert_equal 'weekly_week_num_12', info.destination
    assert_equal 15, info.page_number
  end

  def test_resolve_returns_nil_for_unknown
    info = @registry.resolve(:nonexistent)
    assert_nil info
  end

  def test_resolve_returns_nil_for_wrong_params
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: 12)
    @registry.register(decl, page_number: 15)

    info = @registry.resolve(:weekly, week_num: 999)
    assert_nil info
  end

  def test_resolve_key_directly
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:year_events)
    @registry.register(decl, page_number: 1)

    info = @registry.resolve_key('year_events')

    assert_equal 'year_events', info.destination
    assert_equal 1, info.page_number
  end

  # Multiple pages of same type

  def test_register_multiple_weekly_pages
    (1..53).each do |week_num|
      decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: week_num)
      @registry.register(decl, page_number: week_num + 3)
    end

    assert_equal 53, @registry.destinations_for_type(:weekly).length

    info = @registry.resolve(:weekly, week_num: 42)
    assert_equal 'weekly_week_num_42', info.destination
    assert_equal 45, info.page_number
  end

  # Existence checks

  def test_exists?
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:year_events)
    @registry.register(decl, page_number: 1)

    assert @registry.exists?(:year_events)
    refute @registry.exists?(:nonexistent)
  end

  def test_key_exists?
    decl = BujoPdf::PdfDSL::PageDeclaration.new(:year_events)
    @registry.register(decl, page_number: 1)

    assert @registry.key_exists?('year_events')
    refute @registry.key_exists?('nonexistent')
  end

  # Groups

  def test_register_and_resolve_group
    # Register pages first
    %i[grid_dot grid_graph grid_lined].each_with_index do |type, idx|
      decl = BujoPdf::PdfDSL::PageDeclaration.new(type)
      @registry.register(decl, page_number: 10 + idx)
    end

    # Create and register group
    group = BujoPdf::PdfDSL::GroupDeclaration.new(:grids, cycle: true)
    %i[grid_dot grid_graph grid_lined].each do |type|
      group.add_page(BujoPdf::PdfDSL::PageDeclaration.new(type))
    end
    @registry.register_group(group)

    grp_info = @registry.group(:grids)
    assert grp_info[:cycle]
    assert_equal %w[grid_dot grid_graph grid_lined], grp_info[:destinations]
  end

  def test_next_in_cycle
    # Register pages
    %i[grid_dot grid_graph grid_lined].each_with_index do |type, idx|
      decl = BujoPdf::PdfDSL::PageDeclaration.new(type)
      @registry.register(decl, page_number: 10 + idx)
    end

    # Create cycling group
    group = BujoPdf::PdfDSL::GroupDeclaration.new(:grids, cycle: true)
    %i[grid_dot grid_graph grid_lined].each do |type|
      group.add_page(BujoPdf::PdfDSL::PageDeclaration.new(type))
    end
    @registry.register_group(group)

    # Test cycling
    assert_equal 'grid_graph', @registry.next_in_cycle(:grids, 'grid_dot')
    assert_equal 'grid_lined', @registry.next_in_cycle(:grids, 'grid_graph')
    assert_equal 'grid_dot', @registry.next_in_cycle(:grids, 'grid_lined')
  end

  def test_next_in_cycle_returns_first_if_not_in_cycle
    group = BujoPdf::PdfDSL::GroupDeclaration.new(:grids, cycle: true)
    %i[grid_dot grid_graph].each do |type|
      group.add_page(BujoPdf::PdfDSL::PageDeclaration.new(type))
    end
    @registry.register_group(group)

    assert_equal 'grid_dot', @registry.next_in_cycle(:grids, 'unknown')
  end

  def test_next_in_cycle_returns_nil_for_non_cycling_group
    group = BujoPdf::PdfDSL::GroupDeclaration.new(:grids, cycle: false)
    group.add_page(BujoPdf::PdfDSL::PageDeclaration.new(:grid_dot))
    @registry.register_group(group)

    assert_nil @registry.next_in_cycle(:grids, 'grid_dot')
  end

  # Utility methods

  def test_size
    assert_equal 0, @registry.size

    @registry.register(BujoPdf::PdfDSL::PageDeclaration.new(:year_events), page_number: 1)
    assert_equal 1, @registry.size

    @registry.register(BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: 1), page_number: 2)
    assert_equal 2, @registry.size
  end

  def test_keys
    @registry.register(BujoPdf::PdfDSL::PageDeclaration.new(:year_events), page_number: 1)
    @registry.register(BujoPdf::PdfDSL::PageDeclaration.new(:year_highlights), page_number: 2)

    keys = @registry.keys
    assert_includes keys, 'year_events'
    assert_includes keys, 'year_highlights'
  end

  def test_group_names
    @registry.register_group(BujoPdf::PdfDSL::GroupDeclaration.new(:grids))
    @registry.register_group(BujoPdf::PdfDSL::GroupDeclaration.new(:templates))

    names = @registry.group_names
    assert_includes names, :grids
    assert_includes names, :templates
  end

  def test_clear!
    @registry.register(BujoPdf::PdfDSL::PageDeclaration.new(:year_events), page_number: 1)
    @registry.register_group(BujoPdf::PdfDSL::GroupDeclaration.new(:grids))

    @registry.clear!

    assert_equal 0, @registry.size
    assert_empty @registry.group_names
  end
end

class TestLinkResolver < Minitest::Test
  def setup
    @registry = BujoPdf::PdfDSL::LinkRegistry.new

    # Register some pages
    @registry.register(BujoPdf::PdfDSL::PageDeclaration.new(:year_events), page_number: 1)
    @registry.register(BujoPdf::PdfDSL::PageDeclaration.new(:year_highlights), page_number: 2)

    (1..53).each do |week_num|
      decl = BujoPdf::PdfDSL::PageDeclaration.new(:weekly, week_num: week_num)
      @registry.register(decl, page_number: week_num + 2)
    end

    # Register grid group
    %i[grid_dot grid_graph grid_lined].each_with_index do |type, idx|
      decl = BujoPdf::PdfDSL::PageDeclaration.new(type)
      @registry.register(decl, page_number: 56 + idx)
    end

    group = BujoPdf::PdfDSL::GroupDeclaration.new(:grids, cycle: true)
    %i[grid_dot grid_graph grid_lined].each do |type|
      group.add_page(BujoPdf::PdfDSL::PageDeclaration.new(type))
    end
    @registry.register_group(group)
  end

  def test_resolve_by_type_and_params
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry)

    dest = resolver.resolve(:weekly, week_num: 10)
    assert_equal 'weekly_week_num_10', dest
  end

  def test_resolve_simple_type
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry)

    dest = resolver.resolve(:year_events)
    assert_equal 'year_events', dest
  end

  def test_resolve_key
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry)

    dest = resolver.resolve_key('year_highlights')
    assert_equal 'year_highlights', dest
  end

  def test_resolve_returns_nil_for_unknown
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry)

    dest = resolver.resolve(:nonexistent)
    assert_nil dest
  end

  def test_dest_for_prev_week
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry, current_params: { week_num: 10 })

    dest = resolver.dest_for_prev_week
    assert_equal 'weekly_week_num_9', dest
  end

  def test_dest_for_prev_week_returns_nil_at_week_1
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry, current_params: { week_num: 1 })

    dest = resolver.dest_for_prev_week
    assert_nil dest
  end

  def test_dest_for_next_week
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry, current_params: { week_num: 10, total_weeks: 53 })

    dest = resolver.dest_for_next_week
    assert_equal 'weekly_week_num_11', dest
  end

  def test_dest_for_next_week_returns_nil_at_last_week
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry, current_params: { week_num: 53, total_weeks: 53 })

    dest = resolver.dest_for_next_week
    assert_nil dest
  end

  def test_dest_for_prev_week_with_explicit_week
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry)

    dest = resolver.dest_for_prev_week(week_num: 20)
    assert_equal 'weekly_week_num_19', dest
  end

  def test_dest_for_next_week_with_explicit_week
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry)

    dest = resolver.dest_for_next_week(week_num: 20, total_weeks: 53)
    assert_equal 'weekly_week_num_21', dest
  end

  def test_group_destinations
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry)

    dests = resolver.group_destinations(:grids)
    assert_equal %w[grid_dot grid_graph grid_lined], dests
  end

  def test_next_in_group
    resolver = BujoPdf::PdfDSL::LinkResolver.new(
      @registry,
      current_page: :grid_dot,
      current_params: {}
    )

    next_dest = resolver.next_in_group(:grids)
    assert_equal 'grid_graph', next_dest
  end

  def test_in_group?
    resolver = BujoPdf::PdfDSL::LinkResolver.new(
      @registry,
      current_page: :grid_dot,
      current_params: {}
    )

    assert resolver.in_group?(:grids)

    resolver2 = BujoPdf::PdfDSL::LinkResolver.new(
      @registry,
      current_page: :year_events,
      current_params: {}
    )

    refute resolver2.in_group?(:grids)
  end

  def test_exists?
    resolver = BujoPdf::PdfDSL::LinkResolver.new(@registry)

    assert resolver.exists?(:year_events)
    assert resolver.exists?(:weekly, week_num: 10)
    refute resolver.exists?(:nonexistent)
  end
end
