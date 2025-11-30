# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Index page for building a custom table of contents.
    #
    # Classic bullet journal technique: numbered lines where users can write
    # their own page references and hyperlink entries. Each index page has
    # a named destination so TOC entries can link to specific index pages.
    #
    # Design:
    # - Two-column layout with numbered lines
    # - Page number boxes for each entry
    # - Named destinations for each index page (index_1, index_2)
    # - 2 pages total covering entries 1-100
    #
    # Example:
    #   context = RenderContext.new(
    #     page_key: :index,
    #     index_page_num: 1,        # Which index page (1 or 2)
    #     index_page_count: 2       # Total index pages
    #   )
    #   page = IndexPage.new(pdf, context)
    #   page.generate
    class IndexPage < Base
      register_page :index,
        title: "Index",
        dest: "index_%{_n}"

      # Mixin providing index_page and index_pages verbs for document builders.
      module Mixin
        include MixinSupport

        # Generate a single index page.
        #
        # @param num [Integer] Which index page (1, 2, etc.)
        # @param total [Integer, nil] Total index pages (defaults to num)
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def index_page(num:, total: nil)
          count = total || num
          define_page(dest: "index_#{num}", title: 'Index', type: :index,
                      index_page_num: num, index_page_count: count) do |ctx|
            IndexPage.new(@pdf, ctx).generate
          end
        end

        # Generate multiple index pages.
        #
        # Uses page_set DSL to automatically populate context.set with
        # page position and label information.
        #
        # @param count [Integer] Number of index pages (default: 2)
        # @return [Array<PageRef>, nil] Array of PageRefs during define phase
        def index_pages(count: 2)
          page_set(count, "Index %page of %total") do
            index_page(num: @current_page_set_index + 1, total: count)
          end
        end
      end

      # Layout constants
      LEFT_MARGIN = 2
      RIGHT_MARGIN = 41
      COLUMN_GAP = 1
      HEADER_ROW = 1
      CONTENT_START_ROW = 4

      # Number of entry lines per column
      LINES_PER_COLUMN = 25

      # Entries per page (2 columns)
      ENTRIES_PER_PAGE = LINES_PER_COLUMN * 2

      # Setup with full page layout (no sidebars for index)
      def setup
        # Get page position from context.set (page_set DSL) or legacy context
        @index_page_num = context.set? ? context.set.page : (context[:index_page_num] || 1)
        @index_page_count = context.set? ? context.set.total : (context[:index_page_count] || 2)

        # Set named destination for this index page
        set_destination("index_#{@index_page_num}")

        use_layout :full_page
      end

      # Render the index page with numbered lines in two columns
      def render
        draw_header
        draw_two_column_layout
        draw_column_divider
        @grid.redraw_dots(col: 0, row: 0, width: @grid.cols, height: @grid.rows)
        # Footer drawn after dots so text appears clean
        draw_set_label(col: LEFT_MARGIN, width: content_width)
      end

      private

      # Draw the page header
      #
      # @return [void]
      def draw_header
        h2(LEFT_MARGIN, HEADER_ROW, 'Index')
      end

      # Draw the two-column layout with entry lines using RuledList
      #
      # @return [void]
      def draw_two_column_layout
        left, right = @grid.divide_columns(col: LEFT_MARGIN, width: content_width, count: 2, gap: COLUMN_GAP)

        # Starting entry number for this page
        base_entry = (@index_page_num - 1) * ENTRIES_PER_PAGE

        # Draw left column
        ruled_list(left.col, CONTENT_START_ROW, left.width,
                   entries: LINES_PER_COLUMN,
                   start_num: base_entry + 1)

        # Draw right column
        ruled_list(right.col, CONTENT_START_ROW, right.width,
                   entries: LINES_PER_COLUMN,
                   start_num: base_entry + LINES_PER_COLUMN + 1)
      end

      # Draw vertical divider between columns
      #
      # @return [void]
      def draw_column_divider
        left, _right = @grid.divide_columns(col: LEFT_MARGIN, width: content_width, count: 2, gap: COLUMN_GAP)
        divider_col = left.col + left.width
        divider_height = LINES_PER_COLUMN * 2  # 2 rows per entry

        vline(divider_col, CONTENT_START_ROW, divider_height, color: 'E5E5E5')
      end

      # Calculate content width (usable area between margins)
      #
      # @return [Integer] Width in grid boxes
      def content_width
        RIGHT_MARGIN - LEFT_MARGIN
      end
    end
  end
end
