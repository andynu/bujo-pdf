#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require 'bujo_pdf'
require 'bujo_pdf/pdf_dsl'

# Ensure pages are loaded
require 'bujo_pdf/pages/all'

class TestInlinePageGeneration < Minitest::Test
  def setup
    BujoPdf::PdfDSL.clear_recipes!
  end

  def test_generate_pdf_with_inline_page
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :notes, outline: 'Notes') do
        layout :full_page
        background :dot_grid

        body do
          h1(2, 1, "Notes")
          ruled_lines(2, 3, 38, 10)
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
    assert_equal 1, pdf.page_count
  end

  def test_generate_pdf_with_multiple_inline_pages
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :notes_1, outline: 'Notes 1') do
        body do
          h1(2, 1, "Notes Page 1")
        end
      end

      page(id: :notes_2, outline: 'Notes 2') do
        body do
          h1(2, 1, "Notes Page 2")
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
    assert_equal 2, pdf.page_count
  end

  def test_generate_pdf_mixing_inline_and_standard_pages
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page :reference

      page(id: :custom_notes) do
        layout :full_page
        body do
          h1(2, 1, "Custom Notes")
          text(2, 3, "This is a custom inline page")
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
    assert_equal 2, pdf.page_count
  end

  def test_inline_page_with_ruled_background
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :ruled_notes) do
        background :ruled

        body do
          h1(2, 1, "Ruled Notes")
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
  end

  def test_inline_page_with_blank_background
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :blank_page) do
        background :blank

        body do
          h1(2, 1, "Blank Canvas")
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
  end

  def test_inline_page_with_standard_sidebars_layout
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :with_sidebars) do
        layout :standard_with_sidebars, current_week: 1

        body do
          h1(5, 1, "Page with Sidebars")
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
  end

  def test_minimal_inline_page
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page do
        body do
          h1(2, 1, "Minimal")
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
  end

  def test_inline_page_with_multiple_components
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :complex) do
        layout :full_page

        body do
          h1(2, 1, "Complex Page")
          h2(2, 3, "Section 1")
          ruled_lines(2, 5, 20, 5)
          box(25, 5, 15, 5)
          text(26, 6, "Notes area")
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
  end

  def test_inline_page_recipe_definition
    BujoPdf.define_pdf :simple_notes do |year:|
      page(id: :notes_cover, outline: 'Notes') do
        body do
          h1(15, 25, "Notes #{year}", align: :center, width: 13)
        end
      end

      page(id: :notes_1) do
        background :ruled
        body do
          h1(2, 1, "Page 1")
        end
      end

      page(id: :notes_2) do
        background :ruled
        body do
          h1(2, 1, "Page 2")
        end
      end
    end

    pdf = BujoPdf::PdfDSL.generate(:simple_notes, year: 2025)

    assert_instance_of Prawn::Document, pdf
    assert_equal 3, pdf.page_count
  end

  def test_inline_page_in_group
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      group :custom_pages, cycle: true do
        page(id: :custom_1) do
          body do
            h1(2, 1, "Custom 1")
          end
        end

        page(id: :custom_2) do
          body do
            h1(2, 1, "Custom 2")
          end
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
    assert_equal 2, pdf.page_count
  end

  def test_inline_page_with_all_component_verbs
    # Test that all available component verbs work in inline pages
    pdf = BujoPdf::PdfDSL.generate(year: 2025) do
      page(id: :all_verbs) do
        body do
          # Text components
          h1(2, 1, "Header 1")
          h2(2, 3, "Header 2")
          text(2, 5, "Regular text")

          # Line components
          hline(2, 7, 20)
          vline(25, 7, 5)

          # Area components
          box(2, 10, 10, 5)
          ruled_lines(15, 10, 15, 5)
        end
      end
    end

    assert_instance_of Prawn::Document, pdf
  end
end
