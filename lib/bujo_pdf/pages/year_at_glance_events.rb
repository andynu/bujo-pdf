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
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def year_events_page
          define_page(dest: 'year_events', title: 'Year at a Glance - Events', type: :year_overview) do |ctx|
            YearAtGlanceEvents.new(@pdf, ctx).generate
          end
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
