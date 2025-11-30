# frozen_string_literal: true

require_relative '../test_helper'

class TestPageRef < Minitest::Test
  def test_creates_with_required_attributes
    ref = BujoPdf::PageRef.new(
      dest_name: 'seasonal',
      title: 'Seasonal Calendar',
      page_type: :seasonal
    )

    assert_equal 'seasonal', ref.dest_name
    assert_equal 'Seasonal Calendar', ref.title
    assert_equal :seasonal, ref.page_type
    assert_equal({}, ref.metadata)
  end

  def test_accepts_metadata
    ref = BujoPdf::PageRef.new(
      dest_name: 'week_5',
      title: 'Week 5',
      page_type: :weekly,
      metadata: { week_num: 5, month: 'February' }
    )

    assert_equal 5, ref.metadata[:week_num]
    assert_equal 'February', ref.metadata[:month]
  end

  def test_pdf_page_number_initially_nil
    ref = BujoPdf::PageRef.new(
      dest_name: 'test',
      title: 'Test',
      page_type: :test
    )

    assert_nil ref.pdf_page_number
  end

  def test_pdf_page_number_assignable
    ref = BujoPdf::PageRef.new(
      dest_name: 'test',
      title: 'Test',
      page_type: :test
    )

    ref.pdf_page_number = 42
    assert_equal 42, ref.pdf_page_number
  end

  def test_set_context_initially_nil
    ref = BujoPdf::PageRef.new(
      dest_name: 'test',
      title: 'Test',
      page_type: :test
    )

    assert_nil ref.set_context
  end

  def test_in_set_false_without_context
    ref = BujoPdf::PageRef.new(
      dest_name: 'test',
      title: 'Test',
      page_type: :test
    )

    refute ref.in_set?
  end

  def test_in_set_true_with_context
    ref = BujoPdf::PageRef.new(
      dest_name: 'test',
      title: 'Test',
      page_type: :test
    )

    ref.set_context = BujoPdf::PageSet::SetContext.new(
      page: 1,
      total: 2,
      label: 'Test 1 of 2',
      set_name: 'Test Set'
    )

    assert ref.in_set?
  end

  def test_outline_title_returns_title_when_not_in_set
    ref = BujoPdf::PageRef.new(
      dest_name: 'test',
      title: 'My Title',
      page_type: :test
    )

    assert_equal 'My Title', ref.outline_title
  end

  def test_outline_title_returns_label_when_in_set
    ref = BujoPdf::PageRef.new(
      dest_name: 'test',
      title: 'My Title',
      page_type: :test
    )

    ref.set_context = BujoPdf::PageSet::SetContext.new(
      page: 1,
      total: 2,
      label: 'Index 1 of 2',
      set_name: 'Index'
    )

    assert_equal 'Index 1 of 2', ref.outline_title
  end

  def test_valid_destination_always_true
    ref = BujoPdf::PageRef.new(
      dest_name: 'test',
      title: 'Test',
      page_type: :test
    )

    assert ref.valid_destination?
  end
end
