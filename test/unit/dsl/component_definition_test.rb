# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl'

class TestComponentDefinition < Minitest::Test
  def setup
    # Clear registry before each test
    BujoPdf::DSL::ComponentRegistry.clear!
  end

  def teardown
    # Clean up registry after tests
    BujoPdf::DSL::ComponentRegistry.clear!
  end

  # ComponentDefinition tests

  def test_definition_stores_name_and_params
    definition = BujoPdf::DSL::ComponentDefinition.new(:test_component, [:title, :content]) {}

    assert_equal :test_component, definition.name
    assert_equal [:title, :content], definition.params
    refute_nil definition.block
  end

  def test_definition_defaults_to_empty_params
    definition = BujoPdf::DSL::ComponentDefinition.new(:simple) {}

    assert_equal [], definition.params
  end

  def test_definition_build_creates_wrapper_node
    definition = BujoPdf::DSL::ComponentDefinition.new(:card) do
      text "Static content"
    end

    builder = BujoPdf::DSL::LayoutBuilder.new
    result = definition.build(builder)

    assert_instance_of BujoPdf::DSL::SectionNode, result
    assert_equal :card, result.name
  end

  def test_definition_build_passes_params_to_block
    received_title = nil
    definition = BujoPdf::DSL::ComponentDefinition.new(:header, [:title]) do |title:|
      received_title = title
      text title, style: :title
    end

    builder = BujoPdf::DSL::LayoutBuilder.new
    definition.build(builder, title: "Hello World")

    assert_equal "Hello World", received_title
  end

  def test_definition_build_raises_on_missing_params
    definition = BujoPdf::DSL::ComponentDefinition.new(:card, [:title, :content]) do |title:, content:|
      text title
      text content
    end

    builder = BujoPdf::DSL::LayoutBuilder.new

    error = assert_raises(ArgumentError) do
      definition.build(builder, title: "Only Title")
    end
    assert_match(/Missing required parameters.*content/, error.message)
  end

  def test_definition_build_allows_extra_params
    definition = BujoPdf::DSL::ComponentDefinition.new(:simple, [:name]) do |name:, **|
      text name
    end

    builder = BujoPdf::DSL::LayoutBuilder.new
    # Should not raise - extra params are ignored
    definition.build(builder, name: "Test", extra: "ignored")
  end

  def test_definition_build_adds_children_to_wrapper
    definition = BujoPdf::DSL::ComponentDefinition.new(:box) do
      header height: 2 do
        text "Header"
      end
      field name: :content, flex: 1
    end

    builder = BujoPdf::DSL::LayoutBuilder.new
    result = definition.build(builder)

    assert_equal 2, result.children.length
    assert_instance_of BujoPdf::DSL::HeaderNode, result.children[0]
    assert_instance_of BujoPdf::DSL::FieldNode, result.children[1]
  end

  # ComponentRegistry tests

  def test_registry_register_and_get
    BujoPdf::DSL::ComponentRegistry.register(:test_comp) do
      text "Test"
    end

    definition = BujoPdf::DSL::ComponentRegistry.get(:test_comp)

    refute_nil definition
    assert_instance_of BujoPdf::DSL::ComponentDefinition, definition
    assert_equal :test_comp, definition.name
  end

  def test_registry_registered_check
    refute BujoPdf::DSL::ComponentRegistry.registered?(:unregistered)

    BujoPdf::DSL::ComponentRegistry.register(:registered) {}

    assert BujoPdf::DSL::ComponentRegistry.registered?(:registered)
    refute BujoPdf::DSL::ComponentRegistry.registered?(:unregistered)
  end

  def test_registry_names_returns_all_registered
    BujoPdf::DSL::ComponentRegistry.register(:comp_a) {}
    BujoPdf::DSL::ComponentRegistry.register(:comp_b) {}
    BujoPdf::DSL::ComponentRegistry.register(:comp_c) {}

    names = BujoPdf::DSL::ComponentRegistry.names

    assert_includes names, :comp_a
    assert_includes names, :comp_b
    assert_includes names, :comp_c
    assert_equal 3, names.length
  end

  def test_registry_clear_removes_all
    BujoPdf::DSL::ComponentRegistry.register(:to_clear) {}
    assert BujoPdf::DSL::ComponentRegistry.registered?(:to_clear)

    BujoPdf::DSL::ComponentRegistry.clear!

    refute BujoPdf::DSL::ComponentRegistry.registered?(:to_clear)
    assert_empty BujoPdf::DSL::ComponentRegistry.names
  end

  def test_registry_define_is_alias_for_register
    BujoPdf::DSL::ComponentRegistry.define(:defined_comp, params: [:x]) do |x:|
      text x.to_s
    end

    definition = BujoPdf::DSL::ComponentRegistry.get(:defined_comp)

    refute_nil definition
    assert_equal [:x], definition.params
  end

  def test_registry_replaces_existing_definition
    BujoPdf::DSL::ComponentRegistry.register(:replaceable) do
      text "Original"
    end

    BujoPdf::DSL::ComponentRegistry.register(:replaceable) do
      text "Replacement"
    end

    assert_equal 1, BujoPdf::DSL::ComponentRegistry.names.count(:replaceable)
  end

  # LayoutBuilder#component integration tests

  def test_builder_component_instantiates_registered
    BujoPdf::DSL::ComponentRegistry.register(:simple_box) do
      field flex: 1
    end

    layout = BujoPdf::DSL.build_layout do
      component :simple_box
    end

    # Root should have the component wrapper
    assert_equal 1, layout.children.length
    wrapper = layout.children.first
    assert_equal :simple_box, wrapper.name
  end

  def test_builder_component_passes_params
    received_value = nil
    BujoPdf::DSL::ComponentRegistry.register(:param_test, [:value]) do |value:|
      received_value = value
      text value.to_s
    end

    BujoPdf::DSL.build_layout do
      component :param_test, value: 42
    end

    assert_equal 42, received_value
  end

  def test_builder_component_raises_on_unknown
    error = assert_raises(ArgumentError) do
      BujoPdf::DSL.build_layout do
        component :nonexistent
      end
    end

    assert_match(/Unknown component: nonexistent/, error.message)
  end

  def test_builder_component_nests_inside_sections
    BujoPdf::DSL::ComponentRegistry.register(:inner) do
      text "Inner content"
    end

    layout = BujoPdf::DSL.build_layout do
      section name: :outer do
        component :inner
      end
    end

    outer = layout.find(:outer)
    refute_nil outer
    assert_equal 1, outer.children.length
    assert_equal :inner, outer.children.first.name
  end

  def test_builder_component_can_use_other_components
    BujoPdf::DSL::ComponentRegistry.register(:leaf) do
      text "Leaf"
    end

    BujoPdf::DSL::ComponentRegistry.register(:container) do
      header height: 1 do
        text "Container Header"
      end
      component :leaf
    end

    layout = BujoPdf::DSL.build_layout do
      component :container
    end

    container = layout.children.first
    assert_equal :container, container.name
    assert_equal 2, container.children.length
    assert_equal :leaf, container.children[1].name
  end

  def test_builder_multiple_components_in_layout
    BujoPdf::DSL::ComponentRegistry.register(:box_a) do
      text "A"
    end

    BujoPdf::DSL::ComponentRegistry.register(:box_b) do
      text "B"
    end

    layout = BujoPdf::DSL.build_layout do
      component :box_a
      spacer height: 1
      component :box_b
    end

    assert_equal 3, layout.children.length
    assert_equal :box_a, layout.children[0].name
    assert_instance_of BujoPdf::DSL::SpacerNode, layout.children[1]
    assert_equal :box_b, layout.children[2].name
  end

  # Realistic component test

  def test_day_header_component_example
    # Register a realistic day_header component
    BujoPdf::DSL::ComponentRegistry.register(:day_header, [:day_name, :day_number]) do |day_name:, day_number:|
      header height: 2 do
        text day_name, style: :day_name
        text day_number.to_s, style: :day_number
      end
    end

    layout = BujoPdf::DSL.build_layout do
      columns count: 7 do |day_idx|
        day_names = %w[Mon Tue Wed Thu Fri Sat Sun]
        component :day_header, day_name: day_names[day_idx], day_number: day_idx + 1
      end
    end

    columns_node = layout.children.first
    assert_equal 7, columns_node.children.length

    # Check first day
    first_day_section = columns_node.children[0]
    day_header = first_day_section.children.first
    assert_equal :day_header, day_header.name

    # Check the header inside the component
    header = day_header.children.first
    assert_instance_of BujoPdf::DSL::HeaderNode, header
    assert_equal 2, header.constraints[:height]
  end
end
