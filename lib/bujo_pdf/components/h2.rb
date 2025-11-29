# frozen_string_literal: true

require_relative 'text'

module BujoPdf
  module Components
    # H2 renders a secondary header, two grid boxes tall.
    #
    # Simple header component that renders bold text positioned at a grid
    # location. Width is determined by the text content. The taller height
    # allows for larger text or more vertical breathing room.
    #
    # Example usage in a page:
    #   h2(2, 1, "Monthly Review")
    #   h2(2, 1, "Q1 Planning", color: '666666')
    #
    class H2
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
        # @return [void]
        def h2(col, row, content, color: nil, style: :bold)
          H2.new(
            pdf: @pdf,
            grid: @grid,
            col: col,
            row: row,
            content: content,
            color: color,
            style: style
          ).render
        end
      end

      # Initialize a new H2 component
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param grid [GridSystem] The grid system for coordinate conversion
      # @param col [Integer] Column position (left edge)
      # @param row [Integer] Row position (top edge)
      # @param content [String] Header text
      # @param color [String, nil] Text color as hex string
      # @param style [Symbol] Font style
      def initialize(pdf:, grid:, col:, row:, content:, color: nil, style: :bold)
        @pdf = pdf
        @grid = grid
        @col = col
        @row = row
        @content = content
        @color = color
        @style = style
      end

      # Render the H2 header using the text component
      #
      # @return [void]
      def render
        text(@col, @row, @content,
             size: FONT_SIZE,
             height: 2,
             color: @color,
             style: @style)
      end
    end
  end
end
