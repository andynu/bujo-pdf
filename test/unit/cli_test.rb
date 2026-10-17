#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
load File.expand_path('../../bin/bujo-pdf', __dir__)

class TestCli < Minitest::Test
  OUTPUT = 'tmp/test_cli_output.pdf'

  def setup
    FileUtils.mkdir_p('tmp')
    FileUtils.rm_f(OUTPUT)
  end

  def teardown
    FileUtils.rm_f(OUTPUT)
  end

  def test_build_prints_warnings_to_stderr_and_writes_pdf
    assert_output('', %(Warning: outline entry "Ghost" points at "ghost", which no page declares\n)) do
      BujoPdf::CLI.build(dead_outline_recipe, output: OUTPUT, strict: false, year: 2026)
    end

    assert File.exist?(OUTPUT)
  end

  def test_strict_build_raises_and_writes_nothing
    error = assert_raises(BujoPdf::PdfDSL::WarningsError) do
      BujoPdf::CLI.build(dead_outline_recipe, output: OUTPUT, strict: true, year: 2026)
    end

    assert_includes error.message, '"ghost"'
    refute File.exist?(OUTPUT)
  end

  def test_help_lists_strict
    out, = capture_io do
      assert_raises(SystemExit) { BujoPdf::CLI.run(['--help']) }
    end

    assert_includes out, '--strict'
  end

  def test_invalid_year_exits_with_error
    _, err = capture_io do
      error = assert_raises(SystemExit) { BujoPdf::CLI.run(['--strict', '1800']) }
      assert_equal 1, error.status
    end

    assert_includes err, "Invalid year '1800'"
  end

  private

  def dead_outline_recipe
    BujoPdf::PdfDSL::PdfDefinition.new(:cli_test) do |year:|
      page(id: :home) { body {} }
      outline_entry :ghost, 'Ghost'
    end
  end
end
