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

      # Get the element type for style resolution.
      #
      # Override in subclasses to return the element type used for
      # looking up default styles in themes.
      #
      # @return [Symbol] The element type
      def element_type
        :content
      end

      # Get inline styles specified on this node.
      #
      # Override in subclasses to return style properties that were
      # specified directly on the node (not through a style reference).
      #
      # @return [Hash] Inline style properties
      def inline_styles
        {}
      end

      # Get the named style reference (if any).
      #
      # @return [Symbol, nil] Style name or nil
      def style_ref
        nil
      end

      # Resolve styles for this node using a StyleResolver.
      #
      # Combines element defaults, named style, and inline styles.
      #
      # @param resolver [StyleResolver] The style resolver to use
      # @return [Hash] Resolved style properties
      def resolved_styles(resolver)
        resolver.resolve(element_type, style: style_ref, **inline_styles)
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
    # @example With inline style overrides
    #   TextNode.new(content: "Custom", style: :title, font_size: 18)
    #
    class TextNode < ContentNode
      attr_reader :content, :style, :align, :valign, :font_size, :font_weight, :color

      # Style properties that can be specified inline
      STYLE_PROPERTIES = %i[font_size font_weight font_family font_style color].freeze

      # Initialize a text node.
      #
      # @param content [String] The text to display
      # @param style [Symbol] Style name (defined in theme)
      # @param align [Symbol] Horizontal alignment (:left, :center, :right)
      # @param valign [Symbol] Vertical alignment (:top, :center, :bottom)
      # @param font_size [Numeric, nil] Inline font size override
      # @param font_weight [Symbol, nil] Inline font weight override
      # @param font_family [String, nil] Inline font family override
      # @param font_style [Symbol, nil] Inline font style override
      # @param color [String, nil] Inline color override (hex string)
      # @param kwargs [Hash] Additional constraints
      def initialize(content:, style: :body, align: :left, valign: :top,
                     font_size: nil, font_weight: nil, font_family: nil,
                     font_style: nil, color: nil, **kwargs)
        super(**kwargs)
        @content = content
        @style = style
        @align = align
        @valign = valign
        @font_size = font_size
        @font_weight = font_weight
        @font_family = font_family
        @font_style = font_style
        @color = color
      end

      # @return [Symbol] Element type for style resolution
      def element_type
        :text
      end

      # @return [Symbol, nil] Named style reference
      def style_ref
        @style
      end

      # Get inline style properties.
      #
      # Returns only the style properties that were explicitly set.
      #
      # @return [Hash] Inline style properties
      def inline_styles
        result = {}
        result[:font_size] = @font_size if @font_size
        result[:font_weight] = @font_weight if @font_weight
        result[:font_family] = @font_family if @font_family
        result[:font_style] = @font_style if @font_style
        result[:color] = @color if @color
        result
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
          inline_styles: inline_styles,
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

      # @return [Symbol] Element type for style resolution
      def element_type
        :field
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
      attr_reader :spacing, :dot_color, :dot_radius

      # Initialize a dot grid node.
      #
      # @param spacing [Numeric] Spacing between dots in grid boxes (default: 1)
      # @param dot_color [String, nil] Dot color (hex string)
      # @param dot_radius [Numeric, nil] Dot radius in points
      # @param kwargs [Hash] Additional constraints
      def initialize(spacing: 1, dot_color: nil, dot_radius: nil, **kwargs)
        super(**kwargs)
        @spacing = spacing
        @dot_color = dot_color
        @dot_radius = dot_radius
      end

      # @return [Symbol] Element type for style resolution
      def element_type
        :dot_grid
      end

      # @return [Hash] Inline style properties
      def inline_styles
        result = {}
        result[:dot_color] = @dot_color if @dot_color
        result[:dot_radius] = @dot_radius if @dot_radius
        result
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :dot_grid,
          spacing: @spacing,
          inline_styles: inline_styles,
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
      attr_reader :spacing, :line_color, :line_width

      # Initialize a graph grid node.
      #
      # @param spacing [Numeric] Spacing between lines in grid boxes (default: 1)
      # @param line_color [String, nil] Line color (hex string)
      # @param line_width [Numeric, nil] Line width in points
      # @param kwargs [Hash] Additional constraints
      def initialize(spacing: 1, line_color: nil, line_width: nil, **kwargs)
        super(**kwargs)
        @spacing = spacing
        @line_color = line_color
        @line_width = line_width
      end

      # @return [Symbol] Element type for style resolution
      def element_type
        :graph_grid
      end

      # @return [Hash] Inline style properties
      def inline_styles
        result = {}
        result[:line_color] = @line_color if @line_color
        result[:line_width] = @line_width if @line_width
        result
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :graph_grid,
          spacing: @spacing,
          inline_styles: inline_styles,
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
      attr_reader :spacing, :line_style, :line_color, :line_width

      # Initialize a ruled lines node.
      #
      # @param spacing [Numeric] Line spacing in grid boxes (default: 1)
      # @param line_style [Symbol] Line style (:solid, :dashed)
      # @param line_color [String, nil] Line color (hex string)
      # @param line_width [Numeric, nil] Line width in points
      # @param kwargs [Hash] Additional constraints
      def initialize(spacing: 1, line_style: :solid, line_color: nil, line_width: nil, **kwargs)
        super(**kwargs)
        @spacing = spacing
        @line_style = line_style
        @line_color = line_color
        @line_width = line_width
      end

      # @return [Symbol] Element type for style resolution
      def element_type
        :ruled_lines
      end

      # @return [Hash] Inline style properties
      def inline_styles
        result = {}
        result[:line_color] = @line_color if @line_color
        result[:line_width] = @line_width if @line_width
        result
      end

      # Get rendering parameters.
      #
      # @return [Hash] Parameters for rendering
      def render_params
        {
          type: :ruled_lines,
          spacing: @spacing,
          line_style: @line_style,
          inline_styles: inline_styles,
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
      # @return [Symbol] Element type for style resolution
      def element_type
        :spacer
      end

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
      attr_reader :orientation, :line_style, :thickness, :color

      # Initialize a divider node.
      #
      # @param orientation [Symbol] :horizontal or :vertical
      # @param line_style [Symbol] Line style (:solid, :dashed, :dotted)
      # @param thickness [Numeric] Line thickness in points (default: 0.5)
      # @param color [String, nil] Line color (hex string)
      # @param kwargs [Hash] Additional constraints (height: for horizontal, width: for vertical)
      def initialize(orientation: :horizontal, line_style: :solid, thickness: 0.5, color: nil, **kwargs)
        super(**kwargs)
        @orientation = orientation
        @line_style = line_style
        @thickness = thickness
        @color = color
      end

      # @return [Symbol] Element type for style resolution
      def element_type
        :divider
      end

      # @return [Hash] Inline style properties
      def inline_styles
        result = {}
        result[:thickness] = @thickness if @thickness != 0.5  # Only if non-default
        result[:color] = @color if @color
        result
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
          inline_styles: inline_styles,
          bounds: @computed_bounds
        }
      end
    end
  end
end
