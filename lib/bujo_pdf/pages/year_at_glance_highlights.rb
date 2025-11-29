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
      def page_title
        "Highlights of #{context[:year]}"
      end

      def destination_name
        'year_highlights'
      end
    end
  end
end
