#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl/sidebar_definition'

class TestSidebarDefinition < Minitest::Test
  def test_requires_name
    assert_raises(ArgumentError) do
      BujoPdf::PdfDSL::SidebarDefinition.new(name: nil, position: :left)
    end
  end

  def test_requires_valid_position
    assert_raises(ArgumentError) do
      BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :invalid)
    end
  end

  def test_rejects_top_position
    assert_raises(ArgumentError) do
      BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :top)
    end
  end

  def test_rejects_bottom_position
    assert_raises(ArgumentError) do
      BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :bottom)
    end
  end

  def test_accepts_left_position
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :left)
    assert_equal :left, definition.position
  end

  def test_accepts_right_position
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :right)
    assert_equal :right, definition.position
  end

  def test_stores_name
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(name: :my_sidebar, position: :left)
    assert_equal :my_sidebar, definition.name
  end

  def test_stores_width
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :left, width: 5)
    assert_equal 5, definition.width
  end

  def test_default_width_is_3
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :left)
    assert_equal 3, definition.width
    assert_equal BujoPdf::PdfDSL::SidebarDefinition::DEFAULT_WIDTH, definition.width
  end

  def test_stores_body_block
    block = proc { |_ctx| "rendered" }
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :left, &block)

    assert definition.body?
    assert_equal "rendered", definition.body_block.call(nil)
  end

  def test_body_false_without_block
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :left)
    refute definition.body?
  end

  def test_left_predicate
    left = BujoPdf::PdfDSL::SidebarDefinition.new(name: :test, position: :left)
    right = BujoPdf::PdfDSL::SidebarDefinition.new(name: :test2, position: :right)

    assert left.left?
    refute left.right?
    refute right.left?
    assert right.right?
  end

  def test_to_h
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(
      name: :my_sidebar,
      position: :left,
      width: 4
    ) { |_| }

    hash = definition.to_h
    assert_equal :my_sidebar, hash[:name]
    assert_equal :left, hash[:position]
    assert_equal 4, hash[:width]
    assert hash[:has_body]
  end

  def test_to_h_without_body
    definition = BujoPdf::PdfDSL::SidebarDefinition.new(
      name: :empty,
      position: :right
    )

    hash = definition.to_h
    refute hash[:has_body]
  end
end
