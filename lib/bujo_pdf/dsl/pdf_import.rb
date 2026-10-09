# frozen_string_literal: true

require 'yaml'
require 'pdf/reader'

module BujoPdf
  module PdfDSL
    # PdfImport describes an external PDF whose pages can be inserted into a
    # recipe, plus the manifest that gives those pages stable keys.
    #
    # The manifest is YAML, kept next to the PDF:
    #
    #   pdf: bujo_ritual_deck.pdf    # optional; defaults to the manifest's basename
    #   pages:
    #     daily: 1                   # key: page number (1-based)
    #     monthly:
    #       page: 3
    #       title: The Monthly Ritual   # optional outline title
    #
    # The manifest is checked against the PDF when loaded, so a regenerated deck
    # that no longer matches fails the build instead of linking to the wrong page.
    # PDF pages with no manifest entry only warn, since a deck grows before its
    # manifest does.
    #
    # @example
    #   deck = PdfImport.new('assets/ritual_deck/manifest.yml', prefix: :ritual)
    #   deck.keys             # => [:daily, :weekly, ...]
    #   deck.page_id(:daily)  # => :ritual_daily
    class PdfImport
      # Raised for any problem with the manifest or the PDF it names.
      class Error < ArgumentError; end

      ImportedPage = Struct.new(:key, :page_number, :title, keyword_init: true)

      ENTRY_OPTIONS = %w[page title].freeze
      KEY_PATTERN = /\A[A-Za-z_][A-Za-z0-9_]*\z/

      attr_reader :manifest_path, :pdf_path, :prefix, :pages, :page_count

      # @param manifest_path [String] Path to the YAML manifest
      # @param prefix [Symbol, String, nil] Prepended to keys to form page ids
      # @raise [Error] If the manifest or PDF is missing, unreadable or inconsistent
      def initialize(manifest_path, prefix: nil)
        @manifest_path = File.expand_path(manifest_path)
        @prefix = prefix
        manifest = read_manifest
        @pdf_path = resolve_pdf_path(manifest)
        @page_count = read_page_count
        @pages = build_pages(manifest['pages']).sort_by(&:page_number).freeze
        warn_about_unlisted_pages
      end

      # @return [Array<Symbol>] Keys in PDF page order
      def keys
        @pages.map(&:key)
      end

      # @param key [Symbol, String] A manifest key
      # @return [ImportedPage]
      # @raise [Error] If the key is not in the manifest
      def page(key)
        @pages.find { |entry| entry.key == key.to_sym } ||
          raise(Error, "no page :#{key} in #{manifest_path} (known: #{keys.join(', ')})")
      end

      # The page id (and named destination) an imported page is declared under.
      #
      # @param key [Symbol, String] A manifest key
      # @return [Symbol]
      def page_id(key)
        @prefix ? :"#{@prefix}_#{key}" : key.to_sym
      end

      private

      def read_manifest
        raise Error, "manifest not found: #{manifest_path}" unless File.file?(manifest_path)

        manifest = YAML.safe_load_file(manifest_path)
        unless manifest.is_a?(Hash) && manifest['pages'].is_a?(Hash) && !manifest['pages'].empty?
          raise Error, "#{manifest_path} must have a non-empty `pages:` mapping of key to page number"
        end

        manifest
      rescue Psych::Exception => e
        raise Error, "#{manifest_path} is not valid YAML: #{e.message}"
      end

      def resolve_pdf_path(manifest)
        name = manifest['pdf'] || "#{File.basename(manifest_path, '.*')}.pdf"
        path = File.expand_path(name, File.dirname(manifest_path))
        raise Error, "PDF not found: #{path} (named by #{manifest_path})" unless File.file?(path)

        path
      end

      def read_page_count
        PDF::Reader.new(pdf_path).page_count
      rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError,
             PDF::Reader::EncryptedPDFError
        raise Error, "#{pdf_path} is not a readable PDF"
      end

      def build_pages(entries)
        seen = {}
        entries.map do |raw_key, value|
          key = raw_key.to_s
          raise Error, "invalid page key #{raw_key.inspect} in #{manifest_path}" unless key.match?(KEY_PATTERN)

          number, title = parse_entry(key, value)
          validate_page_number(key, number)
          if seen.key?(number)
            raise Error, "page #{number} is claimed by both :#{seen[number]} and :#{key}"
          end

          seen[number] = key
          ImportedPage.new(key: key.to_sym, page_number: number, title: title || titleize(key))
        end
      end

      def parse_entry(key, value)
        return [value, nil] unless value.is_a?(Hash)

        unknown = value.keys.map(&:to_s) - ENTRY_OPTIONS
        raise Error, "unknown option(s) #{unknown.join(', ')} for :#{key} (allowed: #{ENTRY_OPTIONS.join(', ')})" if unknown.any?

        [value['page'], value['title']&.to_s]
      end

      def validate_page_number(key, number)
        unless number.is_a?(Integer) && number >= 1
          raise Error, ":#{key} needs a page number of 1 or more, got #{number.inspect}"
        end
        return if number <= page_count

        raise Error, ":#{key} is page #{number} but #{File.basename(pdf_path)} has #{page_count} pages"
      end

      def warn_about_unlisted_pages
        unlisted = (1..page_count).to_a - @pages.map(&:page_number)
        return if unlisted.empty?

        label = unlisted.one? ? 'page' : 'pages'
        warn "#{File.basename(pdf_path)}: #{label} #{unlisted.join(', ')} not in #{File.basename(manifest_path)}"
      end

      def titleize(key)
        key.tr('_', ' ').split.map(&:capitalize).join(' ')
      end
    end
  end
end
