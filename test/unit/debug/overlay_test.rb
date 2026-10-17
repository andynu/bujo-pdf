#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'pdf/reader'
require 'stringio'

class TestDebugOverlay < Minitest::Test
  Overlay = BujoPdf::Debug::Overlay

  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
  end

  # Option parsing

  def test_build_returns_nil_when_off
    assert_nil Overlay.build(nil)
    assert_nil Overlay.build(false)
    assert_nil Overlay.build([])
  end

  def test_build_true_enables_every_kind
    assert_equal Overlay::KINDS, Overlay.build(true).kinds
  end

  def test_build_accepts_comma_separated_string
    assert_equal %i[grid link], Overlay.build('grid,link').kinds
  end

  def test_build_accepts_symbol_array
    assert_equal %i[fieldset], Overlay.build(%i[fieldset]).kinds
  end

  def test_build_rejects_unknown_kind
    error = assert_raises(ArgumentError) { Overlay.build('grid,widget') }
    assert_match(/widget/, error.message)
    assert_match(/fieldset/, error.message)
  end

  # Installation

  def test_install_off_leaves_document_untouched
    BujoPdf::Debug.install(@pdf, nil)

    refute_respond_to @pdf, :debug_overlay
    assert_nil BujoPdf::Debug.overlay(@pdf)
  end

  def test_install_on_attaches_overlay
    BujoPdf::Debug.install(@pdf, true)

    assert_kind_of Overlay, BujoPdf::Debug.overlay(@pdf)
  end

  def test_overlay_is_nil_for_plain_document
    assert_nil BujoPdf::Debug.overlay(@pdf)
  end

  # Recording

  def test_link_annotations_are_recorded
    BujoPdf::Debug.install(@pdf, %i[link])
    @pdf.link_annotation([10, 20, 110, 60], Dest: 'week_1')

    assert_equal [{ kind: :link, left: 10, top: 60, width: 100, height: 40, dashed: false }],
                 BujoPdf::Debug.overlay(@pdf).rects
  end

  def test_link_annotation_still_creates_annotation
    BujoPdf::Debug.install(@pdf, %i[link])
    @pdf.link_annotation([10, 20, 110, 60], Dest: 'week_1')

    annots = reader_for(@pdf).pages.first.attributes[:Annots]
    assert_equal 1, annots.length
  end

  def test_kinds_not_enabled_are_not_recorded
    BujoPdf::Debug.install(@pdf, %i[fieldset])
    @pdf.link_annotation([10, 20, 110, 60], Dest: 'week_1')

    assert_empty BujoPdf::Debug.overlay(@pdf).rects
  end

  def test_fieldset_records_outer_and_content_rects
    BujoPdf::Debug.install(@pdf, %i[fieldset])
    canvas = BujoPdf::Canvas.new(@pdf, @grid)
    BujoPdf::Components::Fieldset.new(canvas: canvas, col: 2, row: 4, width: 10, height: 6,
                                      legend: 'Tasks').render

    outer, inner = BujoPdf::Debug.overlay(@pdf).rects
    assert_equal({ kind: :fieldset, left: @grid.x(2), top: @grid.y(4),
                   width: @grid.width(10), height: @grid.height(6), dashed: false }, outer)
    assert_equal({ kind: :fieldset, left: @grid.x(2.5), top: @grid.y(4.5),
                   width: @grid.width(9), height: @grid.height(5), dashed: true }, inner)
  end

  # Drawing

  def test_draw_strokes_recorded_rects_and_clears_them
    BujoPdf::Debug.install(@pdf, %i[link])
    @pdf.link_annotation([10, 20, 110, 60], Dest: 'week_1')
    overlay = BujoPdf::Debug.overlay(@pdf)

    overlay.draw(@pdf, @grid)

    assert_includes content(@pdf), "#{PDF::Core.real_params([10.25, 20.25, 99.5, 39.5])} re"
    assert_includes content(@pdf), "#{color_op('E11D48')} SCN"
    assert_empty overlay.rects
  end

  def test_draw_outlines_chrome_regions_and_content_area
    overlay = Overlay.build(%i[chrome content])
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar, right: :tab_sidebar)
    content_area = { col: 2, row: 0, width_boxes: 40, height_boxes: 55 }

    overlay.draw(@pdf, @grid, chrome_spec: spec, content_area: content_area)

    ops = content(@pdf)
    assert_includes ops, rect_op(@grid.x(0), @grid.y(0), @grid.width(2), @grid.height(55))
    assert_includes ops, rect_op(@grid.x(42), @grid.y(0), @grid.width(1), @grid.height(55))
    assert_includes ops, rect_op(@grid.x(2), @grid.y(0), @grid.width(40), @grid.height(55))
    assert_includes ops, "#{color_op(Overlay::COLORS[:chrome])} SCN"
    assert_includes ops, "#{color_op(Overlay::COLORS[:content])} SCN"
  end

  def test_draw_without_chrome_kind_skips_regions
    overlay = Overlay.build(%i[content])
    spec = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar)

    overlay.draw(@pdf, @grid, chrome_spec: spec)

    refute_includes content(@pdf), "#{color_op(Overlay::COLORS[:chrome])} SCN"
  end

  def test_draw_grid_kind_draws_diagnostic_grid
    called = false
    Diagnostics.stub(:draw_grid, ->(*) { called = true }) do
      Overlay.build(%i[grid]).draw(@pdf, @grid)
    end

    assert called
  end

  def test_draw_without_grid_kind_skips_diagnostic_grid
    Diagnostics.stub(:draw_grid, ->(*) { flunk 'grid drawn' }) do
      Overlay.build(%i[link]).draw(@pdf, @grid)
    end
  end

  def test_draw_restores_graphics_state
    @pdf.stroke_color '123456'
    @pdf.line_width 3
    Overlay.build(true).draw(@pdf, @grid)

    assert_equal '123456', @pdf.stroke_color
    assert_equal 3, @pdf.line_width
  end

  def test_draw_restores_font
    @pdf.font 'Times-Roman', size: 14
    Overlay.build(true).draw(@pdf, @grid)

    assert_equal 'Times-Roman', @pdf.font.family
    assert_equal 14, @pdf.font_size
  end

  private

  def reader_for(pdf)
    PDF::Reader.new(StringIO.new(pdf.render))
  end

  def content(pdf)
    reader_for(pdf).pages.first.raw_content
  end

  def color_op(hex)
    PDF::Core.real_params(hex.scan(/../).map { |c| c.to_i(16) / 255.0 })
  end

  def rect_op(left, top, width, height)
    inset = Overlay::INSET
    "#{PDF::Core.real_params([left + inset, top - height + inset, width - (inset * 2), height - (inset * 2)])} re"
  end
end
