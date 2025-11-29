# frozen_string_literal: true

require_relative 'erase_dots'

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
      include EraseDots::Mixin
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
        # @param text [String] Header text
        # @param color [String, nil] Text color as hex string (default: theme text_black)
        # @param style [Symbol] Font style :bold, :normal, :italic (default: :bold)
        # @return [void]
        def h2(col, row, text, color: nil, style: :bold)
          H2.new(
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

      # Initialize a new H2 component
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

      # Render the H2 header
      #
      # @return [void]
      def render
        require_relative '../themes/theme_registry'

        text_color = @color || BujoPdf::Themes.current[:colors][:text_black]

        @pdf.font 'Helvetica', style: @style, size: FONT_SIZE

        # Calculate text width and convert to grid boxes
        text_width_pt = @pdf.width_of(@text)
        text_width_boxes = (text_width_pt / @grid.dot_spacing).ceil

        # Erase the middle row of dots behind the text
        # Row 1 (middle of the 2-box height) runs through the text
        erase_dots(@col, @row + 1, text_width_boxes)

        # Draw the text
        @pdf.fill_color text_color
        @pdf.text_box @text,
                      at: [@grid.x(@col), @grid.y(@row)],
                      width: @grid.width(40), # Wide enough for any reasonable header
                      height: @grid.height(2),
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
