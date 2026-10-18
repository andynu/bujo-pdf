# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # One entry in a navigation list: the page it links to and its short label.
    NavItem = Data.define(:id, :label)

    # A section of the right-hand navigation: a tab that lands on one page
    # and, on pages inside the section, expands to list every item.
    #
    # Sections are declared for navigation only, so a section's pages need not
    # be contiguous in the PDF.
    NavSection = Data.define(:key, :label, :landing, :items)

    # A month of the left-hand calendar navigation: it links to its first week
    # and, on its own calendar pages, expands to list its items in PDF order.
    NavMonth = Data.define(:month, :label, :first_week, :items)
  end
end
