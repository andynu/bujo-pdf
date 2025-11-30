# frozen_string_literal: true

require_relative 'page_set_context'

module BujoPdf
  # Collection of related pages with pagination context.
  #
  # PageSet holds PageRef objects and assigns set context to each page
  # upon finalization. This enables automatic "page X of Y" labeling,
  # coordinated outline generation, and cycling navigation for multi-page spreads.
  #
  # Two usage patterns are supported:
  #
  # 1. **Deferred finalization** (new DSL): Add pages during define phase,
  #    then call finalize! to compute totals and assign contexts.
  #
  # 2. **Upfront count** (legacy): Provide count at initialization for
  #    backward compatibility with existing code.
  #
  # @example Deferred finalization (new DSL)
  #   set = PageSet.new(name: :index, label_pattern: 'Index %page of %total')
  #   set.add(page_ref_1)
  #   set.add(page_ref_2)
  #   set.finalize!
  #   page_ref_1.set_context.label  # => "Index 1 of 2"
  #
  # @example Upfront count (legacy)
  #   set = PageSet.new(name: :index, count: 2, label_pattern: 'Index %page of %total')
  #   set.add(page_ref_1)  # context assigned immediately
  #   set.add(page_ref_2)
  #
  # @example Cycling navigation
  #   set = PageSet.new(name: :grids, cycle: true)
  #   set.add(grid_showcase_ref)
  #   set.add(grids_overview_ref)
  #   set.finalize!
  #   set.destination_keys  # => ["grid_showcase", "grids_overview"]
  #
  class PageSet
    include Enumerable

    attr_reader :name, :label_pattern, :pages

    # Create a new PageSet.
    #
    # @param name [String, Symbol] Display name for the set (used in outlines)
    # @param count [Integer, nil] Expected page count (if known upfront)
    # @param label_pattern [String, nil] Pattern with %page and %total placeholders
    # @param cycle [Boolean] Enable cycling navigation through pages
    def initialize(name:, count: nil, label_pattern: nil, cycle: false)
      @name = name.to_s
      @count = count
      @label_pattern = label_pattern || default_label_pattern
      @cycle = cycle
      @pages = []
      @finalized = false
    end

    # Add a page reference to this set.
    #
    # If count was provided at initialization (legacy mode), assigns
    # context immediately. Otherwise, context is assigned during finalize!.
    #
    # @param page_ref [PageRef] The page to add
    # @return [PageRef] The same page_ref (for chaining)
    # @raise [RuntimeError] if set has been finalized
    def add(page_ref)
      raise "PageSet '#{@name}' already finalized" if @finalized

      @pages << page_ref

      # Legacy mode: assign context immediately if count is known
      if @count
        assign_context_to_page(page_ref, @pages.length, @count)
      end

      page_ref
    end

    # Finalize the set and assign contexts to all pages.
    #
    # Called after all pages have been added. Computes totals and
    # assigns PageSetContext::Context to each page's set_context.
    #
    # In legacy mode (count provided), this is a no-op since contexts
    # were assigned during add().
    #
    # @return [void]
    def finalize!
      return if @finalized

      # Only need to assign contexts if we didn't have count upfront
      unless @count
        total = @pages.size
        @pages.each_with_index do |page_ref, index|
          assign_context_to_page(page_ref, index + 1, total)
        end
      end

      @finalized = true
    end

    # Check if the set has been finalized.
    #
    # @return [Boolean] true if finalize! has been called
    def finalized?
      @finalized
    end

    # Check if cycling navigation is enabled.
    #
    # @return [Boolean] true if tab clicking should cycle through pages
    def cycle?
      @cycle
    end

    # Get destination keys for all pages (used for cycling navigation).
    #
    # @return [Array<String>] Destination names in order
    def destination_keys
      @pages.map { |p| p.dest_name.to_s }
    end

    # Iterate over page references.
    #
    # @yield [PageRef] Each page in the set
    # @return [Enumerator] if no block given
    def each(&block)
      @pages.each(&block)
    end

    # Get a page by index.
    #
    # @param index [Integer] 0-based index
    # @return [PageRef, nil] The page at that index
    def [](index)
      @pages[index]
    end

    # Get the first page in the set.
    #
    # @return [PageRef, nil]
    def first
      @pages.first
    end

    # Get the last page in the set.
    #
    # @return [PageRef, nil]
    def last
      @pages.last
    end

    # Get the number of pages currently in the set.
    #
    # @return [Integer]
    def size
      @pages.length
    end

    # Get outline entry for PDF bookmarks.
    #
    # @return [Hash] Hash with :destination and :title keys
    def outline_entry
      { destination: first&.pdf_page_number, title: @name }
    end

    private

    # Default label pattern based on set name.
    #
    # @return [String] Pattern like "Index %page of %total"
    def default_label_pattern
      humanized_name = @name.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
      "#{humanized_name} %page of %total"
    end

    # Assign set context to a page.
    #
    # @param page_ref [PageRef] The page to update
    # @param position [Integer] 1-based position in set
    # @param total [Integer] Total pages in set
    # @return [void]
    def assign_context_to_page(page_ref, position, total)
      page_ref.set_context = PageSetContext::Context.new(
        page: position,
        total: total,
        label: interpolate_label(position, total),
        name: @name
      )
    end

    # Interpolate label pattern with page number and total.
    #
    # @param position [Integer] 1-based position
    # @param total [Integer] Total pages
    # @return [String, nil] Interpolated label
    def interpolate_label(position, total)
      return nil unless @label_pattern

      @label_pattern
        .gsub('%page', position.to_s)
        .gsub('%total', total.to_s)
    end
  end
end
