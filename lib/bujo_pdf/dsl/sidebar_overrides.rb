# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # Registry for sidebar tab destination overrides.
    #
    # Stores mappings from source pages to tab destinations, allowing
    # customization of where sidebar tabs navigate based on which page
    # the user is currently viewing.
    #
    # @example Setting overrides for weekly pages
    #   overrides = SidebarOverrides.new
    #   overrides.set(from: :week_1, tab: :future, to: :future_log_1)
    #   overrides.set(from: :week_27, tab: :future, to: :future_log_2)
    #
    # @example Looking up an override
    #   overrides.get(:week_1, "Future")  # => "future_log_1"
    #   overrides.get(:week_27, "Future") # => "future_log_2"
    #   overrides.get(:seasonal, "Future") # => nil (no override)
    #
    class SidebarOverrides
      def initialize
        @overrides = {}  # { page_key => { tab_label => dest } }
      end

      # Set an override for a specific page and tab.
      #
      # @param from [Symbol, String] The source page key
      # @param tab [Symbol, String] The tab label (e.g., :future, "Future")
      # @param to [Symbol, String] The destination page key
      # @return [void]
      def set(from:, tab:, to:)
        @overrides[from.to_s] ||= {}
        @overrides[from.to_s][normalize_tab(tab)] = to.to_s
      end

      # Get the override destination for a page and tab.
      #
      # @param page_key [Symbol, String] The current page key
      # @param tab_label [Symbol, String] The tab label
      # @return [String, nil] The override destination, or nil if none set
      def get(page_key, tab_label)
        @overrides.dig(page_key.to_s, normalize_tab(tab_label))
      end

      private

      # Normalize tab label to handle both symbols (:future) and strings ("Future").
      #
      # @param tab [Symbol, String] The tab label
      # @return [String] Normalized lowercase string
      def normalize_tab(tab)
        tab.to_s.downcase
      end
    end
  end
end
