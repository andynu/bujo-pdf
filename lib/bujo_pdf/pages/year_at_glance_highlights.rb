# frozen_string_literal: true

require_relative 'year_at_glance_base'

module BujoPdf
  module Pages
    # Year At Glance - Highlights page.
    #
    # This page shows a 12×31 grid (months × days) for tracking yearly highlights.
    # Each cell represents one day and links to the corresponding weekly page.
    #
    # Example:
    #   page = YearAtGlanceHighlights.new(pdf, { year: 2025 })
    #   page.generate
    class YearAtGlanceHighlights < YearAtGlanceBase
      # Mixin providing the year_highlights_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the Year at a Glance - Highlights page.
        #
        # @return [void]
        def year_highlights_page
          start_new_page
          context = build_context(page_key: :year_highlights)
          YearAtGlanceHighlights.new(@pdf, context).generate
        end
      end

      def page_title
        "Highlights of #{context[:year]}"
      end

      def destination_name
        'year_highlights'
      end
    end
  end
end
