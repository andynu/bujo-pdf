# frozen_string_literal: true

module BujoPdf
  # Factory for creating page instances.
  #
  # The PageFactory manages the registry of available page types and
  # provides methods for instantiating pages with the correct dependencies.
  #
  # Page classes auto-register themselves via the PageRegistry mixin's
  # `register_page` class method, which calls PageFactory.register.
  #
  # Example:
  #   page = PageFactory.create(:weekly, pdf, context)
  #   page.generate
  #
  #   # Manual registration (usually not needed - use register_page in page class)
  #   PageFactory.register(:custom, MyCustomPage)
  #
  class PageFactory
    # Registry mapping page keys to page classes.
    # Starts empty - populated by page classes calling register_page.
    @registry = {}

    class << self
      attr_reader :registry

      # Create a page instance.
      #
      # @param page_key [Symbol] The page type key (e.g., :dots, :seasonal)
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [Hash] Rendering context (year, week_num, etc.)
      # @raise [ArgumentError] if the page type is not registered
      # @return [Pages::Base] A page instance ready to generate
      def create(page_key, pdf, context)
        page_class = registry[page_key]
        raise ArgumentError, "Unknown page type: #{page_key}" unless page_class

        page_class.new(pdf, context)
      end

      # Register a page type.
      #
      # Usually called automatically by PageRegistry.register_page.
      # Can also be called manually for custom page types.
      #
      # @param page_key [Symbol] The page type key to register
      # @param page_class [Class] The page class
      # @return [void]
      def register(page_key, page_class)
        @registry = @registry.merge(page_key => page_class)
      end

      # Create a weekly page instance.
      #
      # This is a specialized factory method for creating weekly pages with
      # the appropriate context (week number, start/end dates).
      #
      # @param week_num [Integer] The week number (1-52 or 1-53)
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [Hash] Base rendering context (must include :year)
      # @return [Pages::Base] A weekly page instance ready to generate
      def create_weekly_page(week_num, pdf, context)
        require_relative 'utilities/date_calculator'
        require_relative 'pages/weekly_page'

        year = context[:year]
        context_with_week = context.merge(
          week_num: week_num,
          week_start: Utilities::DateCalculator.week_start(year, week_num),
          week_end: Utilities::DateCalculator.week_end(year, week_num)
        )

        Pages::WeeklyPage.new(pdf, context_with_week)
      end

      # Create an index page instance.
      #
      # This is a specialized factory method for creating index pages with
      # the appropriate context (index page number, total count).
      #
      # @param index_page_num [Integer] The index page number (1, 2, 3...)
      # @param index_page_count [Integer] Total number of index pages
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param context [Hash] Base rendering context
      # @return [Pages::Base] An index page instance ready to generate
      def create_index_page(index_page_num, index_page_count, pdf, context)
        require_relative 'pages/index_pages'
        require_relative 'render_context'

        context_with_index = context.is_a?(RenderContext) ? context.to_h : context
        context_with_index = context_with_index.merge(
          page_key: "index_#{index_page_num}".to_sym,
          index_page_num: index_page_num,
          index_page_count: index_page_count
        )

        Pages::IndexPage.new(pdf, context_with_index)
      end
    end
  end
end
