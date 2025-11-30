# frozen_string_literal: true

module BujoPdf
  # Layout defines the spatial organization of a page.
  #
  # A Layout specifies where content can be rendered (the content area) and
  # where chrome elements like sidebars and navigation appear. This separation
  # enables reusable layout patterns across different page types.
  #
  # The layout system uses grid coordinates (column, row, width, height) to
  # specify regions. All positions are in grid boxes, not points.
  #
  # Key Concepts:
  # - **Content Area**: The region where page-specific content is rendered
  # - **Sidebars**: Chrome regions outside content area (left, right, top, bottom)
  # - **Background**: Dot grid, ruled lines, or blank
  # - **Debug Mode**: Enable diagnostic grid overlay
  #
  # @example Creating a custom layout
  #   layout = Layout.new(
  #     name: "custom",
  #     content_area: { col: 2, row: 2, width: 39, height: 51 },
  #     sidebars: [
  #       { position: :left, col: 0, row: 0, width: 2, height: 55 }
  #     ],
  #     background_type: :dot_grid,
  #     debug: false
  #   )
  #
  # @example Using factory methods
  #   full_layout = Layout.full_page
  #   weekly_layout = Layout.weekly_layout
  #   sidebar_layout = Layout.with_sidebars(left_width: 3, right_width: 1)
  class Layout
    # @return [String] Layout name (e.g., "full_page", "weekly_layout")
    attr_reader :name

    # @return [Hash] Content area specification { col:, row:, width:, height: }
    attr_reader :content_area_spec

    # @return [Array<Hash>] Sidebar specifications [{ position:, col:, row:, width:, height: }]
    attr_reader :sidebar_specs

    # @return [Hash] Additional layout options
    attr_reader :options

    # Initialize a new layout.
    #
    # @param name [String] Layout name for identification
    # @param content_area [Hash] Content area grid specification
    # @option content_area [Integer] :col Starting column (0-42)
    # @option content_area [Integer] :row Starting row (0-54)
    # @option content_area [Integer] :width Width in grid boxes
    # @option content_area [Integer] :height Height in grid boxes
    # @param sidebars [Array<Hash>] Sidebar specifications
    # @option sidebars [Symbol] :position Position (:left, :right, :top, :bottom)
    # @option sidebars [Integer] :col Starting column
    # @option sidebars [Integer] :row Starting row
    # @option sidebars [Integer] :width Width in grid boxes
    # @option sidebars [Integer] :height Height in grid boxes
    # @param options [Hash] Additional options
    # @option options [Boolean] :background Enable background rendering (default: true)
    # @option options [Symbol] :background_type Background type (:dot_grid, :ruled, :blank, default: :dot_grid)
    # @option options [Boolean] :debug Enable debug mode (default: false)
    # @option options [Boolean] :footer Enable footer rendering (default: false)
    def initialize(name: "default", content_area:, sidebars: [], **options)
      @name = name
      @content_area_spec = content_area
      @sidebar_specs = sidebars
      @options = options

      validate_content_area
      validate_sidebars
    end

    # Check if background rendering is enabled.
    #
    # @return [Boolean] True if background should be rendered
    def background_enabled?
      @options.fetch(:background, true)
    end

    # Get the background type.
    #
    # @return [Symbol] Background type (:dot_grid, :ruled, :blank)
    def background_type
      @options.fetch(:background_type, :dot_grid)
    end

    # Check if debug mode is enabled.
    #
    # @return [Boolean] True if diagnostic grid should be shown
    def debug_mode?
      @options.fetch(:debug, false)
    end

    # Check if footer rendering is enabled.
    #
    # @return [Boolean] True if footer should be rendered
    def footer_enabled?
      @options.fetch(:footer, false)
    end

    # Get sidebar specification by position.
    #
    # @param position [Symbol] Sidebar position (:left, :right, :top, :bottom)
    # @return [Hash, nil] Sidebar specification or nil if not found
    def sidebar(position)
      @sidebar_specs.find { |s| s[:position] == position }
    end

    # Factory: Full page layout with no sidebars.
    #
    # Content area spans the entire page (43 cols × 55 rows).
    #
    # @param options [Hash] Additional options to pass to Layout
    # @return [Layout] Full page layout
    def self.full_page(**options)
      new(
        name: "full_page",
        content_area: { col: 0, row: 0, width: 43, height: 55 },
        **options
      )
    end

    # Factory: Layout with sidebars.
    #
    # Creates a layout with optional left, right, and top sidebars.
    # The content area is automatically calculated to fit between sidebars.
    #
    # @param left_width [Integer] Left sidebar width in grid boxes (default: 0)
    # @param right_width [Integer] Right sidebar width in grid boxes (default: 0)
    # @param top_height [Integer] Top navigation height in grid boxes (default: 0)
    # @param options [Hash] Additional options to pass to Layout
    # @return [Layout] Layout with specified sidebars
    #
    # @example
    #   # Layout with 2-box left sidebar and 1-box right sidebar
    #   layout = Layout.with_sidebars(left_width: 2, right_width: 1)
    #
    #   # Layout with top navigation and sidebars
    #   layout = Layout.with_sidebars(left_width: 2, right_width: 1, top_height: 2)
    def self.with_sidebars(left_width: 0, right_width: 0, top_height: 0, **options)
      sidebars = []

      # Left sidebar (full height)
      if left_width > 0
        sidebars << {
          position: :left,
          col: 0,
          row: 0,
          width: left_width,
          height: 55
        }
      end

      # Right sidebar (full height)
      if right_width > 0
        sidebars << {
          position: :right,
          col: 43 - right_width,
          row: 0,
          width: right_width,
          height: 55
        }
      end

      # Top navigation bar (spans between sidebars)
      if top_height > 0
        sidebars << {
          position: :top,
          col: left_width,
          row: 0,
          width: 43 - left_width - right_width,
          height: top_height
        }
      end

      # Content area is what remains
      new(
        name: "with_sidebars",
        content_area: {
          col: left_width,
          row: top_height,
          width: 43 - left_width - right_width,
          height: 55 - top_height
        },
        sidebars: sidebars,
        **options
      )
    end

    # Factory: Standard weekly page layout.
    #
    # Left sidebar (2 cols), top navigation (2 rows), right sidebar (1 col).
    # Content area: cols 2-41, rows 2-54 (39×53 boxes).
    #
    # @param options [Hash] Additional options to pass to Layout
    # @return [Layout] Weekly page layout
    def self.weekly_layout(**options)
      with_sidebars(left_width: 2, right_width: 1, top_height: 2, **options)
    end

    # Factory: Year overview layout.
    #
    # Similar to weekly but with slightly different proportions.
    # Left sidebar (2 cols), right sidebar (1 col), top header (2 rows).
    #
    # @param options [Hash] Additional options to pass to Layout
    # @return [Layout] Year overview layout
    def self.year_overview_layout(**options)
      with_sidebars(left_width: 2, right_width: 1, top_height: 2, **options)
    end

    private

    # Validate content area specification.
    #
    # @raise [ArgumentError] if content area is invalid
    def validate_content_area
      required_keys = [:col, :row, :width, :height]
      missing_keys = required_keys - @content_area_spec.keys

      if missing_keys.any?
        raise ArgumentError, "Content area missing required keys: #{missing_keys.join(', ')}"
      end

      # Validate bounds
      col = @content_area_spec[:col]
      row = @content_area_spec[:row]
      width = @content_area_spec[:width]
      height = @content_area_spec[:height]

      if col < 0 || col >= 43
        raise ArgumentError, "Content area col must be 0-42, got #{col}"
      end

      if row < 0 || row >= 55
        raise ArgumentError, "Content area row must be 0-54, got #{row}"
      end

      if width <= 0 || col + width > 43
        raise ArgumentError, "Content area width invalid: col=#{col}, width=#{width}"
      end

      if height <= 0 || row + height > 55
        raise ArgumentError, "Content area height invalid: row=#{row}, height=#{height}"
      end
    end

    # Validate sidebar specifications.
    #
    # @raise [ArgumentError] if any sidebar is invalid
    def validate_sidebars
      @sidebar_specs.each_with_index do |sidebar, index|
        required_keys = [:position, :col, :row, :width, :height]
        missing_keys = required_keys - sidebar.keys

        if missing_keys.any?
          raise ArgumentError, "Sidebar #{index} missing required keys: #{missing_keys.join(', ')}"
        end

        valid_positions = [:left, :right, :top, :bottom]
        unless valid_positions.include?(sidebar[:position])
          raise ArgumentError, "Sidebar #{index} has invalid position: #{sidebar[:position]}"
        end
      end
    end
  end
end
