# frozen_string_literal: true

require_relative 'base'
require_relative '../utilities/styling'

module BujoPdf
  module Pages
    # Visual Table of Contents page with thumbnail previews.
    #
    # This page displays thumbnail images of different page types with
    # labels and optional links. Thumbnails must be pre-generated using
    # bin/generate-thumbnails before rendering this page.
    #
    # Design:
    # - Grid of thumbnails with labels
    # - Links to corresponding page destinations
    # - Theme-aware styling
    #
    # Example:
    #   context = { year: 2025, total_weeks: 52 }
    #   page = VisualToc.new(pdf, context)
    #   page.generate
    class VisualToc < Base
      include Styling::Colors
      include Styling::Grid

      register_page :visual_toc,
        title: 'Visual Table of Contents',
        dest: 'visual_toc'

      # Thumbnail configuration
      # Maps section name to display label and link destination
      SECTIONS = [
        { name: 'index', label: 'Index', dest: 'index_1' },
        { name: 'future_log', label: 'Future Log', dest: 'future_log_1' },
        { name: 'seasonal', label: 'Seasonal', dest: 'seasonal' },
        { name: 'year_events', label: 'Year Events', dest: 'year_events' },
        { name: 'year_highlights', label: 'Year Highlights', dest: 'year_highlights' },
        { name: 'multi_year', label: 'Multi-Year', dest: 'multi_year' },
        { name: 'quarterly', label: 'Quarterly', dest: 'quarter_1' },
        { name: 'monthly_review', label: 'Monthly Review', dest: 'review_1' },
        { name: 'weekly', label: 'Weekly', dest: 'week_1' },
        { name: 'daily_wheel', label: 'Daily Wheel', dest: 'daily_wheel' },
        { name: 'year_wheel', label: 'Year Wheel', dest: 'year_wheel' },
        { name: 'grid_showcase', label: 'Grid Types', dest: 'grid_showcase' }
      ].freeze

      # Layout constants
      COLS_PER_ROW = 4
      THUMBNAIL_WIDTH = 8   # Grid boxes for thumbnail
      THUMBNAIL_HEIGHT = 10 # Grid boxes (including label)
      LABEL_HEIGHT = 1      # Grid boxes for label
      ROW_GAP = 1           # Gap between rows
      COL_GAP = 1           # Gap between columns

      # Mixin providing the visual_toc verb for document builders.
      module Mixin
        include MixinSupport

        # Generate the visual TOC page.
        #
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def visual_toc
          define_page(dest: 'visual_toc', title: 'Visual Table of Contents', type: :visual_toc) do |ctx|
            VisualToc.new(@pdf, ctx).generate
          end
        end
      end

      def setup
        set_destination('visual_toc')
        @year = context[:year]
        @total_weeks = context[:total_weeks] || 52

        use_layout :full_page
      end

      def render
        draw_dot_grid
        draw_header
        draw_thumbnails
      end

      private

      def draw_header
        header = @grid_system.rect(0, 0, COLS, 3)
        @pdf.font 'Helvetica-Bold', size: 18
        @pdf.fill_color Styling::Colors.TEXT_BLACK
        @pdf.text_box 'Planner Sections',
                      at: [header[:x], header[:y]],
                      width: header[:width],
                      height: header[:height],
                      align: :center,
                      valign: :center
      end

      def draw_thumbnails
        start_row = 4
        start_col = 2

        SECTIONS.each_with_index do |section, idx|
          col_idx = idx % COLS_PER_ROW
          row_idx = idx / COLS_PER_ROW

          # Calculate position
          col = start_col + (col_idx * (THUMBNAIL_WIDTH + COL_GAP))
          row = start_row + (row_idx * (THUMBNAIL_HEIGHT + ROW_GAP))

          draw_thumbnail(section, col, row)
        end
      end

      def draw_thumbnail(section, col, row)
        thumbnail_path = thumbnail_file(section[:name])

        # Draw thumbnail border
        @pdf.stroke_color Styling::Colors.BORDERS
        box_rect = @grid_system.rect(col, row, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT - LABEL_HEIGHT)
        @pdf.stroke_rectangle([box_rect[:x], box_rect[:y]], box_rect[:width], box_rect[:height])

        # Embed thumbnail image if it exists
        if File.exist?(thumbnail_path)
          image_rect = @grid_system.rect(col, row, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT - LABEL_HEIGHT)

          # Calculate image size to fit within bounds (maintaining aspect ratio)
          @pdf.image thumbnail_path,
                     at: [image_rect[:x] + 2, image_rect[:y] - 2],
                     fit: [image_rect[:width] - 4, image_rect[:height] - 4]
        else
          # Draw placeholder
          @pdf.fill_color 'F0F0F0'
          @pdf.fill_rectangle([box_rect[:x], box_rect[:y]], box_rect[:width], box_rect[:height])
          @pdf.fill_color Styling::Colors.TEXT_BLACK
        end

        # Draw label
        label_rect = @grid_system.rect(col, row + THUMBNAIL_HEIGHT - LABEL_HEIGHT, THUMBNAIL_WIDTH, LABEL_HEIGHT)
        @pdf.font 'Helvetica', size: 8
        @pdf.fill_color Styling::Colors.TEXT_BLACK
        @pdf.text_box section[:label],
                      at: [label_rect[:x], label_rect[:y]],
                      width: label_rect[:width],
                      height: label_rect[:height],
                      align: :center,
                      valign: :center

        # Add link annotation
        full_rect = @grid_system.rect(col, row, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
        link_bottom = full_rect[:y] - full_rect[:height]
        @pdf.link_annotation(
          [full_rect[:x], link_bottom, full_rect[:x] + full_rect[:width], full_rect[:y]],
          Dest: section[:dest],
          Border: [0, 0, 0]
        )
      end

      def thumbnail_file(name)
        File.expand_path("../../../assets/thumbnails/#{name}.png", __dir__)
      end
    end
  end
end
