# frozen_string_literal: true

require_relative '../utilities/diagnostics'

module BujoPdf
  # Build-level layout debugging: `debug: true` (or a list of kinds) on a
  # build outlines what each page drew, without editing page classes.
  #
  # The overlay rides on the Prawn document. Components that know a rect worth
  # outlining hand it to Debug.overlay(pdf), which is nil when debug is off,
  # and Pages::Base draws the collected rects after the page has finished
  # rendering, so the outlines sit on top and cannot move anything.
  #
  # @example
  #   BujoPdf.generate_from_recipe :standard_planner, year: 2026, debug: true
  #   BujoPdf.generate_from_recipe :daily, year: 2026, debug: 'fieldset,link'
  module Debug
    # Install an overlay on a document. A falsy option leaves it untouched.
    #
    # @param pdf [Prawn::Document] The document being built
    # @param option [Boolean, String, Array<Symbol>, nil] See Overlay.build
    # @return [Overlay, nil] The installed overlay
    def self.install(pdf, option)
      overlay = Overlay.build(option)
      return unless overlay

      pdf.extend(LinkRecording)
      pdf.debug_overlay = overlay
    end

    # The overlay installed on a document, or nil.
    #
    # @param pdf [Prawn::Document]
    # @return [Overlay, nil]
    def self.overlay(pdf)
      pdf.debug_overlay if pdf.respond_to?(:debug_overlay)
    end

    # Every link annotation passes through Prawn's link_annotation, so
    # wrapping it on the one document catches them all.
    module LinkRecording
      attr_accessor :debug_overlay

      def link_annotation(rect, options = {})
        left, bottom, right, top = rect
        debug_overlay.record(:link, left, top, right - left, top - bottom)
        super
      end
    end

    # Collects outline rects for the current page and draws them.
    class Overlay
      KINDS = %i[grid chrome content fieldset link].freeze

      COLORS = {
        chrome: '0EA5E9',
        content: '16A34A',
        fieldset: '7C3AED',
        link: 'E11D48'
      }.freeze

      # Strokes sit just inside their rect so adjacent outlines stay distinct.
      INSET = 0.25
      LINE_WIDTH = 0.5

      # @param option [true, String, Array, nil, false] true for every kind,
      #   or kinds as "grid,link" or %i[grid link]
      # @return [Overlay, nil] nil when the option turns debugging off
      # @raise [ArgumentError] for an unknown kind
      def self.build(option)
        kinds = case option
                when nil, false then []
                when true then KINDS
                when String then option.split(',').map { |kind| kind.strip.to_sym }
                else Array(option).map(&:to_sym)
                end
        return nil if kinds.empty?

        unknown = kinds - KINDS
        unless unknown.empty?
          raise ArgumentError, "Unknown debug kind: #{unknown.join(', ')} (available: #{KINDS.join(', ')})"
        end

        new(kinds)
      end

      attr_reader :kinds, :rects

      def initialize(kinds)
        @kinds = kinds
        @rects = []
      end

      def enabled?(kind)
        @kinds.include?(kind)
      end

      # Record a rect, in page points with a top-left corner, for this page.
      #
      # @param dashed [Boolean] Dash the outline (inner areas, e.g. fieldset content)
      # @return [void]
      def record(kind, left, top, width, height, dashed: false)
        return unless enabled?(kind)

        @rects << { kind: kind, left: left, top: top, width: width, height: height, dashed: dashed }
      end

      # Draw the overlay for the page just rendered, then forget its rects.
      #
      # @param pdf [Prawn::Document]
      # @param grid [GridSystem]
      # @param chrome_spec [Layouts::ChromeSpec, nil] The page layout's chrome
      # @param content_area [Hash, nil] The page's content area in grid boxes
      # @return [void]
      def draw(pdf, grid, chrome_spec: nil, content_area: nil)
        pdf.save_graphics_state do
          Diagnostics.draw_grid(pdf, grid, label_every: 5) if enabled?(:grid)
          pdf.line_width LINE_WIDTH
          chrome_rects(grid, chrome_spec).each { |rect| stroke(pdf, :chrome, rect) } if enabled?(:chrome)
          stroke(pdf, :content, grid_rect(grid, content_area)) if content_area && enabled?(:content)
          @rects.each { |rect| stroke(pdf, rect[:kind], rect) }
        end
      ensure
        @rects.clear
      end

      private

      def stroke(pdf, kind, rect)
        pdf.stroke_color COLORS.fetch(kind)
        rect[:dashed] ? pdf.dash(2, space: 2) : pdf.undash
        pdf.stroke_rectangle [rect[:left] + INSET, rect[:top] - INSET],
                             rect[:width] - (INSET * 2), rect[:height] - (INSET * 2)
      end

      # One rect per active chrome region: left and right run the full page
      # height, top and bottom span the columns between them.
      def chrome_rects(grid, spec)
        return [] unless spec

        left = spec.region_width(:left)
        right = spec.region_width(:right)
        top = spec.region_width(:top)
        bottom = spec.region_width(:bottom)
        middle = grid.cols - left - right

        [
          [left.positive?, 0, 0, left, grid.rows],
          [right.positive?, grid.cols - right, 0, right, grid.rows],
          [top.positive?, left, 0, middle, top],
          [bottom.positive?, left, grid.rows - bottom, middle, bottom]
        ].filter_map do |active, col, row, width, height|
          box_rect(grid, col, row, width, height) if active
        end
      end

      def grid_rect(grid, area)
        box_rect(grid, area[:col], area[:row], area[:width_boxes], area[:height_boxes])
      end

      def box_rect(grid, col, row, width, height)
        { left: grid.x(col), top: grid.y(row), width: grid.width(width), height: grid.height(height) }
      end
    end
  end
end
