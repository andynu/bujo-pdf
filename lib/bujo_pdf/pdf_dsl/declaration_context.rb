# frozen_string_literal: true

require_relative 'page_declaration'
require_relative 'metadata_builder'
require_relative 'week'

module BujoPdf
  module PdfDSL
    # DeclarationContext provides the DSL methods for PDF definition evaluation.
    #
    # When a PdfDefinition is evaluated, its block runs in the context of this
    # class, collecting page declarations, groups, and metadata.
    #
    # @example Inside a definition block
    #   BujoPdf.define_pdf :my_planner do |year:|
    #     # These methods are provided by DeclarationContext
    #     metadata { title "Planner #{year}" }
    #     theme :earth
    #
    #     page :seasonal_calendar, year: year
    #
    #     weeks_in(year).each do |week|
    #       page :weekly, week: week
    #     end
    #   end
    #
    class DeclarationContext
      attr_reader :pages, :groups, :metadata_builder, :theme_name

      # Initialize a new declaration context.
      def initialize
        @pages = []
        @groups = []
        @metadata_builder = nil
        @theme_name = nil
        @current_group = nil
      end

      # Declare a page.
      #
      # @param type [Symbol] The page type (e.g., :weekly, :seasonal_calendar)
      # @param id [Symbol, nil] Optional explicit page ID
      # @param params [Hash] Parameters for the page
      # @return [PageDeclaration] The created declaration
      #
      # @example
      #   page :seasonal_calendar, year: 2025
      #   page :weekly, week: week, id: :custom_id
      def page(type, id: nil, **params)
        decl = PageDeclaration.new(type, id: id, **params)

        if @current_group
          @current_group.add_page(decl)
        end

        @pages << decl
        decl
      end

      # Declare a group of related pages.
      #
      # @param name [Symbol] The group name
      # @param options [Hash] Group options
      # @option options [Boolean] :cycle Enable cycling through pages
      # @yield Block containing page declarations for this group
      # @return [GroupDeclaration] The created group
      #
      # @example
      #   group :grids, cycle: true do
      #     page :dot_grid
      #     page :graph_grid
      #   end
      def group(name, **options, &block)
        group_decl = GroupDeclaration.new(name, **options)
        @groups << group_decl

        if block_given?
          previous_group = @current_group
          @current_group = group_decl
          instance_eval(&block)
          @current_group = previous_group
        end

        group_decl
      end

      # Set PDF metadata.
      #
      # @yield Block containing metadata DSL calls
      # @return [MetadataBuilder] The metadata builder
      #
      # @example
      #   metadata do
      #     title "My Planner"
      #     author "BujoPdf"
      #   end
      def metadata(&block)
        @metadata_builder = MetadataBuilder.new(&block)
      end

      # Set the theme.
      #
      # @param name [Symbol] The theme name
      # @return [Symbol] The set theme name
      #
      # @example
      #   theme :earth
      def theme(name)
        @theme_name = name
      end

      # Get all weeks in a year.
      #
      # @param year [Integer] The year
      # @return [Array<Week>] All weeks in the year
      #
      # @example
      #   weeks_in(2025).each do |week|
      #     page :weekly, week: week
      #   end
      def weeks_in(year)
        Week.weeks_in(year)
      end

      # Get all months in a year.
      #
      # @param year [Integer] The year
      # @return [Array<Month>] All 12 months
      #
      # @example
      #   months_in(2025).each do |month|
      #     page :monthly_overview, month: month
      #   end
      def months_in(year)
        Month.months_in(year)
      end

      # Iterate over each month with a block.
      #
      # @param year [Integer] The year
      # @yield [Month] Each month
      #
      # @example
      #   each_month(2025) do |month|
      #     page :monthly_overview, month: month
      #   end
      def each_month(year, &block)
        months_in(year).each(&block)
      end

      # Iterate over weeks in a month or year.
      #
      # @param month_or_year [Month, Integer] Either a Month object or year integer
      # @yield [Week] Each week
      #
      # @example
      #   each_week(month) do |week|
      #     page :weekly, week: week
      #   end
      def each_week(month_or_year, &block)
        weeks = case month_or_year
        when Month
          month_or_year.weeks
        when Integer
          weeks_in(month_or_year)
        else
          raise ArgumentError, "Expected Month or Integer, got #{month_or_year.class}"
        end

        weeks.each(&block)
      end

      # Get the metadata hash for Prawn.
      #
      # @return [Hash] Metadata suitable for Prawn::Document.new, or empty hash
      def prawn_metadata
        @metadata_builder&.to_prawn_info || {}
      end
    end
  end
end
