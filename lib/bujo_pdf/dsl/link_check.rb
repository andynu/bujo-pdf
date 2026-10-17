# frozen_string_literal: true

module BujoPdf
  class Error < StandardError; end

  module PdfDSL
    # Raised by a strict build that collected warnings, in place of writing the PDF.
    class WarningsError < BujoPdf::Error
      attr_reader :warnings

      # @param warnings [Warnings] Every warning the build collected
      def initialize(warnings)
        @warnings = warnings
        super("PDF not written, #{warnings.size} warning#{'s' unless warnings.size == 1}:\n" +
              warnings.map { |w| "  #{w.message}" }.join("\n"))
      end
    end

    # Everything a build noticed about its links but did not raise on.
    #
    # Equal warnings are kept once, so a link drawn twice on one page is one
    # warning, while the same dead tab on every page is one per page.
    class Warnings
      include Enumerable

      UnresolvedLink = Data.define(:dest, :page) do
        def message = %(link to "#{dest}" on page #{page} has no matching destination)
      end

      UnresolvedOutline = Data.define(:dest, :title) do
        def message = %(outline entry "#{title}" points at "#{dest}", which no page declares)
      end

      DuplicatePageId = Data.define(:id, :page, :first_page) do
        def message = %(page id "#{id}" on page #{page} is already used by page #{first_page})
      end

      DuplicateDestination = Data.define(:dest, :page, :first_page) do
        def message = %(destination "#{dest}" on page #{page} is already defined on page #{first_page})
      end

      def initialize
        @items = []
      end

      def <<(warning)
        @items << warning unless @items.include?(warning)
        self
      end

      def each(&)
        return enum_for(:each) unless block_given?

        @items.each(&)
        self
      end

      def size = @items.size
      def empty? = @items.empty?
    end

    # LinkCheck records every named destination and every link the render
    # pass draws, then reports links whose destination no page defined.
    #
    # It hooks Prawn's add_dest and link_annotation on one document, so every
    # page, component and sidebar is covered without each caller reporting
    # its own links. Links are checked after the last page, since a link may
    # point forward to a page not yet drawn.
    class LinkCheck
      # Prepended to a document's singleton class by LinkCheck.attach.
      module Recorder
        attr_accessor :link_check

        def add_dest(name, reference)
          link_check.destination(name.to_s, page_number)
          super
        end

        def link_annotation(rect, options = {})
          dest = options[:Dest]
          link_check.link(dest.to_s, page_number) if dest.is_a?(String) || dest.is_a?(Symbol)
          super
        end
      end

      # Start recording a document's destinations and links.
      #
      # @param pdf [Prawn::Document] The document about to be rendered
      # @param warnings [Warnings] Collector for the warnings found
      # @return [LinkCheck]
      def self.attach(pdf, warnings)
        check = new(warnings)
        pdf.singleton_class.prepend(Recorder)
        pdf.link_check = check
        check
      end

      def initialize(warnings)
        @warnings = warnings
        @destinations = {}
        @links = []
      end

      # @param name [String] Destination name
      # @param page [Integer] 1-based page the destination is on
      def destination(name, page)
        if (first_page = @destinations[name])
          @warnings << Warnings::DuplicateDestination.new(dest: name, page: page, first_page: first_page)
        else
          @destinations[name] = page
        end
      end

      # @param dest [String] Destination name the link points at
      # @param page [Integer] 1-based page the link is on
      def link(dest, page)
        @links << [dest, page]
      end

      # Add a warning for every recorded link with no destination.
      #
      # @return [void]
      def finish
        @links.each do |dest, page|
          @warnings << Warnings::UnresolvedLink.new(dest: dest, page: page) unless @destinations.key?(dest)
        end
      end
    end
  end
end
