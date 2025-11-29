# frozen_string_literal: true

# DSL module provides a declarative domain-specific language for defining
# page layouts. Instead of imperative Prawn calls, pages are specified as
# a tree of layout nodes that compute their positions during a layout pass.
#
# Key concepts:
# - Grid-centric: All sizes in grid boxes (not points), aligned to 5mm dot grid
# - Layout tree: Nodes compute bounds based on constraints and available space
# - Separation: Layout specification is separate from rendering
#
# @example Simple page layout
#   BujoPdf::DSL.build_layout do
#     sidebar width: 3 do
#       nav_link dest: :year_events, label: "Year"
#     end
#
#     section name: :content, flex: 1 do
#       header height: 2 do
#         text "Week 42", style: :title
#       end
#
#       columns count: 7 do |col|
#         text "Day #{col}"
#       end
#     end
#   end
#
module BujoPdf
  module DSL
    # Load all DSL components
    autoload :LayoutNode, 'bujo_pdf/dsl/layout_node'
    autoload :ContainerNode, 'bujo_pdf/dsl/container_node'
    autoload :SectionNode, 'bujo_pdf/dsl/section_node'
    autoload :SidebarNode, 'bujo_pdf/dsl/section_node'
    autoload :HeaderNode, 'bujo_pdf/dsl/section_node'
    autoload :FooterNode, 'bujo_pdf/dsl/section_node'
    autoload :ColumnsNode, 'bujo_pdf/dsl/columns_node'
    autoload :RowsNode, 'bujo_pdf/dsl/columns_node'
    autoload :GridNode, 'bujo_pdf/dsl/columns_node'
    autoload :ContentNode, 'bujo_pdf/dsl/content_node'
    autoload :TextNode, 'bujo_pdf/dsl/content_node'
    autoload :FieldNode, 'bujo_pdf/dsl/content_node'
    autoload :DotGridNode, 'bujo_pdf/dsl/content_node'
    autoload :GraphGridNode, 'bujo_pdf/dsl/content_node'
    autoload :RuledLinesNode, 'bujo_pdf/dsl/content_node'
    autoload :SpacerNode, 'bujo_pdf/dsl/content_node'
    autoload :DividerNode, 'bujo_pdf/dsl/content_node'
    autoload :NavLinkNode, 'bujo_pdf/dsl/navigation_node'
    autoload :NavGroupNode, 'bujo_pdf/dsl/navigation_node'
    autoload :TabNode, 'bujo_pdf/dsl/navigation_node'
    autoload :ComponentDefinition, 'bujo_pdf/dsl/component_definition'
    autoload :ComponentRegistry, 'bujo_pdf/dsl/component_definition'
    autoload :LayoutBuilder, 'bujo_pdf/dsl/layout_builder'
    autoload :StyleResolver, 'bujo_pdf/dsl/style_resolver'
    autoload :Theme, 'bujo_pdf/dsl/style_resolver'
    autoload :ThemeBuilder, 'bujo_pdf/dsl/style_resolver'
    autoload :ThemeRegistry, 'bujo_pdf/dsl/style_resolver'
    autoload :LayoutRenderer, 'bujo_pdf/dsl/layout_renderer'
    autoload :CustomNode, 'bujo_pdf/dsl/layout_renderer'

    # Build a layout tree using the DSL.
    #
    # @yield Block containing DSL commands
    # @return [LayoutNode] Root node of the layout tree
    #
    # @example
    #   layout = BujoPdf::DSL.build_layout do
    #     sidebar width: 3
    #     section name: :content, flex: 1
    #   end
    def self.build_layout(&block)
      builder = LayoutBuilder.new
      builder.instance_eval(&block)
      builder.root
    end

    # Compute layout for a tree given page dimensions.
    #
    # @param root [LayoutNode] Root node of layout tree
    # @param cols [Integer] Available columns (default: 43)
    # @param rows [Integer] Available rows (default: 55)
    # @return [LayoutNode] The same root with computed bounds
    def self.compute_layout(root, cols: 43, rows: 55)
      root.compute_bounds(col: 0, row: 0, width: cols, height: rows)
      root
    end
  end
end
