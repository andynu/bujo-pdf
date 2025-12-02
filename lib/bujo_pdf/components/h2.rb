# frozen_string_literal: true

require_relative '../base/component'
require_relative 'text'

module BujoPdf
  module Components
    # H2 renders a secondary header, two grid boxes tall.
    #
    # Simple header component that renders bold text positioned at a grid
    # location. The taller height allows for larger text or more vertical
    # breathing room.
    #
    # Supports text alignment:
    # - :left (default) - left-aligned
    # - :center - centered within width
    # - :right - right-aligned within width
    #
    # Example usage in a page:
    #   h2(2, 1, "Monthly Review")
    #   h2(2, 1, "Q1 Planning", color: '666666')
    #   h2(2, 1, "Centered", width: 20, align: :center)
    #
    class H2 < Component
      include Text::Mixin

      # Default font size for H2 headers (fits in 2 boxes = ~28pt)
      FONT_SIZE = 18

      # Mixin providing the h2 verb for pages
      #
      # Include via Components::All in Pages::Base
      module Mixin
        # Render an H2 header at a grid position
        #
        # @param col [Integer] Column position (left edge)
        # @param row [Integer] Row position (top edge)
        # @param content [String] Header text
        # @param color [String, nil] Text color as hex string (default: theme text_black)
        # @param style [Symbol] Font style :bold, :normal, :italic (default: :bold)
        # @param align [Symbol] Text alignment :left, :center, :right (default: :left)
        # @param width [Integer, nil] Width in grid boxes (default: nil, auto-sized)
        # @return [void]
        def h2(col, row, content, color: nil, style: :bold, align: :left, width: nil)
          c = @canvas || Canvas.new(@pdf, @grid)
          H2.new(
            canvas: c,
            col: col,
            row: row,
            content: content,
            color: color,
            style: style,
            align: align,
            width: width
          ).render
        end
      end

      # Initialize a new H2 component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Column position (left edge)
      # @param row [Integer] Row position (top edge)
      # @param content [String] Header text
      # @param color [String, nil] Text color as hex string
      # @param style [Symbol] Font style
      # @param align [Symbol] Text alignment :left, :center, :right
      # @param width [Integer, nil] Width in grid boxes
      def initialize(canvas:, col:, row:, content:, color: nil, style: :bold, align: :left, width: nil)
        super(canvas: canvas)
        @col = col
        @row = row
        @content = content
        @color = color
        @style = style
        @align = align
        @width = width
      end

      # Render the H2 header using the text component
      #
      # @return [void]
      def render
        text(@col, @row, @content,
             size: FONT_SIZE,
             height: 2,
             color: @color,
             style: @style,
             align: @align,
             width: @width)
      end
    end
  end
end
