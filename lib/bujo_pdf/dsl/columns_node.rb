# frozen_string_literal: true

require_relative 'layout_node'

module BujoPdf
  module DSL
    # ColumnsNode creates a horizontal layout with equal or specified column widths.
    #
    # Columns are a common layout pattern. This node provides two modes:
    # 1. Equal columns: specify count, space is divided evenly
    # 2. Specified widths: provide array of widths
    #
    # Quantization: When possible, columns align to whole grid boxes.
    # For example, 35 boxes / 7 columns = 5 boxes each (perfectly quantized).
    # If division doesn't work evenly, the last column gets extra space.
    #
    # @example 7 equal columns (like days of week)
    #   ColumnsNode.new(count: 7)
    #
    # @example Specified widths for Cornell notes layout
    #   ColumnsNode.new(widths: [8, 35])  # cues column, notes column
    #
    class ColumnsNode < LayoutNode
      attr_reader :count, :widths, :gap

      # Initialize a columns node.
      #
      # Provide either count (for equal columns) or widths (for specified widths).
      #
      # @param count [Integer, nil] Number of equal-width columns
      # @param widths [Array<Numeric>, nil] Array of column widths in grid boxes
      # @param gap [Numeric] Space between columns in grid boxes (default: 0)
      # @param kwargs [Hash] Additional constraints
      def initialize(count: nil, widths: nil, gap: 0, **kwargs)
        super(**kwargs)
        @count = count
        @widths = widths
        @gap = gap

        # Validate: must have count or widths, not both
        if count.nil? && widths.nil?
          raise ArgumentError, "ColumnsNode requires either count: or widths:"
        end
        if count && widths
          raise ArgumentError, "ColumnsNode accepts count: or widths:, not both"
        end
      end

      # Get the number of columns.
      #
      # @return [Integer] Number of columns
      def column_count
        @count || @widths.length
      end

      # Compute bounding boxes for this node and generate child column nodes.
      #
      # Unlike ContainerNode, ColumnsNode generates its children during layout
      # computation based on the column configuration.
      #
      # @param col [Numeric] Starting column
      # @param row [Numeric] Starting row
      # @param width [Numeric] Available width
      # @param height [Numeric] Available height
      # @return [Hash] Computed bounds
      def compute_bounds(col:, row:, width:, height:)
        # Compute our own bounds first
        @computed_bounds = super

        available_width = @computed_bounds[:width]
        available_height = @computed_bounds[:height]
        start_col = @computed_bounds[:col]
        start_row = @computed_bounds[:row]

        # Calculate total gap space
        num_gaps = column_count - 1
        total_gap = @gap * num_gaps

        # Calculate column widths
        col_widths = if @widths
          @widths.dup
        else
          distribute_equal_widths(available_width - total_gap, @count)
        end

        # Create child nodes for each column and compute their bounds
        current_col = start_col
        @children = []  # Clear any existing children

        col_widths.each_with_index do |col_width, index|
          # Create a section for this column
          child = SectionNode.new(name: :"column_#{index}", width: col_width)
          @children << child

          child.compute_bounds(
            col: current_col,
            row: start_row,
            width: col_width,
            height: available_height
          )

          current_col += col_width
          current_col += @gap if index < col_widths.length - 1
        end

        @computed_bounds
      end

      # Get the bounds for a specific column.
      #
      # @param index [Integer] Column index (0-based)
      # @return [Hash, nil] Column bounds or nil if not computed
      def column_bounds(index)
        return nil unless @children && index < @children.length
        @children[index].computed_bounds
      end

      # Iterate over columns with their bounds.
      #
      # @yield [Integer, Hash] Column index and bounds
      # @return [Enumerator] If no block given
      def each_column(&block)
        return enum_for(:each_column) unless block_given?

        @children.each_with_index do |child, index|
          yield index, child.computed_bounds
        end
      end

      private

      # Distribute width evenly among columns with quantization.
      #
      # Uses whole grid boxes when possible. Extra space goes to the last column.
      #
      # @param available [Numeric] Available width for columns
      # @param num_columns [Integer] Number of columns
      # @return [Array<Integer>] Array of column widths
      def distribute_equal_widths(available, num_columns)
        base_width = (available / num_columns).floor
        widths = Array.new(num_columns, base_width)

        # Give remainder to last column
        remainder = available - (base_width * num_columns)
        widths[-1] += remainder if remainder > 0

        widths
      end
    end

    # RowsNode creates a vertical layout with equal or specified row heights.
    #
    # Rows are the vertical counterpart to columns. Same quantization rules apply.
    #
    # @example 4 equal rows
    #   RowsNode.new(count: 4)
    #
    # @example Specified heights
    #   RowsNode.new(heights: [3, 1, 8])  # header, divider, content
    #
    class RowsNode < LayoutNode
      attr_reader :count, :heights, :gap

      # Initialize a rows node.
      #
      # @param count [Integer, nil] Number of equal-height rows
      # @param heights [Array<Numeric>, nil] Array of row heights in grid boxes
      # @param gap [Numeric] Space between rows in grid boxes (default: 0)
      # @param kwargs [Hash] Additional constraints
      def initialize(count: nil, heights: nil, gap: 0, **kwargs)
        super(**kwargs)
        @count = count
        @heights = heights
        @gap = gap

        if count.nil? && heights.nil?
          raise ArgumentError, "RowsNode requires either count: or heights:"
        end
        if count && heights
          raise ArgumentError, "RowsNode accepts count: or heights:, not both"
        end
      end

      # Get the number of rows.
      #
      # @return [Integer] Number of rows
      def row_count
        @count || @heights.length
      end

      # Compute bounding boxes for this node and generate child row nodes.
      #
      # @param col [Numeric] Starting column
      # @param row [Numeric] Starting row
      # @param width [Numeric] Available width
      # @param height [Numeric] Available height
      # @return [Hash] Computed bounds
      def compute_bounds(col:, row:, width:, height:)
        @computed_bounds = super

        available_width = @computed_bounds[:width]
        available_height = @computed_bounds[:height]
        start_col = @computed_bounds[:col]
        start_row = @computed_bounds[:row]

        # Calculate total gap space
        num_gaps = row_count - 1
        total_gap = @gap * num_gaps

        # Calculate row heights
        row_heights = if @heights
          @heights.dup
        else
          distribute_equal_heights(available_height - total_gap, @count)
        end

        # Create child nodes for each row
        current_row = start_row
        @children = []

        row_heights.each_with_index do |row_height, index|
          child = SectionNode.new(name: :"row_#{index}", height: row_height)
          @children << child

          child.compute_bounds(
            col: start_col,
            row: current_row,
            width: available_width,
            height: row_height
          )

          current_row += row_height
          current_row += @gap if index < row_heights.length - 1
        end

        @computed_bounds
      end

      # Get the bounds for a specific row.
      #
      # @param index [Integer] Row index (0-based)
      # @return [Hash, nil] Row bounds or nil if not computed
      def row_bounds(index)
        return nil unless @children && index < @children.length
        @children[index].computed_bounds
      end

      # Iterate over rows with their bounds.
      #
      # @yield [Integer, Hash] Row index and bounds
      # @return [Enumerator] If no block given
      def each_row(&block)
        return enum_for(:each_row) unless block_given?

        @children.each_with_index do |child, index|
          yield index, child.computed_bounds
        end
      end

      private

      # Distribute height evenly among rows with quantization.
      #
      # @param available [Numeric] Available height for rows
      # @param num_rows [Integer] Number of rows
      # @return [Array<Integer>] Array of row heights
      def distribute_equal_heights(available, num_rows)
        base_height = (available / num_rows).floor
        heights = Array.new(num_rows, base_height)

        # Give remainder to last row
        remainder = available - (base_height * num_rows)
        heights[-1] += remainder if remainder > 0

        heights
      end
    end

    # GridNode creates a 2D grid of cells.
    #
    # This is a convenience for creating a regular grid of equal-sized cells.
    # Uses ColumnsNode internally with RowsNode children.
    #
    # @example 7x5 grid (week calendar)
    #   GridNode.new(cols: 7, rows: 5)
    #
    class GridNode < LayoutNode
      attr_reader :num_cols, :num_rows, :col_gap, :row_gap

      # Initialize a grid node.
      #
      # @param cols [Integer] Number of columns
      # @param rows [Integer] Number of rows
      # @param col_gap [Numeric] Gap between columns (default: 0)
      # @param row_gap [Numeric] Gap between rows (default: 0)
      # @param kwargs [Hash] Additional constraints
      def initialize(cols:, rows:, col_gap: 0, row_gap: 0, **kwargs)
        super(**kwargs)
        @num_cols = cols
        @num_rows = rows
        @col_gap = col_gap
        @row_gap = row_gap
      end

      # Compute bounding boxes for the grid and all cells.
      #
      # @param col [Numeric] Starting column
      # @param row [Numeric] Starting row
      # @param width [Numeric] Available width
      # @param height [Numeric] Available height
      # @return [Hash] Computed bounds
      def compute_bounds(col:, row:, width:, height:)
        @computed_bounds = super

        available_width = @computed_bounds[:width]
        available_height = @computed_bounds[:height]
        start_col = @computed_bounds[:col]
        start_row = @computed_bounds[:row]

        # Calculate cell dimensions
        total_col_gap = @col_gap * (@num_cols - 1)
        total_row_gap = @row_gap * (@num_rows - 1)

        cell_width = ((available_width - total_col_gap) / @num_cols).floor
        cell_height = ((available_height - total_row_gap) / @num_rows).floor

        # Generate cells
        @children = []
        @cell_bounds = []

        current_row = start_row
        @num_rows.times do |row_idx|
          row_cells = []
          current_col = start_col

          @num_cols.times do |col_idx|
            # Last column/row gets any remaining space
            actual_width = if col_idx == @num_cols - 1
              available_width - (current_col - start_col)
            else
              cell_width
            end

            actual_height = if row_idx == @num_rows - 1
              available_height - (current_row - start_row)
            else
              cell_height
            end

            cell = SectionNode.new(name: :"cell_#{row_idx}_#{col_idx}")
            cell.compute_bounds(
              col: current_col,
              row: current_row,
              width: actual_width,
              height: actual_height
            )

            @children << cell
            row_cells << cell.computed_bounds

            current_col += cell_width + @col_gap
          end

          @cell_bounds << row_cells
          current_row += cell_height + @row_gap
        end

        @computed_bounds
      end

      # Get bounds for a specific cell.
      #
      # @param row_idx [Integer] Row index (0-based)
      # @param col_idx [Integer] Column index (0-based)
      # @return [Hash, nil] Cell bounds or nil if not computed
      def cell_bounds(row_idx, col_idx)
        return nil unless @cell_bounds
        @cell_bounds.dig(row_idx, col_idx)
      end

      # Iterate over all cells.
      #
      # @yield [Integer, Integer, Hash] Row index, column index, and bounds
      # @return [Enumerator] If no block given
      def each_cell(&block)
        return enum_for(:each_cell) unless block_given?

        @num_rows.times do |row_idx|
          @num_cols.times do |col_idx|
            yield row_idx, col_idx, cell_bounds(row_idx, col_idx)
          end
        end
      end
    end
  end
end
