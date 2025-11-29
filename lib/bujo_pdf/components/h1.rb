# frozen_string_literal: true

require_relative 'text'

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
      include Text::Mixin

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
        # @param content [String] Header text
        # @param color [String, nil] Text color as hex string (default: theme text_black)
        # @param style [Symbol] Font style :bold, :normal, :italic (default: :bold)
        # @param position [Symbol] Vertical position :center, :superscript, :subscript (default: :center)
        # @param align [Symbol] Text alignment :left, :center, :right (default: :left)
        # @param width [Integer, nil] Width in grid boxes (default: nil, auto-sized)
        # @return [void]
        def h1(col, row, content, color: nil, style: :bold, position: :center, align: :left, width: nil)
          H1.new(
            pdf: @pdf,
            grid: @grid,
            col: col,
            row: row,
            content: content,
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
      # @param content [String] Header text
      # @param color [String, nil] Text color as hex string
      # @param style [Symbol] Font style
      # @param position [Symbol] Vertical position :center, :superscript, :subscript
      # @param align [Symbol] Text alignment :left, :center, :right
      # @param width [Integer, nil] Width in grid boxes
      def initialize(pdf:, grid:, col:, row:, content:, color: nil, style: :bold, position: :center, align: :left, width: nil)
        @pdf = pdf
        @grid = grid
        @col = col
        @row = row
        @content = content
        @color = color
        @style = style
        @position = position
        @align = align
        @width = width
      end

      # Render the H1 header using the text component
      #
      # @return [void]
      def render
        text(@col, @row, @content,
             size: FONT_SIZE,
             height: 1,
             color: @color,
             style: @style,
             position: @position,
             align: @align,
             width: @width)
      end
    end
  end
end
