# frozen_string_literal: true

require_relative '../../test_helper'

module BujoPdf
  module Pages
    class MixinSupportTest < Minitest::Test
      # Test class that includes MixinSupport
      class TestIncluder
        include MixinSupport

        attr_accessor :pdf, :year, :date_config, :event_store, :total_pages
        attr_accessor :defining, :pages, :current_builder_page_set
        attr_accessor :first_page_used, :current_page_set, :current_page_set_index

        def initialize
          @pdf = Prawn::Document.new(page_size: 'LETTER', margin: 0)
          DotGrid.create_stamp(@pdf, "page_dots")
          @year = 2025
          @date_config = nil
          @event_store = nil
          @total_pages = 100
          @defining = false
          @pages = []
          @current_builder_page_set = nil
          @first_page_used = false
          @current_page_set = nil
          @current_page_set_index = nil
        end
      end

      def setup
        @includer = TestIncluder.new
      end

      # ============================================
      # start_new_page Tests
      # ============================================

      def test_start_new_page_first_call_does_not_add_page
        assert_equal 1, @includer.pdf.page_count

        @includer.send(:start_new_page)

        assert_equal 1, @includer.pdf.page_count
        assert @includer.first_page_used
      end

      def test_start_new_page_second_call_adds_page
        @includer.send(:start_new_page)  # First call
        @includer.send(:start_new_page)  # Second call

        assert_equal 2, @includer.pdf.page_count
      end

      def test_start_new_page_multiple_calls
        5.times { @includer.send(:start_new_page) }

        assert_equal 5, @includer.pdf.page_count  # First uses initial page, then adds 4
      end

      # ============================================
      # build_context Tests
      # ============================================

      def test_build_context_returns_render_context
        context = @includer.send(:build_context, page_key: :test_page)

        assert_kind_of RenderContext, context
      end

      def test_build_context_includes_page_key
        context = @includer.send(:build_context, page_key: :my_page)

        assert_equal :my_page, context.page_key
      end

      def test_build_context_includes_year
        @includer.year = 2026
        context = @includer.send(:build_context, page_key: :test)

        assert_equal 2026, context.year
      end

      def test_build_context_includes_page_number
        @includer.send(:start_new_page)
        context = @includer.send(:build_context, page_key: :test)

        assert_equal 1, context.page_number
      end

      def test_build_context_includes_total_weeks
        context = @includer.send(:build_context, page_key: :test)

        # Should calculate total weeks for 2025
        assert context.total_weeks.is_a?(Integer)
        assert context.total_weeks >= 52
        assert context.total_weeks <= 54
      end

      def test_build_context_includes_total_pages
        @includer.total_pages = 150
        context = @includer.send(:build_context, page_key: :test)

        assert_equal 150, context.total_pages
      end

      def test_build_context_includes_date_config
        @includer.date_config = 'config_placeholder'
        context = @includer.send(:build_context, page_key: :test)

        assert_equal 'config_placeholder', context.date_config
      end

      def test_build_context_includes_event_store
        @includer.event_store = 'event_store_placeholder'
        context = @includer.send(:build_context, page_key: :test)

        assert_equal 'event_store_placeholder', context.event_store
      end

      def test_build_context_includes_extra_params
        context = @includer.send(:build_context, page_key: :test, week_num: 5, custom: 'value')

        assert_equal 5, context.week_num
        assert_equal 'value', context[:custom]  # Extra params accessed via []
      end

      def test_build_context_attaches_page_set_context
        page_set = PageSetContext.new(count: 3, label: "Page %page of %total")
        @includer.current_page_set = page_set
        @includer.current_page_set_index = 1

        context = @includer.send(:build_context, page_key: :test)

        assert context.set
        assert_equal 2, context.set.page  # 1-based
        assert_equal 3, context.set.total
        assert_equal "Page 2 of 3", context.set.label
      end

      def test_build_context_without_page_set_context
        context = @includer.send(:build_context, page_key: :test)

        # set defaults to NullContext when not in a page_set block
        assert_kind_of PageSetContext::NullContext, context.set
        refute context.set?
      end

      # ============================================
      # total_weeks Tests
      # ============================================

      def test_total_weeks_calculates_for_year
        @includer.year = 2025
        total = @includer.send(:total_weeks)

        assert total.is_a?(Integer)
        assert total >= 52
      end

      def test_total_weeks_caches_result
        @includer.year = 2025
        first_call = @includer.send(:total_weeks)
        second_call = @includer.send(:total_weeks)

        assert_equal first_call, second_call
        # Verify it's the same object (cached)
        assert_same first_call, second_call
      end

      # ============================================
      # define_page Tests (Render Phase)
      # ============================================

      def test_define_page_render_phase_starts_new_page
        @includer.defining = false

        @includer.send(:define_page, dest: 'test', title: 'Test', type: :test) do |ctx|
          # Block called immediately
        end

        assert @includer.first_page_used
      end

      def test_define_page_render_phase_calls_block
        @includer.defining = false
        block_called = false
        ctx_received = nil

        @includer.send(:define_page, dest: 'test', title: 'Test', type: :test) do |ctx|
          block_called = true
          ctx_received = ctx
        end

        assert block_called
        assert_kind_of RenderContext, ctx_received
      end

      def test_define_page_render_phase_returns_nil
        @includer.defining = false

        result = @includer.send(:define_page, dest: 'test', title: 'Test', type: :test) {}

        assert_nil result
      end

      def test_define_page_render_phase_uses_dest_as_page_key
        @includer.defining = false
        ctx_received = nil

        @includer.send(:define_page, dest: 'my_dest', title: 'Test', type: :test) do |ctx|
          ctx_received = ctx
        end

        assert_equal :my_dest, ctx_received.page_key
      end

      def test_define_page_render_phase_with_explicit_page_key
        @includer.defining = false
        ctx_received = nil

        @includer.send(:define_page, dest: 'my_dest', title: 'Test', type: :test, page_key: :custom_key) do |ctx|
          ctx_received = ctx
        end

        assert_equal :custom_key, ctx_received.page_key
      end

      def test_define_page_render_phase_passes_metadata_to_context
        @includer.defining = false
        ctx_received = nil

        @includer.send(:define_page, dest: 'test', title: 'Test', type: :test, week_num: 5) do |ctx|
          ctx_received = ctx
        end

        assert_equal 5, ctx_received.week_num
      end

      # ============================================
      # define_page Tests (Define Phase)
      # ============================================

      def test_define_page_define_phase_returns_page_ref
        @includer.defining = true

        result = @includer.send(:define_page, dest: 'test', title: 'Test Page', type: :test) {}

        assert_kind_of PageRef, result
      end

      def test_define_page_define_phase_creates_page_ref_with_metadata
        @includer.defining = true

        result = @includer.send(:define_page, dest: 'my_dest', title: 'My Title', type: :my_type) {}

        assert_equal 'my_dest', result.dest_name
        assert_equal 'My Title', result.title
        assert_equal :my_type, result.page_type
      end

      def test_define_page_define_phase_adds_to_pages_array
        @includer.defining = true

        @includer.send(:define_page, dest: 'test', title: 'Test', type: :test) {}

        assert_equal 1, @includer.pages.size
        assert_kind_of PageRef, @includer.pages.first
      end

      def test_define_page_define_phase_does_not_call_block
        @includer.defining = true
        block_called = false

        @includer.send(:define_page, dest: 'test', title: 'Test', type: :test) do |ctx|
          block_called = true
        end

        refute block_called
      end

      def test_define_page_define_phase_stores_render_block
        @includer.defining = true

        result = @includer.send(:define_page, dest: 'test', title: 'Test', type: :test) { |ctx| }

        assert result.render_block
      end

      def test_define_page_define_phase_render_block_execution
        @includer.defining = true
        block_called = false

        result = @includer.send(:define_page, dest: 'test', title: 'Test', type: :test) do |ctx|
          block_called = true
        end

        # Now execute the stored render block
        @includer.defining = false
        result.render

        assert block_called
        assert @includer.first_page_used
      end

      def test_define_page_define_phase_adds_to_page_set_if_active
        @includer.defining = true
        mock_page_set = Minitest::Mock.new
        mock_page_set.expect :add, nil, [PageRef]
        @includer.current_builder_page_set = mock_page_set

        @includer.send(:define_page, dest: 'test', title: 'Test', type: :test) {}

        mock_page_set.verify
      end

      # ============================================
      # page_set Tests
      # ============================================

      def test_page_set_without_block_returns_page_set_context
        result = @includer.send(:page_set, 3, "Index %page of %total")

        assert_kind_of PageSetContext, result
        assert_equal 3, result.count
      end

      def test_page_set_with_block_iterates_over_count
        iterations = []

        @includer.send(:page_set, 3, "Test %page") do |set|
          iterations << @includer.current_page_set_index
        end

        assert_equal [0, 1, 2], iterations
      end

      def test_page_set_sets_current_page_set_during_iteration
        captured_sets = []

        @includer.send(:page_set, 2, "Test") do |set|
          captured_sets << @includer.current_page_set
        end

        assert_equal 2, captured_sets.size
        captured_sets.each { |s| assert_kind_of PageSetContext, s }
      end

      def test_page_set_clears_context_after_block
        @includer.send(:page_set, 2, "Test") { |set| }

        assert_nil @includer.current_page_set
        assert_nil @includer.current_page_set_index
      end

      def test_page_set_clears_context_on_exception
        begin
          @includer.send(:page_set, 2, "Test") do |set|
            raise "test error"
          end
        rescue RuntimeError
          # Expected
        end

        assert_nil @includer.current_page_set
        assert_nil @includer.current_page_set_index
      end

      def test_page_set_with_name_parameter
        result = @includer.send(:page_set, 2, name: "Custom Name")

        assert_equal "Custom Name", result.name
      end

      def test_page_set_extracts_name_from_label
        result = @includer.send(:page_set, 2, "Index %page of %total")

        assert_equal "Index", result.name
      end
    end
  end
end
