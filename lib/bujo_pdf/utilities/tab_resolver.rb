# frozen_string_literal: true

module BujoPdf
  module Utilities
    # TabResolver provides reusable logic for resolving tab destinations.
    #
    # This utility extracts the common pattern of resolving tab configurations
    # to actual destinations with current-page highlighting. It supports:
    #
    # - Single destinations (String/Symbol)
    # - Multi-destination arrays for cyclic navigation
    # - Page context-aware current page detection
    # - Highlight tab fallback for pre-render configuration
    # - Sidebar override lookups
    #
    # @example Basic usage with single destination
    #   resolver = TabResolver.new(page_context: context)
    #   resolved = resolver.resolve(label: "Year", dest: :seasonal)
    #   # => { label: "Year", dest: "seasonal", current: true/false }
    #
    # @example Cyclic destination
    #   resolver = TabResolver.new(page_context: context)
    #   resolved = resolver.resolve(label: "Grids", dest: [:grids_overview, :grid_dot])
    #   # => { label: "Grids", dest: "grid_dot", current: true } if on grids_overview
    #
    # @example Resolving multiple tabs
    #   resolver = TabResolver.new(page_context: context)
    #   tabs = [
    #     { label: "Year", dest: :seasonal },
    #     { label: "Grids", dest: [:grids_overview, :grid_dot] }
    #   ]
    #   resolved_tabs = resolver.resolve_all(tabs)
    class TabResolver
      # Initialize a new TabResolver.
      #
      # @param page_context [Object, nil] Context object with current_page? method
      # @param highlight_tab [Symbol, String, nil] Pre-configured highlight override
      # @param sidebar_overrides [Object, nil] Sidebar override configuration
      def initialize(page_context: nil, highlight_tab: nil, sidebar_overrides: nil)
        @page_context = page_context
        @highlight_tab = highlight_tab
        @sidebar_overrides = sidebar_overrides
      end

      # Resolve a single tab configuration to a destination with current state.
      #
      # @param tab [Hash] Tab configuration with :label and :dest keys
      # @option tab [String] :label Display label for the tab
      # @option tab [String, Symbol, Array] :dest Destination or array of destinations
      # @return [Hash] Resolved tab with :label, :dest (String), and :current (Boolean)
      def resolve(tab)
        dest = tab[:dest]

        # Already-resolved tab (has :current key) passes through
        return tab if tab.key?(:current)

        # Single destination: simple pass-through with highlighting
        if dest.is_a?(String) || dest.is_a?(Symbol)
          return {
            label: tab[:label],
            dest: dest.to_s,
            current: current_page?(dest) || highlight_matches?(dest)
          }
        end

        # Multi-destination array: compute cycle
        if dest.is_a?(Array)
          return resolve_cyclic_destination(tab[:label], dest)
        end

        # Unexpected type: raise error
        raise ArgumentError, "Tab destination must be String, Symbol, or Array, got #{dest.class}"
      end

      # Resolve multiple tabs at once.
      #
      # @param tabs [Array<Hash>] Array of tab configurations
      # @return [Array<Hash>] Array of resolved tabs
      def resolve_all(tabs)
        tabs.map { |tab| resolve(tab) }
      end

      private

      # Check if currently rendering a specific page.
      #
      # @param dest [Symbol, String] Destination to check
      # @return [Boolean] True if on specified page
      def current_page?(dest)
        return false unless @page_context

        if @page_context.respond_to?(:current_page?)
          @page_context.current_page?(dest)
        elsif @page_context.is_a?(Hash) && @page_context[:page_key]
          @page_context[:page_key].to_s == dest.to_s
        else
          false
        end
      end

      # Check if highlight_tab option matches destination.
      #
      # @param dest [Symbol, String] Destination to check
      # @return [Boolean] True if highlight_tab matches
      def highlight_matches?(dest)
        return false unless @highlight_tab

        @highlight_tab.to_s == dest.to_s
      end

      # Resolve cyclic destination for multi-tap navigation.
      #
      # @param label [String] Tab label
      # @param dest_array [Array<Symbol>] Array of destination page keys
      # @return [Hash] Resolved tab with :label, :dest, and :current
      def resolve_cyclic_destination(label, dest_array)
        # Find current page in cycle
        current_index = dest_array.index { |d| current_page?(d) }

        # Also check if highlight_tab matches any page in cycle
        highlight_index = if @highlight_tab
                            dest_array.index { |d| d.to_s == @highlight_tab.to_s }
                          end

        # Determine which index to use (prefer current_index from actual page)
        active_index = current_index || highlight_index

        if active_index
          # In cycle: advance to next page (wrap around), highlighted
          next_index = (active_index + 1) % dest_array.size
          return {
            label: label,
            dest: dest_array[next_index].to_s,
            current: true
          }
        end

        # Not in cycle: check for sidebar override
        if @page_context.is_a?(Hash)
          page_key = @page_context[:page_key]
          if @sidebar_overrides
            override = @sidebar_overrides.get(page_key, label)
            if override
              return {
                label: label,
                dest: override,
                current: false
              }
            end
          end
        end

        # Default: go to first page (entry point), not highlighted
        {
          label: label,
          dest: dest_array.first.to_s,
          current: false
        }
      end
    end
  end
end
