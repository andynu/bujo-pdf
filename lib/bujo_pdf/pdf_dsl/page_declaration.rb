# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # PageDeclaration represents a declared page in a PDF definition.
    #
    # A page declaration captures the page type and parameters needed to
    # instantiate and render the page. Pages are declared during definition
    # evaluation and rendered during the build phase.
    #
    # @example
    #   decl = PageDeclaration.new(:weekly, week: week_obj)
    #   decl.type       # => :weekly
    #   decl.params     # => { week: week_obj }
    #
    class PageDeclaration
      attr_reader :type, :params, :id

      # Initialize a new page declaration.
      #
      # @param type [Symbol] The page type (e.g., :weekly, :seasonal_calendar)
      # @param id [Symbol, nil] Optional explicit page ID
      # @param params [Hash] Parameters to pass to the page
      def initialize(type, id: nil, **params)
        @type = type
        @id = id
        @params = params
      end

      # Generate a destination key for this page.
      #
      # Used for link resolution. The key is either the explicit ID or
      # a generated key based on type and params.
      #
      # @return [String] The destination key
      def destination_key
        return @id.to_s if @id

        if @params.empty?
          @type.to_s
        else
          params_str = @params.sort_by { |k, _| k.to_s }.map { |k, v|
            value_str = case v
            when Date
              v.strftime('%Y%m%d')
            when Numeric
              v.to_s
            when nil
              'nil'
            else
              v.to_s.gsub(/[^a-z0-9_]/i, '_')
            end
            "#{k}_#{value_str}"
          }.join('_')
          "#{@type}_#{params_str}"
        end
      end

      # Check if this declaration matches a destination.
      #
      # @param dest_type [Symbol] The destination page type
      # @param dest_params [Hash] The destination parameters
      # @return [Boolean] true if this page matches the destination
      def matches?(dest_type, **dest_params)
        return false unless @type == dest_type
        return true if dest_params.empty?

        # Check all provided dest_params match
        dest_params.all? { |k, v| @params[k] == v }
      end
    end

    # GroupDeclaration represents a group of related pages.
    #
    # Groups organize pages logically and can enable navigation features
    # like cycling through pages with a single tab click.
    #
    # @example
    #   group = GroupDeclaration.new(:grids, cycle: true)
    #   group.add_page(PageDeclaration.new(:dot_grid))
    #   group.add_page(PageDeclaration.new(:graph_grid))
    #
    class GroupDeclaration
      attr_reader :name, :options, :pages

      # Initialize a new group declaration.
      #
      # @param name [Symbol] The group name
      # @param options [Hash] Group options
      # @option options [Boolean] :cycle Enable tab cycling through pages
      def initialize(name, **options)
        @name = name
        @options = options
        @pages = []
      end

      # Add a page to this group.
      #
      # @param page [PageDeclaration] The page to add
      # @return [PageDeclaration] The added page
      def add_page(page)
        @pages << page
        page
      end

      # Check if this group has cycling enabled.
      #
      # @return [Boolean] true if cycling is enabled
      def cycle?
        @options[:cycle] == true
      end

      # Get all page destination keys for cycling.
      #
      # @return [Array<String>] Destination keys in order
      def destination_keys
        @pages.map(&:destination_key)
      end
    end
  end
end
