# frozen_string_literal: true

module BujoPdf
  module Components
    # Aggregates all component mixins for inclusion in pages.
    #
    # Each component defines a Mixin module with its verb method(s).
    # This module includes all of them, providing a single include
    # point for Pages::Base.
    #
    # Example:
    #   class MyPage < Pages::Base
    #     # Pages::Base includes Components::All, so verbs are available:
    #     def render
    #       ruled_lines(2, 5, 20, 10)
    #       grid_dots(2, 5, 20, 10)
    #     end
    #   end
    #
    # Adding a new component:
    #   1. Create the component class with a Mixin module
    #   2. Require it in this file
    #   3. Include the Mixin here
    #
    module All
      def self.included(base)
        # Include each component's mixin
        base.include GridDots::Mixin
        base.include RuledLines::Mixin
        base.include EraseDots::Mixin
        base.include Box::Mixin
        base.include HLine::Mixin
        base.include VLine::Mixin
        base.include Text::Mixin
        base.include H1::Mixin
        base.include H2::Mixin
        base.include MiniMonth::Mixin
        base.include RuledList::Mixin
        base.include List::Mixin
        base.include Fieldset::Mixin
        base.include LayoutHelpers::Mixin
        base.include LinkBox::Mixin
      end
    end
  end
end
