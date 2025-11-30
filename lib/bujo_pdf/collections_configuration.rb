# frozen_string_literal: true

require 'yaml'

module BujoPdf
  # Immutable collection record.
  #
  # @example
  #   c = Collection.new(id: 'books', title: 'Books to Read', subtitle: 'Fiction and more')
  #   c.title     # => "Books to Read"
  #   c.frozen?   # => true
  #
  Collection = Data.define(:id, :title, :subtitle) do
    # Build a Collection from a hash, with defaults and ID generation.
    #
    # @param h [Hash] Hash with :id, :title, :subtitle keys
    # @return [Collection]
    def self.from_hash(h)
      new(
        id: h[:id] || slugify(h[:title]) || 'collection',
        title: h[:title] || 'Untitled Collection',
        subtitle: h[:subtitle]
      )
    end

    def self.slugify(s)
      s&.downcase&.gsub(/[^a-z0-9]+/, '_')&.gsub(/^_|_$/, '')
    end
    private_class_method :slugify
  end

  # Load collection configurations from YAML.
  #
  # Returns a frozen array of immutable Collection objects.
  #
  # @example
  #   collections = CollectionsConfiguration.load
  #   collections.each { |c| puts c.title }
  #
  # @example Check if any collections exist
  #   CollectionsConfiguration.load.any?
  #
  module CollectionsConfiguration
    DEFAULT_PATH = 'config/collections.yml'

    # Load collections from a YAML file.
    #
    # @param path [String] Path to the YAML file
    # @return [Array<Collection>] Frozen array of Collection objects
    def self.load(path = DEFAULT_PATH)
      return [].freeze unless File.exist?(path)

      yaml = YAML.safe_load(File.read(path), symbolize_names: true)
      (yaml&.dig(:collections) || []).map { |h| Collection.from_hash(h) }.freeze
    end
  end
end
