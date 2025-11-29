# frozen_string_literal: true

require 'yaml'

module BujoPdf
  # Loads and manages collection page configuration.
  #
  # Collections are user-defined themed pages like "Books to Read" or
  # "Project Ideas". Each collection becomes a titled blank page in the
  # planner with an optional subtitle.
  #
  # Configuration is loaded from a YAML file with this structure:
  #
  #   collections:
  #     - id: books_to_read
  #       title: Books to Read
  #       subtitle: Fiction, non-fiction, and everything in between
  #     - id: project_ideas
  #       title: Project Ideas
  #     - id: recipes
  #       title: Recipes to Try
  #       subtitle: Meals worth making again
  #
  # Example:
  #   config = CollectionsConfiguration.new('config/collections.yml')
  #   config.collections.each do |collection|
  #     puts collection[:title]
  #   end
  class CollectionsConfiguration
    attr_reader :collections

    # Initialize configuration from a YAML file.
    #
    # @param config_path [String] Path to the collections YAML file
    def initialize(config_path = 'config/collections.yml')
      @collections = load_collections(config_path)
    end

    # Check if any collections are configured.
    #
    # @return [Boolean] True if at least one collection exists
    def any?
      @collections.any?
    end

    # Get the count of collections.
    #
    # @return [Integer] Number of configured collections
    def count
      @collections.count
    end

    private

    # Load collections from YAML file.
    #
    # @param config_path [String] Path to the YAML file
    # @return [Array<Hash>] Array of collection configurations
    def load_collections(config_path)
      return [] unless File.exist?(config_path)

      data = YAML.safe_load(File.read(config_path), symbolize_names: true)
      return [] unless data && data[:collections]

      data[:collections].map do |collection|
        {
          id: collection[:id] || generate_id(collection[:title]),
          title: collection[:title] || "Untitled Collection",
          subtitle: collection[:subtitle]
        }
      end
    end

    # Generate an ID from a title.
    #
    # @param title [String] Collection title
    # @return [String] Snake_case ID
    def generate_id(title)
      return "collection" unless title

      title.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
    end
  end
end
