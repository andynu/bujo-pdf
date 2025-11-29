# frozen_string_literal: true

require_relative 'container_node'
require_relative 'section_node'
require_relative 'columns_node'
require_relative 'content_node'
require_relative 'navigation_node'
require_relative 'component_definition'
require_relative 'layout_renderer'

module BujoPdf
  module DSL
    # LayoutBuilder provides the DSL interface for building layout trees.
    #
    # The builder maintains a stack of parent nodes to support nested
    # blocks. When you call a method like `sidebar`, it creates a node,
    # adds it to the current parent, and if a block is given, pushes it
    # onto the stack as the new parent.
    #
    # @example Building a layout
    #   builder = LayoutBuilder.new
    #   builder.sidebar width: 3 do
    #     builder.nav_link dest: :year_events, label: "Year"
    #   end
    #   builder.section name: :content, flex: 1 do
    #     builder.header height: 2 do
    #       builder.text "Title", style: :title
    #     end
    #   end
    #   root = builder.root
    #
    class LayoutBuilder
      attr_reader :root

      # Initialize a new layout builder.
      #
      # The builder starts with a root container node with vertical direction.
      def initialize
        @root = ContainerNode.new(name: :root, direction: :vertical)
        @stack = [@root]
      end

      # Get the current parent node.
      #
      # @return [LayoutNode] Current parent in the hierarchy
      def current_parent
        @stack.last
      end

      # Create a section node.
      #
      # @param name [Symbol] Section name
      # @param direction [Symbol] :vertical or :horizontal
      # @param kwargs [Hash] Constraints (width:, height:, flex:, etc.)
      # @yield Block for child nodes
      # @return [SectionNode] The created node
      def section(name: nil, direction: :vertical, **kwargs, &block)
        node = SectionNode.new(name: name, direction: direction, **kwargs)
        add_node(node, &block)
      end

      # Create a sidebar node (fixed-width vertical strip).
      #
      # @param name [Symbol] Sidebar name
      # @param width [Numeric] Width in grid boxes
      # @param kwargs [Hash] Additional constraints
      # @yield Block for child nodes
      # @return [SidebarNode] The created node
      def sidebar(name: nil, width:, **kwargs, &block)
        node = SidebarNode.new(name: name, width: width, **kwargs)
        add_node(node, &block)
      end

      # Create a header node (fixed-height horizontal strip at top).
      #
      # @param name [Symbol] Header name
      # @param height [Numeric] Height in grid boxes
      # @param kwargs [Hash] Additional constraints
      # @yield Block for child nodes
      # @return [HeaderNode] The created node
      def header(name: nil, height:, **kwargs, &block)
        node = HeaderNode.new(name: name, height: height, **kwargs)
        add_node(node, &block)
      end

      # Create a footer node (fixed-height horizontal strip at bottom).
      #
      # @param name [Symbol] Footer name
      # @param height [Numeric] Height in grid boxes
      # @param kwargs [Hash] Additional constraints
      # @yield Block for child nodes
      # @return [FooterNode] The created node
      def footer(name: nil, height:, **kwargs, &block)
        node = FooterNode.new(name: name, height: height, **kwargs)
        add_node(node, &block)
      end

      # Create columns (horizontal layout with equal or specified widths).
      #
      # @param count [Integer, nil] Number of equal-width columns
      # @param widths [Array<Numeric>, nil] Array of column widths
      # @param gap [Numeric] Gap between columns
      # @param kwargs [Hash] Additional constraints
      # @yield [Integer] Block called for each column with column index
      # @return [ColumnsNode] The created node
      def columns(count: nil, widths: nil, gap: 0, **kwargs, &block)
        node = ColumnsNode.new(count: count, widths: widths, gap: gap, **kwargs)
        add_node(node)

        # If block given and takes an argument, call it for each column
        if block && block.arity > 0
          node.column_count.times do |i|
            # The block defines what goes in each column
            # This is a deferred pattern - actual content will be built during render
            # For now, store the block info
            column_child = SectionNode.new(name: :"column_#{i}_content")
            node.add_child(column_child)
            @stack.push(column_child)
            yield i
            @stack.pop
          end
        elsif block
          @stack.push(node)
          block.call
          @stack.pop
        end

        node
      end

      # Create rows (vertical layout with equal or specified heights).
      #
      # @param count [Integer, nil] Number of equal-height rows
      # @param heights [Array<Numeric>, nil] Array of row heights
      # @param gap [Numeric] Gap between rows
      # @param kwargs [Hash] Additional constraints
      # @yield [Integer] Block called for each row with row index
      # @return [RowsNode] The created node
      def rows(count: nil, heights: nil, gap: 0, **kwargs, &block)
        node = RowsNode.new(count: count, heights: heights, gap: gap, **kwargs)
        add_node(node)

        if block && block.arity > 0
          node.row_count.times do |i|
            row_child = SectionNode.new(name: :"row_#{i}_content")
            node.add_child(row_child)
            @stack.push(row_child)
            yield i
            @stack.pop
          end
        elsif block
          @stack.push(node)
          block.call
          @stack.pop
        end

        node
      end

      # Create a 2D grid.
      #
      # @param cols [Integer] Number of columns
      # @param rows [Integer] Number of rows
      # @param col_gap [Numeric] Gap between columns
      # @param row_gap [Numeric] Gap between rows
      # @param kwargs [Hash] Additional constraints
      # @yield [Integer, Integer] Block called for each cell with col and row indices
      # @return [GridNode] The created node
      def grid(cols:, rows:, col_gap: 0, row_gap: 0, **kwargs, &block)
        node = GridNode.new(cols: cols, rows: rows, col_gap: col_gap, row_gap: row_gap, **kwargs)
        add_node(node)

        if block && block.arity == 2
          rows.times do |row_idx|
            cols.times do |col_idx|
              cell_child = SectionNode.new(name: :"cell_#{row_idx}_#{col_idx}_content")
              node.add_child(cell_child)
              @stack.push(cell_child)
              yield col_idx, row_idx
              @stack.pop
            end
          end
        elsif block
          @stack.push(node)
          block.call
          @stack.pop
        end

        node
      end

      # Create a text node.
      #
      # @param content [String] Text content
      # @param style [Symbol] Style name
      # @param align [Symbol] Horizontal alignment
      # @param valign [Symbol] Vertical alignment
      # @param kwargs [Hash] Additional constraints
      # @return [TextNode] The created node
      def text(content, style: :body, align: :left, valign: :top, **kwargs)
        node = TextNode.new(content: content, style: style, align: align, valign: valign, **kwargs)
        add_node(node)
      end

      # Create a field node (writable area).
      #
      # @param name [Symbol] Field name
      # @param lines [Integer, nil] Number of ruled lines
      # @param line_style [Symbol] Line style
      # @param background [Symbol] Background type
      # @param label [String, nil] Optional label
      # @param kwargs [Hash] Additional constraints
      # @return [FieldNode] The created node
      def field(name: nil, lines: nil, line_style: :ruled, background: :blank, label: nil, **kwargs)
        node = FieldNode.new(
          name: name,
          lines: lines,
          line_style: line_style,
          background: background,
          label: label,
          **kwargs
        )
        add_node(node)
      end

      # Create a dot grid node.
      #
      # @param spacing [Numeric] Spacing between dots
      # @param kwargs [Hash] Additional constraints
      # @return [DotGridNode] The created node
      def dot_grid(spacing: 1, **kwargs)
        node = DotGridNode.new(spacing: spacing, **kwargs)
        add_node(node)
      end

      # Create a graph grid node.
      #
      # @param spacing [Numeric] Spacing between lines
      # @param kwargs [Hash] Additional constraints
      # @return [GraphGridNode] The created node
      def graph_grid(spacing: 1, **kwargs)
        node = GraphGridNode.new(spacing: spacing, **kwargs)
        add_node(node)
      end

      # Create ruled lines.
      #
      # @param spacing [Numeric] Line spacing
      # @param line_style [Symbol] Line style
      # @param kwargs [Hash] Additional constraints
      # @return [RuledLinesNode] The created node
      def ruled_lines(spacing: 1, line_style: :solid, **kwargs)
        node = RuledLinesNode.new(spacing: spacing, line_style: line_style, **kwargs)
        add_node(node)
      end

      # Create a spacer node.
      #
      # @param kwargs [Hash] Constraints (height:, flex:, etc.)
      # @return [SpacerNode] The created node
      def spacer(**kwargs)
        node = SpacerNode.new(**kwargs)
        add_node(node)
      end

      # Create a divider line.
      #
      # @param orientation [Symbol] :horizontal or :vertical
      # @param line_style [Symbol] Line style
      # @param thickness [Numeric] Line thickness in points
      # @param kwargs [Hash] Additional constraints
      # @return [DividerNode] The created node
      def divider(orientation: :horizontal, line_style: :solid, thickness: 0.5, **kwargs)
        node = DividerNode.new(
          orientation: orientation,
          line_style: line_style,
          thickness: thickness,
          **kwargs
        )
        add_node(node)
      end

      # Create a navigation link.
      #
      # @param dest [Symbol] Destination page type
      # @param params [Hash] Destination parameters
      # @param label [String, nil] Link label
      # @param icon [String, nil] Icon character
      # @param style [Symbol] Link style
      # @param kwargs [Hash] Additional constraints
      # @return [NavLinkNode] The created node
      def nav_link(dest:, params: {}, label: nil, icon: nil, style: :nav_link, **kwargs)
        node = NavLinkNode.new(
          dest: dest,
          params: params,
          label: label,
          icon: icon,
          style: style,
          **kwargs
        )
        add_node(node)
      end

      # Create a navigation group.
      #
      # @param name [Symbol] Group name
      # @param cycle [Boolean] Whether clicking cycles through pages
      # @param destinations [Array<Symbol>] List of destinations
      # @param kwargs [Hash] Additional constraints
      # @yield Block for adding nav links
      # @return [NavGroupNode] The created node
      def nav_group(name:, cycle: false, destinations: [], **kwargs, &block)
        node = NavGroupNode.new(name: name, cycle: cycle, destinations: destinations, **kwargs)
        add_node(node, &block)
      end

      # Create a tab.
      #
      # @param dest [Symbol, Array<Symbol>] Destination(s)
      # @param label [String] Tab label
      # @param style [Symbol] Tab style
      # @param cycle [Boolean] Whether tab cycles
      # @param rotation [Numeric] Rotation angle
      # @param kwargs [Hash] Additional constraints
      # @return [TabNode] The created node
      def tab(dest:, label:, style: :tab, cycle: false, rotation: -90, **kwargs)
        node = TabNode.new(
          dest: dest,
          label: label,
          style: style,
          cycle: cycle,
          rotation: rotation,
          **kwargs
        )
        add_node(node)
      end

      # Create a content container (generic section that defaults to vertical layout).
      #
      # This is a convenience method for creating a flex section for main content.
      #
      # @param kwargs [Hash] Constraints
      # @yield Block for child nodes
      # @return [SectionNode] The created node
      def content(**kwargs, &block)
        section(name: :content, flex: 1, **kwargs, &block)
      end

      # Instantiate a registered component.
      #
      # Looks up the component by name in the ComponentRegistry and builds
      # an instance with the provided parameters.
      #
      # @param name [Symbol] Component name
      # @param kwargs [Hash] Parameters to pass to the component
      # @raise [ArgumentError] if the component is not registered
      # @return [SectionNode] The created component wrapper node
      #
      # @example Using a component
      #   component :day_header, day: week.days[0]
      def component(name, **kwargs)
        definition = ComponentRegistry.get(name)
        raise ArgumentError, "Unknown component: #{name}" unless definition

        definition.build(self, **kwargs)
      end

      # Create a custom render node.
      #
      # Custom nodes allow arbitrary Prawn drawing within a layout.
      # The block receives the PDF document and bounds in points.
      #
      # @param name [Symbol] Node name
      # @param kwargs [Hash] Constraints (width:, height:, flex:, etc.)
      # @yield [pdf, bounds] Block for custom rendering
      # @return [CustomNode] The created node
      #
      # @example Drawing a circle
      #   custom name: :circle, width: 10, height: 10 do |pdf, bounds|
      #     center_x = bounds[:x] + bounds[:width] / 2
      #     center_y = bounds[:y] - bounds[:height] / 2
      #     pdf.stroke_circle([center_x, center_y], bounds[:width] / 2)
      #   end
      def custom(name: nil, **kwargs, &block)
        node = CustomNode.new(name: name, **kwargs, &block)
        add_node(node)
      end

      private

      # Add a node to the current parent.
      #
      # @param node [LayoutNode] The node to add
      # @yield Optional block for child nodes
      # @return [LayoutNode] The added node
      def add_node(node, &block)
        current_parent.add_child(node)

        if block && !node.is_a?(ContentNode)
          @stack.push(node)
          block.call
          @stack.pop
        end

        node
      end
    end
  end
end
