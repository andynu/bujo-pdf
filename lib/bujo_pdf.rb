# frozen_string_literal: true

require 'prawn'
require 'date'

# Load version first
require_relative 'bujo_pdf/version'

# Load themes (must be loaded before styling)
require_relative 'bujo_pdf/themes/theme_registry'

# Load utilities (no dependencies)
require_relative 'bujo_pdf/utilities/styling'
require_relative 'bujo_pdf/utilities/grid_system'
require_relative 'bujo_pdf/utilities/dot_grid'
require_relative 'bujo_pdf/utilities/diagnostics'
require_relative 'bujo_pdf/utilities/date_calculator'

# Load shared infrastructure
require_relative 'bujo_pdf/page_ref'
require_relative 'bujo_pdf/page_set'
require_relative 'bujo_pdf/page_set_context'
require_relative 'bujo_pdf/week'
require_relative 'bujo_pdf/render_context'
require_relative 'bujo_pdf/component_context'
require_relative 'bujo_pdf/collections_configuration'

# Load base classes
require_relative 'bujo_pdf/component'
require_relative 'bujo_pdf/layout'

# Load sub-components (used by components)
require_relative 'bujo_pdf/sub_components/base'
require_relative 'bujo_pdf/sub_components/fieldset'
require_relative 'bujo_pdf/sub_components/week_column'
require_relative 'bujo_pdf/sub_components/day_header'

# Load components
require_relative 'bujo_pdf/components/top_navigation'
require_relative 'bujo_pdf/components/week_sidebar'
require_relative 'bujo_pdf/components/right_sidebar'
require_relative 'bujo_pdf/components/daily_section'
require_relative 'bujo_pdf/components/cornell_notes'
require_relative 'bujo_pdf/components/week_grid'
require_relative 'bujo_pdf/components/grid_ruler'
require_relative 'bujo_pdf/components/grid_dots'
require_relative 'bujo_pdf/components/ruled_lines'
require_relative 'bujo_pdf/components/erase_dots'
require_relative 'bujo_pdf/components/box'
require_relative 'bujo_pdf/components/hline'
require_relative 'bujo_pdf/components/vline'
require_relative 'bujo_pdf/components/text'
require_relative 'bujo_pdf/components/h1'
require_relative 'bujo_pdf/components/h2'
require_relative 'bujo_pdf/components/mini_month'
require_relative 'bujo_pdf/components/ruled_list'
require_relative 'bujo_pdf/components/layout_helpers'
require_relative 'bujo_pdf/components/all'

# Load layouts
require_relative 'bujo_pdf/layouts/base_layout'
require_relative 'bujo_pdf/layouts/full_page_layout'
require_relative 'bujo_pdf/layouts/standard_with_sidebars_layout'
require_relative 'bujo_pdf/layouts/layout_factory'

# Load page base classes
require_relative 'bujo_pdf/pages/base'
require_relative 'bujo_pdf/pages/standard_layout_page'
require_relative 'bujo_pdf/pages/mixin_support'  # Shared helpers for page mixins

# Load page factory
require_relative 'bujo_pdf/page_factory'

# Load concrete page classes
require_relative 'bujo_pdf/pages/seasonal_calendar'
require_relative 'bujo_pdf/pages/year_at_glance_base'
require_relative 'bujo_pdf/pages/year_at_glance_events'
require_relative 'bujo_pdf/pages/year_at_glance_highlights'
require_relative 'bujo_pdf/pages/multi_year_overview'
require_relative 'bujo_pdf/pages/weekly_page'
require_relative 'bujo_pdf/pages/index_pages'
require_relative 'bujo_pdf/pages/future_log'
require_relative 'bujo_pdf/pages/monthly_review'
require_relative 'bujo_pdf/pages/quarterly_planning'
require_relative 'bujo_pdf/pages/collection_page'
require_relative 'bujo_pdf/pages/reference_calibration'
require_relative 'bujo_pdf/pages/tracker_example'
require_relative 'bujo_pdf/pages/daily_wheel'
require_relative 'bujo_pdf/pages/year_wheel'
require_relative 'bujo_pdf/pages/grid_showcase'
require_relative 'bujo_pdf/pages/grids_overview'

# Load grid page classes
require_relative 'bujo_pdf/pages/grids/dot_grid_page'
require_relative 'bujo_pdf/pages/grids/graph_grid_page'
require_relative 'bujo_pdf/pages/grids/lined_grid_page'
require_relative 'bujo_pdf/pages/grids/isometric_grid_page'
require_relative 'bujo_pdf/pages/grids/perspective_grid_page'
require_relative 'bujo_pdf/pages/grids/hexagon_grid_page'

# Load page verb aggregator (after all page classes)
require_relative 'bujo_pdf/pages/all'

# Load PDF DSL (depends on everything above)
require_relative 'bujo_pdf/pdf_dsl'

# Module for namespace
module BujoPdf
  class Error < StandardError; end

  # Convenience method for generating planners
  #
  # @param year [Integer] The year to generate the planner for (default: current year)
  # @param output_path [String, nil] The output file path (default: planner_YEAR.pdf)
  # @param theme [Symbol, String, nil] The theme to use (default: :light)
  # @return [String] The path to the generated PDF file
  #
  # @example Generate planner for current year
  #   BujoPdf.generate
  #
  # @example Generate planner for specific year
  #   BujoPdf.generate(2025)
  #
  # @example Generate with custom output path
  #   BujoPdf.generate(2025, output_path: 'my_planner.pdf')
  #
  # @example Generate with a specific theme
  #   BujoPdf.generate(2025, theme: :earth)
  #
  def self.generate(year = Date.today.year, output_path: nil, theme: nil)
    output_path ||= "planner_#{year}.pdf"
    PdfDSL.load_recipes!
    generate_from_recipe(:standard_planner, year: year, theme: theme, output: output_path)
  end

end
