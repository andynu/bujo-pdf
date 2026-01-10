# frozen_string_literal: true

module BujoPdf
  module PdfDSL
    # ChromeBuilder captures sidebar configuration during PDF definition evaluation.
    #
    # Chrome refers to the visual frame around page content: sidebars, tabs, and
    # navigation elements. This builder provides a DSL for declaring which sidebars
    # appear on each edge of the page.
    #
    # Sidebars can be specified by name (referencing registered sidebar types) or
    # with additional configuration. The right sidebar supports an inline tabs block
    # for defining navigation tabs.
    #
    # @example Basic chrome configuration
    #   chrome do
    #     left :week_sidebar
    #     right :right_sidebar
    #   end
    #
    # @example Right sidebar with tabs block
    #   chrome do
    #     left :week_sidebar
    #     right :right_sidebar do
    #       tab "Index", dest: :index
    #       tab "Future", dest: :future_log_1
    #     end
    #   end
    #
    # @example Tabs with cycling destinations
    #   chrome do
    #     right :tab_sidebar do
    #       tab "Year", dest: :seasonal
    #       tab "Weeks", dest: [:week_1, :week_2, :week_3]  # Cycles through weeks
    #       tab "Notes", dest: :notes
    #     end
    #   end
    #
    # @example All four edges
    #   chrome do
    #     top :header_bar, title: "My Planner"
    #     bottom :footer_bar
    #     left :week_sidebar
    #     right :nav_tabs
    #   end
    #
    class ChromeBuilder
      # Configuration for a single sidebar edge.
      #
      # @attr_reader sidebar_name [Symbol] The registered sidebar type name
      # @attr_reader options [Hash] Additional options passed to the sidebar
      # @attr_reader tabs [Array<TabConfig>, nil] Tab definitions (for right sidebar)
      SidebarConfig = Struct.new(:sidebar_name, :options, :tabs, keyword_init: true) do
        # Check if this sidebar has inline tab configuration.
        #
        # @return [Boolean] True if tabs are configured
        def tabs?
          tabs && !tabs.empty?
        end
      end

      # Configuration for a single navigation tab.
      #
      # @attr_reader label [String] The tab label text
      # @attr_reader dest [Symbol, Array<Symbol>] Single destination or array of cycling destinations
      # @attr_reader options [Hash] Additional options (icon, style, etc.)
      TabConfig = Struct.new(:label, :dest, :options, keyword_init: true) do
        # Check if this tab has cycling destinations.
        #
        # Cycling destinations enable a tap-to-advance navigation pattern where
        # each tap moves to the next destination in the array.
        #
        # @return [Boolean] True if dest is an array of destinations
        def cycling?
          dest.is_a?(Array)
        end
      end

      attr_reader :left_config, :right_config, :top_config, :bottom_config

      # Initialize a new chrome builder.
      def initialize
        @left_config = nil
        @right_config = nil
        @top_config = nil
        @bottom_config = nil
      end

      # Configure the left sidebar.
      #
      # @param sidebar_name [Symbol] The registered sidebar type name
      # @param options [Hash] Additional options passed to the sidebar
      # @return [SidebarConfig] The created configuration
      #
      # @example
      #   left :week_sidebar
      #   left :week_sidebar, current_week: 27
      def left(sidebar_name, **options)
        @left_config = SidebarConfig.new(
          sidebar_name: sidebar_name,
          options: options,
          tabs: nil
        )
      end

      # Configure the right sidebar.
      #
      # Supports an optional block for inline tab configuration.
      #
      # @param sidebar_name [Symbol] The registered sidebar type name
      # @param options [Hash] Additional options passed to the sidebar
      # @yield Optional block for tab configuration
      # @return [SidebarConfig] The created configuration
      #
      # @example Simple right sidebar
      #   right :nav_tabs
      #
      # @example Right sidebar with inline tabs
      #   right :right_sidebar do
      #     tab "Index", dest: :index
      #     tab "Future", dest: :future_log_1
      #   end
      def right(sidebar_name, **options, &block)
        tabs = nil
        if block_given?
          tabs_builder = TabsBuilder.new
          tabs_builder.instance_eval(&block)
          tabs = tabs_builder.tabs
        end

        @right_config = SidebarConfig.new(
          sidebar_name: sidebar_name,
          options: options,
          tabs: tabs
        )
      end

      # Configure the top sidebar/header.
      #
      # @param sidebar_name [Symbol] The registered sidebar type name
      # @param options [Hash] Additional options passed to the sidebar
      # @return [SidebarConfig] The created configuration
      #
      # @example
      #   top :header_bar
      #   top :header_bar, title: "2025 Planner"
      def top(sidebar_name, **options)
        @top_config = SidebarConfig.new(
          sidebar_name: sidebar_name,
          options: options,
          tabs: nil
        )
      end

      # Configure the bottom sidebar/footer.
      #
      # @param sidebar_name [Symbol] The registered sidebar type name
      # @param options [Hash] Additional options passed to the sidebar
      # @return [SidebarConfig] The created configuration
      #
      # @example
      #   bottom :footer_bar
      #   bottom :footer_bar, show_page_number: true
      def bottom(sidebar_name, **options)
        @bottom_config = SidebarConfig.new(
          sidebar_name: sidebar_name,
          options: options,
          tabs: nil
        )
      end

      # Check if any chrome is configured.
      #
      # @return [Boolean] True if at least one sidebar is configured
      def any?
        [@left_config, @right_config, @top_config, @bottom_config].any?
      end

      # Check if chrome is empty (no sidebars configured).
      #
      # @return [Boolean] True if no sidebars are configured
      def empty?
        !any?
      end

      # Convert to a hash representation.
      #
      # Useful for debugging and serialization.
      #
      # @return [Hash] Hash with :left, :right, :top, :bottom keys
      def to_h
        {
          left: @left_config,
          right: @right_config,
          top: @top_config,
          bottom: @bottom_config
        }.compact
      end

      # Internal builder for tab configuration inside right sidebar block.
      #
      # @api private
      class TabsBuilder
        attr_reader :tabs

        def initialize
          @tabs = []
        end

        # Add a tab to the configuration.
        #
        # @param label [String] The tab label text
        # @param dest [Symbol, Array<Symbol>] Single destination page ID or array of cycling destinations
        # @param options [Hash] Additional options
        # @return [TabConfig] The created tab configuration
        #
        # @example Single destination
        #   tab "Index", dest: :index
        #   tab "Future", dest: :future_log, icon: :calendar
        #
        # @example Cycling destinations (tap to advance through pages)
        #   tab "Weeks", dest: [:week_1, :week_2, :week_3]  # Cycles through weeks
        #   tab "Grids", dest: [:grids_overview, :grid_dot, :grid_graph]
        def tab(label, dest:, **options)
          @tabs << TabConfig.new(
            label: label,
            dest: dest,
            options: options
          )
        end
      end
    end
  end
end
