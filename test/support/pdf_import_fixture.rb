# frozen_string_literal: true

require 'tmpdir'
require 'prawn'

# Builds a small multi-page PDF and manifest on disk for PDF import tests,
# so no binary fixture has to be committed.
module PdfImportFixture
  PAGE_TEXTS = %w[ALPHA BRAVO CHARLIE].freeze

  DEFAULT_MANIFEST = <<~YAML
    pages:
      first: 1
      second:
        page: 2
        title: The Second One
      third: 3
  YAML

  # Yields a temp dir holding deck.pdf and deck.yml; the dir is removed afterwards.
  def with_deck(texts: PAGE_TEXTS, manifest: DEFAULT_MANIFEST)
    Dir.mktmpdir('pdf_import_test') do |dir|
      write_deck_pdf(File.join(dir, 'deck.pdf'), texts)
      File.write(File.join(dir, 'deck.yml'), manifest)
      yield dir, File.join(dir, 'deck.yml')
    end
  end

  def write_deck_pdf(path, texts)
    Prawn::Document.generate(path, page_size: 'LETTER', margin: 0) do |pdf|
      texts.each_with_index do |text, index|
        pdf.start_new_page if index.positive?
        pdf.text_box text, at: [50, 700]
      end
    end
  end
end
