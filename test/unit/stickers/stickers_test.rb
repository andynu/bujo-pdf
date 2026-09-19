#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'

class TestStickers < Minitest::Test
  BOX = BujoPdf::Stickers::Base::BOX

  # Sizing - the property that makes a placed sticker line up with the page

  def test_sticker_dimensions_are_whole_grid_boxes
    BujoPdf::Stickers::Generator.default_pack(all: true).each do |sticker|
      assert_in_delta sticker.width_boxes * BOX, sticker.width_pt, 0.001, sticker.slug
      assert_in_delta sticker.height_boxes * BOX, sticker.height_pt, 0.001, sticker.slug
      assert_equal sticker.width_boxes, sticker.width_boxes.to_i, "#{sticker.slug} is not a whole number of boxes"
    end
  end

  def test_filenames_are_unique_and_carry_their_size
    pack = BujoPdf::Stickers::Generator.default_pack(all: true)
    names = pack.map(&:filename)

    assert_equal names.uniq.length, names.length, "duplicate sticker filenames"
    pack.each { |s| assert_includes s.filename, s.size_label }
  end

  # Pack composition

  def test_perspective_grid_is_not_offered_as_a_patch
    # Its vanishing point is a page-scale construction; shrunk to a patch it
    # degrades into crossing lines with no depth cue.
    refute_includes BujoPdf::Stickers::GridPatch::TYPES.keys, :perspective
  end

  def test_dot_patch_is_excluded_by_default_but_available
    default = BujoPdf::Stickers::GridPatch.all.map(&:type)
    every = BujoPdf::Stickers::GridPatch.all(all: true).map(&:type)

    refute_includes default, :dot, "dot patch duplicates the page's own dot grid"
    assert_includes every, :dot
  end

  def test_lined_patch_suppresses_the_page_margin_rule
    lined = BujoPdf::Stickers::GridPatch.new(type: :lined)
    spec = BujoPdf::Stickers::GridPatch::TYPES[:lined]

    assert_equal false, spec[:options][:show_margin]
    assert lined # constructed without error
  end

  def test_radial_dividers_cover_every_segment_count_and_depth
    dividers = BujoPdf::Stickers::RadialDivider.all
    combos = dividers.map { |d| [d.segments, d.depth_name] }
    expected = BujoPdf::Stickers::RadialDivider::SEGMENTS.keys.product(
      BujoPdf::Stickers::RadialDivider::DEPTHS.keys
    )

    assert_equal expected.sort, combos.sort
  end

  def test_radial_depths_are_fractions_of_the_radius
    BujoPdf::Stickers::RadialDivider::DEPTHS.each_value do |depth|
      assert_operator depth, :>, 0
      assert_operator depth, :<, 1, "a depth of 1 would close the open centre"
    end
  end

  # Rendering

  def test_every_sticker_draws_without_error
    BujoPdf::Stickers::Generator.default_pack(all: true).each do |sticker|
      pdf = Prawn::Document.new(page_size: [sticker.width_pt, sticker.height_pt], margin: 0)
      sticker.draw(pdf)
      refute_empty pdf.render, "#{sticker.slug} produced no output"
    end
  end

  def test_radial_divider_keeps_its_rim_inside_the_page
    sticker = BujoPdf::Stickers::RadialDivider.new(segments: 24, depth: :deep)
    calls = []
    pdf = Prawn::Document.new(page_size: [sticker.width_pt, sticker.height_pt], margin: 0)
    pdf.define_singleton_method(:stroke_circle) { |c, r| calls << [c, r] }
    pdf.define_singleton_method(:stroke_line) { |_a, _b| nil }

    sticker.draw(pdf)

    assert_equal 2, calls.length, "expected an outer rim and an inner ring"
    outer = calls.map(&:last).max
    assert_operator outer, :<, sticker.width_pt / 2.0,
                    "rim would be clipped by the page edge"
  end

  def test_base_requires_subclasses_to_implement_draw
    sticker = BujoPdf::Stickers::Base.new(
      slug: 'x', title: 'X', width_boxes: 1, height_boxes: 1
    )

    assert_raises(NotImplementedError) { sticker.draw(nil) }
  end

  # Generator

  def test_generate_writes_a_png_and_pdf_for_every_sticker
    skip 'pdftocairo not installed' unless BujoPdf::Stickers::Generator.converter_available?

    Dir.mktmpdir do |dir|
      pack = [BujoPdf::Stickers::RadialDivider.new(segments: 12, depth: :deep)]
      generator = BujoPdf::Stickers::Generator.new(output_dir: dir, dpi: 72, stickers: pack)
      paths = generator.generate

      assert_equal 1, paths.length
      assert_path_exists paths.first
      assert_path_exists File.join(dir, 'pdf', 'radial_12_deep_10x10.pdf')
      assert_path_exists File.join(dir, 'README.txt')
    end
  end

  def test_generated_png_is_transparent_and_sized_to_the_grid
    skip 'pdftocairo not installed' unless BujoPdf::Stickers::Generator.converter_available?

    Dir.mktmpdir do |dir|
      sticker = BujoPdf::Stickers::GridPatch.new(type: :graph)
      dpi = 72
      BujoPdf::Stickers::Generator.new(
        output_dir: dir, dpi: dpi, stickers: [sticker]
      ).generate

      png = File.join(dir, 'png', "#{sticker.filename}.png")
      data = File.binread(png)

      assert_equal "\x89PNG\r\n\x1A\n".b, data[0, 8], 'not a PNG'

      width, height = data[16, 8].unpack('N2')
      expected = (sticker.width_pt * dpi / 72.0).round
      assert_in_delta expected, width, 1
      assert_in_delta expected, height, 1

      color_type = data[25].ord
      assert_equal 6, color_type, 'expected RGBA (transparent) output'
    end
  end
end
