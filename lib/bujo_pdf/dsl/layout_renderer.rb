# frozen_string_literal: true

require_relative 'style_resolver'

module BujoPdf
  module DSL
    # LayoutRenderer converts computed layout trees into Prawn PDF content.
    #
    # After a layout tree has had its bounds computed, the renderer walks
    # the tree and generates Prawn calls to draw each node. The renderer
    # handles coordinate system conversion (grid units to points) and
    # style resolution.
    #
    # @example Rendering a layout
    #   # Build and compute layout
    #   builder = LayoutBuilder.new
    #   builder.section(name: :content, flex: 1) do
    #     builder.text("Hello", style: :title)
    #   end
    #   root = builder.root
    #   root.compute_bounds(col: 0, row: 0, width: 43, height: 55)
    #
    #   # Render to PDF
    #   renderer = LayoutRenderer.new(pdf, theme: my_theme)
    #   renderer.render(root)
    #
    class LayoutRenderer
      include Styling::Grid

      # Initialize a layout renderer.
      #
      # @param pdf [Prawn::Document] The PDF document to render to
      # @param theme [Theme, nil] The theme for style resolution
      # @param grid_system [GridSystem, nil] Grid system for coordinate conversion
      def initialize(pdf, theme: nil, grid_system: nil)
        @pdf = pdf
        @theme = theme
        @style_resolver = theme ? StyleResolver.new(theme) : nil
        @grid_system = grid_system
      end

      # Render a layout tree to the PDF.
      #
      # @param root [LayoutNode] The root node of the computed layout tree
      def render(root)
        render_node(root)
      end

      private

      # Render a single node and its children.
      #
      # @param node [LayoutNode] The node to render
      def render_node(node)
        bounds = node.computed_bounds
        return unless bounds

        # Dispatch to type-specific renderer
        case node
        when TextNode
          render_text(node, bounds)
        when DotGridNode
          render_dot_grid(node, bounds)
        when GraphGridNode
          render_graph_grid(node, bounds)
        when RuledLinesNode
          render_ruled_lines(node, bounds)
        when DividerNode
          render_divider(node, bounds)
        when FieldNode
          render_field(node, bounds)
        when SpacerNode
          # Spacers are invisible - nothing to render
        when NavLinkNode
          render_nav_link(node, bounds)
        when TabNode
          render_tab(node, bounds)
        when CustomNode
          render_custom(node, bounds)
        end

        # Render children
        node.children.each { |child| render_node(child) }
      end

      # Convert grid bounds to point coordinates.
      #
      # @param bounds [Hash] Grid bounds { col:, row:, width:, height: }
      # @return [Hash] Point bounds { x:, y:, width:, height: }
      def grid_to_points(bounds)
        if @grid_system
          x = @grid_system.x(bounds[:col])
          y = @grid_system.y(bounds[:row])
          width = @grid_system.width(bounds[:width])
          height = @grid_system.height(bounds[:height])
        else
          # Fallback: assume DOT_SPACING conversion
          x = bounds[:col] * DOT_SPACING
          y = PAGE_HEIGHT - (bounds[:row] * DOT_SPACING)
          width = bounds[:width] * DOT_SPACING
          height = bounds[:height] * DOT_SPACING
        end

        { x: x, y: y, width: width, height: height }
      end

      # Render a text node.
      #
      # @param node [TextNode] The text node
      # @param bounds [Hash] Grid bounds
      def render_text(node, bounds)
        pt = grid_to_points(bounds)

        # Resolve styles
        styles = if @style_resolver
          node.resolved_styles(@style_resolver)
        else
          node.inline_styles
        end

        # Set font properties
        font_size = styles[:font_size] || 10
        font_family = styles[:font_family] || 'Helvetica'
        font_style = resolve_font_style(styles)
        color = styles[:color] || '000000'

        @pdf.font(font_family, style: font_style) do
          @pdf.fill_color(color)
          @pdf.text_box(
            node.content,
            at: [pt[:x], pt[:y]],
            width: pt[:width],
            height: pt[:height],
            size: font_size,
            align: node.align,
            valign: node.valign,
            overflow: :shrink_to_fit
          )
        end
      end

      # Resolve Prawn font style from style properties.
      #
      # @param styles [Hash] Style properties
      # @return [Symbol] Prawn font style
      def resolve_font_style(styles)
        weight = styles[:font_weight]
        style = styles[:font_style]

        if weight == :bold && style == :italic
          :bold_italic
        elsif weight == :bold
          :bold
        elsif style == :italic
          :italic
        else
          :normal
        end
      end

      # Render a dot grid node.
      #
      # @param node [DotGridNode] The dot grid node
      # @param bounds [Hash] Grid bounds
      def render_dot_grid(node, bounds)
        pt = grid_to_points(bounds)

        # Resolve styles
        styles = if @style_resolver
          node.resolved_styles(@style_resolver)
        else
          node.inline_styles
        end

        dot_color = styles[:dot_color] || 'CCCCCC'
        dot_radius = styles[:dot_radius] || 0.5
        spacing_pts = node.spacing * DOT_SPACING

        @pdf.fill_color(dot_color)

        # Draw dots within the bounds
        x = pt[:x]
        while x <= pt[:x] + pt[:width]
          y = pt[:y]
          while y >= pt[:y] - pt[:height]
            @pdf.fill_circle([x, y], dot_radius)
            y -= spacing_pts
          end
          x += spacing_pts
        end
      end

      # Render a graph grid node.
      #
      # @param node [GraphGridNode] The graph grid node
      # @param bounds [Hash] Grid bounds
      def render_graph_grid(node, bounds)
        pt = grid_to_points(bounds)

        styles = if @style_resolver
          node.resolved_styles(@style_resolver)
        else
          node.inline_styles
        end

        line_color = styles[:line_color] || 'CCCCCC'
        line_width = styles[:line_width] || 0.25
        spacing_pts = node.spacing * DOT_SPACING

        @pdf.stroke_color(line_color)
        @pdf.line_width(line_width)

        # Vertical lines
        x = pt[:x]
        while x <= pt[:x] + pt[:width]
          @pdf.stroke_line([x, pt[:y]], [x, pt[:y] - pt[:height]])
          x += spacing_pts
        end

        # Horizontal lines
        y = pt[:y]
        while y >= pt[:y] - pt[:height]
          @pdf.stroke_line([pt[:x], y], [pt[:x] + pt[:width], y])
          y -= spacing_pts
        end
      end

      # Render a ruled lines node.
      #
      # @param node [RuledLinesNode] The ruled lines node
      # @param bounds [Hash] Grid bounds
      def render_ruled_lines(node, bounds)
        pt = grid_to_points(bounds)

        styles = if @style_resolver
          node.resolved_styles(@style_resolver)
        else
          node.inline_styles
        end

        line_color = styles[:line_color] || 'CCCCCC'
        line_width = styles[:line_width] || 0.25
        spacing_pts = node.spacing * DOT_SPACING

        @pdf.stroke_color(line_color)
        @pdf.line_width(line_width)

        # Apply line style
        case node.line_style
        when :dashed
          @pdf.dash(3, space: 2)
        when :dotted
          @pdf.dash(1, space: 2)
        end

        # Horizontal lines
        y = pt[:y]
        while y >= pt[:y] - pt[:height]
          @pdf.stroke_line([pt[:x], y], [pt[:x] + pt[:width], y])
          y -= spacing_pts
        end

        @pdf.undash if node.line_style != :solid
      end

      # Render a divider node.
      #
      # @param node [DividerNode] The divider node
      # @param bounds [Hash] Grid bounds
      def render_divider(node, bounds)
        pt = grid_to_points(bounds)

        styles = if @style_resolver
          node.resolved_styles(@style_resolver)
        else
          node.inline_styles
        end

        color = styles[:color] || 'CCCCCC'
        thickness = styles[:thickness] || node.thickness

        @pdf.stroke_color(color)
        @pdf.line_width(thickness)

        # Apply line style
        case node.line_style
        when :dashed
          @pdf.dash(3, space: 2)
        when :dotted
          @pdf.dash(1, space: 2)
        end

        if node.orientation == :horizontal
          center_y = pt[:y] - pt[:height] / 2
          @pdf.stroke_line([pt[:x], center_y], [pt[:x] + pt[:width], center_y])
        else
          center_x = pt[:x] + pt[:width] / 2
          @pdf.stroke_line([center_x, pt[:y]], [center_x, pt[:y] - pt[:height]])
        end

        @pdf.undash if node.line_style != :solid
      end

      # Render a field node.
      #
      # @param node [FieldNode] The field node
      # @param bounds [Hash] Grid bounds
      def render_field(node, bounds)
        pt = grid_to_points(bounds)

        # Render background if specified
        case node.background
        when :dot_grid
          render_dot_grid_area(pt)
        when :graph_grid
          render_graph_grid_area(pt)
        end

        # Render ruled lines if specified
        if node.lines
          render_field_lines(node, pt)
        end

        # Render label if specified
        if node.label
          render_field_label(node, pt)
        end
      end

      # Render dot grid within an area.
      def render_dot_grid_area(pt)
        @pdf.fill_color('CCCCCC')
        x = pt[:x]
        while x <= pt[:x] + pt[:width]
          y = pt[:y]
          while y >= pt[:y] - pt[:height]
            @pdf.fill_circle([x, y], 0.5)
            y -= DOT_SPACING
          end
          x += DOT_SPACING
        end
      end

      # Render graph grid within an area.
      def render_graph_grid_area(pt)
        @pdf.stroke_color('CCCCCC')
        @pdf.line_width(0.25)

        x = pt[:x]
        while x <= pt[:x] + pt[:width]
          @pdf.stroke_line([x, pt[:y]], [x, pt[:y] - pt[:height]])
          x += DOT_SPACING
        end

        y = pt[:y]
        while y >= pt[:y] - pt[:height]
          @pdf.stroke_line([pt[:x], y], [pt[:x] + pt[:width], y])
          y -= DOT_SPACING
        end
      end

      # Render ruled lines for a field.
      def render_field_lines(node, pt)
        @pdf.stroke_color('CCCCCC')
        @pdf.line_width(0.25)

        case node.line_style
        when :dashed
          @pdf.dash(3, space: 2)
        end

        line_spacing = pt[:height] / (node.lines + 1)
        (1..node.lines).each do |i|
          y = pt[:y] - (i * line_spacing)
          @pdf.stroke_line([pt[:x], y], [pt[:x] + pt[:width], y])
        end

        @pdf.undash if node.line_style == :dashed
      end

      # Render field label.
      def render_field_label(node, pt)
        @pdf.fill_color('888888')
        @pdf.font('Helvetica', size: 8) do
          @pdf.text_box(
            node.label,
            at: [pt[:x] + 2, pt[:y] - 2],
            width: pt[:width] - 4,
            height: 12
          )
        end
      end

      # Render a navigation link node.
      #
      # @param node [NavLinkNode] The nav link node
      # @param bounds [Hash] Grid bounds
      def render_nav_link(node, bounds)
        pt = grid_to_points(bounds)

        # Draw label if present
        if node.label
          @pdf.fill_color('666666')
          @pdf.font('Helvetica', size: 8) do
            @pdf.text_box(
              node.label,
              at: [pt[:x], pt[:y]],
              width: pt[:width],
              height: pt[:height],
              align: :center,
              valign: :center
            )
          end
        end

        # Create link annotation
        # Note: destination_key should be resolved by the LinkResolver
        @pdf.link_annotation(
          [pt[:x], pt[:y] - pt[:height], pt[:x] + pt[:width], pt[:y]],
          Dest: node.destination_key,
          Border: [0, 0, 0]
        )
      end

      # Render a tab node.
      #
      # @param node [TabNode] The tab node
      # @param bounds [Hash] Grid bounds
      def render_tab(node, bounds)
        pt = grid_to_points(bounds)

        # Draw rotated label
        @pdf.fill_color('666666')
        @pdf.font('Helvetica', size: 8) do
          center_x = pt[:x] + pt[:width] / 2
          center_y = pt[:y] - pt[:height] / 2

          @pdf.rotate(node.rotation, origin: [center_x, center_y]) do
            @pdf.text_box(
              node.label,
              at: [center_x - 40, center_y + 6],
              width: 80,
              height: 12,
              align: :center,
              valign: :center
            )
          end
        end

        # Create link annotation for first destination
        dest = node.destinations.first
        @pdf.link_annotation(
          [pt[:x], pt[:y] - pt[:height], pt[:x] + pt[:width], pt[:y]],
          Dest: dest.to_s,
          Border: [0, 0, 0]
        )
      end

      # Render a custom node with a render block.
      #
      # @param node [CustomNode] The custom node
      # @param bounds [Hash] Grid bounds
      def render_custom(node, bounds)
        pt = grid_to_points(bounds)
        node.render_block&.call(@pdf, pt)
      end
    end

    # CustomNode allows arbitrary Prawn drawing within a layout.
    #
    # Use this for specialized rendering that doesn't fit the standard
    # content nodes, such as circles, arbitrary lines, etc.
    #
    # @example Drawing a circle
    #   CustomNode.new(name: :reference_circle) do |pdf, bounds|
    #     center_x = bounds[:x] + bounds[:width] / 2
    #     center_y = bounds[:y] - bounds[:height] / 2
    #     radius = [bounds[:width], bounds[:height]].min / 2
    #     pdf.stroke_circle([center_x, center_y], radius)
    #   end
    #
    class CustomNode < ContentNode
      attr_reader :render_block

      # Initialize a custom node.
      #
      # @param name [Symbol] Node name
      # @param kwargs [Hash] Constraints
      # @yield [pdf, bounds] Block that renders custom content
      def initialize(name: nil, **kwargs, &block)
        super(name: name, **kwargs)
        @render_block = block
      end

      # @return [Symbol] Element type for style resolution
      def element_type
        :custom
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :custom,
          name: @name,
          bounds: @computed_bounds
        }
      end
    end
  end
end
