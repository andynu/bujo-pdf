# frozen_string_literal: true

require_relative 'layout_node'

module BujoPdf
  module DSL
    # ContentNode is a leaf node that represents renderable content.
    #
    # Content nodes don't have children - they represent things that get
    # drawn: text, fields, grids, images, etc. They participate in layout
    # but delegate rendering to a renderer.
    #
    # @abstract Subclasses represent specific content types
    #
    class ContentNode < LayoutNode
      # Content nodes can't have children
      def add_child(_child)
        raise NotImplementedError, "ContentNode cannot have children"
      end
    end

    # TextNode represents styled text content.
    #
    # Text is positioned within its bounds according to alignment settings.
    # Style name references a theme-defined style.
    #
    # @example Simple text
    #   TextNode.new(content: "Week 42", style: :title)
    #
    # @example Aligned text
    #   TextNode.new(content: "Notes", style: :label, align: :center, valign: :center)
    #
    class TextNode < ContentNode
      attr_reader :content, :style, :align, :valign

      # Initialize a text node.
      #
      # @param content [String] The text to display
      # @param style [Symbol] Style name (defined in theme)
      # @param align [Symbol] Horizontal alignment (:left, :center, :right)
      # @param valign [Symbol] Vertical alignment (:top, :center, :bottom)
      # @param kwargs [Hash] Additional constraints
      def initialize(content:, style: :body, align: :left, valign: :top, **kwargs)
        super(**kwargs)
        @content = content
        @style = style
        @align = align
        @valign = valign
      end

      # Get rendering parameters for this node.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :text,
          content: @content,
          style: @style,
          align: @align,
          valign: @valign,
          bounds: @computed_bounds
        }
      end
    end

    # FieldNode represents an empty writable area.
    #
    # Fields are regions where users write by hand. They can have:
    # - Optional ruled lines for writing guides
    # - Optional dot grid background
    # - Optional label
    #
    # @example Simple field
    #   FieldNode.new(name: :notes)
    #
    # @example Lined field
    #   FieldNode.new(name: :tasks, lines: 5, line_style: :ruled)
    #
    # @example Field with dot grid
    #   FieldNode.new(name: :notes, background: :dot_grid)
    #
    class FieldNode < ContentNode
      attr_reader :lines, :line_style, :background, :label

      # Initialize a field node.
      #
      # @param name [Symbol] Field name
      # @param lines [Integer, nil] Number of ruled lines
      # @param line_style [Symbol] Line style (:ruled, :dashed)
      # @param background [Symbol] Background type (:blank, :dot_grid, :graph_grid)
      # @param label [String, nil] Optional label text
      # @param kwargs [Hash] Additional constraints
      def initialize(name: nil, lines: nil, line_style: :ruled, background: :blank, label: nil, **kwargs)
        super(name: name, **kwargs)
        @lines = lines
        @line_style = line_style
        @background = background
        @label = label
      end

      # Get rendering parameters for this node.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :field,
          name: @name,
          lines: @lines,
          line_style: @line_style,
          background: @background,
          label: @label,
          bounds: @computed_bounds
        }
      end
    end

    # DotGridNode fills its area with a dot grid pattern.
    #
    # The dot grid aligns with the page's 5mm grid system.
    #
    # @example Default spacing
    #   DotGridNode.new
    #
    # @example Custom spacing
    #   DotGridNode.new(spacing: 2)  # Every 2 grid boxes
    #
    class DotGridNode < ContentNode
      attr_reader :spacing

      # Initialize a dot grid node.
      #
      # @param spacing [Numeric] Spacing between dots in grid boxes (default: 1)
      # @param kwargs [Hash] Additional constraints
      def initialize(spacing: 1, **kwargs)
        super(**kwargs)
        @spacing = spacing
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :dot_grid,
          spacing: @spacing,
          bounds: @computed_bounds
        }
      end
    end

    # GraphGridNode fills its area with a square grid pattern.
    #
    # @example Default spacing
    #   GraphGridNode.new
    #
    class GraphGridNode < ContentNode
      attr_reader :spacing

      # Initialize a graph grid node.
      #
      # @param spacing [Numeric] Spacing between lines in grid boxes (default: 1)
      # @param kwargs [Hash] Additional constraints
      def initialize(spacing: 1, **kwargs)
        super(**kwargs)
        @spacing = spacing
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :graph_grid,
          spacing: @spacing,
          bounds: @computed_bounds
        }
      end
    end

    # RuledLinesNode fills its area with horizontal ruled lines.
    #
    # @example Default line spacing
    #   RuledLinesNode.new
    #
    # @example Wide spacing
    #   RuledLinesNode.new(spacing: 2)  # Every 2 grid boxes
    #
    class RuledLinesNode < ContentNode
      attr_reader :spacing, :line_style

      # Initialize a ruled lines node.
      #
      # @param spacing [Numeric] Line spacing in grid boxes (default: 1)
      # @param line_style [Symbol] Line style (:solid, :dashed)
      # @param kwargs [Hash] Additional constraints
      def initialize(spacing: 1, line_style: :solid, **kwargs)
        super(**kwargs)
        @spacing = spacing
        @line_style = line_style
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :ruled_lines,
          spacing: @spacing,
          line_style: @line_style,
          bounds: @computed_bounds
        }
      end
    end

    # SpacerNode is invisible and just takes up space.
    #
    # Useful for pushing content apart or creating fixed gaps.
    #
    # @example Fixed spacer
    #   SpacerNode.new(height: 2)
    #
    # @example Flexible spacer (pushes surrounding content apart)
    #   SpacerNode.new(flex: 1)
    #
    class SpacerNode < ContentNode
      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering (basically nothing)
      def render_params
        {
          type: :spacer,
          bounds: @computed_bounds
        }
      end
    end

    # DividerNode renders a horizontal or vertical line.
    #
    # @example Horizontal divider
    #   DividerNode.new(orientation: :horizontal)
    #
    # @example Vertical divider
    #   DividerNode.new(orientation: :vertical, style: :dashed)
    #
    class DividerNode < ContentNode
      attr_reader :orientation, :line_style, :thickness

      # Initialize a divider node.
      #
      # @param orientation [Symbol] :horizontal or :vertical
      # @param line_style [Symbol] Line style (:solid, :dashed, :dotted)
      # @param thickness [Numeric] Line thickness in points (default: 0.5)
      # @param kwargs [Hash] Additional constraints (height: for horizontal, width: for vertical)
      def initialize(orientation: :horizontal, line_style: :solid, thickness: 0.5, **kwargs)
        super(**kwargs)
        @orientation = orientation
        @line_style = line_style
        @thickness = thickness
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :divider,
          orientation: @orientation,
          line_style: @line_style,
          thickness: @thickness,
          bounds: @computed_bounds
        }
      end
    end
  end
end
