# frozen_string_literal: true

require_relative '../base/component'
require_relative 'hline'

module BujoPdf
  module Components
    # Text renders text at a grid position with various styling options.
    #
    # Base text component that handles grid-aligned text rendering.
    # Supports font size, style, alignment, positioning, and optional
    # dot/line erasure for text that overlaps grid elements.
    #
    # This is the foundation for H1, H2, and other text components.
    #
    # Example usage in a page:
    #   text(2, 52, "Page 1 of 2", size: 9, align: :center, width: 39)
    #   text(2, 5, "Note", size: 12, style: :bold)
    #
    class Text < Component
      include HLine::Mixin

      # Default font size
      DEFAULT_SIZE = 10

      # Mixin providing the text verb for pages and components
      module Mixin
        # Render text at a grid position
        #
        # @param col [Integer] Column position (left edge)
        # @param row [Integer] Row position (top edge)
        # @param content [String] Text to render
        # @param size [Integer] Font size in points (default: 10)
        # @param height [Integer] Height in grid boxes (default: 1)
        # @param color [String, nil] Text color as hex string (default: theme text_black)
        # @param style [Symbol] Font style :normal, :bold, :italic (default: :normal)
        # @param position [Symbol] Vertical position :center, :superscript, :subscript (default: :center)
        # @param align [Symbol] Text alignment :left, :center, :right (default: :left)
        # @param width [Integer, nil] Width in grid boxes (default: nil, auto-sized)
        # @param rotation [Integer] Rotation in degrees: 0, 90, -90 (default: 0)
        # @param pt_x [Float, nil] X position in points (overrides col when set)
        # @param pt_y [Float, nil] Y position in points (overrides row when set)
        # @param pt_width [Float, nil] Width in points (overrides width when set)
        # @param pt_height [Float, nil] Height in points (overrides height when set)
        # @param centered [Boolean] When true with rotation, pt_x/pt_y specify the center
        #   point of the text box (and rotation origin) instead of top-left (default: false)
        # @return [void]
        def text(col, row, content, size: DEFAULT_SIZE, height: 1, color: nil, style: :normal, position: :center, align: :left, width: nil, rotation: 0, pt_x: nil, pt_y: nil, pt_width: nil, pt_height: nil, centered: false)
          c = @canvas || Canvas.new(@pdf, @grid)
          Text.new(
            canvas: c,
            col: col,
            row: row,
            content: content,
            size: size,
            height: height,
            color: color,
            style: style,
            position: position,
            align: align,
            width: width,
            rotation: rotation,
            pt_x: pt_x,
            pt_y: pt_y,
            pt_width: pt_width,
            pt_height: pt_height,
            centered: centered
          ).render
        end
      end

      # Initialize a new Text component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Column position (left edge)
      # @param row [Integer] Row position (top edge)
      # @param content [String] Text to render
      # @param size [Integer] Font size in points
      # @param height [Integer] Height in grid boxes
      # @param color [String, nil] Text color as hex string
      # @param style [Symbol] Font style
      # @param position [Symbol] Vertical position :center, :superscript, :subscript
      # @param align [Symbol] Text alignment :left, :center, :right
      # @param width [Integer, nil] Width in grid boxes
      # @param rotation [Integer] Rotation in degrees: 0, 90, -90
      # @param pt_x [Float, nil] X position in points (overrides col when set)
      # @param pt_y [Float, nil] Y position in points (overrides row when set)
      # @param pt_width [Float, nil] Width in points (overrides width when set)
      # @param pt_height [Float, nil] Height in points (overrides height when set)
      # @param centered [Boolean] When true, pt_x/pt_y specify the center point
      def initialize(canvas:, col:, row:, content:, size: DEFAULT_SIZE, height: 1, color: nil, style: :normal, position: :center, align: :left, width: nil, rotation: 0, pt_x: nil, pt_y: nil, pt_width: nil, pt_height: nil, centered: false)
        super(canvas: canvas)
        @col = col
        @row = row
        @content = content
        @size = size
        @height = height
        @color = color
        @style = style
        @position = position
        @align = align
        @width = width
        @rotation = rotation
        @pt_x = pt_x
        @pt_y = pt_y
        @pt_width = pt_width
        @pt_height = pt_height
        @centered = centered
      end

      # Render the text
      #
      # @return [void]
      def render
        require_relative '../themes/theme_registry'

        text_color = @color || BujoPdf::Themes.current[:colors][:text_black]
        bg_color = BujoPdf::Themes.current[:colors][:background]

        pdf.font 'Helvetica', style: @style, size: @size

        if @rotation != 0
          render_rotated(text_color)
        else
          render_normal(text_color, bg_color)
        end

        # Reset to defaults
        pdf.font 'Helvetica', style: :normal
        pdf.fill_color BujoPdf::Themes.current[:colors][:text_black]
      end

      private

      # Render text without rotation (normal case)
      #
      # @param text_color [String] Text color as hex string
      # @param bg_color [String] Background color for dot erasure
      # @return [void]
      def render_normal(text_color, bg_color)
        # Calculate text width for erasure (round to nearest, not ceil)
        text_width_pt = pdf.width_of(@content)
        text_width_boxes = (text_width_pt / grid.dot_spacing).round

        # Determine render width (explicit or auto)
        render_width_boxes = @width || 40

        # Calculate vertical offset and handle dot/line erasure
        y_offset = calculate_y_offset
        erase_dots_if_needed(text_width_boxes, bg_color)

        # Draw the text
        pdf.fill_color text_color
        pdf.text_box @content,
                      at: [grid.x(@col), grid.y(@row) + y_offset],
                      width: grid.width(render_width_boxes),
                      height: grid.height(@height),
                      size: @size,
                      align: @align,
                      valign: :center,
                      overflow: :truncate
      end

      # Render text with rotation
      #
      # Rotation is applied around the center of the text box.
      # Dot erasure is disabled for rotated text (not needed for label use cases).
      #
      # When pt_x/pt_y/pt_width/pt_height are provided, uses pixel-based
      # positioning instead of grid-based. This is useful for components
      # that need precise pixel positioning (e.g., RightSidebar tabs).
      #
      # When centered: true, pt_x/pt_y specify the CENTER of the text box
      # (and rotation origin). The text box is positioned so its center
      # coincides with this point. This is useful for rotated labels in
      # narrow spaces like sidebar tabs.
      #
      # @param text_color [String] Text color as hex string
      # @return [void]
      def render_rotated(text_color)
        # Calculate text box dimensions in points
        # Use pixel overrides if provided, otherwise grid-based
        box_width = @pt_width || grid.width(@width || 1)
        box_height = @pt_height || grid.height(@height)

        if @centered && @pt_x && @pt_y
          # Centered mode: pt_x/pt_y specify the center point
          center_x = @pt_x
          center_y = @pt_y
          # Position text box so its center is at (center_x, center_y)
          box_x = center_x - (box_width / 2.0)
          box_top = center_y + (box_height / 2.0)
        else
          # Default mode: pt_x/pt_y specify the top-left corner
          box_x = @pt_x || grid.x(@col)
          box_top = @pt_y || grid.y(@row)
          # Calculate center from box position
          center_x = box_x + (box_width / 2.0)
          center_y = (box_top - box_height) + (box_height / 2.0)
        end

        pdf.fill_color text_color
        pdf.rotate(@rotation, origin: [center_x, center_y]) do
          pdf.text_box @content,
                        at: [box_x, box_top],
                        width: box_width,
                        height: box_height,
                        size: @size,
                        align: @align,
                        valign: :center,
                        overflow: :truncate
        end
      end

      # Calculate vertical offset based on position
      #
      # @return [Float] Y offset in points
      def calculate_y_offset
        half_box = grid.height(0.5)
        case @position
        when :superscript
          half_box
        when :subscript
          -half_box
        else
          0
        end
      end

      # Erase dots/lines if position shifts text onto a grid row
      #
      # @param text_width_boxes [Integer] Width of text in grid boxes
      # @param bg_color [String] Background color for erasing
      # @return [void]
      def erase_dots_if_needed(text_width_boxes, bg_color)
        return if @position == :center && @height == 1

        if @position != :center
          # Superscript text overlaps the top dot row (@row)
          # Subscript text overlaps the bottom dot row (@row + @height)
          erase_row = @position == :superscript ? @row : @row + @height
          erase_col = calculate_erase_col(text_width_boxes)
          hline(erase_col, erase_row, text_width_boxes, color: bg_color, stroke: 3)
        elsif @height >= 2
          # Multi-row text has middle rows that may have dots
          # Erase middle rows (not top or bottom edges)
          1.upto(@height - 1) do |offset|
            hline(@col, @row + offset, text_width_boxes, color: bg_color, stroke: 3)
          end
        end
      end

      # Calculate the starting column for erasing based on alignment
      #
      # @param text_width_boxes [Integer] Width of text in grid boxes
      # @return [Integer] Starting column for erase
      def calculate_erase_col(text_width_boxes)
        return @col if @align == :left || @width.nil?

        render_width_boxes = @width
        case @align
        when :center
          @col + ((render_width_boxes - text_width_boxes) / 2.0).floor
        when :right
          @col + render_width_boxes - text_width_boxes
        else
          @col
        end
      end
    end
  end
end
