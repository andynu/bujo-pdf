# frozen_string_literal: true

require_relative '../base/component'
require_relative '../utilities/styling'
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
    # Two entry points are provided via the Mixin:
    #   - link_box: Grid-based positioning (col, row, width, height)
    #   - link_box_pt: Point-based positioning (pt_x, pt_y, pt_width, pt_height)
    #
    # Example usage:
    #   # Grid-based horizontal link box:
    #   link_box(0, 0, 2, 1, "w42", dest: "week_42")
    #
    #   # Current page (stroked, bold, no link):
    #   link_box(0, 0, 2, 1, "2025", dest: "seasonal", current: true)
    #
    #   # Grid-based vertical/rotated link box:
    #   link_box(42, 2, 1, 4, "Year", dest: "seasonal", rotation: -90)
    #
    #   # Point-based positioning (for dynamic/calculated positions):
    #   link_box_pt(100.0, 500.0, 50.0, 20.0, "Tab", dest: "tab_dest", rotation: -90)
    #
    class LinkBox < Component
      include Styling::Colors
      include Text::Mixin

      DEFAULT_FONT_SIZE = 8
      DEFAULT_INSET = 2

      # Mixin providing the link_box verb for pages and components
      module Mixin
        # Render a navigation link box using grid coordinates
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
        # @return [void]
        def link_box(col, row, width, height, text, dest:, current: false, rotation: 0, font_size: DEFAULT_FONT_SIZE, inset: DEFAULT_INSET, color: nil)
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
            color: color
          ).render
        end

        # Render a navigation link box using point coordinates
        #
        # @param pt_x [Float] X position in points
        # @param pt_y [Float] Y position in points (top of box)
        # @param pt_width [Float] Width in points
        # @param pt_height [Float] Height in points
        # @param text [String] Label text
        # @param dest [String] Named destination for link
        # @param current [Boolean] When true, stroked border instead of filled, bold text, no link
        # @param rotation [Integer] 0 (default) or -90 for vertical text
        # @param font_size [Integer] Font size (default: 8)
        # @param inset [Integer] Visual breathing room inside rectangle in points (default: 2)
        # @param color [String, nil] Override text color (default: theme text_gray, or text_black when current)
        # @return [void]
        def link_box_pt(pt_x, pt_y, pt_width, pt_height, text, dest:, current: false, rotation: 0, font_size: DEFAULT_FONT_SIZE, inset: DEFAULT_INSET, color: nil)
          c = @canvas || Canvas.new(@pdf, @grid)
          LinkBox.new(
            canvas: c,
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
      # Positioning can be specified in two ways:
      # 1. Grid coordinates: col, row, width, height (converted via grid system)
      # 2. Point coordinates: pt_x, pt_y, pt_width, pt_height (used directly)
      #
      # When pt_ values are provided, they take precedence over grid values.
      # At least one complete set of coordinates must be provided.
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param text [String] Label text
      # @param dest [String] Named destination for link
      # @param col [Integer, Float, nil] Column position (grid-based)
      # @param row [Integer, Float, nil] Row position (grid-based)
      # @param width [Integer, Float, nil] Width in grid boxes
      # @param height [Integer, Float, nil] Height in grid boxes
      # @param current [Boolean] When true, stroked border, bold text, no link
      # @param rotation [Integer] 0 or -90 for vertical text
      # @param font_size [Integer] Font size in points
      # @param inset [Integer] Inset in points for visual breathing room
      # @param color [String, nil] Override text color
      # @param pt_x [Float, nil] X position in points
      # @param pt_y [Float, nil] Y position in points (top of box)
      # @param pt_width [Float, nil] Width in points
      # @param pt_height [Float, nil] Height in points
      def initialize(canvas:, text:, dest:, col: nil, row: nil, width: nil, height: nil, current: false, rotation: 0, font_size: DEFAULT_FONT_SIZE, inset: DEFAULT_INSET, color: nil, pt_x: nil, pt_y: nil, pt_width: nil, pt_height: nil)
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
        # Apply inset for visual breathing room
        rect_left = left + @inset
        rect_width = width - (@inset * 2)
        rect_top = top - @inset
        rect_height = height - (@inset * 2)

        if @current
          # Current: stroked border only (no fill)
          with_stroke_color(color_borders) do
            pdf.stroke_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
          end
        else
          # Non-current: 20% opacity filled background
          pdf.transparent(0.2) do
            with_fill_color(color_borders) do
              pdf.fill_rounded_rectangle([rect_left, rect_top], rect_width, rect_height, 2)
            end
          end
        end
      end

      def draw_text(left, top, width, height)
        # Determine style and color based on current state
        style = @current ? :bold : :normal
        txt_color = @color || (@current ? color_text_black : color_text_gray)

        if @rotation != 0
          # Rotated text (vertical tabs)
          text(
            0, 0, @text,
            rotation: @rotation,
            size: @font_size,
            style: style,
            color: txt_color,
            align: :center,
            pt_x: left + (width / 2.0),
            pt_y: top - (height / 2.0),
            pt_width: height - (@inset * 2),
            pt_height: width,
            centered: true
          )
        else
          # Horizontal text
          with_font("Helvetica", @font_size) do
            pdf.font "Helvetica", style: style, size: @font_size
            with_fill_color(txt_color) do
              pdf.text_box @text,
                            at: [left, top],
                            width: width,
                            height: height,
                            align: :center,
                            valign: :center
            end
          end
        end
      end
    end
  end
end
