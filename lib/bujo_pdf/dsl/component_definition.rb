# frozen_string_literal: true

module BujoPdf
  module DSL
    # ComponentDefinition captures a reusable component's structure.
    #
    # Components are named, parameterized layout patterns that can be reused
    # across pages. A component definition stores the component's name,
    # required parameters, and the block that builds its layout tree.
    #
    # @example Defining a component
    #   definition = ComponentDefinition.new(:day_header, [:day]) do |day:|
    #     header height: 2 do
    #       text day.name, style: :day_header
    #       text day.date, style: :day_date
    #     end
    #   end
    #
    # @example Building a component instance
    #   builder = LayoutBuilder.new
    #   definition.build(builder, day: week.days[0])
    #
    class ComponentDefinition
      attr_reader :name, :params, :block

      # Initialize a new component definition.
      #
      # @param name [Symbol] The component name
      # @param params [Array<Symbol>] Required parameter names
      # @param block [Proc] Block that builds the component layout
      def initialize(name, params = [], &block)
        @name = name
        @params = params
        @block = block
      end

      # Build an instance of this component.
      #
      # Evaluates the component's block in the context of a LayoutBuilder,
      # passing the provided parameters.
      #
      # @param builder [LayoutBuilder] The builder to add nodes to
      # @param kwargs [Hash] Parameter values for the component
      # @raise [ArgumentError] if required parameters are missing
      # @return [LayoutNode] The created layout tree
      def build(builder, **kwargs)
        validate_params!(kwargs)

        # Create a wrapper section for the component
        wrapper = SectionNode.new(name: @name, direction: :vertical)
        builder.current_parent.add_child(wrapper)

        # Evaluate the block in builder context with params
        # Push wrapper as parent temporarily
        original_parent = builder.instance_variable_get(:@stack)
        builder.instance_variable_get(:@stack).push(wrapper)

        begin
          builder.instance_exec(**kwargs, &@block)
        ensure
          builder.instance_variable_get(:@stack).pop
        end

        wrapper
      end

      private

      # Validate that all required parameters are provided.
      #
      # @param kwargs [Hash] Provided parameters
      # @raise [ArgumentError] if any required params are missing
      def validate_params!(kwargs)
        missing = @params - kwargs.keys
        unless missing.empty?
          raise ArgumentError, "Missing required parameters for component '#{@name}': #{missing.join(', ')}"
        end
      end
    end

    # ComponentRegistry manages component definitions.
    #
    # The registry is a singleton that stores all defined components and
    # provides lookup for instantiation.
    #
    # @example Registering a component
    #   ComponentRegistry.register(:day_header, [:day]) do |day:|
    #     header height: 2 do
    #       text day.name
    #     end
    #   end
    #
    # @example Looking up a component
    #   definition = ComponentRegistry.get(:day_header)
    #
    class ComponentRegistry
      @registry = {}

      class << self
        # Register a new component definition.
        #
        # @param name [Symbol] Component name
        # @param params [Array<Symbol>] Required parameter names
        # @yield Block that builds the component
        # @return [ComponentDefinition] The registered definition
        def register(name, params = [], &block)
          definition = ComponentDefinition.new(name, params, &block)
          @registry[name] = definition
        end

        # Get a component definition by name.
        #
        # @param name [Symbol] Component name
        # @return [ComponentDefinition, nil] The definition or nil
        def get(name)
          @registry[name]
        end

        # Check if a component is registered.
        #
        # @param name [Symbol] Component name
        # @return [Boolean] true if registered
        def registered?(name)
          @registry.key?(name)
        end

        # Get all registered component names.
        #
        # @return [Array<Symbol>] Component names
        def names
          @registry.keys
        end

        # Clear all registrations (useful for testing).
        def clear!
          @registry = {}
        end

        # Define and register a component.
        #
        # This is the main API for defining components from the DSL.
        #
        # @param name [Symbol] Component name
        # @param params [Array<Symbol>] Required parameters
        # @yield Block building the component layout
        # @return [ComponentDefinition] The registered definition
        #
        # @example
        #   ComponentRegistry.define(:card) do |title:, content:|
        #     section do
        #       header height: 1 do
        #         text title, style: :card_title
        #       end
        #       field flex: 1
        #     end
        #   end
        def define(name, params: [], &block)
          register(name, params, &block)
        end
      end
    end
  end
end
