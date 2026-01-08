# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/pdf_dsl'

# Tests for automatic outline generation feature.
#
# The outline system supports three modes:
# - :manual (default) - Outline entries only added when explicitly specified
# - :auto - Automatically generate outline entries from page registry titles
# - :none - No outline entries are generated
#
# In :auto mode, pages can:
# - Let the system auto-generate titles (outline: nil, treated as outline: true)
# - Override with custom title (outline: "Custom Title")
# - Suppress entry entirely (outline: false)
class TestAutoOutline < Minitest::Test
  def setup
    @context = BujoPdf::PdfDSL::DeclarationContext.new
  end

  # ============================================
  # outline_mode :auto - Standard Pages
  # ============================================

  def test_auto_mode_generates_entries_for_pages_with_registered_titles
    @context.outline_mode(:auto)
    @context.page(:seasonal_calendar, year: 2025)

    assert_equal 1, @context.outline_entries.length
    entry = @context.outline_entries.first
    assert entry.title, 'Entry should have a title'
    assert_equal :seasonal_calendar, entry.dest
  end

  def test_auto_mode_outline_false_suppresses_auto_generation
    @context.outline_mode(:auto)

    # Even with auto mode, explicit false suppresses the outline entry
    @context.page(:seasonal_calendar, year: 2025, outline: false)

    assert_equal 0, @context.outline_entries.length, 'outline: false should suppress entry in auto mode'
  end

  def test_auto_mode_outline_string_overrides_auto_generated_title
    @context.outline_mode(:auto)

    @context.page(:seasonal_calendar, year: 2025, outline: 'Custom Calendar Title')

    assert_equal 1, @context.outline_entries.length
    assert_equal 'Custom Calendar Title', @context.outline_entries.first.title
  end

  # ============================================
  # outline_mode :auto - Inline Pages
  # ============================================

  def test_auto_mode_generates_entries_for_inline_pages_from_id
    @context.outline_mode(:auto)

    @context.page(id: :my_custom_notes) do
      layout :full_page
      body { h1(2, 2, 'Notes') }
    end

    assert_equal 1, @context.outline_entries.length
    # Title should be derived from id: "My Custom Notes"
    assert_equal 'My Custom Notes', @context.outline_entries.first.title
  end

  def test_auto_mode_inline_page_outline_false_suppresses
    @context.outline_mode(:auto)

    @context.page(id: :hidden_page, outline: false) do
      layout :full_page
      body { h1(2, 2, 'Hidden') }
    end

    assert_equal 0, @context.outline_entries.length, 'outline: false should suppress inline page entry'
  end

  def test_auto_mode_inline_page_outline_string_overrides
    @context.outline_mode(:auto)

    @context.page(id: :notes, outline: 'Project Notes') do
      layout :full_page
      body { h1(2, 2, 'Notes') }
    end

    assert_equal 1, @context.outline_entries.length
    assert_equal 'Project Notes', @context.outline_entries.first.title
  end

  # ============================================
  # outline_mode :manual (default)
  # ============================================

  def test_manual_mode_requires_explicit_outline_param
    # Default mode is :manual
    assert_equal :manual, @context.current_outline_mode

    @context.page(:seasonal_calendar, year: 2025)
    assert_equal 0, @context.outline_entries.length, 'No entry without explicit outline param'

    @context.page(:seasonal_calendar, year: 2025, outline: true)
    assert_equal 1, @context.outline_entries.length, 'Entry added with outline: true'
  end

  def test_manual_mode_outline_string_creates_entry
    @context.page(:seasonal_calendar, year: 2025, outline: 'Seasonal View')

    assert_equal 1, @context.outline_entries.length
    assert_equal 'Seasonal View', @context.outline_entries.first.title
  end

  def test_manual_mode_outline_false_creates_no_entry
    @context.page(:seasonal_calendar, year: 2025, outline: false)

    assert_equal 0, @context.outline_entries.length
  end

  # ============================================
  # outline_mode :none
  # ============================================

  def test_none_mode_generates_no_outline_entries_at_all
    @context.outline_mode(:none)

    # Standard page with explicit outline
    @context.page(:seasonal_calendar, year: 2025, outline: true)
    assert_equal 0, @context.outline_entries.length

    # Standard page with string outline
    @context.page(:seasonal_calendar, year: 2025, outline: 'Should Not Appear')
    assert_equal 0, @context.outline_entries.length

    # Inline page with outline
    @context.page(id: :notes, outline: 'Notes') do
      layout :full_page
      body { h1(2, 2, 'Notes') }
    end
    assert_equal 0, @context.outline_entries.length
  end

  # ============================================
  # Mixed scenarios
  # ============================================

  def test_auto_mode_with_multiple_pages_selective_suppression
    @context.outline_mode(:auto)

    @context.page(:seasonal_calendar, year: 2025)                   # Auto entry
    @context.page(:year_events, year: 2025, outline: false)         # Suppressed
    @context.page(:year_highlights, year: 2025, outline: 'Highlights') # Override

    assert_equal 2, @context.outline_entries.length
    titles = @context.outline_entries.map(&:title)
    refute_includes titles, nil, 'Should not have nil titles'
    assert_includes titles, 'Highlights'
  end

  def test_inline_page_without_id_in_auto_mode_has_no_entry
    @context.outline_mode(:auto)

    # Inline page with no id cannot have an outline entry because
    # there's no destination to navigate to
    @context.page do
      layout :full_page
      body { h1(2, 2, 'Anonymous') }
    end

    # No entry because there's no destination (id is nil)
    assert_equal 0, @context.outline_entries.length
  end
end
