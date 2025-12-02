# frozen_string_literal: true

require_relative '../base/component'
require_relative 'text'

module BujoPdf
  module Components
    # LinkBox component for navigation link boxes with consistent styling.
    #
    # Renders a clickable box with:
    #   - Rounded rectangle background (filled at 20% opacity, or stroked when current)
    #   - Text rendering (horizontal or rotated)
    #   - Link annotation overlay with destination
    #   - Theme-aware colors
    #
    # Example usage:
    #   # Horizontal link box:
    #   link_box(0, 0, 2, 1, "w42", dest: "week_42")
    #
    #   # Current page (stroked, bold, no link):
    #   link_box(0, 0, 2, 1, "2025", dest: "seasonal", current: true)
    #
    #   # Vertical/rotated link box:
    #   link_box(42, 2, 1, 4, "Year", dest: "seasonal", rotation: -90)
    #
    class LinkBox < Component
      include Text::Mixin

      DEFAULT_FONT_SIZE = 8
      DEFAULT_INSET = 2

      # Mixin providing the link_box verb for pages and components
      module Mixin
        # Render a navigation link box
        #
        # @param col [Integer, Float] Column position
        # @param row [Integer, Float] Row position
        # @param width [Integer, Float] Width in grid boxes
        # @param height [Integer, Float] Height in grid boxes
        # @param text [String] Label text
        # @param dest [String] Named destination for link
        # @param current [Boolean] When true, stroked border instead of filled, bold text, no link
        # @param rotation [Integer] 0 (default) or -90 for vertical text
        # @param font_size [Integer] Font size (default: 8)
        # @param inset [Integer] Visual breathing room inside rectangle in points (default: 2)
        # @param color [String, nil] Override text color (default: theme text_gray, or text_black when current)
        # @param pt_x [Float, nil] X position in points (overrides col when set)
        # @param pt_y [Float, nil] Y position in points (overrides row when set)
        # @param pt_width [Float, nil] Width in points (overrides width when set)
        # @param pt_height [Float, nil] Height in points (overrides height when set)
        # @return [void]
        def link_box(col, row, width, height, text, dest:, current: false, rotation: 0, font_size: DEFAULT_FONT_SIZE, inset: DEFAULT_INSET, color: nil, pt_x: nil, pt_y: nil, pt_width: nil, pt_height: nil)
          c = @canvas || Canvas.new(@pdf, @grid)
          LinkBox.new(
            canvas: c,
            col: col,
            row: row,
            width: width,
            height: height,
            text: text,
            dest: dest,
            current: current,
            rotation: rotation,
            font_size: font_size,
            inset: inset,
            color: color,
            pt_x: pt_x,
            pt_y: pt_y,
            pt_width: pt_width,
            pt_height: pt_height
          ).render
        end
      end

      # Initialize a new LinkBox component
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer, Float] Column position
      # @param row [Integer, Float] Row position
      # @param width [Integer, Float] Width in grid boxes
      # @param height [Integer, Float] Height in grid boxes
      # @param text [String] Label text
      # @param dest [String] Named destination for link
      # @param current [Boolean] When true, stroked border, bold text, no link
      # @param rotation [Integer] 0 or -90 for vertical text
      # @param font_size [Integer] Font size in points
      # @param inset [Integer] Inset in points for visual breathing room
      # @param color [String, nil] Override text color
      # @param pt_x [Float, nil] X position in points (overrides col)
      # @param pt_y [Float, nil] Y position in points (overrides row)
      # @param pt_width [Float, nil] Width in points (overrides width)
      # @param pt_height [Float, nil] Height in points (overrides height)
      def initialize(canvas:, col:, row:, width:, height:, text:, dest:, current: false, rotation: 0, font_size: DEFAULT_FONT_SIZE, inset: DEFAULT_INSET, color: nil, pt_x: nil, pt_y: nil, pt_width: nil, pt_height: nil)
        super(canvas: canvas)
        @col = col
        @row = row
        @width = width
        @height = height
        @text = text
        @dest = dest
        @current = current
        @rotation = rotation
        @font_size = font_size
        @inset = inset
        @color = color
        @pt_x = pt_x
        @pt_y = pt_y
        @pt_width = pt_width
        @pt_height = pt_height
      end

      def render
        require_relative '../themes/theme_registry'

        # Calculate box coordinates (use pt_ overrides if provided)
        box_left = @pt_x || grid.x(@col)
        box_top = @pt_y || grid.y(@row)
        box_width = @pt_width || grid.width(@width)
        box_height = @pt_height || grid.height(@height)
        box_bottom = box_top - box_height
        box_right = box_left + box_width

        # Draw background
        draw_background(box_left, box_top, box_width, box_height)

        # Draw text
        draw_text(box_left, box_top, box_width, box_height)

        # Add link annotation (skip for current page)
        unless @current
          pdf.link_annotation([box_left, box_bottom, box_right, box_top],
                               Dest: @dest,
                               Border: [0, 0, 0])
        end
      end

      private

      def draw_background(left, top, width, height)
        border_color = BujoPdf::Themes.current[:colors][:borders]

        # Apply inset for visual breathing room
        rect_left = left + @inset
        rect_width = width - (@inset * 2)
        rect_top = top - @inset
        rect_height = height - (@inset * 2)

        if @current
          # Current: stroked border only (no fill)
          pdf.stroke_color border_color
          pdf.stroke_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
        else
          # Non-current: 20% opacity filled background
          pdf.transparent(0.2) do
            pdf.fill_color border_color
            pdf.fill_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
          end
        end

        # Reset colors
        text_color = BujoPdf::Themes.current[:colors][:text_black]
        pdf.fill_color text_color
        pdf.stroke_color text_color
      end

      def draw_text(left, top, width, height)
        # Determine style and color based on current state
        style = @current ? :bold : :normal
        text_color = @color || (@current ? BujoPdf::Themes.current[:colors][:text_black] : BujoPdf::Themes.current[:colors][:text_gray])

        if @rotation != 0
          # Rotated text (vertical tabs)
          text(
            0, 0, @text,
            rotation: @rotation,
            size: @font_size,
            style: style,
            color: text_color,
            align: :center,
            pt_x: left + (width / 2.0),
            pt_y: top - (height / 2.0),
            pt_width: height - (@inset * 2),
            pt_height: width,
            centered: true
          )
        else
          # Horizontal text
          pdf.font "Helvetica", style: style, size: @font_size
          pdf.fill_color text_color
          pdf.text_box @text,
                        at: [left, top],
                        width: width,
                        height: height,
                        align: :center,
                        valign: :center

          # Reset color
          pdf.fill_color BujoPdf::Themes.current[:colors][:text_black]
        end
      end
    end
  end
end
