# frozen_string_literal: true

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
    class Text
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
        # @return [void]
        def text(col, row, content, size: DEFAULT_SIZE, height: 1, color: nil, style: :normal, position: :center, align: :left, width: nil)
          Text.new(
            pdf: @pdf,
            grid: @grid,
            col: col,
            row: row,
            content: content,
            size: size,
            height: height,
            color: color,
            style: style,
            position: position,
            align: align,
            width: width
          ).render
        end
      end

      # Initialize a new Text component
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param grid [GridSystem] The grid system for coordinate conversion
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
      def initialize(pdf:, grid:, col:, row:, content:, size: DEFAULT_SIZE, height: 1, color: nil, style: :normal, position: :center, align: :left, width: nil)
        @pdf = pdf
        @grid = grid
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
      end

      # Render the text
      #
      # @return [void]
      def render
        require_relative '../themes/theme_registry'

        text_color = @color || BujoPdf::Themes.current[:colors][:text_black]
        bg_color = BujoPdf::Themes.current[:colors][:background]

        @pdf.font 'Helvetica', style: @style, size: @size

        # Calculate text width for erasure (round to nearest, not ceil)
        text_width_pt = @pdf.width_of(@content)
        text_width_boxes = (text_width_pt / @grid.dot_spacing).round

        # Determine render width (explicit or auto)
        render_width_boxes = @width || 40

        # Calculate vertical offset and handle dot/line erasure
        y_offset = calculate_y_offset
        erase_dots_if_needed(text_width_boxes, bg_color)

        # Draw the text
        @pdf.fill_color text_color
        @pdf.text_box @content,
                      at: [@grid.x(@col), @grid.y(@row) + y_offset],
                      width: @grid.width(render_width_boxes),
                      height: @grid.height(@height),
                      size: @size,
                      align: @align,
                      valign: :center,
                      overflow: :truncate

        # Reset to defaults
        @pdf.font 'Helvetica', style: :normal
        @pdf.fill_color BujoPdf::Themes.current[:colors][:text_black]
      end

      private

      # Calculate vertical offset based on position
      #
      # @return [Float] Y offset in points
      def calculate_y_offset
        half_box = @grid.height(0.5)
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
