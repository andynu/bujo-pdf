# frozen_string_literal: true

require_relative 'page_declaration'
require_relative 'inline_page_context'

module BujoPdf
  module PdfDSL
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
