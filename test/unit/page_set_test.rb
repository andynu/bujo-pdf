# frozen_string_literal: true

require_relative '../test_helper'

class TestPageSet < Minitest::Test
  def test_creates_with_name_count_and_label_pattern
    set = BujoPdf::PageSet.new(
      name: 'Index',
      count: 2,
      label_pattern: 'Index %page of %total'
    )

    assert_equal 'Index', set.name
    assert_equal 2, set.count
    assert_equal 'Index %page of %total', set.label_pattern
  end

  def test_add_returns_page_ref
    set = BujoPdf::PageSet.new(name: 'Index', count: 2)
    ref = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)

    result = set.add(ref)

    assert_same ref, result
  end

  def test_add_assigns_set_context_to_page
    set = BujoPdf::PageSet.new(
      name: 'Index',
      count: 2,
      label_pattern: 'Index %page of %total'
    )
    ref = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)

    set.add(ref)

    assert_kind_of BujoPdf::PageSet::SetContext, ref.set_context
    assert_equal 1, ref.set_context.page
    assert_equal 2, ref.set_context.total
    assert_equal 'Index 1 of 2', ref.set_context.label
    assert_equal 'Index', ref.set_context.set_name
  end

  def test_add_increments_position
    set = BujoPdf::PageSet.new(name: 'Index', count: 2, label_pattern: 'Index %page of %total')
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref2 = BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)

    set.add(ref1)
    set.add(ref2)

    assert_equal 1, ref1.set_context.page
    assert_equal 2, ref2.set_context.page
    assert_equal 'Index 1 of 2', ref1.set_context.label
    assert_equal 'Index 2 of 2', ref2.set_context.label
  end

  def test_each_iterates_over_pages
    set = BujoPdf::PageSet.new(name: 'Index', count: 2)
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref2 = BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)
    set.add(ref1)
    set.add(ref2)

    collected = []
    set.each { |page| collected << page }

    assert_equal [ref1, ref2], collected
  end

  def test_is_enumerable
    set = BujoPdf::PageSet.new(name: 'Index', count: 2)

    assert_kind_of Enumerable, set
  end

  def test_bracket_access
    set = BujoPdf::PageSet.new(name: 'Index', count: 2)
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref2 = BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)
    set.add(ref1)
    set.add(ref2)

    assert_same ref1, set[0]
    assert_same ref2, set[1]
    assert_nil set[2]
  end

  def test_first_and_last
    set = BujoPdf::PageSet.new(name: 'Index', count: 2)
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref2 = BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)
    set.add(ref1)
    set.add(ref2)

    assert_same ref1, set.first
    assert_same ref2, set.last
  end

  def test_size_returns_pages_added
    set = BujoPdf::PageSet.new(name: 'Index', count: 2)

    assert_equal 0, set.size

    set.add(BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index))
    assert_equal 1, set.size

    set.add(BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index))
    assert_equal 2, set.size
  end

  def test_outline_entry
    set = BujoPdf::PageSet.new(name: 'Index', count: 2)
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref1.pdf_page_number = 5
    set.add(ref1)

    entry = set.outline_entry

    assert_equal 5, entry[:destination]
    assert_equal 'Index', entry[:title]
  end

  def test_outline_entry_nil_destination_when_empty
    set = BujoPdf::PageSet.new(name: 'Index', count: 2)

    entry = set.outline_entry

    assert_nil entry[:destination]
    assert_equal 'Index', entry[:title]
  end
end

class TestSetContext < Minitest::Test
  def test_first_true_for_page_1
    ctx = BujoPdf::PageSet::SetContext.new(page: 1, total: 3, label: 'Test', set_name: 'Test')

    assert ctx.first?
  end

  def test_first_false_for_other_pages
    ctx = BujoPdf::PageSet::SetContext.new(page: 2, total: 3, label: 'Test', set_name: 'Test')

    refute ctx.first?
  end

  def test_last_true_for_final_page
    ctx = BujoPdf::PageSet::SetContext.new(page: 3, total: 3, label: 'Test', set_name: 'Test')

    assert ctx.last?
  end

  def test_last_false_for_other_pages
    ctx = BujoPdf::PageSet::SetContext.new(page: 2, total: 3, label: 'Test', set_name: 'Test')

    refute ctx.last?
  end
end
