# frozen_string_literal: true

# PdfDSL module provides a declarative domain-specific language for defining
# complete PDFs from page definitions.
#
# The PDF DSL sits above the Page DSL and handles document-level concerns:
# - Page ordering and grouping
# - Cross-reference resolution (Phase 2)
# - PDF metadata
# - Reusable recipes for common planner configurations (Phase 3)
#
# @example Defining a PDF recipe
#   BujoPdf.define_pdf :standard_planner do |year:, theme: :light|
#     metadata do
#       title "Planner #{year}"
#       author "BujoPdf"
#     end
#
#     theme theme
#
#     page :seasonal_calendar, year: year
#     page :year_events, year: year
#
#     weeks_in(year).each do |week|
#       page :weekly, week: week
#     end
#
#     group :grids, cycle: true do
#       page :grid_dot
#       page :grid_graph
#     end
#   end
#
# @example Generating a PDF
#   BujoPdf.generate :standard_planner, year: 2025, theme: :earth
#
# @example Inline definition
#   BujoPdf.generate year: 2025 do
#     page :seasonal_calendar, year: 2025
#     weeks_in(2025).each do |week|
#       page :weekly, week: week
#     end
#   end
#
module BujoPdf
  module PdfDSL
    # Load all PDF DSL components
    require_relative 'pdf_dsl/pdf_definition'
    require_relative 'pdf_dsl/declaration_context'
    require_relative 'pdf_dsl/page_declaration'
    require_relative 'pdf_dsl/metadata_builder'
    require_relative 'pdf_dsl/week'
    require_relative 'pdf_dsl/pdf_builder'
    require_relative 'pdf_dsl/link_registry'

    # Recipe registry (Phase 3)
    @recipes = {}

    class << self
      attr_reader :recipes

      # Define a named PDF recipe.
      #
      # @param name [Symbol] Recipe name
      # @yield [Hash] Block receiving keyword parameters
      # @return [PdfDefinition] The defined recipe
      #
      # @example
      #   BujoPdf::PdfDSL.define_pdf :minimal_planner do |year:|
      #     page :year_events, year: year
      #     weeks_in(year).each { |week| page :weekly, week: week }
      #   end
      def define_pdf(name, &block)
        definition = PdfDefinition.new(name, &block)
        @recipes[name] = definition
        definition
      end

      # Generate a PDF from a recipe or inline definition.
      #
      # @param name [Symbol, nil] Recipe name (nil for inline)
      # @param output [String, nil] Output file path
      # @param params [Hash] Parameters for the recipe
      # @yield [Hash] Block for inline definition
      # @return [Prawn::Document, String] PDF document or output path
      #
      # @example From recipe
      #   BujoPdf::PdfDSL.generate :standard_planner, year: 2025
      #
      # @example Inline
      #   BujoPdf::PdfDSL.generate year: 2025 do
      #     page :seasonal_calendar, year: 2025
      #   end
      def generate(name = nil, output: nil, **params, &block)
        definition = if block_given?
          PdfDefinition.new(:inline, &block)
        elsif name
          @recipes.fetch(name) { raise ArgumentError, "Unknown recipe: #{name}" }
        else
          raise ArgumentError, "Provide either a recipe name or a block"
        end

        builder = PdfBuilder.new
        builder.build(definition, output: output, **params)
      end

      # Check if a recipe is registered.
      #
      # @param name [Symbol] Recipe name
      # @return [Boolean] true if registered
      def recipe?(name)
        @recipes.key?(name)
      end

      # Clear all registered recipes.
      #
      # Useful for testing.
      def clear_recipes!
        @recipes = {}
      end

      # Load built-in recipes.
      #
      # Call this after requiring pdf_dsl to register standard recipes.
      # Uses load instead of require to allow re-loading after clear_recipes!
      def load_recipes!
        recipe_path = File.expand_path('pdf_dsl/recipes/standard_planner.rb', __dir__)
        load recipe_path
      end
    end
  end

  # Convenience methods at module level
  class << self
    # Define a named PDF recipe.
    #
    # @see PdfDSL.define_pdf
    def define_pdf(name, &block)
      PdfDSL.define_pdf(name, &block)
    end

    # Generate a PDF from a recipe.
    #
    # Note: This overrides the existing generate method.
    # The new version supports both the old API (year, output_path, theme)
    # and the new DSL API (recipe name, keyword params).
    #
    # @overload generate_from_recipe(name, **params)
    #   Generate from a named recipe
    #   @param name [Symbol] Recipe name
    #   @param params [Hash] Recipe parameters
    #   @return [String, Prawn::Document]
    #
    # @overload generate_from_recipe(**params, &block)
    #   Generate from inline definition
    #   @param params [Hash] Parameters
    #   @yield Block containing page declarations
    #   @return [String, Prawn::Document]
    def generate_from_recipe(name = nil, **params, &block)
      PdfDSL.generate(name, **params, &block)
    end
  end
end
