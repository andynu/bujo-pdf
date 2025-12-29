# frozen_string_literal: true

require_relative 'daily_with_sidebars_layout'
require_relative 'full_page_layout'
require_relative 'standard_with_sidebars_layout'

module BujoPdf
  module Layouts
    # Factory for creating layout instances by symbolic name.
    #
    # Provides a centralized registry of available layouts and creates
    # layout instances with appropriate initialization parameters.
    #
    # @example Create a layout
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
    # @example List available layouts
    #   LayoutFactory.available_layouts
    #   # => [:full_page, :standard_with_sidebars]
    class LayoutFactory
      # Registry of available layouts.
      #
      # Maps symbolic layout names to their corresponding class.
      LAYOUTS = {
        daily_with_sidebars: DailyWithSidebarsLayout,
        full_page: FullPageLayout,
        standard_with_sidebars: StandardWithSidebarsLayout
      }.freeze

      # Create a layout instance by name.
      #
      # @param name [Symbol] Layout name (:full_page, :standard_with_sidebars)
      # @param pdf [Prawn::Document] PDF document
      # @param grid_system [Utilities::GridSystem] Grid system
      # @param options [Hash] Layout-specific options passed to the layout constructor
      # @return [BaseLayout] Layout instance
      # @raise [ArgumentError] if layout name is not registered
      #
      # @example
      #   factory = LayoutFactory.create(:full_page, pdf, grid_system)
      def self.create(name, pdf, grid_system, **options)
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
      #   # => [:full_page, :standard_with_sidebars]
      def self.available_layouts
        LAYOUTS.keys
      end
    end
  end
end
