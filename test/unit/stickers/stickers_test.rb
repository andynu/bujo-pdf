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
    # Only stickers that accept a card have two versions to keep apart. The
    # ones that decline (ornament, stamps, photo frames) appear in a --backed
    # run under their plain name, which is right: there is one version of
    # them, so there is nothing for a card to overwrite.
    cards = BujoPdf::Stickers::Generator.new(all: true, backed: true)
                                        .stickers.grep(BujoPdf::Stickers::Backed)

    assert_empty(cards.map(&:filename) &
                 BujoPdf::Stickers::Generator.default_pack(all: true).map(&:filename))
    cards.each { |c| assert_includes c.slug, '_card' }
  end

  def test_a_backed_run_still_contains_the_whole_pack
    plain = BujoPdf::Stickers::Generator.new(all: true).stickers
    backed = BujoPdf::Stickers::Generator.new(all: true, backed: true).stickers

    assert_equal plain.length, backed.length
  end

  def test_stickers_that_decline_a_card_pass_through_wrap_untouched
    rosette = BujoPdf::Stickers::Rosette.new
    wrapped = BujoPdf::Stickers::Backed.wrap([rosette])

    refute_predicate rosette, :backable?
    assert_same rosette, wrapped.first,
                'a card behind ornament fills the negative space that is the ornament'
  end

  # Marks - the half of the pack applied to what is already on the page

  def test_every_mark_declines_a_card
    # These are ink, ornament or an object lying on the page. A card behind
    # any of them replaces the design with a beige plate.
    BujoPdf::Stickers::Generator.marks(all: true).each do |sticker|
      refute_predicate sticker, :backable?, sticker.slug
    end
  end

  def test_every_form_still_accepts_a_card
    BujoPdf::Stickers::Generator.forms(all: true).each do |sticker|
      assert_predicate sticker, :backable?, sticker.slug
    end
  end

  def test_stamp_ink_follows_the_group_not_the_word
    default = BujoPdf::Stickers::Stamp.all
    by_word = default.to_h { |s| [s.text, s.ink] }

    assert_equal :oxide, by_word['SUCCESS'], 'a verdict should be loud'
    assert_equal :charcoal, by_word['PERMANENT RECORD'], 'provenance should be quiet'
  end

  def test_stamp_alternate_inks_are_available_behind_all
    default = BujoPdf::Stickers::Stamp.all.map(&:slug)
    every = BujoPdf::Stickers::Stamp.all(all: true).map(&:slug)

    refute_includes default, 'stamp_success_charcoal'
    assert_includes every, 'stamp_success_charcoal'
  end

  def test_blank_stamp_ships_in_both_inks_by_default
    blanks = BujoPdf::Stickers::Stamp.all.select { |s| s.text.nil? }

    assert_equal BujoPdf::Stickers::Stamp::INKS.keys.sort, blanks.map(&:ink).sort,
                 'the word is the user\'s, so we cannot pick its register'
  end

  def test_stamp_is_wide_enough_for_its_word
    # Width is rounded up to whole boxes from a measured string. If the
    # rounding ever went the other way the word would touch the frame.
    BujoPdf::Stickers::Stamp.all.reject { |s| s.text.nil? }.each do |stamp|
      needed = BujoPdf::Stickers::Stamp.text_width(stamp.text)
      assert_operator stamp.width_pt, :>, needed, stamp.slug
    end
  end

  # Ornament

  def test_rosette_and_guilloche_leave_a_centre_worth_writing_in
    box = BujoPdf::Stickers::Base::BOX

    BujoPdf::Stickers::Guilloche.all.each do |ring|
      assert_operator ring.core_radius, :>, box * 2,
                      "#{ring.slug} leaves no room for a title"
    end
  end

  def test_guilloche_curve_stays_inside_its_own_rim
    ring = BujoPdf::Stickers::Guilloche.new(lobes: 9)
    cx = ring.width_pt / 2.0
    cy = ring.height_pt / 2.0
    radii = ring.send(:curve_points, cx, cy).map do |x, y|
      Math.sqrt(((x - cx)**2) + ((y - cy)**2))
    end

    assert_operator radii.max, :<=, ring.outer_radius + 0.01, 'curve escapes the page'
    assert_in_delta ring.core_radius, radii.min, 0.5,
                    'the open middle should be exactly what the curve leaves'
  end

  def test_ornament_uses_weight_contrast
    # A single hairline repeated twelve times reads as a spirograph; iron is
    # legible because its members are visibly different thicknesses.
    weights = BujoPdf::Stickers::Ornament::WEIGHTS.values

    assert_equal weights.sort.reverse, weights
    assert_operator weights.first / weights.last, :>, 3
  end

  def test_divider_gap_is_centred_and_wide_enough_to_write_in
    BujoPdf::Stickers::Divider.all.each do |divider|
      start, width = divider.gap

      assert_in_delta divider.width_boxes / 2.0, start + (width / 2.0), 0.001
      assert_operator width, :>=, 5, 'a gap under 5 boxes crowds a short word'
    end
  end

  # Objects

  def test_photo_frame_caption_strip_is_deeper_than_its_other_borders
    # The deep bottom edge is the entire reason the shape reads as instant
    # film rather than as a picture frame.
    assert_operator BujoPdf::Stickers::PhotoFrame::CAPTION, :>,
                    BujoPdf::Stickers::PhotoFrame::TOP * 2
  end

  def test_photo_frame_window_sits_inside_the_frame
    BujoPdf::Stickers::PhotoFrame.all.each do |frame|
      col, row, cols, rows = frame.window

      assert_operator col, :>, 0, frame.slug
      assert_operator row, :>, 0, frame.slug
      assert_operator col + cols, :<, frame.width_boxes, frame.slug
      assert_operator row + rows, :<, frame.height_boxes, frame.slug
    end
  end

  def test_venn_circles_overlap_and_stay_on_the_sticker
    BujoPdf::Stickers::Venn.all.each do |venn|
      radius = venn.send(:bx, BujoPdf::Stickers::Venn::RADIUS)
      centres = venn.centres

      centres.combination(2) do |a, b|
        gap = Math.sqrt(((a[0] - b[0])**2) + ((a[1] - b[1])**2))
        assert_operator gap, :<, radius * 2, "#{venn.slug}: circles do not overlap"
        assert_operator gap, :>, radius, "#{venn.slug}: circles nearly coincide"
      end

      centres.each do |x, y|
        assert_operator x - radius, :>=, -0.01, venn.slug
        assert_operator x + radius, :<=, venn.width_pt + 0.01, venn.slug
        assert_operator y - radius, :>=, -0.01, venn.slug
        assert_operator y + radius, :<=, venn.height_pt + 0.01, venn.slug
      end
    end
  end

  def test_venn_rejects_counts_it_cannot_draw
    assert_raises(ArgumentError) { BujoPdf::Stickers::Venn.new(circles: 4) }
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

  def test_radial_dividers_ask_for_a_round_card
    assert_equal :circle, BujoPdf::Stickers::RadialDivider.new(segments: 12).backing_shape
  end

  def test_other_stickers_default_to_a_rectangular_card
    assert_equal :rect, BujoPdf::Stickers::GridPatch.new(type: :graph).backing_shape
    assert_equal :rect, BujoPdf::Stickers::TopThree.new.backing_shape
  end

  def test_card_adopts_the_shape_its_sticker_asks_for
    round = BujoPdf::Stickers::Backed.new(
      sticker: BujoPdf::Stickers::RadialDivider.new(segments: 24)
    )
    square = BujoPdf::Stickers::Backed.new(
      sticker: BujoPdf::Stickers::GridPatch.new(type: :graph)
    )

    assert_predicate round, :round?
    refute_predicate square, :round?
  end

  def test_card_shape_can_be_overridden
    card = BujoPdf::Stickers::Backed.new(
      sticker: BujoPdf::Stickers::GridPatch.new(type: :graph), shape: :circle
    )

    assert_predicate card, :round?
  end

  def test_round_cards_draw_circles_not_rectangles
    card = BujoPdf::Stickers::Backed.new(
      sticker: BujoPdf::Stickers::RadialDivider.new(segments: 12)
    )
    mock_pdf = MockPDF.new
    card.draw(mock_pdf)
    methods = mock_pdf.calls.map { |c| c[:method] }

    assert_includes methods, :fill_circle
    refute_includes methods, :fill_rounded_rectangle
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
