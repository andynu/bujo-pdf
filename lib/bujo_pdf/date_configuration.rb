# frozen_string_literal: true

require 'yaml'
require 'date'

module BujoPdf
  # DateConfiguration manages highlighted dates from a YAML configuration file
  # and provides lookup methods for date-specific styling and labels.
  class DateConfiguration
    attr_reader :dates, :categories, :priorities

    # HighlightedDate represents a single date with highlighting information
    class HighlightedDate
      attr_reader :date, :label, :category, :priority, :color, :text_color

      def initialize(date:, label:, category: 'other', priority: 'normal', color: nil, text_color: nil)
        @date = Date.parse(date.to_s)
        @label = label
        @category = category
        @priority = priority
        @color = color
        @text_color = text_color
      end

      # Calculate which week this date falls in (1-indexed)
      # @param year_start_monday [Date] The Monday of week 1
      # @return [Integer] The week number (1-53)
      def week_number(year_start_monday)
        days_from_start = (@date - year_start_monday).to_i
        (days_from_start / 7) + 1
      end

      # Get the day of week as a string
      # @return [String] Day name (e.g., "Monday", "Tuesday")
      def day_of_week
        @date.strftime('%A')
      end
    end

    # Initialize the DateConfiguration with optional config path
    # @param config_path [String] Path to YAML configuration file
    # @param year [Integer] Optional year for validation
    def initialize(config_path = 'config/dates.yml', year: nil)
      @config_path = config_path
      @year = year
      @dates = []
      @categories = default_categories
      @priorities = default_priorities
      load_config if File.exist?(@config_path)
    end

    # Load configuration from YAML file
    def load_config
      return unless File.exist?(@config_path)

      begin
        config = YAML.safe_load_file(@config_path, permitted_classes: [Date])

        # Validate structure
        unless config.is_a?(Hash)
          warn "Invalid config format in #{@config_path}"
          return
        end

        # Validate year if specified in both config and initialization
        if @year && config['year'] && config['year'] != @year
          warn "Config year (#{config['year']}) doesn't match generator year (#{@year})"
        end

        # Load category definitions
        @categories.merge!(config['categories']) if config['categories']
        @priorities.merge!(config['priorities']) if config['priorities']

        # Parse dates
        return unless config['dates']

        config['dates'].each do |date_config|
          @dates << HighlightedDate.new(**date_config.transform_keys(&:to_sym))
        rescue ArgumentError => e
          warn "Skipping invalid date: #{date_config.inspect} - #{e.message}"
        end

      rescue Psych::SyntaxError => e
        warn "YAML syntax error in #{@config_path}: #{e.message}"
      rescue StandardError => e
        warn "Error loading date configuration: #{e.message}"
      end
    end

    # Get all dates for a specific month
    # @param month [Integer] Month number (1-12)
    # @return [Array<HighlightedDate>] Dates in that month
    def dates_for_month(month)
      @dates.select { |d| d.date.month == month }
    end

    # Get all dates for a specific week
    # @param week_num [Integer] Week number (1-53)
    # @param year_start_monday [Date] The Monday of week 1
    # @return [Array<HighlightedDate>] Dates in that week
    def dates_for_week(week_num, year_start_monday)
      @dates.select { |d| d.week_number(year_start_monday) == week_num }
    end

    # Get the highlighted date for a specific day
    # @param date [Date] The date to look up
    # @return [HighlightedDate, nil] The highlighted date if found
    def date_for_day(date)
      @dates.find { |d| d.date == date }
    end

    # Get the style definition for a category
    # @param category_name [String] Category name
    # @return [Hash] Style hash with color, text_color, and icon
    def category_style(category_name)
      @categories[category_name] || @categories['other']
    end

    # Get the style definition for a priority level
    # @param priority_name [String] Priority name
    # @return [Hash] Style hash with border_width and bold
    def priority_style(priority_name)
      @priorities[priority_name] || @priorities['normal']
    end

    # Check if any dates are configured
    # @return [Boolean] True if configuration has dates
    def any?
      !@dates.empty?
    end

    private

    # Default category styles
    # @return [Hash] Default category definitions
    def default_categories
      {
        'holiday' => {
          'color' => 'FFE5E5',
          'text_color' => 'CC0000',
          'icon' => '*'
        },
        'personal' => {
          'color' => 'E5F0FF',
          'text_color' => '0066CC',
          'icon' => '+'
        },
        'work' => {
          'color' => 'FFF5E5',
          'text_color' => 'CC7700',
          'icon' => '#'
        },
        'other' => {
          'color' => 'F0F0F0',
          'text_color' => '666666',
          'icon' => 'o'
        }
      }
    end

    # Default priority styles
    # @return [Hash] Default priority definitions
    def default_priorities
      {
        'high' => { 'border_width' => 1.5, 'bold' => true },
        'normal' => { 'border_width' => 0.5, 'bold' => false }
      }
    end
  end
end
