# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Chrome drawn over a page imported from another PDF.
    #
    # The builder creates the page from the source PDF as a template and
    # writes its destination, then runs this to add the recipe's sidebars on
    # top. It draws no background and no body, so the imported content shows
    # through untouched.
    class ImportedPage < Base
      def self.background_enabled?
        false
      end

      def render; end
    end
  end
end
