#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
load File.expand_path('../../bin/bujo-pdf', __dir__)

class TestCliDebug < Minitest::Test
  def test_no_flag_leaves_debug_off
    assert_nil generate_kwargs(%w[2026])[:debug]
  end

  def test_bare_flag_enables_every_kind
    assert_equal true, generate_kwargs(%w[2026 --debug])[:debug]
  end

  def test_flag_with_kinds
    assert_equal 'grid,link', generate_kwargs(%w[--debug=grid,link 2026])[:debug]
  end

  def test_unknown_kind_exits_before_generating
    BujoPdf::CLI.stub(:build, ->(*, **) { flunk 'generated' }) do
      _out, err = capture_io do
        assert_raises(SystemExit) { BujoPdf::CLI.run(%w[2026 --debug=sparkles]) }
      end
      assert_match(/sparkles/, err)
    end
  end

  private

  def generate_kwargs(args)
    received = nil
    BujoPdf::CLI.stub(:build, ->(_definition, **kwargs) { received = kwargs }) do
      _out, err = capture_io do
        BujoPdf::CLI.run(args)
      rescue SystemExit
        received = :exited
      end
      flunk "CLI exited: #{err}" if received == :exited
    end
    received
  end
end
