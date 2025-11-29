# frozen_string_literal: true

module BujoPdf
  module DSL
    # StyleResolver resolves styles for layout nodes using CSS-like cascading.
    #
    # The cascade order (lowest to highest priority):
    # 1. Theme default styles (base styles from theme)
    # 2. Named style from theme (e.g., style: :title)
    # 3. Inline styles on element (e.g., font_size: 14)
    #
    # @example Resolving styles for a text node
    #   resolver = StyleResolver.new(theme)
    #   styles = resolver.resolve(:text, style: :title, font_size: 18)
    #   # => { font_family: 'Helvetica', font_size: 18, color: '4A4A4A', font_weight: :bold }
    #
    class StyleResolver
      # Initialize a new style resolver.
      #
      # @param theme [Theme] The theme containing style definitions
      def initialize(theme)
        @theme = theme
      end

      # Resolve styles for an element.
      #
      # Merges styles from the cascade in order:
      # 1. Element-type default styles from theme
      # 2. Named style (if style: param provided)
      # 3. Inline styles (any remaining params)
      #
      # @param element_type [Symbol] The element type (:text, :field, :dot_grid, etc.)
      # @param style [Symbol, nil] Named style to apply
      # @param inline_styles [Hash] Inline style overrides
      # @return [Hash] Resolved styles
      def resolve(element_type, style: nil, **inline_styles)
        result = {}

        # 1. Element-type defaults from theme
        defaults = @theme.defaults_for(element_type)
        result.merge!(defaults) if defaults

        # 2. Named style from theme
        if style
          named = @theme.style(style)
          result.merge!(named) if named
        end

        # 3. Inline styles (highest priority)
        result.merge!(inline_styles)

        result
      end

      # Resolve a color from the theme.
      #
      # @param name [Symbol] Color name
      # @return [String, nil] Hex color string or nil if not found
      def color(name)
        @theme.color(name)
      end

      # Resolve multiple colors at once.
      #
      # @param names [Array<Symbol>] Color names
      # @return [Hash<Symbol, String>] Map of names to colors
      def colors(*names)
        names.each_with_object({}) do |name, hash|
          hash[name] = color(name)
        end
      end
    end

    # Theme defines named styles and colors for a visual theme.
    #
    # Themes provide:
    # - Named colors (e.g., :background, :dot_grid, :text_primary)
    # - Named styles (e.g., :title, :body, :nav_link)
    # - Element-type defaults (base styles for :text, :field, etc.)
    #
    # @example Defining a theme
    #   theme = Theme.build(:earth) do
    #     # Define colors
    #     color :background, 'F5F0E6'
    #     color :dot_grid, 'D4C9B8'
    #     color :text_primary, '4A4A4A'
    #
    #     # Define named styles
    #     style :title,
    #       font_size: 14,
    #       font_weight: :bold,
    #       color: '4A4A4A'
    #
    #     style :body,
    #       font_size: 10,
    #       color: '333333'
    #
    #     # Define element defaults
    #     defaults_for :text,
    #       font_family: 'Helvetica',
    #       font_size: 10
    #
    #     defaults_for :dot_grid,
    #       dot_color: 'D4C9B8',
    #       dot_radius: 0.5
    #   end
    #
    class Theme
      attr_reader :name

      # Build a theme using the DSL.
      #
      # @param name [Symbol] Theme name
      # @yield Block for theme definition DSL
      # @return [Theme] The built theme
      def self.build(name, &block)
        theme = new(name)
        builder = ThemeBuilder.new(theme)
        builder.instance_eval(&block) if block
        theme
      end

      # Initialize a new theme.
      #
      # @param name [Symbol] Theme name
      def initialize(name)
        @name = name
        @colors = {}
        @styles = {}
        @defaults = {}
      end

      # Get a color by name.
      #
      # @param name [Symbol] Color name
      # @return [String, nil] Hex color string
      def color(name)
        @colors[name]
      end

      # Set a color.
      #
      # @param name [Symbol] Color name
      # @param value [String] Hex color string
      def set_color(name, value)
        @colors[name] = value
      end

      # Get all colors.
      #
      # @return [Hash<Symbol, String>] All colors
      def colors
        @colors.dup
      end

      # Get a named style.
      #
      # @param name [Symbol] Style name
      # @return [Hash, nil] Style hash
      def style(name)
        @styles[name]&.dup
      end

      # Set a named style.
      #
      # @param name [Symbol] Style name
      # @param properties [Hash] Style properties
      def set_style(name, properties)
        @styles[name] = properties
      end

      # Get all style names.
      #
      # @return [Array<Symbol>] Style names
      def style_names
        @styles.keys
      end

      # Get default styles for an element type.
      #
      # @param element_type [Symbol] Element type
      # @return [Hash, nil] Default styles
      def defaults_for(element_type)
        @defaults[element_type]&.dup
      end

      # Set default styles for an element type.
      #
      # @param element_type [Symbol] Element type
      # @param properties [Hash] Default properties
      def set_defaults(element_type, properties)
        @defaults[element_type] = properties
      end

      # Check if a style is defined.
      #
      # @param name [Symbol] Style name
      # @return [Boolean]
      def style?(name)
        @styles.key?(name)
      end

      # Check if a color is defined.
      #
      # @param name [Symbol] Color name
      # @return [Boolean]
      def color?(name)
        @colors.key?(name)
      end

      # Merge another theme's definitions into this one.
      #
      # Lower-level styles in the other theme override this one.
      #
      # @param other [Theme] Theme to merge
      # @return [self]
      def merge!(other)
        @colors.merge!(other.colors)
        other.style_names.each do |name|
          @styles[name] = style(name)&.merge(other.style(name)) || other.style(name)
        end
        other.instance_variable_get(:@defaults).each do |type, props|
          @defaults[type] = (@defaults[type] || {}).merge(props)
        end
        self
      end

      # Create a copy of this theme.
      #
      # @return [Theme] A new theme with copied definitions
      def dup
        copy = Theme.new(@name)
        copy.instance_variable_set(:@colors, @colors.dup)
        copy.instance_variable_set(:@styles, @styles.transform_values(&:dup))
        copy.instance_variable_set(:@defaults, @defaults.transform_values(&:dup))
        copy
      end
    end

    # ThemeBuilder provides the DSL for building themes.
    #
    # Used internally by Theme.build
    #
    class ThemeBuilder
      # Initialize a new theme builder.
      #
      # @param theme [Theme] Theme to build into
      def initialize(theme)
        @theme = theme
      end

      # Define a color.
      #
      # @param name [Symbol] Color name
      # @param value [String] Hex color value
      #
      # @example
      #   color :background, 'FFFFFF'
      #   color :dot_grid, 'CCCCCC'
      def color(name, value)
        @theme.set_color(name, value)
      end

      # Define a named style.
      #
      # @param name [Symbol] Style name
      # @param properties [Hash] Style properties
      #
      # @example
      #   style :title, font_size: 14, font_weight: :bold, color: '4A4A4A'
      #   style :body, font_size: 10, color: '333333'
      def style(name, **properties)
        @theme.set_style(name, properties)
      end

      # Define default styles for an element type.
      #
      # @param element_type [Symbol] Element type
      # @param properties [Hash] Default properties
      #
      # @example
      #   defaults_for :text, font_family: 'Helvetica', font_size: 10
      #   defaults_for :dot_grid, dot_color: 'CCCCCC', dot_radius: 0.5
      def defaults_for(element_type, **properties)
        @theme.set_defaults(element_type, properties)
      end

      # Inherit from another theme.
      #
      # Copies all definitions from the parent theme as a base.
      #
      # @param parent_name [Symbol] Parent theme name
      #
      # @example
      #   extend_theme :light
      def extend_theme(parent_name)
        parent = ThemeRegistry.get(parent_name)
        @theme.merge!(parent) if parent
      end
    end

    # ThemeRegistry stores and retrieves Theme instances.
    #
    # This is separate from the existing BujoPdf::Themes module to support
    # the new DSL-based themes while maintaining backward compatibility.
    #
    # @example Registering a theme
    #   ThemeRegistry.register :earth do
    #     color :background, 'F5F0E6'
    #     style :title, font_size: 14, font_weight: :bold
    #   end
    #
    # @example Retrieving a theme
    #   theme = ThemeRegistry.get(:earth)
    #
    class ThemeRegistry
      @registry = {}
      @default_theme = :light

      class << self
        attr_accessor :default_theme

        # Register a new theme.
        #
        # @param name [Symbol] Theme name
        # @yield Block for theme definition
        # @return [Theme] The registered theme
        def register(name, &block)
          theme = Theme.build(name, &block)
          @registry[name] = theme
        end

        # Get a theme by name.
        #
        # @param name [Symbol] Theme name
        # @return [Theme, nil] The theme or nil if not found
        def get(name)
          @registry[name]
        end

        # Get a theme by name, raising if not found.
        #
        # @param name [Symbol] Theme name
        # @return [Theme] The theme
        # @raise [ArgumentError] if theme not found
        def fetch(name)
          @registry[name] || raise(ArgumentError, "Unknown theme: #{name}. Available: #{names.join(', ')}")
        end

        # Check if a theme is registered.
        #
        # @param name [Symbol] Theme name
        # @return [Boolean]
        def registered?(name)
          @registry.key?(name)
        end

        # Get all registered theme names.
        #
        # @return [Array<Symbol>]
        def names
          @registry.keys
        end

        # Get the default theme.
        #
        # @return [Theme] The default theme
        def default
          @registry[@default_theme] || raise("Default theme '#{@default_theme}' not registered")
        end

        # Clear all registrations (useful for testing).
        def clear!
          @registry = {}
        end
      end
    end
  end
end

# Convenience method at module level
module BujoPdf
  class << self
    # Define a theme using the DSL.
    #
    # @param name [Symbol] Theme name
    # @yield Block for theme definition
    # @return [DSL::Theme] The defined theme
    #
    # @example
    #   BujoPdf.define_theme :earth do
    #     color :background, 'F5F0E6'
    #     style :title, font_size: 14, font_weight: :bold
    #   end
    def define_theme(name, &block)
      DSL::ThemeRegistry.register(name, &block)
    end
  end
end
