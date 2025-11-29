# frozen_string_literal: true

require_relative 'content_node'

module BujoPdf
  module DSL
    # NavLinkNode represents a clickable link to another page.
    #
    # Navigation links create PDF link annotations that jump to named
    # destinations. The link's visual appearance (text, icon, style) is
    # separate from its destination.
    #
    # @example Link to a named page
    #   NavLinkNode.new(dest: :year_events, label: "Year")
    #
    # @example Link with parameters
    #   NavLinkNode.new(dest: :weekly, params: { week: 12 }, label: "Week 12")
    #
    # @example Link with icon
    #   NavLinkNode.new(dest: :prev_week, icon: "<-", params: { week: current_week - 1 })
    #
    class NavLinkNode < ContentNode
      attr_reader :dest, :params, :label, :icon, :style

      # Initialize a navigation link node.
      #
      # @param dest [Symbol] Destination page type (e.g., :weekly, :year_events)
      # @param params [Hash] Parameters for the destination (e.g., week: 12)
      # @param label [String, nil] Link label text
      # @param icon [String, nil] Icon character or symbol
      # @param style [Symbol] Style name for the link
      # @param kwargs [Hash] Additional constraints
      def initialize(dest:, params: {}, label: nil, icon: nil, style: :nav_link, **kwargs)
        super(**kwargs)
        @dest = dest
        @params = params
        @label = label
        @icon = icon
        @style = style
      end

      # Generate the destination key for link resolution.
      #
      # This creates a consistent key that the link resolver can use to
      # find the target page.
      #
      # @return [String] Destination key
      def destination_key
        if @params.empty?
          @dest.to_s
        else
          params_str = @params.sort.map { |k, v| "#{k}_#{v}" }.join("_")
          "#{@dest}_#{params_str}"
        end
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :nav_link,
          dest: @dest,
          params: @params,
          destination_key: destination_key,
          label: @label,
          icon: @icon,
          style: @style,
          bounds: @computed_bounds
        }
      end
    end

    # NavGroupNode represents a group of related navigation links.
    #
    # Nav groups can cycle through their pages when clicked repeatedly.
    # This is useful for grid pages, reference sections, etc.
    #
    # @example Cycling grid navigation
    #   group = NavGroupNode.new(name: :grids, cycle: true)
    #   group.add_child(NavLinkNode.new(dest: :dot_grid))
    #   group.add_child(NavLinkNode.new(dest: :graph_grid))
    #
    class NavGroupNode < ContentNode
      attr_reader :cycle, :destinations

      # Initialize a navigation group node.
      #
      # @param name [Symbol] Group name
      # @param cycle [Boolean] Whether clicking cycles through pages
      # @param destinations [Array<Symbol>] List of destination page types
      # @param kwargs [Hash] Additional constraints
      def initialize(name:, cycle: false, destinations: [], **kwargs)
        super(name: name, **kwargs)
        @cycle = cycle
        @destinations = destinations
      end

      # Override add_child to extract destinations from nav links.
      #
      # @param child [NavLinkNode] A navigation link to add
      # @return [NavLinkNode] The added child
      def add_child(child)
        unless child.is_a?(NavLinkNode)
          raise ArgumentError, "NavGroupNode children must be NavLinkNode"
        end

        @destinations << child.dest
        # Nav groups don't actually store children for layout purposes
        # They just collect destination info
        child
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :nav_group,
          name: @name,
          cycle: @cycle,
          destinations: @destinations,
          bounds: @computed_bounds
        }
      end
    end

    # TabNode represents a navigation tab (like the right sidebar tabs).
    #
    # Tabs are visually distinct from regular links - they're typically
    # rotated, have different styling, and may highlight when active.
    #
    # @example Simple tab
    #   TabNode.new(dest: :year_events, label: "Year")
    #
    # @example Tab that cycles through pages
    #   TabNode.new(dest: [:grid_dot, :grid_graph, :grid_lined], label: "Grids", cycle: true)
    #
    class TabNode < ContentNode
      attr_reader :dest, :label, :style, :cycle, :rotation

      # Initialize a tab node.
      #
      # @param dest [Symbol, Array<Symbol>] Destination(s) for this tab
      # @param label [String] Tab label
      # @param style [Symbol] Style name
      # @param cycle [Boolean] Whether tab cycles through destinations
      # @param rotation [Numeric] Rotation angle in degrees (default: -90 for vertical)
      # @param kwargs [Hash] Additional constraints
      def initialize(dest:, label:, style: :tab, cycle: false, rotation: -90, **kwargs)
        super(**kwargs)
        @dest = dest
        @label = label
        @style = style
        @cycle = cycle
        @rotation = rotation
      end

      # Get all destinations for this tab.
      #
      # @return [Array<Symbol>] List of destinations
      def destinations
        @dest.is_a?(Array) ? @dest : [@dest]
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :tab,
          dest: @dest,
          destinations: destinations,
          label: @label,
          style: @style,
          cycle: @cycle,
          rotation: @rotation,
          bounds: @computed_bounds
        }
      end
    end
  end
end
