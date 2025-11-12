# frozen_string_literal: true

require_relative 'lib/bujo_pdf/version'

Gem::Specification.new do |spec|
  spec.name          = 'bujo-pdf'
  spec.version       = BujoPdf::VERSION
  spec.authors       = ['Andy Nutter-Upham']
  spec.email         = ['andynu@gmail.com']

  spec.summary       = 'Generate programmable bullet journal PDFs'
  spec.description   = 'A Ruby-based PDF planner generator that creates programmable bullet journal PDFs optimized for digital note-taking apps (Noteshelf, GoodNotes). Includes seasonal calendar, year-at-a-glance pages, weekly pages with Cornell notes, and PDF hyperlink navigation.'
  spec.homepage      = 'https://github.com/andynu/bujo-pdf'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir['lib/**/*.rb', 'bin/*', 'README.md', 'LICENSE', 'CHANGELOG.md']
  spec.bindir = 'bin'
  spec.executables = ['bujo-pdf']
  spec.require_paths = ['lib']

  spec.add_dependency 'prawn', '~> 2.4'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
