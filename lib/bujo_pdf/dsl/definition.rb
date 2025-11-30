# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # PdfDefinition represents a named PDF recipe.
    #
    # A PDF definition is a reusable template that specifies what pages to include
    # and how to configure them. Definitions are evaluated with parameters to
    # produce a list of page declarations.
    #
    # @example Defining a PDF recipe
    #   definition = PdfDefinition.new(:standard_planner) do |year:, theme: :light|
    #     metadata { title "Planner #{year}" }
    #     theme theme
    #     page :seasonal_calendar, year: year
    #     weeks_in(year).each { |week| page :weekly, week: week }
    #   end
    #
    # @example Evaluating a definition
    #   context = DeclarationContext.new
    #   definition.evaluate(context, year: 2025)
    #   # context.pages now contains all declared pages
    #
    class PdfDefinition
      attr_reader :name, :block

      # Initialize a new PDF definition.
      #
      # @param name [Symbol] The recipe name
      # @param block [Proc] The definition block
      def initialize(name, &block)
        @name = name
        @block = block
      end

      # Evaluate the definition with the given parameters.
      #
      # Executes the definition block in the context of a DeclarationContext,
      # passing the provided parameters as keyword arguments.
      #
      # @param context [DeclarationContext] Context to collect declarations
      # @param params [Hash] Parameters to pass to the block
      # @return [void]
      def evaluate(context, **params)
        context.instance_exec(**params, &@block)
      end
    end
  end
end
