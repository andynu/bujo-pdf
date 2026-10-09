# frozen_string_literal: true

require_relative '../base/sidebar_base'
require_relative '../components/all'
require_relative 'sidebar_registry'

module BujoPdf
  module Sidebars
    # InlineSidebar executes a user-provided block for custom sidebar rendering.
    #
    # Unlike standard sidebars (WeekSidebar, MonthSidebar) that have fixed behavior,
    # InlineSidebar allows PDF recipes to define custom sidebar content inline.
    # The body block has access to all component verbs (h1, h2, ruled_lines, etc.)
    # and receives page context for conditional rendering.
    #
    # @example Usage from a PDF recipe
    #   sidebar :project_nav, position: :left, width: 3 do |context|
    #     h2(0, 0, "Projects")
    #     ruled_lines(0, 2, 3, 10)
    #   end
    #
    # @example Creating an InlineSidebar directly
    #   sidebar = InlineSidebar.new(
    #     canvas: canvas,
    #     position: :left,
    #     width: 3,
    #     body_block: ->(ctx) { h1(0, 0, "Title") },
    #     context: page_context
    #   )
    #   sidebar.render
    #
    class InlineSidebar < SidebarBase
      include Components::All
      include SidebarRegistry
      register_sidebar :inline_sidebar

      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param position [Symbol] Sidebar position (:left or :right)
      # @param width [Integer] Sidebar width in grid columns
      # @param body_block [Proc] Block defining sidebar content rendering
      # @param context [Object] Page context passed to the body block
      def initialize(canvas:, position:, width:, body_block:, context: nil)
        # Calculate start column based on position
        start_col = position == :right ? (43 - width) : 0

        super(canvas: canvas, page_context: context, start_col: start_col, width_boxes: width)
        @position = position
        @body_block = body_block
        @context = context
      end

      # Render the sidebar by executing the body block.
      #
      # The block is executed with component verbs available (h1, h2, etc.)
      # and receives the page context as its argument.
      #
      # @return [void]
      def render
        return unless @body_block

        instance_exec(@context, &@body_block)
      end

      # @return [Symbol] The sidebar position (:left or :right)
      attr_reader :position
    end
  end
end
