# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # SidebarDefinition captures an inline sidebar definition from a PDF recipe.
    #
    # Inline sidebars allow recipes to define custom sidebars directly in the
    # PDF definition block, rather than referencing pre-registered sidebar types.
    # The body block is captured and later executed when the sidebar renders.
    #
    # @example In a PDF definition
    #   sidebar :project_nav, position: :left, width: 3 do |context|
    #     h2(0, 0, "Projects")
    #     # Component verbs available
    #   end
    #
    class SidebarDefinition
      attr_reader :name, :position, :width, :body_block

      # Valid position values for sidebars.
      VALID_POSITIONS = %i[left right].freeze

      # Default sidebar width in grid columns.
      DEFAULT_WIDTH = 3

      # Initialize a new sidebar definition.
      #
      # @param name [Symbol] The sidebar identifier (used to reference in chrome config)
      # @param position [Symbol] Where the sidebar appears (:left or :right)
      # @param width [Integer] Width in grid columns (default: 3)
      # @param body_block [Proc] Block defining sidebar rendering
      # @raise [ArgumentError] if name is nil or position is invalid
      def initialize(name:, position:, width: DEFAULT_WIDTH, &body_block)
        raise ArgumentError, 'sidebar name is required' if name.nil?

        unless VALID_POSITIONS.include?(position)
          raise ArgumentError,
                "invalid sidebar position: #{position}. Must be one of: #{VALID_POSITIONS.join(', ')}"
        end

        @name = name
        @position = position
        @width = width
        @body_block = body_block
      end

      # Check if a body block is defined.
      #
      # @return [Boolean] true if a body block was provided
      def body?
        !@body_block.nil?
      end

      # Check if this sidebar is on the left.
      #
      # @return [Boolean] true if position is :left
      def left?
        @position == :left
      end

      # Check if this sidebar is on the right.
      #
      # @return [Boolean] true if position is :right
      def right?
        @position == :right
      end

      # Convert to a hash representation.
      #
      # @return [Hash] Hash with :name, :position, :width keys
      def to_h
        {
          name: @name,
          position: @position,
          width: @width,
          has_body: body?
        }
      end
    end
  end
end
