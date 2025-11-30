# frozen_string_literal: true

require_relative 'page_declaration'
require_relative 'metadata_builder'
require_relative 'outline_declaration'
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
      attr_reader :pages, :groups, :metadata_builder, :theme_name, :outline_entries

      # Initialize a new declaration context.
      def initialize
        @pages = []
        @groups = []
        @metadata_builder = nil
        @theme_name = nil
        @current_group = nil
        @outline_entries = []
        @current_section = nil
      end

      # Declare a page.
      #
      # @param type [Symbol] The page type (e.g., :weekly, :seasonal_calendar)
      # @param id [Symbol, nil] Optional explicit page ID
      # @param outline [String, Boolean, nil] Outline entry:
      #   - String: Use as the outline entry title
      #   - true: Auto-derive title from page class's registered title
      #   - nil/false: No outline entry
      # @param params [Hash] Parameters for the page
      # @return [PageDeclaration] The created declaration
      #
      # @example Simple page
      #   page :seasonal_calendar, year: 2025
      #
      # @example With explicit outline title
      #   page :seasonal, id: :seasonal, outline: 'Seasonal Calendar'
      #
      # @example Auto-derive outline title from page registration
      #   page :seasonal, id: :seasonal, outline: true
      #   # Uses the title from: register_page :seasonal, title: "Seasonal Calendar"
      #
      # @example No outline entry (omitted)
      #   page :index, id: :index_2  # No outline
      def page(type, id: nil, outline: nil, **params)
        # Resolve outline: true to the page class's registered title
        outline_title = case outline
        when true
          page_class = PageFactory.registry[type]
          if page_class&.respond_to?(:generate_title)
            page_class.generate_title(params) || type.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
          else
            type.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
          end
        when String
          outline
        else
          nil
        end

        decl = PageDeclaration.new(type, id: id, outline: outline_title, **params)

        if @current_group
          @current_group.add_page(decl)
        end

        @pages << decl

        # Add outline entry if specified
        if outline_title
          add_outline_entry(OutlineDeclaration.new(title: outline_title, dest: id || type))
        end

        decl
      end

      # Declare a group of related pages.
      #
      # @param name [Symbol] The group name
      # @param outline [String, nil] Optional outline entry title for the group
      # @param options [Hash] Group options
      # @option options [Boolean] :cycle Enable cycling through pages
      # @yield Block containing page declarations for this group
      # @return [GroupDeclaration] The created group
      #
      # @example Simple group
      #   group :grids, cycle: true do
      #     page :dot_grid
      #     page :graph_grid
      #   end
      #
      # @example Group with outline entry
      #   group :grids, cycle: true, outline: 'Grid Types Showcase' do
      #     page :grid_showcase, id: :grid_showcase
      #     page :grid_dot, id: :grid_dot
      #   end
      def group(name, outline: nil, **options, &block)
        group_decl = GroupDeclaration.new(name, outline: outline, **options)
        @groups << group_decl

        # Track where to insert the group's outline entry
        # We'll determine the first page destination after evaluating the block
        outline_placeholder_index = nil
        if outline
          outline_placeholder_index = @outline_entries.length
        end

        if block_given?
          previous_group = @current_group
          @current_group = group_decl
          instance_eval(&block)
          @current_group = previous_group
        end

        # Add outline entry for the group if specified
        # Insert at the recorded position (before any pages added during block eval)
        if outline && group_decl.pages.any?
          first_page = group_decl.pages.first
          entry = OutlineDeclaration.new(
            title: outline,
            dest: first_page.id || first_page.type
          )
          @outline_entries.insert(outline_placeholder_index, entry)
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

      # Include another recipe's pages into this definition.
      #
      # This enables recipe composition - building complex PDFs from smaller
      # reusable recipe fragments.
      #
      # @param recipe_name [Symbol] The recipe to include
      # @param params [Hash] Parameters to pass to the included recipe
      # @raise [ArgumentError] if the recipe is not found
      #
      # @example Composing recipes
      #   BujoPdf.define_pdf :weekly_essentials do |year:|
      #     weeks_in(year).each { |w| page :weekly, week: w }
      #   end
      #
      #   BujoPdf.define_pdf :full_planner do |year:|
      #     page :seasonal_calendar, year: year
      #     include_recipe :weekly_essentials, year: year
      #     page :reference
      #   end
      def include_recipe(recipe_name, **params)
        recipe = BujoPdf::PdfDSL.recipes[recipe_name]
        raise ArgumentError, "Unknown recipe: #{recipe_name}. Available: #{BujoPdf::PdfDSL.recipes.keys.join(', ')}" unless recipe

        # Evaluate the included recipe's block in this context
        recipe.evaluate(self, **params)
      end

      # Add an outline entry for a specific destination.
      #
      # Use this for conditional or computed outline entries that don't
      # correspond directly to a page declaration with outline: param.
      #
      # @param dest [Symbol] The destination page ID
      # @param title [String] The outline entry title
      # @return [OutlineDeclaration] The created entry
      #
      # @example Month header pointing to first week
      #   weeks_in(year).each do |week|
      #     page :weekly, id: :"week_#{week.number}", week: week
      #
      #     if week.first_of_month?
      #       outline_entry :"week_#{week.number}", "#{week.month_name} #{year}"
      #     end
      #   end
      def outline_entry(dest, title)
        entry = OutlineDeclaration.new(title: title, dest: dest)
        add_outline_entry(entry)
        entry
      end

      # Create an outline section with nested entries.
      #
      # Pages declared inside an outline_section block inherit that section
      # context - their outline entries become children of the section.
      #
      # @param title [String] The section title in the outline
      # @param dest [Symbol, :first, nil] The destination when clicking the section header
      #   - Symbol: Link to that specific destination
      #   - :first: Link to the first child's destination
      #   - nil: Section header is not clickable (just expands)
      # @yield Block containing page declarations for this section
      # @return [OutlineDeclaration] The created section
      #
      # @example Section with explicit destination
      #   outline_section 'Grids', dest: :grid_showcase do
      #     page :grid_showcase, id: :grid_showcase, outline: 'Grid Showcase'
      #     page :grid_dot, id: :grid_dot, outline: 'Dot Grid'
      #   end
      #
      # @example Section linked to first child
      #   outline_section 'January', dest: :first do
      #     page :monthly_review, id: :review_1, outline: 'Monthly Review'
      #     page :weekly, id: :week_1, outline: 'Week 1'
      #   end
      #
      # @example Non-clickable section header
      #   outline_section 'Reference Pages' do
      #     page :reference, id: :reference, outline: 'Calibration'
      #     page :tracker_example, id: :tracker_example, outline: 'Tracker Ideas'
      #   end
      def outline_section(title, dest: nil, &block)
        section = OutlineDeclaration.new(title: title, dest: dest == :first ? nil : dest)

        # Push section context and evaluate block
        previous_section = @current_section
        @current_section = section
        instance_eval(&block) if block_given?
        @current_section = previous_section

        # Handle dest: :first - link to first child's destination
        if dest == :first && section.children.any?
          section.instance_variable_set(:@dest, section.children.first.dest)
        end

        # Add section to parent (or root)
        if previous_section
          previous_section.add_child(section)
        else
          @outline_entries << section
        end

        section
      end

      private

      # Add an outline entry to the current context.
      #
      # If inside an outline_section, adds as child of that section.
      # Otherwise adds to the root outline entries.
      #
      # @param entry [OutlineDeclaration] The entry to add
      def add_outline_entry(entry)
        if @current_section
          @current_section.add_child(entry)
        else
          @outline_entries << entry
        end
      end
    end
  end
end
