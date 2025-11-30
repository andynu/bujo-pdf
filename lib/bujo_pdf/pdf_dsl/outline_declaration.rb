# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # OutlineDeclaration represents an entry in the PDF outline/bookmarks.
    #
    # Outline entries can be:
    # - Simple page references (title + destination)
    # - Section headers with children (hierarchical grouping)
    #
    # Entries are collected during definition evaluation and processed
    # during the build phase to create the PDF outline.
    #
    # @example Simple entry
    #   OutlineDeclaration.new(title: 'Index', dest: :index_1)
    #
    # @example Section with children
    #   section = OutlineDeclaration.new(title: 'January', dest: :review_1)
    #   section.children << OutlineDeclaration.new(title: 'Monthly Review', dest: :review_1)
    #   section.children << OutlineDeclaration.new(title: 'Week 1', dest: :week_1)
    #
    class OutlineDeclaration
      attr_reader :title, :dest, :children
      attr_accessor :parent

      # Initialize a new outline declaration.
      #
      # @param title [String] The display title in the outline
      # @param dest [Symbol, nil] The destination page ID (nil for section headers without direct link)
      def initialize(title:, dest: nil)
        @title = title
        @dest = dest
        @children = []
        @parent = nil
      end

      # Check if this is a section (has children).
      #
      # @return [Boolean] true if this entry has children
      def section?
        @children.any?
      end

      # Add a child entry to this section.
      #
      # @param entry [OutlineDeclaration] The child entry
      # @return [OutlineDeclaration] The added entry
      def add_child(entry)
        entry.parent = self
        @children << entry
        entry
      end
    end
  end
end
