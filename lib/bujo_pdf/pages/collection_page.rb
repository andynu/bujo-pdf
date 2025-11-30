# frozen_string_literal: true

require_relative 'base'

module BujoPdf
  module Pages
    # Collection page - a titled blank page for custom lists and collections.
    #
    # Classic bullet journal technique: dedicated pages for themed collections
    # like "Books to Read", "Project Ideas", "Recipes to Try", etc. Each page
    # has a title header and blank dot grid space for writing entries.
    #
    # Users configure collections in config/collections.yml and the generator
    # creates titled pages for each one.
    #
    # Design:
    # - Clean title header at top
    # - Subtitle/description area (optional)
    # - Full dot grid background for flexible use
    # - Named destination for hyperlinking from index
    #
    # Example:
    #   context = RenderContext.new(
    #     page_key: :collection_books_to_read,
    #     collection_title: "Books to Read",
    #     collection_subtitle: "Fiction, non-fiction, and everything in between",
    #     collection_id: "books_to_read",
    #     year: 2025
    #   )
    #   page = CollectionPage.new(pdf, context)
    #   page.generate
    class CollectionPage < Base
      register_page :collection,
        title: "%{collection_title}",
        dest: "collection_%{collection_id}"

      # Mixin providing collection_page verb for document builders.
      module Mixin
        include MixinSupport

        # Generate a single collection page.
        #
        # @param id [String] Collection identifier
        # @param title [String] Collection title
        # @param subtitle [String, nil] Optional subtitle
        # @return [PageRef, nil] PageRef during define phase, nil during render
        def collection_page(id:, title:, subtitle: nil)
          define_page(dest: "collection_#{id}", title: title, type: :collection,
                      collection_id: id, collection_title: title,
                      collection_subtitle: subtitle) do |ctx|
            CollectionPage.new(@pdf, ctx).generate
          end
        end
      end

      def setup
        @title = context[:collection_title] || "Collection"
        @subtitle = context[:collection_subtitle]
        @collection_id = context[:collection_id] || "collection"

        # Set named destination for this collection page
        set_destination("collection_#{@collection_id}")

        use_layout :full_page
      end

      def render
        draw_header
      end

      private

      # Draw the page header with title and optional subtitle
      #
      # @return [void]
      def draw_header
        # Title box
        title_box = @grid_system.rect(2, 1, 39, 3)

        @pdf.bounding_box([title_box[:x], title_box[:y]],
                          width: title_box[:width],
                          height: title_box[:height]) do
          @pdf.text @title,
                    size: 18,
                    style: :bold,
                    align: :left,
                    valign: :bottom
        end

        # Subtitle if provided
        if @subtitle
          subtitle_box = @grid_system.rect(2, 4, 39, 2)

          @pdf.bounding_box([subtitle_box[:x], subtitle_box[:y]],
                            width: subtitle_box[:width],
                            height: subtitle_box[:height]) do
            @pdf.text @subtitle,
                      size: 10,
                      color: '666666',
                      align: :left,
                      valign: :top
          end
        end

        # Draw a subtle divider line below header
        line_row = @subtitle ? 6 : 4
        line_y = @grid_system.y(line_row)
        @pdf.stroke_color 'CCCCCC'
        @pdf.line_width 0.5
        @pdf.stroke_line [@grid_system.x(2), line_y], [@grid_system.x(41), line_y]
        @pdf.stroke_color '000000'
      end
    end
  end
end
