# frozen_string_literal: true

module BujoPdf
  module Components
    # H1 renders a primary header, one grid box tall.
    #
    # Simple header component that renders bold text positioned at a grid
    # location. Width is determined by the text content.
    #
    # Example usage in a page:
    #   h1(2, 1, "Index")
    #   h1(2, 1, "January 2025", color: '333333')
    #
    class H1
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
        # @return [void]
        def h1(col, row, text, color: nil, style: :bold)
          H1.new(
            pdf: @pdf,
            grid: @grid_system,
            col: col,
            row: row,
            text: text,
            color: color,
            style: style
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
      def initialize(pdf:, grid:, col:, row:, text:, color: nil, style: :bold)
        @pdf = pdf
        @grid = grid
        @col = col
        @row = row
        @text = text
        @color = color
        @style = style
      end

      # Render the H1 header
      #
      # @return [void]
      def render
        require_relative '../themes/theme_registry'

        text_color = @color || BujoPdf::Themes.current[:colors][:text_black]

        @pdf.font 'Helvetica', style: @style
        @pdf.fill_color text_color

        @pdf.text_box @text,
                      at: [@grid.x(@col), @grid.y(@row)],
                      width: @grid.width(40), # Wide enough for any reasonable header
                      height: @grid.height(1),
                      size: FONT_SIZE,
                      valign: :center,
                      overflow: :truncate

        # Reset to defaults
        @pdf.font 'Helvetica', style: :normal
        @pdf.fill_color BujoPdf::Themes.current[:colors][:text_black]
      end
    end
  end
end
