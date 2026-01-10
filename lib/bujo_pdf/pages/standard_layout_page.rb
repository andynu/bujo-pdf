# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Base class for pages that use the standard sidebar layout.
    #
    # With the new chrome inheritance system, this class is now a thin
    # organizational layer. Pages that inherit from StandardLayoutPage
    # automatically get sidebars from PDF chrome config, with current
    # week and tab highlighting auto-detected from page_key.
    #
    # This class remains for:
    # - Organizational grouping of sidebar pages
    # - Backward compatibility with existing subclasses
    #
    # Subclasses typically inherit from this when they want sidebars
    # and the default auto-detection behavior.
    #
    # @example Year overview page
    #   class YearAtGlanceEvents < StandardLayoutPage
    #     def render
    #       # Tab highlighting auto-detected from page_key :year_events
    #     end
    #   end
    #
    # @example Weekly page
    #   class WeeklyPage < StandardLayoutPage
    #     def render
    #       # Week highlighting auto-detected from page_key :week_42
    #     end
    #   end
    class StandardLayoutPage < Base
      # No explicit use_layout needed: inherits PDF chrome, auto-detects
      # current_week and highlight_tab from page_key context.
      #
      # Subclasses can override setup to call super and add their own
      # setup logic (e.g., set_destination, initialize instance vars).
    end
  end
end
