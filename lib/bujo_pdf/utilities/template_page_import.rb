# frozen_string_literal: true

require 'prawn/templates'

module BujoPdf
  # prawn-templates follows an imported page's /Parent into the source
  # document's whole page tree and copies every sibling page too. They end up
  # unreachable but still written, so importing one page from a large deck
  # ships the entire deck. Cutting the link while a page is imported keeps the
  # output to the pages actually used; Prawn re-parents the page itself.
  #
  # Scoped to import_page so whole-file templates (Document.new(template:))
  # still copy their page tree intact.
  module TemplatePageImport
    def import_page(input, page_num)
      @importing_single_page = true
      super
    ensure
      @importing_single_page = false
    end

    private

    def load_object_graph(hash, object)
      object.delete(:Parent) if @importing_single_page && object.is_a?(::Hash) && object[:Type] == :Page
      super
    end
  end
end

PDF::Core::ObjectStore.prepend(BujoPdf::TemplatePageImport)
