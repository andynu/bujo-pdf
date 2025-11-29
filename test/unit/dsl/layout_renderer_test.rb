#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl'

class TestLayoutRenderer < Minitest::Test
  include TestHelpers

  DOT_SPACING = 14.17

  def setup
    @pdf = mock_pdf
  end

  def test_render_custom_node
    custom_called = false
    custom_bounds = nil

    builder = BujoPdf::DSL::LayoutBuilder.new
    builder.custom(name: :test, width: 10, height: 5) do |pdf, bounds|
      custom_called = true
      custom_bounds = bounds
    end

    root = builder.root
    root.compute_bounds(col: 5, row: 10, width: 43, height: 55)

    renderer = BujoPdf::DSL::LayoutRenderer.new(@pdf)
    renderer.render(root)

    assert custom_called, "Custom render block should have been called"
    refute_nil custom_bounds
    assert custom_bounds[:width] > 0
    assert custom_bounds[:height] > 0
  end

  def test_render_spacer_does_nothing
    builder = BujoPdf::DSL::LayoutBuilder.new
    builder.spacer(height: 5)

    root = builder.root
    root.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # Clear any setup calls
    @pdf = mock_pdf

    renderer = BujoPdf::DSL::LayoutRenderer.new(@pdf)
    renderer.render(root)

    # Spacers should not generate any PDF calls
    # (excluding method_missing calls to the root node)
    content_calls = @pdf.calls.select { |c| [:text_box, :stroke_line, :fill_circle].include?(c[0]) }
    assert_empty content_calls
  end

  def test_render_nested_structure
    builder = BujoPdf::DSL::LayoutBuilder.new
    builder.instance_eval do
      section(name: :outer, height: 20) do
        section(name: :inner, flex: 1) do
          text "Nested", style: :body
        end
      end
    end

    root = builder.root
    root.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    # Verify the structure was built correctly
    outer = root.find(:outer)
    refute_nil outer
    inner = root.find(:inner)
    refute_nil inner
  end

  def test_grid_to_points_conversion
    renderer = BujoPdf::DSL::LayoutRenderer.new(@pdf)

    # Use send to test private method
    bounds = { col: 0, row: 0, width: 1, height: 1 }
    pt = renderer.send(:grid_to_points, bounds)

    # 1 grid box = DOT_SPACING points
    assert_in_delta DOT_SPACING, pt[:width], 0.01
    assert_in_delta DOT_SPACING, pt[:height], 0.01
  end

  def test_custom_node_receives_pdf_and_bounds
    received_pdf = nil
    received_bounds = nil

    builder = BujoPdf::DSL::LayoutBuilder.new
    builder.custom(name: :test, width: 10, height: 10) do |pdf, bounds|
      received_pdf = pdf
      received_bounds = bounds
    end

    root = builder.root
    root.compute_bounds(col: 0, row: 0, width: 43, height: 55)

    renderer = BujoPdf::DSL::LayoutRenderer.new(@pdf)
    renderer.render(root)

    assert_same @pdf, received_pdf
    assert_kind_of Hash, received_bounds
    assert received_bounds.key?(:x)
    assert received_bounds.key?(:y)
    assert received_bounds.key?(:width)
    assert received_bounds.key?(:height)
  end
end

class TestCustomNode < Minitest::Test
  def test_custom_node_stores_render_block
    block_called = false
    node = BujoPdf::DSL::CustomNode.new(name: :test) do |_pdf, _bounds|
      block_called = true
    end

    node.render_block.call(nil, nil)
    assert block_called
  end

  def test_custom_node_element_type
    node = BujoPdf::DSL::CustomNode.new(name: :test)
    assert_equal :custom, node.element_type
  end

  def test_custom_node_render_params
    node = BujoPdf::DSL::CustomNode.new(name: :my_custom, width: 10)
    node.compute_bounds(col: 0, row: 0, width: 10, height: 10)

    params = node.render_params

    assert_equal :custom, params[:type]
    assert_equal :my_custom, params[:name]
    refute_nil params[:bounds]
  end
end
