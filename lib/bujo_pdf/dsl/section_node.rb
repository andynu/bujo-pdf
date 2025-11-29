# frozen_string_literal: true

require_relative 'container_node'

module BujoPdf
  module DSL
    # SectionNode is a named region that can contain children.
    #
    # Sections are the primary building block for page layouts. They can be:
    # - Fixed size (specify width/height in grid boxes)
    # - Flexible (use flex to take remaining space)
    # - Containers for child nodes
    #
    # @example Fixed height section
    #   SectionNode.new(name: :header, height: 3)
    #
    # @example Flex section that fills remaining space
    #   SectionNode.new(name: :content, flex: 1)
    #
    # @example Section with children
    #   section = SectionNode.new(name: :main, flex: 1, direction: :horizontal)
    #   section.add_child(SectionNode.new(name: :sidebar, width: 3))
    #   section.add_child(SectionNode.new(name: :content, flex: 1))
    #
    class SectionNode < ContainerNode
      # Initialize a section node.
      #
      # @param name [Symbol] Section name for referencing
      # @param direction [Symbol] Layout direction for children (:vertical or :horizontal)
      # @param kwargs [Hash] Constraints (width, height, flex, etc.)
      def initialize(name: nil, direction: :vertical, **kwargs)
        super(name: name, direction: direction, **kwargs)
      end
    end

    # SidebarNode is a fixed-width vertical region, typically for navigation.
    #
    # Sidebars default to vertical layout and are positioned at the edge of
    # their parent container. Use within a horizontal container to create
    # left or right sidebars.
    #
    # @example Left sidebar
    #   container = ContainerNode.new(direction: :horizontal)
    #   container.add_child(SidebarNode.new(name: :left_nav, width: 3))
    #   container.add_child(SectionNode.new(name: :content, flex: 1))
    #
    class SidebarNode < SectionNode
      def initialize(name: nil, width:, **kwargs)
        super(name: name, width: width, direction: :vertical, **kwargs)
      end
    end

    # HeaderNode is a fixed-height horizontal region at the top.
    #
    # Headers default to horizontal layout for arranging items like
    # title, date, navigation links side by side.
    #
    # @example Simple header
    #   HeaderNode.new(name: :page_header, height: 2)
    #
    class HeaderNode < SectionNode
      def initialize(name: nil, height:, **kwargs)
        super(name: name, height: height, direction: :horizontal, **kwargs)
      end
    end

    # FooterNode is a fixed-height horizontal region at the bottom.
    #
    # Footers are structurally identical to headers but semantically
    # positioned at the bottom of their parent container.
    #
    # @example Summary footer
    #   FooterNode.new(name: :summary, height: 3)
    #
    class FooterNode < SectionNode
      def initialize(name: nil, height:, **kwargs)
        super(name: name, height: height, direction: :horizontal, **kwargs)
      end
    end
  end
end
