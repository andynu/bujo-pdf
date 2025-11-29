# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # MetadataBuilder captures PDF metadata during definition evaluation.
    #
    # PDF metadata includes things like title, author, subject, and keywords
    # that are embedded in the PDF document properties.
    #
    # @example
    #   metadata = MetadataBuilder.new do
    #     title "My Planner 2025"
    #     author "BujoPdf"
    #     subject "Digital Bullet Journal"
    #     keywords ["planner", "2025"]
    #   end
    #
    class MetadataBuilder
      attr_reader :values

      # Initialize a new metadata builder.
      #
      # @yield Block containing metadata DSL calls
      def initialize(&block)
        @values = {}
        instance_eval(&block) if block_given?
      end

      # Set the PDF title.
      #
      # @param value [String] The document title
      # @return [String] The set value
      def title(value)
        @values[:title] = value
      end

      # Set the PDF author.
      #
      # @param value [String] The document author
      # @return [String] The set value
      def author(value)
        @values[:author] = value
      end

      # Set the PDF subject.
      #
      # @param value [String] The document subject
      # @return [String] The set value
      def subject(value)
        @values[:subject] = value
      end

      # Set the PDF keywords.
      #
      # @param value [Array<String>, String] Keywords for the document
      # @return [Array<String>] The set value
      def keywords(value)
        @values[:keywords] = Array(value)
      end

      # Set the PDF creator.
      #
      # @param value [String] The creator application name
      # @return [String] The set value
      def creator(value)
        @values[:creator] = value
      end

      # Set the PDF producer.
      #
      # @param value [String] The producer application name
      # @return [String] The set value
      def producer(value)
        @values[:producer] = value
      end

      # Set a custom metadata field.
      #
      # @param key [Symbol] The metadata key
      # @param value [Object] The metadata value
      # @return [Object] The set value
      def custom(key, value)
        @values[key] = value
      end

      # Get the metadata hash for Prawn.
      #
      # @return [Hash] Metadata hash suitable for Prawn::Document.new
      def to_prawn_info
        result = {}
        result[:Title] = @values[:title] if @values[:title]
        result[:Author] = @values[:author] if @values[:author]
        result[:Subject] = @values[:subject] if @values[:subject]
        result[:Keywords] = @values[:keywords].join(', ') if @values[:keywords]
        result[:Creator] = @values[:creator] if @values[:creator]
        result[:Producer] = @values[:producer] if @values[:producer]
        result
      end
    end
  end
end
