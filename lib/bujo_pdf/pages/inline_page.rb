# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # InlinePage is an anonymous page class for rendering inline page definitions.
    #
    # When a page is defined inline in the DSL with a body block, InlinePage is
    # instantiated at render time to execute that block with access to all
    # component verbs.
    #
    # @example Render an inline page
    #   decl = InlinePageDeclaration.new(
    #     inline_context: context_with_body_block
    #   )
    #
    #   page = InlinePage.new(pdf, render_context, inline_declaration: decl)
    #   page.generate
    #
    class InlinePage < Base
      # Initialize a new inline page instance.
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [RenderContext, Hash] Rendering context
      # @param inline_declaration [InlinePageDeclaration] The inline page declaration
      def initialize(pdf, context, inline_declaration:)
        super(pdf, context)
        @inline_declaration = inline_declaration
      end

      protected

      # Set up the page with the declared layout.
      #
      # @return [void]
      def setup
        # Apply layout from declaration
        use_layout(
          @inline_declaration.layout_name,
          **@inline_declaration.layout_options
        )

        # Set named destination if page has an ID
        if @inline_declaration.id
          set_destination(@inline_declaration.id.to_s)
        end
      end

      # Set up page background based on declaration.
      #
      # @return [void]
      def setup_page
        case @inline_declaration.background_type
        when :dot_grid
          draw_background_dots
        when :ruled
          draw_background_ruled
        when :blank
          draw_background_blank
        end
      end

      # Render the page content by executing the body block.
      #
      # @return [void]
      def render
        return unless @inline_declaration.body_block

        # Execute the body block in the context of this page instance
        # This gives the block access to all component verbs (h1, ruled_lines, etc.)
        instance_eval(&@inline_declaration.body_block)
      end

      private

      # Draw dot grid background.
      #
      # @return [void]
      def draw_background_dots
        # Draw background color first
        bg_color = Styling::Colors.BACKGROUND
        unless bg_color == 'FFFFFF'
          @pdf.fill_color bg_color
          @pdf.fill_rectangle [0, Styling::Grid::PAGE_HEIGHT], Styling::Grid::PAGE_WIDTH, Styling::Grid::PAGE_HEIGHT
          @pdf.fill_color Styling::Colors.TEXT_BLACK
        end

        # Use stamp if available - try/rescue since stamps may not exist
        begin
          @pdf.stamp('page_dots')
        rescue Prawn::Errors::InvalidName
          # Stamp doesn't exist, draw dots manually
          BujoPdf::DotGrid.draw(@pdf, Styling::Grid::PAGE_WIDTH, Styling::Grid::PAGE_HEIGHT)
        end
      end

      # Draw ruled lines background.
      #
      # @return [void]
      def draw_background_ruled
        # Draw background color first
        bg_color = Styling::Colors.BACKGROUND
        unless bg_color == 'FFFFFF'
          @pdf.fill_color bg_color
          @pdf.fill_rectangle [0, Styling::Grid::PAGE_HEIGHT], Styling::Grid::PAGE_WIDTH, Styling::Grid::PAGE_HEIGHT
          @pdf.fill_color Styling::Colors.TEXT_BLACK
        end

        # Draw horizontal ruled lines every 2 boxes (10mm spacing)
        line_spacing = 2
        @pdf.stroke_color Styling::Colors.BORDERS
        @pdf.line_width 0.5

        (0..55).step(line_spacing) do |row|
          y = @grid.y(row)
          @pdf.stroke_horizontal_line 0, Styling::Grid::PAGE_WIDTH, at: y
        end
      end

      # Draw blank background (just fill with background color).
      #
      # @return [void]
      def draw_background_blank
        bg_color = Styling::Colors.BACKGROUND
        unless bg_color == 'FFFFFF'
          @pdf.fill_color bg_color
          @pdf.fill_rectangle [0, Styling::Grid::PAGE_HEIGHT], Styling::Grid::PAGE_WIDTH, Styling::Grid::PAGE_HEIGHT
          @pdf.fill_color Styling::Colors.TEXT_BLACK
        end
      end
    end
  end
end
