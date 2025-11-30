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

      # Start a new page, but no-op if this is the first page.
      #
      # This allows verbs to always call start_new_page without checking
      # whether they're generating the first page of the document.
      #
      # @return [void]
      def start_new_page
        @pdf.start_new_page if @pdf.page_count > 0
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
        RenderContext.new(
          page_key: page_key,
          page_number: @pdf.page_number,
          year: @year,
          total_weeks: total_weeks,
          total_pages: @total_pages,
          date_config: @date_config,
          event_store: @event_store,
          **extras
        )
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
