# frozen_string_literal: true

require_relative 'chrome_spec'
require_relative 'configurable_layout'
require_relative 'full_page_layout'

module BujoPdf
  module Layouts
    # Factory for creating layout instances by symbolic name or chrome configuration.
    #
    # Provides a centralized registry of available layouts and creates
    # layout instances with appropriate initialization parameters.
    #
    # All named presets use ConfigurableLayout internally with pre-defined
    # chrome configurations. This unifies the layout system around a single
    # flexible implementation.
    #
    # Supports two modes of operation:
    # 1. Named presets: Use symbolic names for common layout configurations
    # 2. Chrome configuration: Pass a chrome hash for arbitrary sidebar combinations
    #
    # @example Create a layout using named preset
    #   layout = LayoutFactory.create(:full_page, pdf, grid_system)
    #
    # @example Create a layout with options
    #   layout = LayoutFactory.create(
    #     :standard_with_sidebars,
    #     pdf,
    #     grid_system,
    #     current_week: 42,
    #     highlight_tab: :year_events
    #   )
    #
    # @example Create a layout with chrome configuration
    #   layout = LayoutFactory.create(:configurable, pdf, grid_system,
    #     chrome: {
    #       left: :week_sidebar,
    #       right: { component: :tab_sidebar, top_tabs: [...] }
    #     }
    #   )
    #
    # @example List available layouts
    #   LayoutFactory.available_layouts
    #   # => [:full_page, :standard_with_sidebars, :daily_with_sidebars, :configurable]
    class LayoutFactory
      # Named layout presets.
      #
      # All presets map to ConfigurableLayout with specific chrome configurations.
      PRESET_NAMES = [:full_page, :standard_with_sidebars, :daily_with_sidebars, :configurable].freeze

      # Preset chrome configurations for named layouts.
      #
      # Maps layout names to their equivalent ChromeSpec configurations.
      # Used to provide shortcuts for common sidebar arrangements.
      CHROME_PRESETS = {
        full_page: {},
        standard_with_sidebars: { left: :week_sidebar, right: :tab_sidebar },
        daily_with_sidebars: { left: :month_sidebar, right: :tab_sidebar }
      }.freeze

      # Create a layout instance by name.
      #
      # All layouts are created using ConfigurableLayout with the appropriate
      # chrome configuration. Named presets (:full_page, :standard_with_sidebars,
      # :daily_with_sidebars) map to pre-defined chrome configurations.
      #
      # When a `chrome:` option is provided, it overrides any preset configuration
      # and creates a ConfigurableLayout with the specified chrome.
      #
      # @param name [Symbol] Layout name (:full_page, :standard_with_sidebars, :daily_with_sidebars, :configurable)
      # @param pdf [Prawn::Document] PDF document
      # @param grid_system [Utilities::GridSystem] Grid system
      # @param chrome [Hash, nil] Optional chrome configuration hash (overrides preset)
      # @param options [Hash] Layout-specific options passed to the layout constructor
      # @return [ConfigurableLayout] Layout instance
      # @raise [ArgumentError] if layout name is not recognized
      #
      # @example Using named preset
      #   LayoutFactory.create(:full_page, pdf, grid_system)
      #
      # @example Using chrome configuration
      #   LayoutFactory.create(:configurable, pdf, grid_system,
      #     chrome: { left: :week_sidebar, right: :tab_sidebar }
      #   )
      def self.create(name, pdf, grid_system, chrome: nil, **options)
        # If chrome hash is provided explicitly, use it directly
        if chrome
          chrome_spec = build_chrome_spec(chrome)
          return ConfigurableLayout.new(pdf, grid_system, chrome_spec: chrome_spec, **options)
        end

        # Validate layout name
        unless PRESET_NAMES.include?(name)
          raise ArgumentError, "Unknown layout: #{name}. Available layouts: #{available_layouts.join(', ')}"
        end

        # Use preset chrome configuration (empty hash for :configurable gives full page)
        preset_chrome = CHROME_PRESETS.fetch(name, {})
        chrome_spec = build_chrome_spec(preset_chrome)
        ConfigurableLayout.new(pdf, grid_system, chrome_spec: chrome_spec, **options)
      end

      # Get list of available layout names.
      #
      # @return [Array<Symbol>] Array of available layout preset names
      #
      # @example
      #   LayoutFactory.available_layouts
      #   # => [:full_page, :standard_with_sidebars, :daily_with_sidebars, :configurable]
      def self.available_layouts
        PRESET_NAMES
      end

      # Get chrome preset configuration for a named layout.
      #
      # @param name [Symbol] Layout preset name
      # @return [Hash, nil] Chrome configuration hash or nil if not a preset
      #
      # @example
      #   LayoutFactory.chrome_preset(:standard_with_sidebars)
      #   # => { left: :week_sidebar, right: :tab_sidebar }
      def self.chrome_preset(name)
        CHROME_PRESETS[name]
      end

      # Build a ChromeSpec from a configuration hash.
      #
      # @param chrome_config [Hash] Chrome configuration with :left, :right, :top, :bottom keys
      # @return [ChromeSpec] ChromeSpec instance
      #
      # @example
      #   build_chrome_spec(left: :week_sidebar, right: :tab_sidebar)
      #   # => #<ChromeSpec left: :week_sidebar, right: :tab_sidebar>
      def self.build_chrome_spec(chrome_config)
        ChromeSpec.new(
          left: chrome_config[:left],
          right: chrome_config[:right],
          top: chrome_config[:top],
          bottom: chrome_config[:bottom]
        )
      end

      private_class_method :build_chrome_spec
    end
  end
end
