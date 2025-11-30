# frozen_string_literal: true

require_relative '../test_helper'

class TestPageSet < Minitest::Test
  def test_creates_with_name_and_label_pattern
    set = BujoPdf::PageSet.new(
      name: 'Index',
      label_pattern: 'Index %page of %total'
    )

    assert_equal 'Index', set.name
    assert_equal 'Index %page of %total', set.label_pattern
  end

  def test_add_returns_page_ref
    set = BujoPdf::PageSet.new(name: 'Index')
    ref = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)

    result = set.add(ref)

    assert_same ref, result
  end

  def test_finalize_assigns_set_context_to_pages
    set = BujoPdf::PageSet.new(
      name: 'Index',
      label_pattern: 'Index %page of %total'
    )
    ref = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)

    set.add(ref)
    set.finalize!

    assert_kind_of BujoPdf::PageSetContext::Context, ref.set_context
    assert_equal 1, ref.set_context.page
    assert_equal 1, ref.set_context.total
    assert_equal 'Index 1 of 1', ref.set_context.label
    assert_equal 'Index', ref.set_context.name
  end

  def test_legacy_count_assigns_context_immediately
    # Legacy mode: when count is provided, context is assigned on add
    set = BujoPdf::PageSet.new(name: 'Index', count: 2, label_pattern: 'Index %page of %total')
    ref = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)

    set.add(ref)

    assert_kind_of BujoPdf::PageSetContext::Context, ref.set_context
    assert_equal 1, ref.set_context.page
    assert_equal 2, ref.set_context.total
    assert_equal 'Index 1 of 2', ref.set_context.label
  end

  def test_finalize_increments_position
    set = BujoPdf::PageSet.new(name: 'Index', label_pattern: 'Index %page of %total')
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref2 = BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)

    set.add(ref1)
    set.add(ref2)
    set.finalize!

    assert_equal 1, ref1.set_context.page
    assert_equal 2, ref2.set_context.page
    assert_equal 'Index 1 of 2', ref1.set_context.label
    assert_equal 'Index 2 of 2', ref2.set_context.label
  end

  def test_each_iterates_over_pages
    set = BujoPdf::PageSet.new(name: 'Index')
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref2 = BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)
    set.add(ref1)
    set.add(ref2)

    collected = []
    set.each { |page| collected << page }

    assert_equal [ref1, ref2], collected
  end

  def test_is_enumerable
    set = BujoPdf::PageSet.new(name: 'Index')

    assert_kind_of Enumerable, set
  end

  def test_bracket_access
    set = BujoPdf::PageSet.new(name: 'Index')
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref2 = BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)
    set.add(ref1)
    set.add(ref2)

    assert_same ref1, set[0]
    assert_same ref2, set[1]
    assert_nil set[2]
  end

  def test_first_and_last
    set = BujoPdf::PageSet.new(name: 'Index')
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref2 = BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)
    set.add(ref1)
    set.add(ref2)

    assert_same ref1, set.first
    assert_same ref2, set.last
  end

  def test_size_returns_pages_added
    set = BujoPdf::PageSet.new(name: 'Index')

    assert_equal 0, set.size

    set.add(BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index))
    assert_equal 1, set.size

    set.add(BujoPdf::PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index))
    assert_equal 2, set.size
  end

  def test_outline_entry
    set = BujoPdf::PageSet.new(name: 'Index')
    ref1 = BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
    ref1.pdf_page_number = 5
    set.add(ref1)

    entry = set.outline_entry

    assert_equal 5, entry[:destination]
    assert_equal 'Index', entry[:title]
  end

  def test_outline_entry_nil_destination_when_empty
    set = BujoPdf::PageSet.new(name: 'Index')

    entry = set.outline_entry

    assert_nil entry[:destination]
    assert_equal 'Index', entry[:title]
  end

  def test_finalized_returns_true_after_finalize
    set = BujoPdf::PageSet.new(name: 'Index')

    refute set.finalized?

    set.finalize!

    assert set.finalized?
  end

  def test_add_raises_after_finalize
    set = BujoPdf::PageSet.new(name: 'Index')
    set.finalize!

    assert_raises RuntimeError do
      set.add(BujoPdf::PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index))
    end
  end

  def test_cycle_option
    set = BujoPdf::PageSet.new(name: 'Grids', cycle: true)

    assert set.cycle?
  end

  def test_destination_keys
    set = BujoPdf::PageSet.new(name: 'Grids')
    ref1 = BujoPdf::PageRef.new(dest_name: 'grid_showcase', title: 'Showcase', page_type: :grid)
    ref2 = BujoPdf::PageRef.new(dest_name: 'grid_dot', title: 'Dots', page_type: :grid)
    set.add(ref1)
    set.add(ref2)

    assert_equal %w[grid_showcase grid_dot], set.destination_keys
  end
end

class TestSetContext < Minitest::Test
  def test_first_true_for_page_1
    ctx = BujoPdf::PageSetContext::Context.new(page: 1, total: 3, label: 'Test', name: 'Test')

    assert ctx.first?
  end

  def test_first_false_for_other_pages
    ctx = BujoPdf::PageSetContext::Context.new(page: 2, total: 3, label: 'Test', name: 'Test')

    refute ctx.first?
  end

  def test_last_true_for_final_page
    ctx = BujoPdf::PageSetContext::Context.new(page: 3, total: 3, label: 'Test', name: 'Test')

    assert ctx.last?
  end

  def test_last_false_for_other_pages
    ctx = BujoPdf::PageSetContext::Context.new(page: 2, total: 3, label: 'Test', name: 'Test')

    refute ctx.last?
  end
end
