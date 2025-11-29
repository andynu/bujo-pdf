#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl'
require 'bujo_pdf/dsl/style_resolver'

class TestStyleResolver < Minitest::Test
  def setup
    # Clear any registered themes before each test
    BujoPdf::DSL::ThemeRegistry.clear!
  end

  # Theme tests

  def test_theme_build_with_block
    theme = BujoPdf::DSL::Theme.build(:test) do
      color :background, 'FFFFFF'
      style :title, font_size: 14, font_weight: :bold
    end

    assert_equal :test, theme.name
    assert_equal 'FFFFFF', theme.color(:background)
    assert_equal({ font_size: 14, font_weight: :bold }, theme.style(:title))
  end

  def test_theme_build_without_block
    theme = BujoPdf::DSL::Theme.build(:empty)

    assert_equal :empty, theme.name
    assert_nil theme.color(:background)
    assert_nil theme.style(:title)
  end

  def test_theme_set_and_get_color
    theme = BujoPdf::DSL::Theme.new(:test)
    theme.set_color(:primary, '4A90D9')

    assert_equal '4A90D9', theme.color(:primary)
    assert theme.color?(:primary)
    refute theme.color?(:secondary)
  end

  def test_theme_colors_returns_copy
    theme = BujoPdf::DSL::Theme.new(:test)
    theme.set_color(:a, '111111')

    colors = theme.colors
    colors[:a] = 'changed'

    assert_equal '111111', theme.color(:a)
  end

  def test_theme_set_and_get_style
    theme = BujoPdf::DSL::Theme.new(:test)
    theme.set_style(:heading, { font_size: 16, color: '333333' })

    style = theme.style(:heading)
    assert_equal 16, style[:font_size]
    assert_equal '333333', style[:color]
    assert theme.style?(:heading)
  end

  def test_theme_style_returns_copy
    theme = BujoPdf::DSL::Theme.new(:test)
    theme.set_style(:test, { font_size: 10 })

    style = theme.style(:test)
    style[:font_size] = 20

    assert_equal 10, theme.style(:test)[:font_size]
  end

  def test_theme_style_names
    theme = BujoPdf::DSL::Theme.build(:test) do
      style :title, font_size: 14
      style :body, font_size: 10
    end

    assert_includes theme.style_names, :title
    assert_includes theme.style_names, :body
  end

  def test_theme_defaults_for_element
    theme = BujoPdf::DSL::Theme.build(:test) do
      defaults_for :text, font_family: 'Helvetica', font_size: 10
    end

    defaults = theme.defaults_for(:text)
    assert_equal 'Helvetica', defaults[:font_family]
    assert_equal 10, defaults[:font_size]
    assert_nil theme.defaults_for(:unknown)
  end

  def test_theme_defaults_returns_copy
    theme = BujoPdf::DSL::Theme.build(:test) do
      defaults_for :text, font_size: 10
    end

    defaults = theme.defaults_for(:text)
    defaults[:font_size] = 20

    assert_equal 10, theme.defaults_for(:text)[:font_size]
  end

  def test_theme_merge
    base = BujoPdf::DSL::Theme.build(:base) do
      color :background, 'FFFFFF'
      color :text, '000000'
      style :title, font_size: 14
      defaults_for :text, font_family: 'Helvetica'
    end

    child = BujoPdf::DSL::Theme.build(:child) do
      color :text, '333333'  # Override
      style :title, color: '444444'  # Merge into existing
      style :body, font_size: 10  # New
    end

    base.merge!(child)

    assert_equal 'FFFFFF', base.color(:background)  # Kept
    assert_equal '333333', base.color(:text)  # Overridden
    assert_equal '444444', base.style(:title)[:color]  # Merged
    assert_equal 10, base.style(:body)[:font_size]  # Added
    assert_equal 'Helvetica', base.defaults_for(:text)[:font_family]  # Kept
  end

  def test_theme_dup
    original = BujoPdf::DSL::Theme.build(:original) do
      color :background, 'FFFFFF'
      style :title, font_size: 14
      defaults_for :text, font_family: 'Helvetica'
    end

    copy = original.dup
    copy.set_color(:background, '000000')
    copy.set_style(:title, { font_size: 20 })

    assert_equal 'FFFFFF', original.color(:background)
    assert_equal 14, original.style(:title)[:font_size]
  end

  # ThemeRegistry tests

  def test_theme_registry_register_and_get
    BujoPdf::DSL::ThemeRegistry.register(:test) do
      color :background, 'FFFFFF'
    end

    theme = BujoPdf::DSL::ThemeRegistry.get(:test)

    assert_equal :test, theme.name
    assert_equal 'FFFFFF', theme.color(:background)
  end

  def test_theme_registry_fetch_raises_on_unknown
    assert_raises ArgumentError do
      BujoPdf::DSL::ThemeRegistry.fetch(:nonexistent)
    end
  end

  def test_theme_registry_registered?
    BujoPdf::DSL::ThemeRegistry.register(:exists) {}

    assert BujoPdf::DSL::ThemeRegistry.registered?(:exists)
    refute BujoPdf::DSL::ThemeRegistry.registered?(:nope)
  end

  def test_theme_registry_names
    BujoPdf::DSL::ThemeRegistry.register(:alpha) {}
    BujoPdf::DSL::ThemeRegistry.register(:beta) {}

    names = BujoPdf::DSL::ThemeRegistry.names

    assert_includes names, :alpha
    assert_includes names, :beta
  end

  def test_theme_registry_clear
    BujoPdf::DSL::ThemeRegistry.register(:test) {}
    BujoPdf::DSL::ThemeRegistry.clear!

    refute BujoPdf::DSL::ThemeRegistry.registered?(:test)
  end

  # StyleResolver tests

  def test_resolver_with_inline_styles_only
    theme = BujoPdf::DSL::Theme.new(:empty)
    resolver = BujoPdf::DSL::StyleResolver.new(theme)

    result = resolver.resolve(:text, font_size: 12, color: '333333')

    assert_equal 12, result[:font_size]
    assert_equal '333333', result[:color]
  end

  def test_resolver_with_element_defaults
    theme = BujoPdf::DSL::Theme.build(:test) do
      defaults_for :text, font_family: 'Helvetica', font_size: 10
    end

    resolver = BujoPdf::DSL::StyleResolver.new(theme)
    result = resolver.resolve(:text)

    assert_equal 'Helvetica', result[:font_family]
    assert_equal 10, result[:font_size]
  end

  def test_resolver_with_named_style
    theme = BujoPdf::DSL::Theme.build(:test) do
      style :title, font_size: 14, font_weight: :bold, color: '4A4A4A'
    end

    resolver = BujoPdf::DSL::StyleResolver.new(theme)
    result = resolver.resolve(:text, style: :title)

    assert_equal 14, result[:font_size]
    assert_equal :bold, result[:font_weight]
    assert_equal '4A4A4A', result[:color]
  end

  def test_resolver_cascade_order
    theme = BujoPdf::DSL::Theme.build(:test) do
      # Element defaults (lowest priority)
      defaults_for :text, font_family: 'Helvetica', font_size: 10, color: '000000'

      # Named style (medium priority)
      style :title, font_size: 14, color: '333333'
    end

    resolver = BujoPdf::DSL::StyleResolver.new(theme)

    # Inline override (highest priority)
    result = resolver.resolve(:text, style: :title, color: 'FF0000')

    assert_equal 'Helvetica', result[:font_family]  # From defaults
    assert_equal 14, result[:font_size]  # From named style
    assert_equal 'FF0000', result[:color]  # From inline
  end

  def test_resolver_color_lookup
    theme = BujoPdf::DSL::Theme.build(:test) do
      color :primary, '4A90D9'
      color :secondary, '7AB8E5'
    end

    resolver = BujoPdf::DSL::StyleResolver.new(theme)

    assert_equal '4A90D9', resolver.color(:primary)
    assert_equal '7AB8E5', resolver.color(:secondary)
    assert_nil resolver.color(:nonexistent)
  end

  def test_resolver_colors_multiple
    theme = BujoPdf::DSL::Theme.build(:test) do
      color :a, '111111'
      color :b, '222222'
      color :c, '333333'
    end

    resolver = BujoPdf::DSL::StyleResolver.new(theme)
    result = resolver.colors(:a, :c)

    assert_equal '111111', result[:a]
    assert_equal '333333', result[:c]
    refute_includes result.keys, :b
  end

  # BujoPdf.define_theme convenience method

  def test_define_theme_convenience_method
    theme = BujoPdf.define_theme(:convenient) do
      color :background, 'FAFAFA'
      style :note, font_size: 9, color: '666666'
    end

    assert_equal :convenient, theme.name
    assert BujoPdf::DSL::ThemeRegistry.registered?(:convenient)

    retrieved = BujoPdf::DSL::ThemeRegistry.get(:convenient)
    assert_equal 'FAFAFA', retrieved.color(:background)
  end

  # ContentNode integration tests

  def test_text_node_resolved_styles
    theme = BujoPdf::DSL::Theme.build(:test) do
      defaults_for :text, font_family: 'Helvetica', font_size: 10
      style :title, font_size: 14, font_weight: :bold
    end

    resolver = BujoPdf::DSL::StyleResolver.new(theme)

    # TextNode with style reference
    node = BujoPdf::DSL::TextNode.new(content: "Hello", style: :title)
    styles = node.resolved_styles(resolver)

    assert_equal 'Helvetica', styles[:font_family]  # From defaults
    assert_equal 14, styles[:font_size]  # From named style
    assert_equal :bold, styles[:font_weight]  # From named style
  end

  def test_text_node_inline_style_override
    theme = BujoPdf::DSL::Theme.build(:test) do
      defaults_for :text, font_family: 'Helvetica', font_size: 10
      style :title, font_size: 14, color: '333333'
    end

    resolver = BujoPdf::DSL::StyleResolver.new(theme)

    # TextNode with style reference AND inline override
    node = BujoPdf::DSL::TextNode.new(
      content: "Hello",
      style: :title,
      font_size: 18,
      color: 'FF0000'
    )
    styles = node.resolved_styles(resolver)

    assert_equal 'Helvetica', styles[:font_family]  # From defaults
    assert_equal 18, styles[:font_size]  # Inline override
    assert_equal 'FF0000', styles[:color]  # Inline override
  end

  def test_text_node_element_type
    node = BujoPdf::DSL::TextNode.new(content: "test")
    assert_equal :text, node.element_type
  end

  def test_text_node_style_ref
    node = BujoPdf::DSL::TextNode.new(content: "test", style: :title)
    assert_equal :title, node.style_ref
  end

  def test_text_node_inline_styles_only_set_values
    node = BujoPdf::DSL::TextNode.new(
      content: "test",
      font_size: 12,
      color: 'FF0000'
    )

    inline = node.inline_styles
    assert_equal 12, inline[:font_size]
    assert_equal 'FF0000', inline[:color]
    refute_includes inline.keys, :font_weight
    refute_includes inline.keys, :font_family
  end

  def test_dot_grid_node_resolved_styles
    theme = BujoPdf::DSL::Theme.build(:test) do
      defaults_for :dot_grid, dot_color: 'CCCCCC', dot_radius: 0.5
    end

    resolver = BujoPdf::DSL::StyleResolver.new(theme)

    # DotGridNode with inline override
    node = BujoPdf::DSL::DotGridNode.new(dot_color: 'AAAAAA')
    styles = node.resolved_styles(resolver)

    assert_equal 'AAAAAA', styles[:dot_color]  # Inline override
    assert_equal 0.5, styles[:dot_radius]  # From defaults
  end

  def test_content_node_base_element_type
    node = BujoPdf::DSL::ContentNode.new
    assert_equal :content, node.element_type
  end
end
