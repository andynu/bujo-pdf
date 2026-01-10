# frozen_string_literal: true

require_relative 'chrome_spec'
require_relative 'configurable_layout'
require_relative 'daily_with_sidebars_layout'
require_relative 'full_page_layout'
require_relative 'standard_with_sidebars_layout'

module BujoPdf
  module Layouts
    # Factory for creating layout instances by symbolic name or chrome configuration.
    #
    # Provides a centralized registry of available layouts and creates
    # layout instances with appropriate initialization parameters.
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
    #   # => [:full_page, :standard_with_sidebars, :configurable]
    class LayoutFactory
      # Registry of available layouts.
      #
      # Maps symbolic layout names to their corresponding class.
      LAYOUTS = {
        configurable: ConfigurableLayout,
        daily_with_sidebars: DailyWithSidebarsLayout,
        full_page: FullPageLayout,
        standard_with_sidebars: StandardWithSidebarsLayout
      }.freeze

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
      # When a `chrome:` option is provided, creates a ConfigurableLayout
      # with the specified chrome configuration. Otherwise, uses the
      # registered layout class for the given name.
      #
      # Named presets still work as before but can be thought of as
      # shortcuts for specific chrome configurations.
      #
      # @param name [Symbol] Layout name (:full_page, :standard_with_sidebars, :configurable)
      # @param pdf [Prawn::Document] PDF document
      # @param grid_system [Utilities::GridSystem] Grid system
      # @param chrome [Hash, nil] Optional chrome configuration hash
      # @param options [Hash] Layout-specific options passed to the layout constructor
      # @return [BaseLayout] Layout instance
      # @raise [ArgumentError] if layout name is not registered
      #
      # @example Using named preset
      #   LayoutFactory.create(:full_page, pdf, grid_system)
      #
      # @example Using chrome configuration
      #   LayoutFactory.create(:configurable, pdf, grid_system,
      #     chrome: { left: :week_sidebar, right: :tab_sidebar }
      #   )
      def self.create(name, pdf, grid_system, chrome: nil, **options)
        # If chrome hash is provided, build a ConfigurableLayout
        if chrome
          chrome_spec = build_chrome_spec(chrome)
          return ConfigurableLayout.new(pdf, grid_system, chrome_spec: chrome_spec, **options)
        end

        layout_class = LAYOUTS[name]
        raise ArgumentError, "Unknown layout: #{name}. Available layouts: #{available_layouts.join(', ')}" unless layout_class

        layout_class.new(pdf, grid_system, **options)
      end

      # Get list of available layout names.
      #
      # @return [Array<Symbol>] Array of registered layout names
      #
      # @example
      #   LayoutFactory.available_layouts
      #   # => [:full_page, :standard_with_sidebars, :configurable]
      def self.available_layouts
        LAYOUTS.keys
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
