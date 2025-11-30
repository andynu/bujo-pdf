# frozen_string_literal: true

module BujoPdf
  module Pages
    # Shared helpers for page verb mixins.
    #
    # This module provides common functionality needed by all page mixins,
    # including smart page creation and context building. Include this in
    # each page's Mixin module to access these helpers.
    #
    # Instance Variable Contract:
    # Classes including page mixins must provide these instance variables:
    # - @pdf [Prawn::Document] - The PDF document
    # - @year [Integer] - The year being generated
    # - @date_config [DateConfiguration, nil] - Date configuration
    # - @event_store [EventStore, nil] - Calendar events
    # - @total_pages [Integer, nil] - Total pages (estimate)
    #
    # Example:
    #   class WeeklyPage < Base
    #     module Mixin
    #       include MixinSupport
    #
    #       def weekly_page(week:)
    #         start_new_page
    #         context = build_context(page_key: "week_#{week}".to_sym, week_num: week)
    #         WeeklyPage.new(@pdf, context).generate
    #       end
    #     end
    #   end
    module MixinSupport
      private

      # Define a page with explicit metadata.
      #
      # During the define phase (when @defining is true), this creates a PageRef
      # with the provided metadata and stores the render block for later execution.
      # During the render phase, it simply executes the render block.
      #
      # @param dest [String] Named destination for PDF linking
      # @param title [String] Display title for the page
      # @param type [Symbol] Type identifier (e.g., :index, :weekly, :seasonal)
      # @param metadata [Hash] Optional additional metadata
      # @yield Block containing the page rendering logic
      # @return [PageRef, nil] The PageRef during define phase, nil during render
      #
      # @example Simple page
      #   def seasonal_calendar
      #     define_page(dest: 'seasonal', title: 'Seasonal Calendar', type: :seasonal) do
      #       start_new_page
      #       context = build_context(page_key: :seasonal)
      #       SeasonalCalendar.new(@pdf, context).generate
      #     end
      #   end
      #
      # @example Parameterized page
      #   def weekly_page(week:)
      #     define_page(dest: "week_#{week}", title: "Week #{week}", type: :weekly) do
      #       start_new_page
      #       context = build_context(page_key: "week_#{week}".to_sym, week_num: week)
      #       WeeklyPage.new(@pdf, context).generate
      #     end
      #   end
      def define_page(dest:, title:, type:, **metadata, &render_block)
        if @defining
          # Define phase: create PageRef with stored render block
          ref = PageRef.new(
            dest_name: dest,
            title: title,
            page_type: type,
            metadata: metadata,
            render_block: render_block
          )

          # Add to current page set if active
          @current_builder_page_set&.add(ref)

          @pages << ref
          ref
        else
          # Render phase: just execute the block
          render_block.call
          nil
        end
      end

      # Create a page set and iterate over its pages.
      #
      # The page_set DSL allows builders to declare multi-page spreads.
      # Pages generated inside the block automatically have context.set
      # populated with the current page position (page, total, label).
      #
      # @param count [Integer] Number of pages in the set
      # @param label [String, nil] Label pattern with %page/%total placeholders
      # @param name [String, nil] Set name (extracted from label if not provided)
      # @yield [PageSet] The page set for the current iteration
      # @return [PageSet, nil] The PageSet if no block given, nil otherwise
      #
      # @example Generate 4 index pages with labels
      #   page_set(4, "Index %page of %total") do |set|
      #     index_page  # context.set.label => "Index 1 of 4", etc.
      #   end
      #
      # @example Generate pages with custom name
      #   page_set(2, name: "Future Log") do |set|
      #     future_log_page
      #   end
      def page_set(count, label = nil, name: nil)
        set = PageSetContext.new(count: count, label: label, name: name)
        return set unless block_given?

        set.each do |i|
          @current_page_set = set
          @current_page_set_index = i
          yield set
        end
      ensure
        @current_page_set = nil
        @current_page_set_index = nil
      end

      # Start a new page, but no-op if on the initial blank page.
      #
      # Prawn documents start with page_count=1 (an initial blank page).
      # This method only adds a new page if content has been rendered,
      # allowing verbs to always call start_new_page without checking
      # whether they're generating the first page of the document.
      #
      # @return [void]
      def start_new_page
        # page_count > 1 means we've started additional pages beyond the initial
        # We track first page usage via @first_page_used instance variable
        if @first_page_used
          @pdf.start_new_page
        else
          @first_page_used = true
        end
      end

      # Build a RenderContext with common fields pre-filled.
      #
      # This helper pre-populates the context with standard fields that
      # most pages need (year, total_weeks, etc.), while allowing each
      # verb to add page-specific fields via **extras.
      #
      # @param page_key [Symbol] Unique identifier for this page
      # @param extras [Hash] Additional context fields
      # @return [RenderContext] Fully populated context
      def build_context(page_key:, **extras)
        ctx = RenderContext.new(
          page_key: page_key,
          page_number: @pdf.page_number,
          year: @year,
          total_weeks: total_weeks,
          total_pages: @total_pages,
          date_config: @date_config,
          event_store: @event_store,
          **extras
        )

        # Attach page set context if inside a page_set block
        if @current_page_set
          ctx.set = @current_page_set[@current_page_set_index]
        end

        ctx
      end

      # Get total weeks for the current year (cached).
      #
      # @return [Integer] Number of weeks in the year
      def total_weeks
        @total_weeks ||= Utilities::DateCalculator.total_weeks(@year)
      end
    end
  end
end
