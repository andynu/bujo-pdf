# frozen_string_literal: true

module BujoPdf
  module Sidebars
    # Mixin for registering sidebar types with the central registry.
    #
    # Sidebar classes call `register_sidebar` to declare their type.
    # The registry provides named lookup for sidebar classes, similar
    # to how PageRegistry works for pages.
    #
    # @example Self-registration in a sidebar class
    #   class WeekSidebar < SidebarBase
    #     include Sidebars::SidebarRegistry
    #     register_sidebar :week_sidebar
    #   end
    #
    # @example Looking up a sidebar class
    #   Sidebars::SidebarRegistry.lookup(:week_sidebar)  # => WeekSidebar
    #   Sidebars::SidebarRegistry.registered?(:week_sidebar)  # => true
    #
    module SidebarRegistry
      # Registry mapping sidebar names to sidebar classes.
      # Starts empty - populated by sidebar classes calling register_sidebar.
      @registry = {}

      class << self
        attr_reader :registry

        # Register a sidebar class by name.
        #
        # Usually called automatically by register_sidebar in sidebar classes.
        # Can also be called manually for custom sidebar types.
        #
        # @param name [Symbol] The sidebar type identifier
        # @param klass [Class] The sidebar class
        # @return [void]
        def register(name, klass)
          @registry = @registry.merge(name => klass)
        end

        # Look up a sidebar class by name.
        #
        # @param name [Symbol] The sidebar type identifier
        # @return [Class, nil] The sidebar class, or nil if not registered
        def lookup(name)
          @registry[name]
        end

        # Check if a sidebar type is registered.
        #
        # @param name [Symbol] The sidebar type identifier
        # @return [Boolean] True if the sidebar is registered
        def registered?(name)
          @registry.key?(name)
        end

        # Clear all registrations (for testing).
        #
        # @return [void]
        def reset!
          @registry = {}
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :sidebar_type

        # Register this sidebar class with its type identifier.
        #
        # @param type [Symbol] Sidebar type identifier (e.g., :week_sidebar)
        def register_sidebar(type)
          @sidebar_type = type
          SidebarRegistry.register(type, self)
        end
      end
    end
  end
end
