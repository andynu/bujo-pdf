#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../test_helper'
require 'bujo_pdf/dsl'

class TestLayoutBuilder < Minitest::Test
  def test_builds_root_container
    layout = BujoPdf::DSL.build_layout do
      # Empty layout
    end

    assert_instance_of BujoPdf::DSL::ContainerNode, layout
    assert_equal :root, layout.name
    assert_equal :vertical, layout.direction
  end

  def test_section_method
    layout = BujoPdf::DSL.build_layout do
      section name: :content, height: 10
    end

    section = layout.find(:content)
    refute_nil section
    assert_equal 10, section.constraints[:height]
  end

  def test_sidebar_method
    layout = BujoPdf::DSL.build_layout do
      sidebar name: :left_nav, width: 3
    end

    sidebar = layout.find(:left_nav)
    refute_nil sidebar
    assert_equal 3, sidebar.constraints[:width]
    assert_equal :vertical, sidebar.direction
  end

  def test_header_method
    layout = BujoPdf::DSL.build_layout do
      header name: :page_header, height: 2
    end

    header = layout.find(:page_header)
    refute_nil header
    assert_equal 2, header.constraints[:height]
    assert_equal :horizontal, header.direction
  end

  def test_footer_method
    layout = BujoPdf::DSL.build_layout do
      footer name: :summary, height: 3
    end

    footer = layout.find(:summary)
    refute_nil footer
    assert_equal 3, footer.constraints[:height]
  end

  def test_nested_sections
    layout = BujoPdf::DSL.build_layout do
      section name: :outer do
        section name: :inner, height: 5
      end
    end

    outer = layout.find(:outer)
    inner = layout.find(:inner)

    refute_nil outer
    refute_nil inner
    assert_equal 1, outer.children.length
    assert_equal inner, outer.children.first
  end

  def test_columns_method
    layout = BujoPdf::DSL.build_layout do
      columns count: 7, gap: 1
    end

    assert_equal 1, layout.children.length
    assert_instance_of BujoPdf::DSL::ColumnsNode, layout.children.first
  end

  def test_rows_method
    layout = BujoPdf::DSL.build_layout do
      rows count: 4
    end

    assert_equal 1, layout.children.length
    assert_instance_of BujoPdf::DSL::RowsNode, layout.children.first
  end

  def test_grid_method
    layout = BujoPdf::DSL.build_layout do
      grid cols: 7, rows: 5
    end

    assert_equal 1, layout.children.length
    assert_instance_of BujoPdf::DSL::GridNode, layout.children.first
  end

  def test_text_method
    layout = BujoPdf::DSL.build_layout do
      text "Hello", style: :title, align: :center
    end

    text_node = layout.children.first
    assert_instance_of BujoPdf::DSL::TextNode, text_node
    assert_equal "Hello", text_node.content
    assert_equal :title, text_node.style
    assert_equal :center, text_node.align
  end

  def test_field_method
    layout = BujoPdf::DSL.build_layout do
      field name: :notes, lines: 5, background: :dot_grid
    end

    field = layout.children.first
    assert_instance_of BujoPdf::DSL::FieldNode, field
    assert_equal :notes, field.name
    assert_equal 5, field.lines
    assert_equal :dot_grid, field.background
  end

  def test_dot_grid_method
    layout = BujoPdf::DSL.build_layout do
      dot_grid spacing: 2
    end

    grid = layout.children.first
    assert_instance_of BujoPdf::DSL::DotGridNode, grid
    assert_equal 2, grid.spacing
  end

  def test_spacer_method
    layout = BujoPdf::DSL.build_layout do
      spacer flex: 1
    end

    spacer = layout.children.first
    assert_instance_of BujoPdf::DSL::SpacerNode, spacer
    assert_equal 1, spacer.constraints[:flex]
  end

  def test_divider_method
    layout = BujoPdf::DSL.build_layout do
      divider orientation: :horizontal, thickness: 1
    end

    divider = layout.children.first
    assert_instance_of BujoPdf::DSL::DividerNode, divider
    assert_equal :horizontal, divider.orientation
    assert_equal 1, divider.thickness
  end

  def test_nav_link_method
    layout = BujoPdf::DSL.build_layout do
      nav_link dest: :year_events, label: "Year"
    end

    link = layout.children.first
    assert_instance_of BujoPdf::DSL::NavLinkNode, link
    assert_equal :year_events, link.dest
    assert_equal "Year", link.label
  end

  def test_tab_method
    layout = BujoPdf::DSL.build_layout do
      tab dest: [:grid_dot, :grid_graph], label: "Grids", cycle: true
    end

    tab = layout.children.first
    assert_instance_of BujoPdf::DSL::TabNode, tab
    assert_equal [:grid_dot, :grid_graph], tab.destinations
    assert_equal "Grids", tab.label
    assert tab.cycle
  end

  def test_content_method
    layout = BujoPdf::DSL.build_layout do
      content do
        text "Main content"
      end
    end

    content = layout.find(:content)
    refute_nil content
    assert_equal 1, content.constraints[:flex]
    assert_equal 1, content.children.length
  end

  def test_complex_layout
    layout = BujoPdf::DSL.build_layout do
      sidebar name: :left, width: 3 do
        nav_link dest: :prev_week, icon: "<-"
        spacer flex: 1
        nav_link dest: :next_week, icon: "->"
      end

      content do
        header name: :week_header, height: 2 do
          text "Week 42", style: :title
        end

        columns count: 7 do
          # Would iterate in real usage
        end

        footer name: :summary, height: 3 do
          divider
          field name: :summary_field, flex: 1
        end
      end
    end

    # Verify structure
    assert_equal 2, layout.children.length  # sidebar + content

    sidebar = layout.find(:left)
    refute_nil sidebar
    assert_equal 3, sidebar.constraints[:width]
    assert_equal 3, sidebar.children.length  # 2 nav_links + spacer

    content = layout.find(:content)
    refute_nil content
    assert_equal 1, content.constraints[:flex]

    header = layout.find(:week_header)
    refute_nil header
    assert_equal 2, header.constraints[:height]
  end

  def test_compute_layout_helper
    layout = BujoPdf::DSL.build_layout do
      sidebar width: 3
      section flex: 1
    end

    BujoPdf::DSL.compute_layout(layout, cols: 43, rows: 55)

    refute_nil layout.computed_bounds
    assert_equal 43, layout.computed_bounds[:width]
    assert_equal 55, layout.computed_bounds[:height]
  end
end
