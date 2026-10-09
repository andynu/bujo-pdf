# frozen_string_literal: true

require_relative 'page_declaration'

module BujoPdf
  module PdfDSL
    # ImportedPageDeclaration is a page copied verbatim from an external PDF.
    #
    # It takes part in link and outline resolution like any other declaration,
    # but the builder inserts the source page as it is instead of rendering one,
    # so it never carries chrome.
    #
    # @example
    #   decl = ImportedPageDeclaration.new(
    #     id: :ritual_daily, pdf_path: '/decks/rituals.pdf', template_page: 1, outline: 'The Daily Protocol'
    #   )
    class ImportedPageDeclaration < PageDeclaration
      attr_reader :pdf_path, :template_page

      # @param id [Symbol] Page id, also the named destination
      # @param pdf_path [String] Absolute path of the source PDF
      # @param template_page [Integer] 1-based page of the source PDF
      # @param outline [String, nil] Outline entry title
      def initialize(id:, pdf_path:, template_page:, outline: nil)
        super(:imported_pdf, id: id, outline: outline, chrome: false)
        @pdf_path = pdf_path
        @template_page = template_page
      end

      # @return [Boolean] Always true for ImportedPageDeclaration
      def imported?
        true
      end
    end
  end
end
