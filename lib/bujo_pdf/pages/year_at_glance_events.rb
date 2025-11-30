# frozen_string_literal: true

require_relative 'year_at_glance_base'

module BujoPdf
  module Pages
    # Year At Glance - Events page.
    #
    # This page shows a 12×31 grid (months × days) for tracking yearly events.
    # Each cell represents one day and links to the corresponding weekly page.
    #
    # Example:
    #   page = YearAtGlanceEvents.new(pdf, { year: 2025 })
    #   page.generate
    class YearAtGlanceEvents < YearAtGlanceBase
      # Mixin providing the year_events_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the Year at a Glance - Events page.
        #
        # @return [void]
        def year_events_page
          start_new_page
          context = build_context(page_key: :year_events)
          YearAtGlanceEvents.new(@pdf, context).generate
        end
      end

      def page_title
        "Events of #{context[:year]}"
      end

      def destination_name
        'year_events'
      end
    end
  end
end
