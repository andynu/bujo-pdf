#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl'

class TestLayoutNode < Minitest::Test
  def test_basic_node_creation
    node = BujoPdf::DSL::LayoutNode.new(name: :test)

    assert_equal :test, node.name
    assert_empty node.children
    assert_nil node.computed_bounds
  end

  def test_constraints_stored
    node = BujoPdf::DSL::LayoutNode.new(width: 10, height: 5, flex: 1)

    assert_equal 10, node.constraints[:width]
    assert_equal 5, node.constraints[:height]
    assert_equal 1, node.constraints[:flex]
  end

  def test_add_child
    parent = BujoPdf::DSL::LayoutNode.new(name: :parent)
    child = BujoPdf::DSL::LayoutNode.new(name: :child)

    result = parent.add_child(child)

    assert_equal child, result
    assert_equal 1, parent.children.length
    assert_equal child, parent.children.first
  end

  def test_fixed_width_check
    fixed = BujoPdf::DSL::LayoutNode.new(width: 10)
    flex = BujoPdf::DSL::LayoutNode.new(flex: 1)

    assert fixed.fixed_width?
    refute flex.fixed_width?
  end

  def test_fixed_height_check
    fixed = BujoPdf::DSL::LayoutNode.new(height: 10)
    flex = BujoPdf::DSL::LayoutNode.new(flex: 1)

    assert fixed.fixed_height?
    refute flex.fixed_height?
  end

  def test_flex_check
    fixed = BujoPdf::DSL::LayoutNode.new(width: 10)
    flex = BujoPdf::DSL::LayoutNode.new(flex: 1)

    refute fixed.flex?
    assert flex.flex?
  end

  def test_flex_weight
    node = BujoPdf::DSL::LayoutNode.new(flex: 2)
    assert_equal 2, node.flex_weight

    fixed = BujoPdf::DSL::LayoutNode.new(width: 10)
    assert_equal 0, fixed.flex_weight
  end

  def test_compute_bounds_with_full_space
    node = BujoPdf::DSL::LayoutNode.new

    bounds = node.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    assert_equal 0, bounds[:col]
    assert_equal 0, bounds[:row]
    assert_equal 43, bounds[:width]
    assert_equal 55, bounds[:height]
  end

  def test_compute_bounds_with_fixed_dimensions
    node = BujoPdf::DSL::LayoutNode.new(width: 10, height: 5)

    bounds = node.compute_bounds(col: 5, row: 10, width: 43, height: 55)

    assert_equal 5, bounds[:col]
    assert_equal 10, bounds[:row]
    assert_equal 10, bounds[:width]  # Fixed, not 43
    assert_equal 5, bounds[:height]  # Fixed, not 55
  end

  def test_compute_bounds_with_min_max
    node = BujoPdf::DSL::LayoutNode.new(min_width: 5, max_width: 15)

    # Available width smaller than min
    bounds = node.compute_bounds(col: 0, row: 0, width: 3, height: 55)
    assert_equal 5, bounds[:width]

    # Available width larger than max
    bounds = node.compute_bounds(col: 0, row: 0, width: 20, height: 55)
    assert_equal 15, bounds[:width]

    # Available width within range
    bounds = node.compute_bounds(col: 0, row: 0, width: 10, height: 55)
    assert_equal 10, bounds[:width]
  end

  def test_find_by_name
    root = BujoPdf::DSL::LayoutNode.new(name: :root)
    child1 = BujoPdf::DSL::LayoutNode.new(name: :child1)
    child2 = BujoPdf::DSL::LayoutNode.new(name: :child2)
    grandchild = BujoPdf::DSL::LayoutNode.new(name: :grandchild)

    root.add_child(child1)
    root.add_child(child2)
    child1.add_child(grandchild)

    assert_equal root, root.find(:root)
    assert_equal child1, root.find(:child1)
    assert_equal grandchild, root.find(:grandchild)
    assert_nil root.find(:nonexistent)
  end

  def test_each_iterates_over_all_nodes
    root = BujoPdf::DSL::LayoutNode.new(name: :root)
    child1 = BujoPdf::DSL::LayoutNode.new(name: :child1)
    child2 = BujoPdf::DSL::LayoutNode.new(name: :child2)

    root.add_child(child1)
    root.add_child(child2)

    names = root.each.map(&:name)

    assert_includes names, :root
    assert_includes names, :child1
    assert_includes names, :child2
    assert_equal 3, names.length
  end
end
