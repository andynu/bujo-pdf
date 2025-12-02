# frozen_string_literal: true

require_relative '../utilities/styling'
require_relative '../utilities/grid_rect'

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
    # - Grid-based positioning using column/row coordinates
    # - Optional day headers (M/T/W/T/F/S/S)
    # - Cell-based rendering with callback support
    #
    # Example usage:
    #   grid = WeekGrid.new(
    #     canvas: canvas,
    #     col: 5,
    #     row: 10,
    #     width: 35,
    #     height: 15,
    #     quantize: true,
    #     first_day: :monday,
    #     show_headers: true,
    #     header_height: 1,
    #     cell_callback: ->(day_index, cell_rect) {
    #       # Custom cell rendering
    #     }
    #   )
    #   grid.render
    class WeekGrid
      # Day of week labels (single letter)
      DAY_LABELS = %w[M T W T F S S].freeze

      # Number of days in a week
      DAYS_IN_WEEK = 7

      # Initialize a new WeekGrid component using grid coordinates
      #
      # @param canvas [Canvas] The canvas wrapping pdf and grid
      # @param col [Integer] Starting column in grid coordinates
      # @param row [Integer] Starting row in grid coordinates
      # @param width [Integer] Width in grid boxes
      # @param height [Integer] Height in grid boxes
      # @param quantize [Boolean] Enable grid-aligned column widths (default: true)
      # @param first_day [Symbol] Week start day :monday or :sunday (default: :monday)
      # @param show_headers [Boolean] Render day labels (default: true)
      # @param header_height [Integer] Height reserved for headers in grid boxes (default: 1)
      # @param cell_callback [Proc, nil] Optional callback for custom cell rendering
      #   Receives (day_index, cell_rect) where day_index is 0-6 and cell_rect
      #   is a hash with :x, :y, :width, :height keys
      def initialize(canvas:, col:, row:, width:, height:, quantize: true, first_day: :monday,
                     show_headers: true, header_height: 1, cell_callback: nil)
        @canvas = canvas
        @rect = GridRect.new(col, row, width, height)
        @quantize = quantize
        @first_day = first_day
        @show_headers = show_headers
        @header_height = header_height
        @cell_callback = cell_callback

        validate_parameters

        @pdf = canvas.pdf
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

        col_x = @rect.x + @column_widths[0...day_index].sum
        cell_y = @show_headers ? @rect.y - header_height_pt : @rect.y
        cell_height = @rect.height_pt - (@show_headers ? header_height_pt : 0)

        {
          x: col_x,
          y: cell_y,
          width: @column_widths[day_index],
          height: cell_height
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

      private

      # Convert header height from grid boxes to points
      def header_height_pt
        @header_height * GridRect::DOT_SPACING
      end

      # Validate constructor parameters
      #
      # @raise [ArgumentError] if any parameters are invalid
      # @return [void]
      def validate_parameters
        raise ArgumentError, 'canvas is required' if @canvas.nil?
        raise ArgumentError, 'width must be positive' if @rect.width <= 0
        raise ArgumentError, 'height must be positive' if @rect.height <= 0
        raise ArgumentError, 'header_height must be non-negative' if @header_height.negative?
        raise ArgumentError, 'first_day must be :monday or :sunday' unless %i[monday sunday].include?(@first_day)

        if @show_headers && @header_height > @rect.height
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
        if @quantize && (@rect.width % DAYS_IN_WEEK).zero?
          # Quantized mode: equal box-aligned widths
          boxes_per_column = @rect.width / DAYS_IN_WEEK
          Array.new(DAYS_IN_WEEK, boxes_per_column * GridRect::DOT_SPACING)
        else
          # Proportional mode: divide available space equally
          Array.new(DAYS_IN_WEEK, @rect.width_pt / DAYS_IN_WEEK.to_f)
        end
      end

      # Draw day header labels
      #
      # @return [void]
      def draw_headers
        @column_widths.each_with_index do |col_width, i|
          x_offset = @column_widths[0...i].sum
          @pdf.text_box DAY_LABELS[i],
                        at: [@rect.x + x_offset, @rect.y],
                        width: col_width,
                        height: header_height_pt,
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
