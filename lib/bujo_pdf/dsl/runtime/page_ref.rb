# frozen_string_literal: true

module BujoPdf
  # Represents a single generated page in the document.
  #
  # PageRef holds metadata about a page including its destination name,
  # title, type, and optional metadata. During the render phase, it receives
  # its PDF page number. When part of a PageSet, it also receives set context.
  #
  # @example Standalone page
  #   ref = PageRef.new(dest_name: 'seasonal', title: 'Seasonal Calendar', page_type: :seasonal)
  #   ref.pdf_page_number = 5  # Assigned during render
  #
  # @example Page in a set
  #   set = PageSet.new(name: 'Index', count: 2, label_pattern: 'Index %page of %total')
  #   ref = PageRef.new(dest_name: 'index_1', title: 'Index', page_type: :index)
  #   set.add(ref)
  #   ref.set_context.label  # => "Index 1 of 2"
  #
  class PageRef
    attr_reader :dest_name, :title, :page_type, :metadata, :render_block
    attr_accessor :pdf_page_number, :set_context

    # Create a new page reference.
    #
    # @param dest_name [String, Symbol] Named destination for PDF linking
    # @param title [String] Display title for the page
    # @param page_type [Symbol] Type identifier (e.g., :index, :weekly, :seasonal)
    # @param metadata [Hash] Optional additional metadata
    # @param render_block [Proc, nil] Block to execute during render phase
    def initialize(dest_name:, title:, page_type:, metadata: {}, render_block: nil)
      @dest_name = dest_name
      @title = title
      @page_type = page_type
      @metadata = metadata
      @render_block = render_block
      @pdf_page_number = nil  # Assigned during render phase
      @set_context = nil      # Assigned if part of PageSet
    end

    # Execute the render block.
    #
    # Called during the render phase to generate page content.
    #
    # @return [void]
    def render
      @render_block&.call
    end

    # Check if this page is part of a PageSet.
    #
    # @return [Boolean] true if page has set context
    def in_set?
      !set_context.nil?
    end

    # Get the title to use in PDF outline/bookmarks.
    #
    # Returns the set label if part of a set, otherwise the page title.
    #
    # @return [String] Title for outline entry
    def outline_title
      set_context&.label || title
    end

    # Check if this is a valid destination for linking.
    #
    # @return [Boolean] Always true for PageRef instances
    def valid_destination?
      true
    end
  end
end
