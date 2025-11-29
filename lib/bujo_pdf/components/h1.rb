# frozen_string_literal: true

require_relative 'hline'

module BujoPdf
  module Components
    # H1 renders a primary header, one grid box tall.
    #
    # Simple header component that renders bold text positioned at a grid
    # location. Width can be explicit or determined by text content.
    #
    # Supports three vertical positions:
    # - :center (default) - centered within the grid box
    # - :superscript - centered on the top dot row (half box up)
    # - :subscript - centered on the bottom dot row (half box down)
    #
    # Supports text alignment:
    # - :left (default) - left-aligned
    # - :center - centered within width
    # - :right - right-aligned within width
    #
    # Example usage in a page:
    #   h1(2, 1, "Index")
    #   h1(2, 1, "January 2025", color: '333333')
    #   h1(2, 1, "Legend", position: :subscript)
    #   h1(2, 1, "Centered", width: 20, align: :center)
    #
    class H1
      include HLine::Mixin

      # Default font size for H1 headers (fits in 1 box = ~14pt)
      FONT_SIZE = 12

      # Mixin providing the h1 verb for pages
      #
      # Include via Components::All in Pages::Base
      module Mixin
        # Render an H1 header at a grid position
        #
        # @param col [Integer] Column position (left edge)
        # @param row [Integer] Row position (top edge)
        # @param text [String] Header text
        # @param color [String, nil] Text color as hex string (default: theme text_black)
        # @param style [Symbol] Font style :bold, :normal, :italic (default: :bold)
        # @param position [Symbol] Vertical position :center, :superscript, :subscript (default: :center)
        # @param align [Symbol] Text alignment :left, :center, :right (default: :left)
        # @param width [Integer, nil] Width in grid boxes (default: nil, auto-sized)
        # @return [void]
        def h1(col, row, text, color: nil, style: :bold, position: :center, align: :left, width: nil)
          H1.new(
            pdf: @pdf,
            grid: @grid,
            col: col,
            row: row,
            text: text,
            color: color,
            style: style,
            position: position,
            align: align,
            width: width
          ).render
        end
      end

      # Initialize a new H1 component
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param grid [GridSystem] The grid system for coordinate conversion
      # @param col [Integer] Column position (left edge)
      # @param row [Integer] Row position (top edge)
      # @param text [String] Header text
      # @param color [String, nil] Text color as hex string
      # @param style [Symbol] Font style
      # @param position [Symbol] Vertical position :center, :superscript, :subscript
      # @param align [Symbol] Text alignment :left, :center, :right
      # @param width [Integer, nil] Width in grid boxes
      def initialize(pdf:, grid:, col:, row:, text:, color: nil, style: :bold, position: :center, align: :left, width: nil)
        @pdf = pdf
        @grid = grid
        @col = col
        @row = row
        @text = text
        @color = color
        @style = style
        @position = position
        @align = align
        @width = width
      end

      # Render the H1 header
      #
      # @return [void]
      def render
        require_relative '../themes/theme_registry'

        text_color = @color || BujoPdf::Themes.current[:colors][:text_black]
        bg_color = BujoPdf::Themes.current[:colors][:background]

        @pdf.font 'Helvetica', style: @style, size: FONT_SIZE

        # Calculate text width in points and boxes
        text_width_pt = @pdf.width_of(@text)
        text_width_boxes = (text_width_pt / @grid.dot_spacing).ceil

        # Determine render width (explicit or auto)
        render_width_boxes = @width || 40

        # Calculate vertical offset and erase dots/lines if needed
        y_offset = calculate_y_offset
        erase_dot_row(text_width_boxes, bg_color) if @position != :center

        # Draw the text
        @pdf.fill_color text_color
        @pdf.text_box @text,
                      at: [@grid.x(@col), @grid.y(@row) + y_offset],
                      width: @grid.width(render_width_boxes),
                      height: @grid.height(1),
                      size: FONT_SIZE,
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

      # Erase the dot row that the text overlaps
      #
      # @param text_width_boxes [Integer] Width of text in grid boxes
      # @param bg_color [String] Background color for erasing
      # @return [void]
      def erase_dot_row(text_width_boxes, bg_color)
        # Superscript text is centered on @row (top of box)
        # Subscript text is centered on @row + 1 (bottom of box)
        erase_row = @position == :superscript ? @row : @row + 1

        # Calculate erase start column based on alignment
        erase_col = calculate_erase_col(text_width_boxes)
        hline(erase_col, erase_row, text_width_boxes, color: bg_color, stroke: 3)
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
