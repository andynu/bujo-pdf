# frozen_string_literal: true

require_relative 'light'
require_relative 'earth'
require_relative 'dark'

module BujoPdf
  module Themes
    # Registry for managing available themes
    class ThemeRegistry
      # All available themes
      THEMES = {
        light: LIGHT,
        earth: EARTH,
        dark: DARK
      }.freeze

      # Default theme
      DEFAULT_THEME = :light

      class << self
        # Get a theme by name
        # @param name [Symbol, String] The theme name
        # @return [Hash] The theme hash
        # @raise [ArgumentError] If theme doesn't exist
        def get(name)
          theme_key = name.to_sym
          THEMES[theme_key] || raise(ArgumentError, "Unknown theme: #{name}. Available themes: #{available_names.join(', ')}")
        end

        # Get list of available theme names
        # @return [Array<Symbol>] Available theme names
        def available_names
          THEMES.keys
        end

        # Get list of available theme display names
        # @return [Array<String>] Available theme display names
        def available_display_names
          THEMES.values.map { |t| t[:name] }
        end

        # Check if a theme exists
        # @param name [Symbol, String] The theme name
        # @return [Boolean]
        def exists?(name)
          THEMES.key?(name.to_sym)
        end
      end
    end

    # Current active theme (defaults to light)
    @current_theme = ThemeRegistry::DEFAULT_THEME

    class << self
      # Get the current active theme
      # @return [Hash] The current theme hash
      def current
        ThemeRegistry.get(@current_theme)
      end

      # Set the active theme
      # @param name [Symbol, String] The theme name
      # @raise [ArgumentError] If theme doesn't exist
      def set(name)
        ThemeRegistry.get(name) # Validate theme exists
        @current_theme = name.to_sym
      end

      # Get the current theme name
      # @return [Symbol] The current theme name
      def current_name
        @current_theme
      end

      # Reset to default theme
      def reset!
        @current_theme = ThemeRegistry::DEFAULT_THEME
      end
    end
  end
end
