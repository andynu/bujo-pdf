# frozen_string_literal: true

require_relative '../../test_helper'

class TestFieldset < Minitest::Test
  def setup
    @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
    @grid = GridSystem.new(@pdf)
    @canvas = BujoPdf::Canvas.new(@pdf, @grid)
  end

  # ============================================
  # Constants Tests
  # ============================================

  def test_defaults_constant_exists
    assert BujoPdf::Components::Fieldset::DEFAULTS.is_a?(Hash)
  end

  def test_defaults_has_position
    assert_equal :top_left, BujoPdf::Components::Fieldset::DEFAULTS[:position]
  end

  def test_defaults_has_legend_padding
    assert_equal 5, BujoPdf::Components::Fieldset::DEFAULTS[:legend_padding]
  end

  def test_defaults_has_font_size
    assert_equal 12, BujoPdf::Components::Fieldset::DEFAULTS[:font_size]
  end

  def test_defaults_has_inset_boxes
    assert_equal 0.5, BujoPdf::Components::Fieldset::DEFAULTS[:inset_boxes]
  end

  def test_position_config_has_all_positions
    config = BujoPdf::Components::Fieldset::POSITION_CONFIG
    assert config[:top_left]
    assert config[:top_center]
    assert config[:top_right]
    assert config[:bottom_left]
    assert config[:bottom_right]
  end

  def test_position_config_top_left
    config = BujoPdf::Components::Fieldset::POSITION_CONFIG[:top_left]
    assert_equal :top, config[:edge]
    assert_equal :left, config[:align]
    assert_equal 0, config[:rotation]
  end

  def test_position_config_top_right
    config = BujoPdf::Components::Fieldset::POSITION_CONFIG[:top_right]
    assert_equal :right, config[:edge]
    assert_equal :top, config[:align]
    assert_equal(-90, config[:rotation])
  end

  def test_position_config_bottom_right
    config = BujoPdf::Components::Fieldset::POSITION_CONFIG[:bottom_right]
    assert_equal :left, config[:edge]
    assert_equal :bottom, config[:align]
    assert_equal 90, config[:rotation]
  end

  # ============================================
  # Initialization Tests
  # ============================================

  def test_initialize_sets_required_params
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test"
    )

    assert_equal 5, fieldset.instance_variable_get(:@col)
    assert_equal 10, fieldset.instance_variable_get(:@row)
    assert_equal 20, fieldset.instance_variable_get(:@width_boxes)
    assert_equal 15, fieldset.instance_variable_get(:@height_boxes)
    assert_equal "Test", fieldset.instance_variable_get(:@legend)
  end

  def test_initialize_default_position
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test"
    )

    assert_equal :top_left, fieldset.instance_variable_get(:@position_name)
  end

  def test_initialize_custom_position
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test",
      position: :bottom_left
    )

    assert_equal :bottom_left, fieldset.instance_variable_get(:@position_name)
  end

  def test_initialize_custom_font_size
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test",
      font_size: 18
    )

    assert_equal 18, fieldset.instance_variable_get(:@font_size)
  end

  def test_initialize_custom_legend_padding
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test",
      legend_padding: 10
    )

    assert_equal 10, fieldset.instance_variable_get(:@legend_padding)
  end

  def test_initialize_custom_border_color
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test",
      border_color: 'FF0000'
    )

    assert_equal 'FF0000', fieldset.instance_variable_get(:@border_color_option)
  end

  def test_initialize_custom_text_color
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test",
      text_color: '0000FF'
    )

    assert_equal '0000FF', fieldset.instance_variable_get(:@text_color_option)
  end

  def test_initialize_custom_inset_boxes
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test",
      inset_boxes: 1.0
    )

    assert_equal 1.0, fieldset.instance_variable_get(:@inset_boxes)
  end

  def test_initialize_custom_legend_offset
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test",
      legend_offset_x: 5,
      legend_offset_y: 3
    )

    assert_equal 5, fieldset.instance_variable_get(:@legend_offset_x)
    assert_equal 3, fieldset.instance_variable_get(:@legend_offset_y)
  end

  def test_initialize_stores_config
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 10, width: 20, height: 15,
      legend: "Test",
      position: :top_right
    )

    config = fieldset.instance_variable_get(:@config)
    assert_equal :right, config[:edge]
    assert_equal :top, config[:align]
    assert_equal(-90, config[:rotation])
  end

  def test_initialize_invalid_position_raises
    assert_raises ArgumentError do
      BujoPdf::Components::Fieldset.new(
        canvas: @canvas,
        col: 5, row: 10, width: 20, height: 15,
        legend: "Test",
        position: :invalid_position
      )
    end
  end

  # ============================================
  # Render Tests (All Positions)
  # ============================================

  def test_render_top_left
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Top Left",
      position: :top_left
    )
    fieldset.render

    # Should render without error
  end

  def test_render_top_center
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Top Center",
      position: :top_center
    )
    fieldset.render

    # Should render without error
  end

  def test_render_top_right
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Right",
      position: :top_right
    )
    fieldset.render

    # Should render without error (vertical text)
  end

  def test_render_bottom_left
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Bottom Left",
      position: :bottom_left
    )
    fieldset.render

    # Should render without error
  end

  def test_render_bottom_right
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Left Side",
      position: :bottom_right
    )
    fieldset.render

    # Should render without error (vertical text)
  end

  def test_render_with_custom_colors
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Colored",
      border_color: 'FF0000',
      text_color: '0000FF'
    )
    fieldset.render

    # Should render without error
  end

  def test_render_with_offsets
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Offset",
      legend_offset_x: 10,
      legend_offset_y: 5
    )
    fieldset.render

    # Should render without error
  end

  # ============================================
  # Private Method Tests
  # ============================================

  def test_border_color_uses_theme_default
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test"
    )
    fieldset.render  # Need to render to set up state

    color = fieldset.send(:border_color)
    assert color.is_a?(String)
    assert_match(/\A[0-9A-Fa-f]{6}\z/, color)
  end

  def test_border_color_uses_custom_option
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test",
      border_color: 'FF0000'
    )

    color = fieldset.send(:border_color)
    assert_equal 'FF0000', color
  end

  def test_text_color_uses_theme_default
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test"
    )
    fieldset.render

    color = fieldset.send(:text_color)
    assert color.is_a?(String)
    assert_match(/\A[0-9A-Fa-f]{6}\z/, color)
  end

  def test_text_color_uses_custom_option
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test",
      text_color: '0000FF'
    )

    color = fieldset.send(:text_color)
    assert_equal '0000FF', color
  end

  def test_calculate_gap_rect_top
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test",
      position: :top_left
    )
    fieldset.render  # Need to render to calculate legend dimensions

    gap = fieldset.send(:calculate_gap_rect)
    assert_equal 4, gap.size
    assert gap[0].is_a?(Numeric)  # col
    assert gap[1].is_a?(Numeric)  # row
    assert gap[2].is_a?(Numeric)  # width
    assert gap[3].is_a?(Numeric)  # height
  end

  def test_calculate_gap_rect_bottom
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test",
      position: :bottom_left
    )
    fieldset.render

    gap = fieldset.send(:calculate_gap_rect)
    assert_equal 4, gap.size
  end

  def test_calculate_gap_rect_right
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test",
      position: :top_right
    )
    fieldset.render

    gap = fieldset.send(:calculate_gap_rect)
    assert_equal 4, gap.size
  end

  def test_calculate_gap_rect_left
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test",
      position: :bottom_right
    )
    fieldset.render

    gap = fieldset.send(:calculate_gap_rect)
    assert_equal 4, gap.size
  end

  def test_calculate_horizontal_gap_col_left
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test"
    )
    fieldset.render

    col = fieldset.send(:calculate_horizontal_gap_col, :left, 0)
    assert col > 5  # Should be offset from left edge
  end

  def test_calculate_horizontal_gap_col_center
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test"
    )
    fieldset.render

    col = fieldset.send(:calculate_horizontal_gap_col, :center, 0)
    # Center should be around col 15 (5 + 20/2)
    assert col > 10
    assert col < 20
  end

  def test_calculate_horizontal_gap_col_right
    fieldset = BujoPdf::Components::Fieldset.new(
      canvas: @canvas,
      col: 5, row: 5, width: 20, height: 15,
      legend: "Test"
    )
    fieldset.render

    col = fieldset.send(:calculate_horizontal_gap_col, :right, 0)
    assert col > 15  # Should be toward right edge
  end
end

class TestFieldsetMixin < Minitest::Test
  class TestIncluder
    include BujoPdf::Components::Fieldset::Mixin

    attr_reader :pdf, :grid, :canvas

    def initialize
      @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
      @grid = GridSystem.new(@pdf)
      @canvas = nil  # Will use Canvas.new fallback
    end
  end

  def setup
    @includer = TestIncluder.new
  end

  def test_mixin_provides_fieldset_method
    assert @includer.respond_to?(:fieldset)
  end

  def test_mixin_fieldset_renders
    @includer.fieldset(5, 5, 20, 15, legend: "Test")

    # Should render without error
  end

  def test_mixin_fieldset_with_options
    @includer.fieldset(5, 5, 20, 15,
      legend: "Test",
      position: :top_right,
      font_size: 14,
      border_color: 'FF0000'
    )

    # Should render without error
  end
end
