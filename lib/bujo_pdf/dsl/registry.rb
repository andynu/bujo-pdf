# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # LinkRegistry maps page declarations to PDF destinations.
    #
    # During the declaration pass, pages are registered with their destination
    # keys and page numbers. During the render pass, navigation links query
    # the registry to resolve symbolic destinations to actual PDF destinations.
    #
    # @example Building the registry
    #   registry = LinkRegistry.new
    #   pages.each_with_index do |page, index|
    #     registry.register(page, page_number: index + 1)
    #   end
    #
    # @example Resolving a destination
    #   info = registry.resolve(:weekly, week_num: 12)
    #   info[:destination]   # => "weekly_week_num_12"
    #   info[:page_number]   # => 15
    #
    class LinkRegistry
      # Information about a registered page destination.
      DestinationInfo = Struct.new(:destination_key, :page_number, :page_type, :params, keyword_init: true) do
        # Get the PDF named destination string.
        #
        # @return [String] The named destination
        def destination
          destination_key
        end
      end

      def initialize
        # Map from destination_key -> DestinationInfo
        @destinations = {}

        # Map from (type, param_key) -> [DestinationInfo] for pattern matching
        @by_type = Hash.new { |h, k| h[k] = [] }

        # Track groups for cycling navigation
        @groups = {}
      end

      # Register a page declaration.
      #
      # @param declaration [PageDeclaration] The page declaration
      # @param page_number [Integer] The 1-based page number
      # @return [DestinationInfo] The registered destination info
      def register(declaration, page_number:)
        key = declaration.destination_key

        info = DestinationInfo.new(
          destination_key: key,
          page_number: page_number,
          page_type: declaration.type,
          params: declaration.params.dup
        )

        @destinations[key] = info
        @by_type[declaration.type] << info

        info
      end

      # Register a group of pages for cycling navigation.
      #
      # @param group [GroupDeclaration] The group declaration
      def register_group(group)
        keys = group.destination_keys
        @groups[group.name] = {
          name: group.name,
          cycle: group.cycle?,
          destinations: keys
        }
      end

      # Resolve a destination by type and parameters.
      #
      # @param dest_type [Symbol] The page type to find
      # @param params [Hash] Parameters to match
      # @return [DestinationInfo, nil] The destination info or nil if not found
      def resolve(dest_type, **params)
        # Try exact key match first
        if params.empty?
          key = dest_type.to_s
          return @destinations[key] if @destinations.key?(key)
        end

        # Search by type and params
        candidates = @by_type[dest_type]
        return nil if candidates.empty?

        # Find best match
        candidates.find do |info|
          params.all? { |k, v| matches_param?(info.params[k], v) }
        end
      end

      # Resolve a destination by its key directly.
      #
      # @param key [String] The destination key
      # @return [DestinationInfo, nil] The destination info or nil
      def resolve_key(key)
        @destinations[key]
      end

      # Get group information for cycling navigation.
      #
      # @param group_name [Symbol] The group name
      # @return [Hash, nil] Group info or nil
      def group(group_name)
        @groups[group_name]
      end

      # Get the next destination in a cycling group.
      #
      # @param group_name [Symbol] The group name
      # @param current_dest [String] Current destination key
      # @return [String, nil] Next destination key or nil
      def next_in_cycle(group_name, current_dest)
        grp = @groups[group_name]
        return nil unless grp&.dig(:cycle)

        dests = grp[:destinations]
        current_idx = dests.index(current_dest)

        if current_idx
          next_idx = (current_idx + 1) % dests.length
          dests[next_idx]
        else
          # Not in cycle, go to first
          dests.first
        end
      end

      # Check if a destination exists.
      #
      # @param dest_type [Symbol] The page type
      # @param params [Hash] Parameters to match
      # @return [Boolean]
      def exists?(dest_type, **params)
        !resolve(dest_type, **params).nil?
      end

      # Check if a key exists.
      #
      # @param key [String] The destination key
      # @return [Boolean]
      def key_exists?(key)
        @destinations.key?(key)
      end

      # Get all registered destination keys.
      #
      # @return [Array<String>]
      def keys
        @destinations.keys
      end

      # Get all destinations for a page type.
      #
      # @param page_type [Symbol] The page type
      # @return [Array<DestinationInfo>]
      def destinations_for_type(page_type)
        @by_type[page_type].dup
      end

      # Get all group names.
      #
      # @return [Array<Symbol>]
      def group_names
        @groups.keys
      end

      # Clear all registrations (useful for testing).
      def clear!
        @destinations.clear
        @by_type.clear
        @groups.clear
      end

      # Get the total number of registered pages.
      #
      # @return [Integer]
      def size
        @destinations.size
      end

      private

      # Check if a stored parameter matches a query parameter.
      #
      # Handles type coercion for common cases.
      #
      # @param stored [Object] The stored parameter value
      # @param query [Object] The query parameter value
      # @return [Boolean]
      def matches_param?(stored, query)
        return stored == query if stored.class == query.class

        # Handle Week objects by comparing number
        if stored.respond_to?(:number) && query.is_a?(Integer)
          return stored.number == query
        end

        # Handle Month objects
        if stored.respond_to?(:number) && query.is_a?(Integer)
          return stored.number == query
        end

        # String/Symbol comparison
        stored.to_s == query.to_s
      end
    end

    # LinkResolver provides high-level link resolution for rendering.
    #
    # This is the primary interface used during page rendering to resolve
    # navigation link destinations. It wraps LinkRegistry with convenience
    # methods for common patterns.
    #
    # @example Resolving a weekly page link
    #   resolver = LinkResolver.new(registry, current_page: :weekly, current_params: { week_num: 10 })
    #   resolver.dest_for_prev_week    # => "weekly_week_num_9"
    #   resolver.dest_for_next_week    # => "weekly_week_num_11"
    #
    class LinkResolver
      attr_reader :registry, :current_page, :current_params

      # Initialize a link resolver.
      #
      # @param registry [LinkRegistry] The link registry
      # @param current_page [Symbol, nil] Current page type
      # @param current_params [Hash] Current page parameters
      def initialize(registry, current_page: nil, current_params: {})
        @registry = registry
        @current_page = current_page
        @current_params = current_params
      end

      # Resolve a destination.
      #
      # @param dest_type [Symbol] Page type
      # @param params [Hash] Parameters
      # @return [String, nil] Destination key or nil
      def resolve(dest_type, **params)
        info = @registry.resolve(dest_type, **params)
        info&.destination
      end

      # Resolve a destination key directly.
      #
      # @param key [String, Symbol] The key
      # @return [String, nil] Destination key or nil
      def resolve_key(key)
        info = @registry.resolve_key(key.to_s)
        info&.destination
      end

      # Check if a destination exists.
      #
      # @param dest_type [Symbol] Page type
      # @param params [Hash] Parameters
      # @return [Boolean]
      def exists?(dest_type, **params)
        @registry.exists?(dest_type, **params)
      end

      # Get the destination for the previous week.
      #
      # @param week_num [Integer, nil] Current week (defaults to current_params[:week_num])
      # @return [String, nil] Destination key or nil
      def dest_for_prev_week(week_num: nil)
        num = week_num || @current_params[:week_num]
        return nil unless num && num > 1

        resolve(:weekly, week_num: num - 1)
      end

      # Get the destination for the next week.
      #
      # @param week_num [Integer, nil] Current week (defaults to current_params[:week_num])
      # @param total_weeks [Integer, nil] Total weeks in year
      # @return [String, nil] Destination key or nil
      def dest_for_next_week(week_num: nil, total_weeks: nil)
        num = week_num || @current_params[:week_num]
        total = total_weeks || @current_params[:total_weeks] || 53
        return nil unless num && num < total

        resolve(:weekly, week_num: num + 1)
      end

      # Get the next destination in a cycling tab group.
      #
      # @param group_name [Symbol] The group name
      # @return [String, nil] Next destination key or nil
      def next_in_group(group_name)
        current_key = @registry.resolve(@current_page, **@current_params)&.destination
        @registry.next_in_cycle(group_name, current_key)
      end

      # Get all destinations in a group.
      #
      # @param group_name [Symbol] The group name
      # @return [Array<String>] Destination keys
      def group_destinations(group_name)
        grp = @registry.group(group_name)
        grp ? grp[:destinations] : []
      end

      # Check if current page is in a group.
      #
      # @param group_name [Symbol] The group name
      # @return [Boolean]
      def in_group?(group_name)
        grp = @registry.group(group_name)
        return false unless grp

        current_key = @registry.resolve(@current_page, **@current_params)&.destination
        grp[:destinations].include?(current_key)
      end
    end
  end
end
