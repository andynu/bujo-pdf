# frozen_string_literal: true

require_relative '../../test_helper'

class TestSidebarRegistry < Minitest::Test
  def setup
    # Save original registry state
    @original_registry = BujoPdf::Sidebars::SidebarRegistry.registry.dup
  end

  def teardown
    # Restore original registry state to avoid test pollution
    # We need to reset and re-register originals
    BujoPdf::Sidebars::SidebarRegistry.reset!
    @original_registry.each do |name, klass|
      BujoPdf::Sidebars::SidebarRegistry.register(name, klass)
    end
  end

  # ============================================
  # Registry Tests
  # ============================================

  def test_registry_is_accessible
    assert_kind_of Hash, BujoPdf::Sidebars::SidebarRegistry.registry
  end

  def test_register_adds_sidebar_to_registry
    test_class = Class.new(BujoPdf::SidebarBase)

    BujoPdf::Sidebars::SidebarRegistry.register(:test_sidebar, test_class)

    assert_equal test_class, BujoPdf::Sidebars::SidebarRegistry.registry[:test_sidebar]
  end

  def test_register_can_override_existing_sidebar
    test_class1 = Class.new(BujoPdf::SidebarBase)
    test_class2 = Class.new(BujoPdf::SidebarBase)

    BujoPdf::Sidebars::SidebarRegistry.register(:override_test, test_class1)
    BujoPdf::Sidebars::SidebarRegistry.register(:override_test, test_class2)

    assert_equal test_class2, BujoPdf::Sidebars::SidebarRegistry.registry[:override_test]
  end

  # ============================================
  # Lookup Tests
  # ============================================

  def test_lookup_returns_registered_class
    test_class = Class.new(BujoPdf::SidebarBase)
    BujoPdf::Sidebars::SidebarRegistry.register(:lookup_test, test_class)

    assert_equal test_class, BujoPdf::Sidebars::SidebarRegistry.lookup(:lookup_test)
  end

  def test_lookup_returns_nil_for_unregistered
    assert_nil BujoPdf::Sidebars::SidebarRegistry.lookup(:nonexistent_sidebar)
  end

  # ============================================
  # Registered? Tests
  # ============================================

  def test_registered_returns_true_for_registered
    test_class = Class.new(BujoPdf::SidebarBase)
    BujoPdf::Sidebars::SidebarRegistry.register(:registered_test, test_class)

    assert BujoPdf::Sidebars::SidebarRegistry.registered?(:registered_test)
  end

  def test_registered_returns_false_for_unregistered
    refute BujoPdf::Sidebars::SidebarRegistry.registered?(:definitely_not_registered)
  end

  # ============================================
  # Reset Tests
  # ============================================

  def test_reset_clears_registry
    test_class = Class.new(BujoPdf::SidebarBase)
    BujoPdf::Sidebars::SidebarRegistry.register(:reset_test, test_class)

    BujoPdf::Sidebars::SidebarRegistry.reset!

    refute BujoPdf::Sidebars::SidebarRegistry.registered?(:reset_test)
    assert_empty BujoPdf::Sidebars::SidebarRegistry.registry
  end

  # ============================================
  # Mixin Integration Tests
  # ============================================

  def test_register_sidebar_class_method_via_mixin
    # Create a test sidebar class that includes the mixin
    test_class = Class.new(BujoPdf::SidebarBase) do
      include BujoPdf::Sidebars::SidebarRegistry
      register_sidebar :mixin_test_sidebar
    end

    assert BujoPdf::Sidebars::SidebarRegistry.registered?(:mixin_test_sidebar)
    assert_equal test_class, BujoPdf::Sidebars::SidebarRegistry.lookup(:mixin_test_sidebar)
  end

  def test_sidebar_type_accessor_is_set
    test_class = Class.new(BujoPdf::SidebarBase) do
      include BujoPdf::Sidebars::SidebarRegistry
      register_sidebar :type_accessor_test
    end

    assert_equal :type_accessor_test, test_class.sidebar_type
  end

  def test_multiple_sidebars_can_register
    test_class1 = Class.new(BujoPdf::SidebarBase) do
      include BujoPdf::Sidebars::SidebarRegistry
      register_sidebar :multi_test_1
    end

    test_class2 = Class.new(BujoPdf::SidebarBase) do
      include BujoPdf::Sidebars::SidebarRegistry
      register_sidebar :multi_test_2
    end

    assert_equal test_class1, BujoPdf::Sidebars::SidebarRegistry.lookup(:multi_test_1)
    assert_equal test_class2, BujoPdf::Sidebars::SidebarRegistry.lookup(:multi_test_2)
    assert_equal :multi_test_1, test_class1.sidebar_type
    assert_equal :multi_test_2, test_class2.sidebar_type
  end
end
