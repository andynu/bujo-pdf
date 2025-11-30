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
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def year_highlights_page
          define_page(dest: 'year_highlights', title: 'Year at a Glance - Highlights', type: :year_overview) do |ctx|
            YearAtGlanceHighlights.new(@pdf, ctx).generate
          end
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
