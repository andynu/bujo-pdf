# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/grid_factory'

module BujoPdf
  module Pages
    # Grid showcase page displaying all available grid types
    #
    # This page demonstrates the four grid types available in the planner:
    # dots, isometric, perspective, and hexagon. Each grid is displayed in
    # a quadrant of the page with a label.
    #
    # This page serves both as a visual reference for users and as a test
    # page for verifying grid rendering.
    #
    # Example:
    #   page = GridShowcase.new(pdf, { year: 2025 })
    #   page.generate
    class GridShowcase < Base
      # Mixin providing grid_showcase_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the grid showcase page.
        #
        # @return [void]
        def grid_showcase_page
          start_new_page
          context = build_context(page_key: :grid_showcase)
          GridShowcase.new(@pdf, context).generate
        end
      end

      GRID_TYPES = [
        { type: :dots, label: 'Dot Grid', position: :top_left },
        { type: :isometric, label: 'Isometric Grid', position: :top_right },
        { type: :perspective, label: 'Perspective Grid', position: :bottom_left },
        { type: :hexagon, label: 'Hexagon Grid', position: :bottom_right }
      ].freeze

      # Set up the named destination for this page
      def setup
        set_destination('grid_showcase')
        use_layout :full_page  # No sidebars for showcase page
      end

      # Render the grid showcase with all four grid types
      def render
        # Draw title
        draw_title

        # Draw each grid type in its quadrant
        GRID_TYPES.each do |grid_spec|
          draw_grid_quadrant(grid_spec)
        end
      end

      private

      # Draw the page title
      #
      # @return [void]
      def draw_title
        title_box = @grid_system.rect(0, 0, 43, 3)

        @pdf.bounding_box([title_box[:x], title_box[:y]],
                          width: title_box[:width],
                          height: title_box[:height]) do
          @pdf.text 'Grid Types', size: 18, style: :bold, align: :center
          @pdf.move_down 5
          @pdf.text 'Visual Reference & Templates', size: 10, align: :center, color: 'AAAAAA'
        end
      end

      # Draw a grid type in its designated quadrant
      #
      # @param grid_spec [Hash] Grid specification with :type, :label, :position
      # @return [void]
      def draw_grid_quadrant(grid_spec)
        type = grid_spec[:type]
        label = grid_spec[:label]
        position = grid_spec[:position]

        # Calculate quadrant bounds
        quadrant = calculate_quadrant(position)

        # Draw label at top of quadrant
        draw_quadrant_label(label, quadrant)

        # Draw the grid in the quadrant
        draw_quadrant_grid(type, quadrant)

        # Draw border around quadrant
        draw_quadrant_border(quadrant)
      end

      # Calculate quadrant bounding box
      #
      # @param position [Symbol] :top_left, :top_right, :bottom_left, :bottom_right
      # @return [Hash] Quadrant bounds with :col, :row, :width, :height keys
      def calculate_quadrant(position)
        # Quadrants are equal size, split the page into 2x2 grid
        # Leave 3 rows for title, 1 row for label per quadrant
        quadrant_width = 21.5  # Half of 43 columns
        quadrant_height = 26   # (55 - 3 title) / 2 = 26 rows per quadrant

        case position
        when :top_left
          { col: 0, row: 3, width: quadrant_width, height: quadrant_height }
        when :top_right
          { col: 21.5, row: 3, width: quadrant_width, height: quadrant_height }
        when :bottom_left
          { col: 0, row: 29, width: quadrant_width, height: quadrant_height }
        when :bottom_right
          { col: 21.5, row: 29, width: quadrant_width, height: quadrant_height }
        end
      end

      # Draw label at top of quadrant
      #
      # @param label [String] Grid type label
      # @param quadrant [Hash] Quadrant bounds
      # @return [void]
      def draw_quadrant_label(label, quadrant)
        label_height = 2  # 2 boxes for label

        label_box = @grid_system.rect(
          quadrant[:col],
          quadrant[:row],
          quadrant[:width],
          label_height
        )

        @pdf.bounding_box([label_box[:x], label_box[:y]],
                          width: label_box[:width],
                          height: label_box[:height]) do
          @pdf.text label, size: 10, style: :bold, align: :center, valign: :center
        end
      end

      # Draw grid pattern in quadrant
      #
      # @param type [Symbol] Grid type (:dots, :isometric, :perspective, :hexagon)
      # @param quadrant [Hash] Quadrant bounds
      # @return [void]
      def draw_quadrant_grid(type, quadrant)
        # Grid area is quadrant minus label
        grid_row = quadrant[:row] + 2  # Skip 2 rows for label
        grid_height = quadrant[:height] - 2

        grid_box = @grid_system.rect(
          quadrant[:col],
          grid_row,
          quadrant[:width],
          grid_height
        )

        # Draw grid within the box
        @pdf.bounding_box([grid_box[:x], grid_box[:y]],
                          width: grid_box[:width],
                          height: grid_box[:height]) do
          # Use slightly heavier lines for hexagon and perspective grids for better visibility
          options = {}
          options[:line_width] = 0.5 if [:hexagon, :perspective].include?(type)

          # Configure 1-point perspective with guide rectangles
          if type == :perspective
            options[:num_points] = 1
            options[:draw_guide_rectangles] = true
            options[:num_converging] = 8  # Fewer lines for cleaner showcase display
          end

          renderer = Utilities::GridFactory.create(
            type,
            @pdf,
            grid_box[:width],
            grid_box[:height],
            **options
          )
          renderer.render
        end
      end

      # Draw border around quadrant
      #
      # @param quadrant [Hash] Quadrant bounds
      # @return [void]
      def draw_quadrant_border(quadrant)
        border_box = @grid_system.rect(
          quadrant[:col],
          quadrant[:row],
          quadrant[:width],
          quadrant[:height]
        )

        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.5
        @pdf.stroke_rectangle [border_box[:x], border_box[:y]],
                              border_box[:width],
                              border_box[:height]
        @pdf.stroke_color '000000'  # Reset to black
      end
    end
  end
end
