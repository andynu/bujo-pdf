# frozen_string_literal: true

require 'fileutils'
require 'shellwords'
require_relative 'grid_patch'
require_relative 'radial_divider'
require_relative 'hour_axis'
require_relative 'eisenhower'
require_relative 'habit_strip'
require_relative 'top_three'
require_relative 'timeline_ribbon'

module BujoPdf
  module Stickers
    # Renders stickers to single-page PDFs and converts them to transparent PNGs.
    #
    # PNG is the delivery format because that is what a note app's sticker
    # library accepts; the PDF is kept alongside it because it is the vector
    # original and costs nothing to retain.
    #
    # Conversion shells out to poppler's pdftocairo, which is the piece that
    # supplies transparency (-transp). Prawn leaves the page unpainted, so the
    # only ink in the output is the sticker itself.
    class Generator
      DEFAULT_OUTPUT_DIR = 'stickers'
      # 300 DPI puts a 10-box patch at ~590px, which stays crisp when scaled
      # up slightly on a high-density tablet display.
      DEFAULT_DPI = 300

      class ConversionError < StandardError; end

      attr_reader :output_dir, :dpi, :stickers, :tag

      # @param output_dir [String] Directory to write into
      # @param dpi [Integer] Raster resolution for the PNGs
      # @param stickers [Array<Base>, nil] Defaults to the standard pack
      # @param tag [String, nil] Suffix appended to every filename; see {#tag_suffix}
      def initialize(output_dir: DEFAULT_OUTPUT_DIR, dpi: DEFAULT_DPI, stickers: nil,
                     all: false, tag: nil)
        @output_dir = output_dir
        @dpi = dpi
        @tag = normalize_tag(tag)
        @stickers = stickers || self.class.default_pack(all: all)
      end

      # Filename for a sticker in this run, including any tag.
      #
      # @param sticker [Base]
      # @return [String]
      def filename_for(sticker)
        "#{sticker.filename}#{tag_suffix}"
      end

      # Suffix that forces a note app to treat these as new files.
      #
      # Noteshelf keys its sticker library on filename and caches that key
      # past deletion: delete an imported set, re-import the same filenames,
      # and nothing comes back. Only genuinely new names import. That makes a
      # corrected sticker impossible to replace, because the fix ships under
      # the name the cache is already holding.
      #
      # Tagging a run renames every file, which the app reads as a new pack.
      #
      # @return [String]
      def tag_suffix
        tag ? "_#{tag}" : ''
      end

      # The standard sticker pack.
      #
      # @param all [Boolean] Include stickers that are off by default
      # @return [Array<Base>]
      def self.default_pack(all: false)
        GridPatch.all(all: all) +
          RadialDivider.all +
          HourAxis.all +
          Eisenhower.all +
          HabitStrip.all +
          TopThree.all +
          TimelineRibbon.all
      end

      # Check that the PNG converter is present.
      #
      # @return [Boolean]
      def self.converter_available?
        system('which pdftocairo > /dev/null 2>&1')
      end

      # Generate every sticker.
      #
      # @yield [Base, String] Each sticker and its PNG path, as they complete
      # @return [Array<String>] Paths to the generated PNGs
      def generate
        png_dir = File.join(output_dir, 'png')
        pdf_dir = File.join(output_dir, 'pdf')
        FileUtils.mkdir_p(png_dir)
        FileUtils.mkdir_p(pdf_dir)

        paths = stickers.map do |sticker|
          stem = filename_for(sticker)
          pdf_path = File.join(pdf_dir, "#{stem}.pdf")
          png_path = File.join(png_dir, "#{stem}.png")

          render_pdf(sticker, pdf_path)
          convert_to_png(pdf_path, png_path)

          yield(sticker, png_path) if block_given?
          png_path
        end

        write_readme
        paths
      end

      private

      # Keep tags filename-safe; a tag becomes part of every name in the pack.
      def normalize_tag(value)
        return nil if value.nil?

        cleaned = value.to_s.strip.gsub(/[^A-Za-z0-9._-]+/, '-').gsub(/\A-+|-+\z/, '')
        cleaned.empty? ? nil : cleaned
      end

      # Draw one sticker onto a page sized exactly to it.
      #
      # A page cut to the sticker's bounds means the page edge crops any
      # overflow (hexagons tile past their frame), and it means the PNG has no
      # surrounding whitespace to position around once placed.
      def render_pdf(sticker, path)
        pdf = Prawn::Document.new(
          page_size: [sticker.width_pt, sticker.height_pt],
          margin: 0
        )
        sticker.draw(pdf)
        pdf.render_file(path)
      end

      def convert_to_png(pdf_path, png_path)
        stem = png_path.sub(/\.png\z/, '')
        cmd = [
          'pdftocairo', '-png', '-transp', '-singlefile',
          '-r', dpi.to_s,
          pdf_path, stem
        ].shelljoin

        return if system("#{cmd} > /dev/null 2>&1")

        raise ConversionError, "pdftocairo failed for #{File.basename(pdf_path)}"
      end

      # A note in the pack explaining how to get these into an app, since the
      # import step is the part that is not obvious.
      def write_readme
        File.write(File.join(output_dir, 'README.txt'), <<~TEXT)
          bujo-pdf stickers
          =================

          Transparent PNGs sized to exact multiples of the planner's grid box
          (#{format('%.2f', Stickers::Base::BOX)}pt, ~5mm). Placed at 100% scale, a 10-box patch
          spans exactly ten dots of the planner's dot grid.

          Importing
          ---------
          Noteshelf:  Stickers menu -> + -> import the png/ folder.
                      Or use split screen and drag a PNG onto a page.
          GoodNotes:  add as an image, then save it to Elements for reuse.

          Alignment
          ---------
          Nothing snaps. A dropped sticker lands where you put it, at whatever
          scale was last used. These are sized so that at 100% they match the
          dot grid - you only have to line them up, not resize them.

          Files
          -----
          png/  what you import
          pdf/  vector originals, same artwork
          #{tag ? "\n          This pack is tagged \"#{tag}\".\n" : ''}
          Re-importing
          ------------
          Noteshelf keys its sticker library on filename and remembers that
          key even after you delete the stickers. Re-importing the same
          filenames brings back nothing - only new names import.

          So to replace a set, regenerate with a new tag:

              bujo-pdf stickers --tag v3

          Every file is renamed, the app sees a new pack, and the whole set
          imports.
        TEXT
      end
    end
  end
end
