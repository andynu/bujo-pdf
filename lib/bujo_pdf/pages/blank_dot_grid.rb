# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Blank dot grid template page.
    #
    # This page renders a simple full-page dot grid that can be used as
    # a template for additional pages. It's the simplest page type and
    # serves as a good example of the minimal page implementation.
    #
    # Example:
    #   page = BlankDotGrid.new(pdf, { year: 2025 })
    #   page.generate
    class BlankDotGrid < Base
      # Set up the named destination for this page.
      def setup
        set_destination('dots')
      end

      # Render the dot grid across the entire page.
      def render
        draw_dot_grid
      end
    end
  end
end
