# frozen_string_literal: true

require_relative 'declaration_context'
require_relative 'pdf_definition'

module BujoPdf
  module PdfDSL
    # PdfBuilder orchestrates the PDF generation process.
    #
    # The builder takes a PDF definition and parameters, evaluates the
    # definition to collect page declarations, then renders each page
    # using the existing page classes.
    #
    # @example Basic usage
    #   definition = PdfDefinition.new(:my_planner) { |year:| ... }
    #   builder = PdfBuilder.new
    #   builder.build(definition, year: 2025)
    #
    # @example With output path
    #   builder.build(definition, year: 2025, output: 'my_planner.pdf')
    #
    class PdfBuilder
      # Build a PDF from a definition.
      #
      # @param definition [PdfDefinition] The PDF definition to build
      # @param output [String, nil] Optional output file path
      # @param params [Hash] Parameters to pass to the definition
      # @return [Prawn::Document, String] The PDF document or output path
      def build(definition, output: nil, **params)
        # Phase 1: Evaluate definition to collect declarations
        context = DeclarationContext.new
        definition.evaluate(context, **params)

        # Set theme if specified
        apply_theme(context.theme_name) if context.theme_name

        # Create PDF document
        pdf = create_document(context)

        # Create dot grid stamp for efficiency
        create_dot_grid_stamp(pdf)

        # Build render context base
        base_context = build_base_context(params, context)

        # Phase 2: Render each declared page
        render_pages(pdf, context.pages, base_context)

        # Output
        if output
          pdf.render_file(output)
          output
        else
          pdf
        end
      ensure
        # Reset theme to avoid side effects
        reset_theme if context&.theme_name
      end

      private

      # Apply the specified theme.
      #
      # @param theme_name [Symbol] Theme name
      def apply_theme(theme_name)
        BujoPdf::Themes.set(theme_name)
      end

      # Reset theme to default.
      def reset_theme
        BujoPdf::Themes.reset!
      end

      # Create a new Prawn document.
      #
      # @param context [DeclarationContext] The declaration context
      # @return [Prawn::Document] A new PDF document
      def create_document(context)
        Prawn::Document.new(
          page_size: 'LETTER',
          margin: 0,
          info: context.prawn_metadata
        )
      end

      # Create the dot grid stamp for efficient rendering.
      #
      # @param pdf [Prawn::Document] The PDF document
      def create_dot_grid_stamp(pdf)
        require_relative '../utilities/dot_grid'

        pdf.create_stamp('page_dots') do
          DotGrid.draw(
            pdf,
            Styling::Grid::PAGE_WIDTH,
            Styling::Grid::PAGE_HEIGHT
          )
        end
      end

      # Build the base render context.
      #
      # @param params [Hash] Parameters from build call
      # @param declaration_context [DeclarationContext] The declaration context
      # @return [Hash] Base context for rendering
      def build_base_context(params, declaration_context)
        year = params[:year] || Date.today.year
        total_weeks = BujoPdf::Utilities::DateCalculator.total_weeks(year)

        {
          year: year,
          total_weeks: total_weeks,
          total_pages: declaration_context.pages.length
        }
      end

      # Render all declared pages.
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param pages [Array<PageDeclaration>] Page declarations
      # @param base_context [Hash] Base render context
      def render_pages(pdf, pages, base_context)
        pages.each_with_index do |page_decl, index|
          # Start new page for all but first
          pdf.start_new_page if index > 0

          # Build page-specific context
          page_context = build_page_context(page_decl, base_context, index)

          # Create and render page
          render_page(pdf, page_decl, page_context)
        end
      end

      # Build context for a specific page.
      #
      # @param page_decl [PageDeclaration] The page declaration
      # @param base_context [Hash] Base render context
      # @param index [Integer] Page index (0-based)
      # @return [Hash] Page-specific context
      def build_page_context(page_decl, base_context, index)
        context = base_context.merge(
          page_key: page_decl.type,
          page_number: index + 1
        )

        # Merge page-specific parameters
        page_decl.params.each do |key, value|
          case value
          when Week
            context[:week_num] = value.number
            context[:week_start] = value.start_date
            context[:week_end] = value.end_date
          when Month
            context[:month] = value.number
            context[:month_name] = value.name
          else
            context[key] = value
          end
        end

        context
      end

      # Render a single page.
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param page_decl [PageDeclaration] The page declaration
      # @param context [Hash] Render context
      def render_page(pdf, page_decl, context)
        page_type = page_decl.type

        # Handle weekly pages specially
        if page_type == :weekly && context[:week_num]
          page = PageFactory.create_weekly_page(context[:week_num], pdf, context)
        else
          page = PageFactory.create(page_type, pdf, context)
        end

        page.generate
      rescue ArgumentError => e
        raise ArgumentError, "Failed to create page '#{page_type}': #{e.message}"
      end
    end
  end
end
