# frozen_string_literal: true

module BujoPdf
  module Pages
    # Mixin for registering page types with their metadata.
    #
    # Page classes call `register_page` to declare their type, default
    # title, and default destination pattern. These can use %{param}
    # interpolation for dynamic values.
    #
    # Interpolation tokens:
    # - %{param_name} - Replaced with params[:param_name]
    # - %{_n} - Replaced with sequence number (auto-incremented per type)
    #
    # @example Simple page (no params)
    #   class SeasonalCalendar < Base
    #     register_page :seasonal,
    #       title: "Seasonal Calendar",
    #       dest: "seasonal"
    #   end
    #
    # @example Page with interpolation
    #   class WeeklyPage < Base
    #     register_page :weekly,
    #       title: "Week %{week_num}",
    #       dest: "week_%{week_num}"
    #   end
    #
    # @example Sequential pages (auto-increment)
    #   class IndexPage < Base
    #     register_page :index,
    #       title: "Index",
    #       dest: "index_%{_n}"
    #   end
    #
    # @example With Proc for complex logic
    #   class MonthlyReview < Base
    #     register_page :monthly_review,
    #       title: ->(p) { Date::MONTHNAMES[p[:month]] },
    #       dest: "review_%{month}"
    #   end
    #
    # @example Minimal registration (uses fallbacks)
    #   class ScratchPage < Base
    #     register_page :scratch
    #   end
    #
    module PageRegistry
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :page_type, :default_title, :default_dest

        # Register this page class with its type and defaults.
        #
        # @param type [Symbol] Page type identifier
        # @param title [String, Proc, nil] Default title (supports %{param} interpolation)
        # @param dest [String, Proc, nil] Default destination (supports %{param} interpolation)
        def register_page(type, title: nil, dest: nil)
          @page_type = type
          @default_title = title
          @default_dest = dest

          # Auto-register with PageFactory
          PageFactory.register(type, self)
        end

        # Generate title for given params.
        #
        # @param params [Hash] Page parameters
        # @return [String, nil] Interpolated title, or nil if no default
        def generate_title(params)
          return nil unless @default_title

          interpolate(@default_title, params)
        end

        # Generate destination for given params.
        #
        # @param params [Hash] Page parameters
        # @param sequence [Integer, nil] Sequence number for %{_n} interpolation
        # @return [String, nil] Interpolated destination, or nil if no default
        def generate_dest(params, sequence: nil)
          return nil unless @default_dest

          interpolate(@default_dest, params.merge(_n: sequence))
        end

        private

        def interpolate(template, params)
          case template
          when Proc
            template.call(params)
          when String
            # Replace %{key} tokens with param values
            template.gsub(/%\{(\w+)\}/) do
              key = ::Regexp.last_match(1).to_sym
              value = params[key]
              if value.nil?
                raise KeyError, "Missing param #{key} for #{@page_type} page"
              end

              value.to_s
            end
          else
            template.to_s
          end
        end
      end
    end
  end
end
