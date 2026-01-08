# frozen_string_literal: true

require_relative 'page_declaration'
require_relative 'inline_page'
require_relative 'metadata'
require_relative 'outline'
require_relative 'sidebar_overrides'
require_relative 'week'

module BujoPdf
  module PdfDSL
    # DeclarationContext provides the DSL methods for PDF definition evaluation.
    #
    # ## Outline System
    #
    # The DSL supports three outline modes controlled by {#outline_mode}:
    #
    # - **:manual** (default): Only pages with explicit `outline:` params get entries.
    #   Backward compatible with existing recipes.
    # - **:auto**: Automatically generates outline entries from page registry titles.
    #   Groups create hierarchical sections. Use `outline: false` to suppress.
    # - **:none**: Disables all outline generation.
    #
    # See {#create_standard_page} and {#create_inline_page} for resolution logic.
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
      attr_reader :pages, :groups, :metadata_builder, :theme_name, :outline_entries, :sidebar_overrides,
                  :current_outline_mode

      # Initialize a new declaration context.
      def initialize
        @pages = []
        @groups = []
        @metadata_builder = nil
        @theme_name = nil
        @current_group = nil
        @outline_entries = []
        @current_section = nil
        @sidebar_overrides = SidebarOverrides.new
        @current_outline_mode = :manual
      end

      # Set the outline generation mode.
      #
      # @param mode [Symbol] The outline mode
      #   - :manual - Outline entries only added when explicitly specified (default)
      #   - :auto - Automatically generate outline entries from page registry titles
      #   - :none - No outline entries are generated
      # @return [Symbol] The set outline mode
      #
      # @example Enable automatic outline generation
      #   outline_mode :auto
      def outline_mode(mode)
        valid_modes = %i[manual auto none]
        raise ArgumentError, "Invalid outline mode: #{mode}. Must be one of: #{valid_modes.join(', ')}" unless valid_modes.include?(mode)

        @current_outline_mode = mode
      end

      # Declare a page.
      #
      # Supports two modes:
      # 1. Reference a predefined page type: page :seasonal_calendar, year: 2025
      # 2. Define an inline page with a block: page id: :notes do ... end
      #
      # @overload page(type, id: nil, outline: nil, **params)
      #   Reference a predefined page type.
      #   @param type [Symbol] The page type (e.g., :weekly, :seasonal_calendar)
      #   @param id [Symbol, nil] Optional explicit page ID
      #   @param outline [String, Boolean, nil] Outline entry
      #   @param params [Hash] Parameters for the page
      #   @return [PageDeclaration] The created declaration
      #
      # @overload page(id: nil, outline: nil, **params, &block)
      #   Define an inline page with a block.
      #   @param id [Symbol, nil] Optional explicit page ID
      #   @param outline [String, Boolean, nil] Outline entry
      #   @param params [Hash] Additional parameters
      #   @yield Block defining inline page configuration and body
      #   @return [InlinePageDeclaration] The created inline declaration
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
      #
      # @example Inline page with block
      #   page id: :notes, outline: 'Notes' do
      #     layout :full_page
      #     background :ruled
      #
      #     body do
      #       h1(2, 1, "Notes")
      #       ruled_lines(2, 3, 38, 50)
      #     end
      #   end
      #
      # @example Minimal inline page
      #   page do
      #     body do
      #       h1(2, 1, "Blank")
      #     end
      #   end
      def page(type = nil, id: nil, outline: nil, **params, &block)
        if block_given?
          # Inline page definition with block
          create_inline_page(id: id, outline: outline, params: params, &block)
        else
          # Standard page type reference
          raise ArgumentError, 'page type is required when not using a block' if type.nil?

          create_standard_page(type, id: id, outline: outline, **params)
        end
      end

      # Declare a group of related pages.
      #
      # In :auto outline mode, groups automatically create hierarchical outline entries.
      # Pages declared inside the group become children of the group's outline section.
      #
      # @param name [Symbol] The group name
      # @param outline [String, Boolean, nil] Outline entry title for the group
      #   - String: Use this as the section title
      #   - false: Suppress the group entry (pages appear at current level)
      #   - nil: In :auto mode, derive title from name; in :manual mode, no section
      # @param options [Hash] Group options
      # @option options [Boolean] :cycle Enable cycling through pages
      # @yield Block containing page declarations for this group
      # @return [GroupDeclaration] The created group
      #
      # @example Simple group (auto mode creates section)
      #   outline_mode :auto
      #   group :monthly_pages do
      #     page :monthly_overview, id: :january, month: 1, year: 2025
      #   end
      #   # Creates: "Monthly Pages" section with child entries
      #
      # @example Group with explicit outline title
      #   group :months, outline: 'All Months' do
      #     page :monthly_overview, id: :january, month: 1, year: 2025
      #   end
      #
      # @example Suppress group outline entry (pages at root level)
      #   group :grids, outline: false do
      #     page :dot_grid, id: :dot_grid
      #   end
      def group(name, outline: nil, **options, &block)
        group_decl = GroupDeclaration.new(name, outline: outline, **options)
        @groups << group_decl

        # Determine effective outline title for the group
        # - outline: false -> no section, pages appear at current level
        # - outline: "Title" -> use that title
        # - outline: nil + auto mode -> derive from name
        # - outline: nil + manual mode -> no section
        effective_outline = determine_group_outline_title(name, outline)

        if block_given?
          previous_group = @current_group
          @current_group = group_decl

          if effective_outline
            # Create a section for the group; pages inside will be children
            # We use :first so the section links to its first child's destination
            outline_section(effective_outline, dest: :first) do
              instance_eval(&block)
            end
          else
            # No section - pages appear at current outline level
            instance_eval(&block)
          end

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

      # Set a sidebar tab destination override for a specific page.
      #
      # Allows customizing which destination a sidebar tab navigates to
      # when viewing a particular page. Useful for context-aware navigation,
      # e.g., weekly pages linking to the appropriate Future Log based on month.
      #
      # @param from [Symbol, String] The source page key (e.g., :week_27)
      # @param tab [Symbol, String] The tab label (e.g., :future, "Future")
      # @param to [Symbol, String] The destination page key (e.g., :future_log_2)
      # @return [void]
      #
      # @example Set Future Log destination based on week's month
      #   weeks_in(year).each do |week|
      #     future_dest = week.start_date.month <= 6 ? :future_log_1 : :future_log_2
      #     set_sidebar_dest from: :"week_#{week.number}", tab: :future, to: future_dest
      #     page :weekly, week: week
      #   end
      def set_sidebar_dest(from:, tab:, to:)
        @sidebar_overrides.set(from: from, tab: tab, to: to)
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

      # Create a standard page declaration referencing a predefined page type.
      #
      # This method handles the outline resolution logic for standard pages:
      #
      # 1. **:none mode**: Never creates outline entries, regardless of outline param
      # 2. **explicit false**: Suppresses outline even in :auto mode (takes precedence)
      # 3. **:auto mode with nil**: Treats nil as true, auto-generates from registry
      # 4. **:manual mode with nil**: No outline entry (backward compatible default)
      # 5. **outline: true**: Resolves title from page class's generate_title method
      # 6. **outline: "Title"**: Uses the explicit string
      #
      # @param type [Symbol] The page type (e.g., :weekly, :seasonal_calendar)
      # @param id [Symbol, nil] Optional explicit page ID for the destination
      # @param outline [String, Boolean, nil] Outline entry specification
      # @param params [Hash] Parameters passed to the page class
      # @return [PageDeclaration] The created declaration
      #
      # @see resolve_outline_title for title generation from page registry
      def create_standard_page(type, id: nil, outline: nil, **params)
        # In :none mode, never add outline entries
        return create_standard_page_without_outline(type, id: id, **params) if @current_outline_mode == :none

        # IMPORTANT: Check for explicit outline: false BEFORE checking auto mode.
        # This allows users to suppress auto-generated outline entries for specific pages
        # even when outline_mode :auto is enabled. The explicit false takes precedence.
        return create_standard_page_without_outline(type, id: id, **params) if outline == false

        # Determine effective outline setting based on mode
        effective_outline = outline
        if outline.nil? && @current_outline_mode == :auto
          # Auto mode: treat nil as true (auto-generate title from registry)
          effective_outline = true
        end

        # Resolve outline: true to the page class's registered title
        outline_title = resolve_outline_title(type, effective_outline, params)

        decl = PageDeclaration.new(type, id: id, outline: outline_title, **params)
        add_page_declaration(decl, outline_title, id || type)
        decl
      end

      # Create a standard page without any outline entry.
      #
      # @param type [Symbol] The page type
      # @param id [Symbol, nil] Optional explicit page ID
      # @param params [Hash] Parameters for the page
      # @return [PageDeclaration] The created declaration
      def create_standard_page_without_outline(type, id: nil, **params)
        decl = PageDeclaration.new(type, id: id, outline: nil, **params)
        add_page_declaration(decl, nil, id || type)
        decl
      end

      # Create an inline page declaration from a block.
      #
      # This method handles the outline resolution logic for inline pages:
      #
      # 1. **:none mode**: Never creates outline entries
      # 2. **explicit false**: Suppresses outline even in :auto mode
      # 3. **:auto mode with nil**: Treats nil as true, derives title from id
      # 4. **:manual mode with nil**: No outline entry
      # 5. **outline: true**: Derives title from id (e.g., :my_notes -> "My Notes")
      # 6. **outline: "Title"**: Uses the explicit string
      #
      # Unlike standard pages, inline pages don't have a page registry entry,
      # so `outline: true` derives the title from the page id using title case.
      #
      # @param id [Symbol, nil] Optional explicit page ID (also used for title derivation)
      # @param outline [String, Boolean, nil] Outline entry specification
      # @param params [Hash] Additional parameters passed to the inline page
      # @yield Block defining inline page configuration (layout, background, body)
      # @return [InlinePageDeclaration] The created inline declaration
      def create_inline_page(id: nil, outline: nil, params: {}, &block)
        # Create context and evaluate the block
        inline_context = InlinePageContext.new
        inline_context.evaluate(&block)

        # Determine effective outline setting based on mode.
        # Check priority: :none mode > explicit false > auto mode > default
        effective_outline = outline
        if @current_outline_mode == :none
          # In :none mode, never add outline entries
          effective_outline = false
        elsif outline == false
          # IMPORTANT: Check for explicit outline: false BEFORE checking auto mode.
          # This allows users to suppress auto-generated outline entries for specific pages
          # even when outline_mode :auto is enabled. The explicit false takes precedence.
          effective_outline = false
        elsif outline.nil? && @current_outline_mode == :auto
          # Auto mode: treat nil as true (auto-generate title from id)
          effective_outline = true
        end

        # Resolve outline title (for inline pages, true uses id-derived title)
        outline_title = case effective_outline
        when true
          id&.to_s&.tr('_', ' ')&.split&.map(&:capitalize)&.join(' ') || 'Untitled'
        when String
          effective_outline
        else
          nil
        end

        decl = InlinePageDeclaration.new(
          id: id,
          outline: outline_title,
          inline_context: inline_context,
          **params
        )
        add_page_declaration(decl, outline_title, id)
        decl
      end

      # Resolve outline title based on outline parameter type.
      #
      # @param type [Symbol] Page type
      # @param outline [String, Boolean, nil] Outline specification
      # @param params [Hash] Page parameters
      # @return [String, nil] Resolved outline title
      def resolve_outline_title(type, outline, params)
        case outline
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
      end

      # Add a page declaration to the context.
      #
      # @param decl [PageDeclaration, InlinePageDeclaration] The declaration
      # @param outline_title [String, nil] Outline title if any
      # @param dest [Symbol] Destination for outline entry
      # @return [void]
      def add_page_declaration(decl, outline_title, dest)
        @current_group&.add_page(decl)
        @pages << decl

        # Add outline entry if specified
        if outline_title && dest
          add_outline_entry(OutlineDeclaration.new(title: outline_title, dest: dest))
        end
      end

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

      # Determine the effective outline title for a group.
      #
      # This method controls whether groups create hierarchical outline sections:
      #
      # - **outline: false**: No section created; pages appear at current level
      # - **outline: "Title"**: Creates section with explicit title
      # - **outline: nil + :auto mode**: Creates section with title from group name
      #   (e.g., :monthly_pages -> "Monthly Pages")
      # - **outline: nil + :manual mode**: No section created (backward compatible)
      #
      # When a section is created, all pages declared inside the group block
      # become children of that section in the PDF outline hierarchy.
      #
      # @param name [Symbol] The group name (used for title derivation in :auto mode)
      # @param outline [String, Boolean, nil] The outline parameter from group()
      # @return [String, nil] The title to use, or nil if no section should be created
      def determine_group_outline_title(name, outline)
        case outline
        when false
          # Explicitly suppressed
          nil
        when String
          # Explicit title provided
          outline
        when nil
          # Derive from name in auto mode, no section in manual mode
          if @current_outline_mode == :auto
            name.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
          else
            nil
          end
        else
          nil
        end
      end
    end
  end
end
