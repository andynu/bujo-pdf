# frozen_string_literal: true

module BujoPdf
  # Collection of related pages with pagination context.
  #
  # PageSet holds PageRef objects and assigns set context to each page
  # when added. This enables automatic "page X of Y" labeling and
  # coordinated outline generation for multi-page spreads.
  #
  # @example Creating a page set with pages
  #   set = PageSet.new(name: 'Index', count: 2, label_pattern: 'Index %page of %total')
  #   ref1 = PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
  #   ref2 = PageRef.new(dest_name: 'index_2', title: 'Index', page_type: :index)
  #   set.add(ref1)
  #   set.add(ref2)
  #   ref1.set_context.label  # => "Index 1 of 2"
  #   ref1.set_context.first? # => true
  #
  # @example Iterating over pages
  #   set.each { |page_ref| render(page_ref) }
  #
  class PageSet
    include Enumerable

    attr_reader :name, :label_pattern, :count

    # Create a new PageSet.
    #
    # @param name [String] Display name for the set (used in outlines)
    # @param count [Integer] Expected number of pages in this set
    # @param label_pattern [String, nil] Pattern with %page and %total placeholders
    def initialize(name:, count:, label_pattern: nil)
      @name = name
      @count = count
      @label_pattern = label_pattern
      @pages = []
    end

    # Add a page reference to this set.
    #
    # Assigns set context to the page with position information.
    #
    # @param page_ref [PageRef] The page to add
    # @return [PageRef] The same page_ref (for chaining)
    def add(page_ref)
      position = @pages.length + 1
      page_ref.set_context = SetContext.new(
        page: position,
        total: @count,
        label: interpolate_label(position),
        set_name: @name
      )
      @pages << page_ref
      page_ref
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

    def interpolate_label(position)
      return nil unless label_pattern

      label_pattern
        .gsub('%page', position.to_s)
        .gsub('%total', @count.to_s)
    end

    # Context assigned to each PageRef when added to a PageSet.
    #
    # Provides position information and convenience methods for
    # determining page position within the set.
    SetContext = Data.define(:page, :total, :label, :set_name) do
      # Check if this is the first page in the set.
      #
      # @return [Boolean]
      def first?
        page == 1
      end

      # Check if this is the last page in the set.
      #
      # @return [Boolean]
      def last?
        page == total
      end
    end
  end
end
