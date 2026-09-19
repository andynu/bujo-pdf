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

  # Backing

  def test_card_adds_a_gutter_on_every_side
    inner = BujoPdf::Stickers::GridPatch.new(type: :graph)
    card = BujoPdf::Stickers::Backed.new(sticker: inner)
    gutter = BujoPdf::Stickers::Backed::GUTTER_BOXES

    assert_equal inner.width_boxes + (gutter * 2), card.width_boxes
    assert_equal inner.height_boxes + (gutter * 2), card.height_boxes
  end

  def test_cards_stay_on_whole_grid_boxes
    # A half-box gutter on each side adds one whole box per axis, so a backed
    # sticker still lands on the grid when placed at 100%.
    BujoPdf::Stickers::Backed.wrap(
      BujoPdf::Stickers::Generator.default_pack(all: true)
    ).each do |card|
      assert_equal card.width_boxes.to_i, card.width_boxes, "#{card.slug} width"
      assert_equal card.height_boxes.to_i, card.height_boxes, "#{card.slug} height"
    end
  end

  def test_card_slugs_never_collide_with_their_transparent_originals
    plain = BujoPdf::Stickers::Generator.new(all: true)
    cards = BujoPdf::Stickers::Generator.new(all: true, backed: true)

    assert_empty(plain.stickers.map { |s| plain.filename_for(s) } &
                 cards.stickers.map { |s| cards.filename_for(s) })
    cards.stickers.each { |c| assert_includes c.slug, '_card' }
  end

  def test_backed_generator_reports_itself
    refute_predicate BujoPdf::Stickers::Generator.new, :backed?
    assert_predicate BujoPdf::Stickers::Generator.new(backed: true), :backed?
  end

  def test_every_card_draws_without_error
    BujoPdf::Stickers::Backed.wrap(
      BujoPdf::Stickers::Generator.default_pack(all: true)
    ).each do |card|
      pdf = Prawn::Document.new(page_size: [card.width_pt, card.height_pt], margin: 0)
      card.draw(pdf)
      refute_empty pdf.render, "#{card.slug} produced no output"
    end
  end

  def test_card_face_is_opaque_and_covers_the_whole_sticker
    # The face is the only reason a card hides the page's dot grid, so assert
    # it directly: a filled rounded rectangle spanning the full sticker, drawn
    # before any content and not wrapped in a transparency group.
    card = BujoPdf::Stickers::Backed.new(
      sticker: BujoPdf::Stickers::GridPatch.new(type: :graph)
    )
    mock_pdf = MockPDF.new
    card.draw(mock_pdf)

    fills = mock_pdf.calls.select { |c| c[:method] == :fill_rounded_rectangle }
    refute_empty fills, 'card drew no face'

    face = fills.first
    _origin, width, height, _radius = face[:args]
    assert_in_delta card.width_pt, width, 0.01
    assert_in_delta card.height_pt, height, 0.01

    face_index = mock_pdf.calls.index { |c| c[:method] == :fill_rounded_rectangle }
    translate_index = mock_pdf.calls.index { |c| c[:method] == :translate }
    assert_operator face_index, :<, translate_index,
                    'the face must be painted before the content sits on it'
  end

  def test_content_is_clipped_to_the_card_face
    # Without a clip, patterns that tile past their frame (the hexagon grid)
    # bleed through the rounded corners, where nothing can paint over them
    # because that area has to stay transparent.
    card = BujoPdf::Stickers::Backed.new(
      sticker: BujoPdf::Stickers::GridPatch.new(type: :hexagon)
    )
    mock_pdf = MockPDF.new
    card.draw(mock_pdf)

    clip = mock_pdf.calls.find { |c| c[:method] == :add_content }
    refute_nil clip, 'content was drawn without a clipping path'
    assert_equal 'W n', clip[:args].first

    methods = mock_pdf.calls.map { |c| c[:method] }
    assert_operator methods.index(:save_graphics_state), :<, methods.index(:translate)
    assert_operator methods.index(:translate), :<, methods.rindex(:restore_graphics_state)
  end

  # Generator

  # Tagging - the escape hatch for Noteshelf's filename cache

  def test_untagged_filenames_are_unchanged
    generator = BujoPdf::Stickers::Generator.new
    sticker = generator.stickers.first

    assert_equal '', generator.tag_suffix
    assert_equal sticker.filename, generator.filename_for(sticker)
  end

  def test_tag_renames_every_file_in_the_pack
    plain = BujoPdf::Stickers::Generator.new
    tagged = BujoPdf::Stickers::Generator.new(tag: 'v2')

    plain_names = plain.stickers.map { |s| plain.filename_for(s) }
    tagged_names = tagged.stickers.map { |s| tagged.filename_for(s) }

    assert_empty(plain_names & tagged_names,
                 'a tagged run must share no filename with an untagged one, ' \
                 'or the app cache will suppress the re-import')
    tagged_names.each { |n| assert_match(/_v2\z/, n) }
  end

  def test_different_tags_never_collide
    a = BujoPdf::Stickers::Generator.new(tag: 'v2')
    b = BujoPdf::Stickers::Generator.new(tag: 'v3')

    assert_empty(a.stickers.map { |s| a.filename_for(s) } &
                 b.stickers.map { |s| b.filename_for(s) })
  end

  def test_tags_are_sanitised_into_filename_safe_text
    generator = BujoPdf::Stickers::Generator.new(tag: 'v2 test/bad chars')

    assert_equal '_v2-test-bad-chars', generator.tag_suffix
  end

  def test_blank_tags_are_treated_as_no_tag
    ['', '   ', nil, '///'].each do |value|
      assert_equal '', BujoPdf::Stickers::Generator.new(tag: value).tag_suffix,
                   "#{value.inspect} should not produce a suffix"
    end
  end

  def test_tagged_run_writes_tagged_files
    skip 'pdftocairo not installed' unless BujoPdf::Stickers::Generator.converter_available?

    Dir.mktmpdir do |dir|
      pack = [BujoPdf::Stickers::GridPatch.new(type: :graph)]
      BujoPdf::Stickers::Generator.new(
        output_dir: dir, dpi: 72, stickers: pack, tag: 'v2'
      ).generate

      assert_path_exists File.join(dir, 'png', 'grid_graph_10x10_v2.png')
      refute_path_exists File.join(dir, 'png', 'grid_graph_10x10.png')
    end
  end

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
