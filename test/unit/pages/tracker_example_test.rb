#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'

class TestTrackerExample < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
    @context = BujoPdf::RenderContext.new(
      page_key: :tracker_example,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )
  end

  def test_page_has_registered_type
    assert_equal :tracker_example, BujoPdf::Pages::TrackerExample.page_type
  end

  def test_page_has_registered_title
    assert_equal "Tracker Ideas", BujoPdf::Pages::TrackerExample.default_title
  end

  def test_page_has_registered_dest
    assert_equal "tracker_example", BujoPdf::Pages::TrackerExample.default_dest
  end

  def test_generate_produces_valid_page
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.generate

    assert_equal 1, @pdf.page_count
  end

  def test_setup_sets_destination
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)

    # Destination should be set (tracker_example)
    # Can't easily verify without PDF introspection
  end

  def test_setup_uses_full_page_layout
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)

    layout = page.instance_variable_get(:@new_layout)
    assert layout, "Expected layout to be set"
  end

  def test_render_calls_all_sections
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)

    # Track method calls
    calls = []
    page.define_singleton_method(:draw_header) { calls << :header }
    page.define_singleton_method(:draw_habit_tracker_example) { calls << :habit }
    page.define_singleton_method(:draw_mood_tracker_example) { calls << :mood }
    page.define_singleton_method(:draw_footer_note) { calls << :footer }

    page.send(:render)

    assert_equal [:header, :habit, :mood, :footer], calls
  end

  def test_draw_header
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_header)

    # Should render header without error
  end

  def test_draw_habit_tracker_example
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_habit_tracker_example)

    # Should render habit tracker without error
  end

  def test_draw_mood_tracker_example
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_mood_tracker_example)

    # Should render mood tracker without error
  end

  def test_draw_footer_note
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_footer_note)

    # Should render footer without error
  end

  def test_draw_day_headers
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_day_headers, 10, 8, 31)

    # Should render day headers without error
  end

  def test_draw_day_headers_with_fewer_days
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_day_headers, 10, 8, 28)

    # Should skip days beyond count
  end

  def test_draw_habit_row
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_habit_row, "Exercise", 10, 31)

    # Should render habit row without error
  end

  def test_draw_weekly_mood_grid
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_weekly_mood_grid, 24)

    # Should render weekly grid without error
  end

  def test_draw_other_ideas
    page = BujoPdf::Pages::TrackerExample.new(@pdf, @context)
    page.send(:setup)
    page.send(:draw_other_ideas, 40)

    # Should render ideas list without error
  end
end

class TestTrackerExampleMixin < Minitest::Test
  class TestBuilder
    include BujoPdf::Pages::TrackerExample::Mixin

    attr_reader :pdf, :year, :date_config, :event_store, :total_pages

    def initialize
      @year = 2025
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @date_config = nil
      @event_store = nil
      @total_pages = 100
      @first_page_used = false
      DotGrid.create_stamp(@pdf, "page_dots")
    end
  end

  def test_mixin_provides_tracker_example_page_method
    builder = TestBuilder.new
    assert builder.respond_to?(:tracker_example_page), "Expected tracker_example_page method"
  end

  def test_tracker_example_page_generates_page
    builder = TestBuilder.new
    builder.tracker_example_page

    assert_equal 1, builder.pdf.page_count
  end
end

class TestTrackerExampleIntegration < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    DotGrid.create_stamp(@pdf, "page_dots")
  end

  def test_full_page_generation
    context = BujoPdf::RenderContext.new(
      page_key: :tracker_example,
      page_number: 1,
      year: 2025,
      total_weeks: 53
    )

    page = BujoPdf::Pages::TrackerExample.new(@pdf, context)
    page.generate

    # PDF should be valid and have content
    assert_equal 1, @pdf.page_count
    assert_kind_of Prawn::Document, @pdf
  end
end
