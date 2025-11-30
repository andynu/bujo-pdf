# frozen_string_literal: true

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
  end
end
