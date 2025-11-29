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
require_relative 'bujo_pdf/render_context'
require_relative 'bujo_pdf/component_context'

# Load base classes
require_relative 'bujo_pdf/component'
require_relative 'bujo_pdf/layout'

# Load sub-components (used by components)
require_relative 'bujo_pdf/sub_components/base'
require_relative 'bujo_pdf/sub_components/fieldset'
require_relative 'bujo_pdf/sub_components/week_column'
require_relative 'bujo_pdf/sub_components/ruled_lines'
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

# Load layouts
require_relative 'bujo_pdf/layouts/base_layout'
require_relative 'bujo_pdf/layouts/full_page_layout'
require_relative 'bujo_pdf/layouts/standard_with_sidebars_layout'
require_relative 'bujo_pdf/layouts/layout_factory'

# Load page base classes
require_relative 'bujo_pdf/pages/base'
require_relative 'bujo_pdf/pages/standard_layout_page'

# Load page factory
require_relative 'bujo_pdf/page_factory'

# Load concrete page classes
require_relative 'bujo_pdf/pages/seasonal_calendar'
require_relative 'bujo_pdf/pages/year_at_glance_base'
require_relative 'bujo_pdf/pages/year_at_glance_events'
require_relative 'bujo_pdf/pages/year_at_glance_highlights'
require_relative 'bujo_pdf/pages/weekly_page'
require_relative 'bujo_pdf/pages/reference_calibration'

# Load main generator (depends on everything above)
require_relative 'bujo_pdf/planner_generator'

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
    # Set theme if provided
    Themes.set(theme) if theme

    output_path ||= "planner_#{year}.pdf"
    generator = PlannerGenerator.new(year)
    generator.generate(output_path)
    output_path
  ensure
    # Reset theme after generation to avoid side effects
    Themes.reset! if theme
  end
end
