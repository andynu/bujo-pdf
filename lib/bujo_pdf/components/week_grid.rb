# frozen_string_literal: true

require_relative '../utilities/styling'

module BujoPdf
  module Components
    # WeekGrid renders a 7-column week-based grid with optional quantization
    #
    # This component creates consistent week-view grids across different page types.
    # When quantization is enabled and the width is divisible by 7 grid boxes,
    # all columns align exactly with the dot grid and share identical widths.
    #
    # Key features:
    # - Quantized column widths for visual consistency across pages
    # - Flexible positioning using either points or grid coordinates
    # - Optional day headers (M/T/W/T/F/S/S)
    # - Cell-based rendering with callback support
    #
    # Example usage:
    #   grid = WeekGrid.new(
    #     pdf: @pdf,
    #     x: 100,
    #     y: 700,
    #     width: 400,
    #     height: 200,
    #     quantize: true,
    #     first_day: :monday,
    #     show_headers: true,
    #     header_height: 14.17,
    #     cell_callback: ->(day_index, cell_rect) {
    #       # Custom cell rendering
    #     }
    #   )
    #   grid.render
    #
    # Or using grid coordinates via the class method:
    #   grid = WeekGrid.from_grid(
    #     pdf: @pdf,
    #     col: 5,
    #     row: 10,
    #     width_boxes: 35,
    #     height_boxes: 15,
    #     quantize: true
    #   )
    class WeekGrid
      # Day of week labels (single letter)
      DAY_LABELS = %w[M T W T F S S].freeze

      # Number of days in a week
      DAYS_IN_WEEK = 7

      # Initialize a new WeekGrid component
      #
      # @param pdf [Prawn::Document] The PDF document to render into
      # @param x [Float] Left edge x-coordinate in points
      # @param y [Float] Top edge y-coordinate in points
      # @param width [Float] Total width in points
      # @param height [Float] Total height in points
      # @param quantize [Boolean] Enable grid-aligned column widths (default: true)
      # @param first_day [Symbol] Week start day :monday or :sunday (default: :monday)
      # @param show_headers [Boolean] Render day labels (default: true)
      # @param header_height [Float] Height reserved for headers in points (default: DOT_SPACING)
      # @param cell_callback [Proc, nil] Optional callback for custom cell rendering
      #   Receives (day_index, cell_rect) where day_index is 0-6 and cell_rect
      #   is a hash with :x, :y, :width, :height keys
      def initialize(pdf:, x:, y:, width:, height:, quantize: true, first_day: :monday,
                     show_headers: true, header_height: Styling::Grid::DOT_SPACING,
                     cell_callback: nil)
        @pdf = pdf
        @x = x
        @y = y
        @width = width
        @height = height
        @quantize = quantize
        @first_day = first_day
        @show_headers = show_headers
        @header_height = header_height
        @cell_callback = cell_callback

        validate_parameters
        @column_widths = calculate_column_widths
      end

      # Render the week grid
      #
      # This draws the grid headers and cells according to the configuration.
      # If a cell_callback was provided, it will be invoked for each day column.
      #
      # @return [void]
      def render
        draw_headers if @show_headers
        render_cells if @cell_callback
      end

      # Get the bounding rectangle for a specific day column
      #
      # @param day_index [Integer] Day index 0-6 (0=first day of week based on first_day setting)
      # @return [Hash] Rectangle with :x, :y, :width, :height keys in points
      # @raise [ArgumentError] if day_index is out of range
      def cell_rect(day_index)
        raise ArgumentError, "day_index must be 0-6, got #{day_index}" unless (0..6).cover?(day_index)

        col_x = @x + @column_widths[0...day_index].sum
        cell_y = @show_headers ? @y - @header_height : @y

        {
          x: col_x,
          y: cell_y,
          width: @column_widths[day_index],
          height: @height - (@show_headers ? @header_height : 0)
        }
      end

      # Iterate over all day columns
      #
      # Yields the day index (0-6) and cell rectangle for each column.
      # Useful for custom rendering logic.
      #
      # @yield [day_index, cell_rect] Block to execute for each day
      # @yieldparam day_index [Integer] Day index 0-6
      # @yieldparam cell_rect [Hash] Cell bounding box
      # @return [void]
      def each_cell
        DAYS_IN_WEEK.times do |day_index|
          yield day_index, cell_rect(day_index)
        end
      end

      # Create a WeekGrid using grid coordinates
      #
      # This is a convenience factory method for working with the grid system.
      # Requires access to grid helper methods (grid_x, grid_y, grid_width, grid_height).
      #
      # @param pdf [Prawn::Document] The PDF document
      # @param grid [GridSystem] The grid system instance
      # @param col [Integer] Starting column in grid coordinates
      # @param row [Integer] Starting row in grid coordinates
      # @param width_boxes [Integer] Width in grid boxes
      # @param height_boxes [Integer] Height in grid boxes
      # @param opts [Hash] Additional options to pass to WeekGrid constructor
      # @return [WeekGrid] New WeekGrid instance
      def self.from_grid(pdf:, grid:, col:, row:, width_boxes:, height_boxes:, **opts)
        new(
          pdf: pdf,
          x: grid.x(col),
          y: grid.y(row),
          width: grid.width(width_boxes),
          height: grid.height(height_boxes),
          **opts
        )
      end

      private

      # Validate constructor parameters
      #
      # @raise [ArgumentError] if any parameters are invalid
      # @return [void]
      def validate_parameters
        raise ArgumentError, 'pdf is required' if @pdf.nil?
        raise ArgumentError, 'width must be positive' if @width <= 0
        raise ArgumentError, 'height must be positive' if @height <= 0
        raise ArgumentError, 'header_height must be non-negative' if @header_height < 0
        raise ArgumentError, 'first_day must be :monday or :sunday' unless %i[monday sunday].include?(@first_day)

        if @show_headers && @header_height > @height
          raise ArgumentError, 'header_height cannot exceed total height when show_headers is true'
        end
      end

      # Calculate column widths based on quantization setting
      #
      # When quantize is true and width is divisible by 7 boxes, columns
      # are sized to align with the dot grid. Otherwise, columns divide
      # available space proportionally.
      #
      # @return [Array<Float>] Array of 7 column widths in points
      def calculate_column_widths
        total_boxes = (@width / Styling::Grid::DOT_SPACING).round

        if @quantize && (total_boxes % DAYS_IN_WEEK).zero?
          # Quantized mode: equal box-aligned widths
          boxes_per_column = total_boxes / DAYS_IN_WEEK
          Array.new(DAYS_IN_WEEK, boxes_per_column * Styling::Grid::DOT_SPACING)
        else
          # Proportional mode: divide available space equally
          width_per_column = @width / DAYS_IN_WEEK.to_f
          Array.new(DAYS_IN_WEEK, width_per_column)
        end
      end

      # Draw day header labels
      #
      # @return [void]
      def draw_headers
        @column_widths.each_with_index do |width, i|
          x_offset = @column_widths[0...i].sum
          @pdf.text_box DAY_LABELS[i],
                        at: [@x + x_offset, @y],
                        width: width,
                        height: @header_height,
                        align: :center,
                        valign: :center,
                        size: 8
        end
      end

      # Render cells using the callback
      #
      # @return [void]
      def render_cells
        each_cell do |day_index, rect|
          @cell_callback.call(day_index, rect)
        end
      end
    end
  end
end
