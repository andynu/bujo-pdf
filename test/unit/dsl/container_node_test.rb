#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl'

class TestContainerNode < Minitest::Test
  def test_default_direction_is_vertical
    container = BujoPdf::DSL::ContainerNode.new

    assert_equal :vertical, container.direction
  end

  def test_horizontal_direction
    container = BujoPdf::DSL::ContainerNode.new(direction: :horizontal)

    assert_equal :horizontal, container.direction
  end

  def test_gap_parameter
    container = BujoPdf::DSL::ContainerNode.new(gap: 1)

    assert_equal 1, container.gap
  end

  def test_vertical_layout_with_fixed_children
    container = BujoPdf::DSL::ContainerNode.new(direction: :vertical)
    child1 = BujoPdf::DSL::SectionNode.new(height: 10)
    child2 = BujoPdf::DSL::SectionNode.new(height: 5)

    container.add_child(child1)
    container.add_child(child2)

    container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # First child at top
    assert_equal 0, child1.computed_bounds[:row]
    assert_equal 10, child1.computed_bounds[:height]

    # Second child below first
    assert_equal 10, child2.computed_bounds[:row]
    assert_equal 5, child2.computed_bounds[:height]
  end

  def test_vertical_layout_with_flex_child
    container = BujoPdf::DSL::ContainerNode.new(direction: :vertical)
    fixed = BujoPdf::DSL::SectionNode.new(height: 10)
    flex = BujoPdf::DSL::SectionNode.new(flex: 1)

    container.add_child(fixed)
    container.add_child(flex)

    container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # Fixed child takes 10
    assert_equal 10, fixed.computed_bounds[:height]

    # Flex child takes remainder (55 - 10 = 45)
    assert_equal 10, flex.computed_bounds[:row]
    assert_equal 45, flex.computed_bounds[:height]
  end

  def test_vertical_layout_with_multiple_flex_children
    container = BujoPdf::DSL::ContainerNode.new(direction: :vertical)
    flex1 = BujoPdf::DSL::SectionNode.new(flex: 1)
    flex2 = BujoPdf::DSL::SectionNode.new(flex: 2)

    container.add_child(flex1)
    container.add_child(flex2)

    container.compute_bounds(col: 0, row: 0, width: 43, height: 54) # 54 divides nicely

    # flex1 gets 1/3 of 54 = 18
    assert_equal 18, flex1.computed_bounds[:height]

    # flex2 gets 2/3 of 54 = 36
    assert_equal 36, flex2.computed_bounds[:height]
  end

  def test_vertical_layout_with_gap
    container = BujoPdf::DSL::ContainerNode.new(direction: :vertical, gap: 1)
    child1 = BujoPdf::DSL::SectionNode.new(height: 10)
    child2 = BujoPdf::DSL::SectionNode.new(height: 10)

    container.add_child(child1)
    container.add_child(child2)

    container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # First child at top
    assert_equal 0, child1.computed_bounds[:row]

    # Second child starts after first + gap
    assert_equal 11, child2.computed_bounds[:row]
  end

  def test_horizontal_layout_with_fixed_children
    container = BujoPdf::DSL::ContainerNode.new(direction: :horizontal)
    child1 = BujoPdf::DSL::SectionNode.new(width: 10)
    child2 = BujoPdf::DSL::SectionNode.new(width: 5)

    container.add_child(child1)
    container.add_child(child2)

    container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # First child at left
    assert_equal 0, child1.computed_bounds[:col]
    assert_equal 10, child1.computed_bounds[:width]

    # Second child to the right of first
    assert_equal 10, child2.computed_bounds[:col]
    assert_equal 5, child2.computed_bounds[:width]
  end

  def test_horizontal_layout_with_flex_child
    container = BujoPdf::DSL::ContainerNode.new(direction: :horizontal)
    fixed = BujoPdf::DSL::SectionNode.new(width: 3)
    flex = BujoPdf::DSL::SectionNode.new(flex: 1)

    container.add_child(fixed)
    container.add_child(flex)

    container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # Fixed child takes 3
    assert_equal 3, fixed.computed_bounds[:width]

    # Flex child takes remainder (43 - 3 = 40)
    assert_equal 3, flex.computed_bounds[:col]
    assert_equal 40, flex.computed_bounds[:width]
  end

  def test_horizontal_layout_with_gap
    container = BujoPdf::DSL::ContainerNode.new(direction: :horizontal, gap: 1)
    child1 = BujoPdf::DSL::SectionNode.new(width: 10)
    child2 = BujoPdf::DSL::SectionNode.new(width: 10)

    container.add_child(child1)
    container.add_child(child2)

    container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # First child at left
    assert_equal 0, child1.computed_bounds[:col]

    # Second child starts after first + gap
    assert_equal 11, child2.computed_bounds[:col]
  end

  def test_children_get_full_perpendicular_dimension
    # Vertical container: children get full width
    v_container = BujoPdf::DSL::ContainerNode.new(direction: :vertical)
    v_child = BujoPdf::DSL::SectionNode.new(height: 10)
    v_container.add_child(v_child)
    v_container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    assert_equal 43, v_child.computed_bounds[:width]

    # Horizontal container: children get full height
    h_container = BujoPdf::DSL::ContainerNode.new(direction: :horizontal)
    h_child = BujoPdf::DSL::SectionNode.new(width: 10)
    h_container.add_child(h_child)
    h_container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    assert_equal 55, h_child.computed_bounds[:height]
  end

  def test_nested_containers
    outer = BujoPdf::DSL::ContainerNode.new(direction: :horizontal)
    sidebar = BujoPdf::DSL::SectionNode.new(name: :sidebar, width: 3)
    content = BujoPdf::DSL::ContainerNode.new(name: :content, direction: :vertical, flex: 1)

    header = BujoPdf::DSL::SectionNode.new(name: :header, height: 2)
    main = BujoPdf::DSL::SectionNode.new(name: :main, flex: 1)

    outer.add_child(sidebar)
    outer.add_child(content)
    content.add_child(header)
    content.add_child(main)

    outer.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # Sidebar
    assert_equal 0, sidebar.computed_bounds[:col]
    assert_equal 3, sidebar.computed_bounds[:width]
    assert_equal 55, sidebar.computed_bounds[:height]

    # Content area
    assert_equal 3, content.computed_bounds[:col]
    assert_equal 40, content.computed_bounds[:width]

    # Header within content
    assert_equal 3, header.computed_bounds[:col]
    assert_equal 0, header.computed_bounds[:row]
    assert_equal 40, header.computed_bounds[:width]
    assert_equal 2, header.computed_bounds[:height]

    # Main within content
    assert_equal 3, main.computed_bounds[:col]
    assert_equal 2, main.computed_bounds[:row]
    assert_equal 40, main.computed_bounds[:width]
    assert_equal 53, main.computed_bounds[:height]  # 55 - 2
  end

  def test_quantization_gives_remainder_to_last_flex
    container = BujoPdf::DSL::ContainerNode.new(direction: :vertical)
    flex1 = BujoPdf::DSL::SectionNode.new(flex: 1)
    flex2 = BujoPdf::DSL::SectionNode.new(flex: 1)

    container.add_child(flex1)
    container.add_child(flex2)

    # 55 doesn't divide evenly by 2
    container.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # First flex gets floor(27.5) = 27
    assert_equal 27, flex1.computed_bounds[:height]

    # Last flex gets remainder = 55 - 27 = 28
    assert_equal 28, flex2.computed_bounds[:height]
  end
end
