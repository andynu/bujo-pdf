# frozen_string_literal: true

require_relative 'page_declaration'

module BujoPdf
  module PdfDSL
    # InlinePageContext captures configuration and body block during DSL declaration.
    #
    # When a page is declared with a block in define_pdf, this context captures:
    # - Layout configuration (layout name, options)
    # - Theme override
    # - Background type
    # - Body block for rendering
    #
    # @example Inline page declaration
    #   page id: :notes, outline: 'Notes' do
    #     layout :full_page
    #     theme :dark
    #     background :ruled
    #
    #     body do
    #       h1(2, 1, "Notes")
    #       ruled_lines(2, 3, 38, 50)
    #     end
    #   end
    #
    class InlinePageContext
      attr_reader :layout_name, :layout_options, :theme_override, :background_type, :body_block

      # Initialize a new inline page context.
      def initialize
        @layout_name = :full_page
        @layout_options = {}
        @theme_override = nil
        @background_type = :dot_grid
        @body_block = nil
      end

      # Set the layout for this page.
      #
      # @param name [Symbol] Layout name (:full_page, :standard_with_sidebars)
      # @param options [Hash] Layout-specific options
      # @return [void]
      #
      # @example
      #   layout :standard_with_sidebars, current_week: 1
      def layout(name, **options)
        @layout_name = name
        @layout_options = options
      end

      # Set a theme override for this page.
      #
      # @param name [Symbol] Theme name (:light, :dark, :earth)
      # @return [void]
      #
      # @example
      #   theme :dark
      def theme(name)
        @theme_override = name
      end

      # Set the background type for this page.
      #
      # @param type [Symbol] Background type (:dot_grid, :ruled, :blank)
      # @return [void]
      #
      # @example
      #   background :ruled
      def background(type)
        @background_type = type
      end

      # Define the page content body.
      #
      # The body block is executed during the render phase with access to
      # all component verbs (h1, ruled_lines, box, etc.).
      #
      # @yield Block containing component verb calls
      # @return [void]
      #
      # @example
      #   body do
      #     h1(2, 1, "My Page")
      #     ruled_lines(2, 3, 38, 10)
      #   end
      def body(&block)
        @body_block = block
      end

      # Evaluate a page block in this context.
      #
      # @param block [Proc] The page block from the DSL
      # @return [void]
      def evaluate(&block)
        instance_eval(&block)
      end
    end

    # InlinePageDeclaration extends PageDeclaration to store inline page configuration.
    #
    # Unlike standard PageDeclaration which references a registered page class,
    # InlinePageDeclaration stores all configuration needed to render an anonymous
    # page defined directly in the DSL.
    #
    # @example Creating an inline declaration
    #   context = InlinePageContext.new
    #   context.layout :full_page
    #   context.body { h1(2, 1, "Title") }
    #
    #   decl = InlinePageDeclaration.new(
    #     id: :my_page,
    #     outline: 'My Page',
    #     inline_context: context
    #   )
    #
    class InlinePageDeclaration < PageDeclaration
      attr_reader :inline_context

      # Initialize a new inline page declaration.
      #
      # @param id [Symbol, nil] Optional explicit page ID
      # @param outline [String, nil] Optional outline entry title
      # @param inline_context [InlinePageContext] The captured inline configuration
      # @param params [Hash] Additional parameters
      def initialize(id: nil, outline: nil, inline_context:, **params)
        # Type is :inline for inline pages
        super(:inline, id: id, outline: outline, **params)
        @inline_context = inline_context
      end

      # Check if this is an inline page declaration.
      #
      # @return [Boolean] Always true for InlinePageDeclaration
      def inline?
        true
      end

      # Get the layout name for this inline page.
      #
      # @return [Symbol] Layout name
      def layout_name
        @inline_context.layout_name
      end

      # Get layout options for this inline page.
      #
      # @return [Hash] Layout options
      def layout_options
        @inline_context.layout_options
      end

      # Get the theme override for this inline page.
      #
      # @return [Symbol, nil] Theme name or nil
      def theme_override
        @inline_context.theme_override
      end

      # Get the background type for this inline page.
      #
      # @return [Symbol] Background type (:dot_grid, :ruled, :blank)
      def background_type
        @inline_context.background_type
      end

      # Get the body block for rendering.
      #
      # @return [Proc, nil] The body block
      def body_block
        @inline_context.body_block
      end
    end
  end
end
