# frozen_string_literal: true

require_relative 'base_layout'

module BujoPdf
  module Layouts
    # Full page layout with no sidebars or navigation.
    #
    # Provides maximum content area (all 43×55 boxes) with no layout chrome.
    # Used for reference/calibration page, blank dot grid page, and other
    # pages that need full control over the entire page area.
    #
    # This is the default layout used when no other layout is specified.
    #
    # @example Use full page layout
    #   class MyPage < Pages::Base
    #     def setup
    #       use_layout :full_page
    #     end
    #   end
    class FullPageLayout < BaseLayout
      # Content area spanning the entire page.
      #
      # @return [Hash] Content area specification with full page dimensions
      def content_area
        {
          col: 0,
          row: 0,
          width_boxes: 43,   # Full page width
          height_boxes: 55   # Full page height
        }
      end

      # No layout components to render before page content.
      #
      # Full page layout has no sidebars or chrome, so this is a no-op.
      #
      # @param page [Pages::Base] The page being rendered (unused)
      # @return [void]
      def render_before(page)
        # No-op: full page has no sidebars or chrome
      end
    end
  end
end
