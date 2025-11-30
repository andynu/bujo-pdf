# frozen_string_literal: true

module BujoPdf
  # Provides pagination context for multi-page spreads.
  #
  # PageSetContext is a simple data structure that provides page position and
  # label information for multi-page spreads. It yields 0-based indices
  # and produces Context objects with 1-based page numbers.
  #
  # Note: This is the legacy context provider. For the new DocumentBuilder DSL,
  # use PageSet which holds PageRef objects directly.
  #
  # @example Basic usage
  #   ps = PageSetContext.new(count: 2, label: "Index %page of %total")
  #   ps[0].label  # => "Index 1 of 2"
  #   ps[1].label  # => "Index 2 of 2"
  #
  # @example Iteration
  #   ps.each do |i|  # yields 0, 1
  #     page_ctx = ps[i]
  #     render_page(page_ctx.page, page_ctx.total)
  #   end
  #
  class PageSetContext
    include Enumerable

    attr_reader :count, :label_pattern, :name

    # Create a new PageSet.
    #
    # @param count [Integer] Number of pages in this set
    # @param label [String, nil] Label pattern with %page and %total placeholders
    # @param name [String, nil] Set name (extracted from label if not provided)
    def initialize(count:, label: nil, name: nil)
      @count = count
      @label_pattern = label
      @name = name || extract_name_from_label(label)
    end

    # Get the context for a specific page index.
    #
    # @param index [Integer] 0-based page index
    # @return [Context] Context object for that page
    # @raise [IndexError] if index is out of bounds
    def [](index)
      raise IndexError, "index #{index} outside page set (0..#{count - 1})" if index < 0 || index >= count

      Context.new(
        page: index + 1,
        total: count,
        label: interpolate_label(index + 1),
        name: name
      )
    end

    # Iterate over page indices.
    #
    # @yield [Integer] 0-based page index
    # @return [Enumerator] if no block given
    def each
      return enum_for(:each) unless block_given?

      count.times { |i| yield i }
    end

    # @return [Integer] Number of pages in this set
    def size
      count
    end

    private

    def interpolate_label(page_num)
      return nil unless label_pattern

      label_pattern
        .gsub('%page', page_num.to_s)
        .gsub('%total', count.to_s)
    end

    def extract_name_from_label(label)
      return nil unless label

      # Remove %page, %total, digits, and common words to get the set name
      label.gsub(/%page|%total|\d+|\bof\b/i, '').squeeze(' ').strip
    end

    # Context object representing a single page within a PageSet.
    #
    # Attached to PageContext.set when inside a page_set block.
    # Provides page position and label information.
    class Context
      attr_reader :page, :total, :label, :name

      # @param page [Integer] 1-based page number within set
      # @param total [Integer] Total pages in set
      # @param label [String, nil] Interpolated label string
      # @param name [String, nil] Set name (e.g., "Index", "Future Log")
      def initialize(page:, total:, label:, name: nil)
        @page = page
        @total = total
        @label = label
        @name = name
      end

      # @return [Boolean] true if this is the first page in the set
      def first?
        page == 1
      end

      # @return [Boolean] true if this is the last page in the set
      def last?
        page == total
      end

      # @return [Hash] Hash representation for context merging
      def to_h
        { set_page: page, set_total: total, set_label: label, set_name: name }
      end
    end

    # Null object for when not inside a page_set block.
    #
    # Responds to all Context methods but returns nil/false.
    # Allows pages to always call context.set.* without nil checks.
    class NullContext
      def page = nil
      def total = nil
      def label = nil
      def name = nil
      def first? = false
      def last? = false

      def to_h
        {}
      end
    end
  end
end
