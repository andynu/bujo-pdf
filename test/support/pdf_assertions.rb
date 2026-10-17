# frozen_string_literal: true

require_relative 'pdf_inspector'

# Minitest assertions over a rendered PDF. The subject is a PdfInspector, or
# anything PdfInspector reads (a Prawn::Document, bytes, a path). Build the
# inspector once when making several assertions, so the PDF is parsed once.
#
# A page is a number, or a named destination standing for its page:
#
#   assert_link pdf, from_page: :week_10, to: :week_9
module PdfAssertions
  def assert_page_count(subject, count, msg = nil)
    actual = pdf_inspector(subject).page_count
    assert actual == count, message(msg) { "Expected #{count} pages, got #{actual} pages" }
  end

  def assert_destination(subject, name, msg = nil, page:)
    actual = pdf_inspector(subject).destinations[name.to_s]
    found = actual ? "it points at page #{actual}" : 'it is not declared'
    assert actual == page, message(msg) { "Expected destination #{name} on page #{page}, but #{found}" }
  end

  # `to:` is a destination name, matched against the name the link carries,
  # or a page number, matched against the page the link lands on.
  def assert_link(subject, msg = nil, from_page:, to:)
    inspector = pdf_inspector(subject)
    links = inspector.links(from_page)
    assert links.any? { |link| link_to?(link, to) }, message(msg) {
      "Expected a link on page #{inspector.page_number(from_page)} to #{link_target(to)}, " \
        "found links to #{describe_links(links)}"
    }
  end

  def refute_link(subject, msg = nil, from_page:, to:)
    inspector = pdf_inspector(subject)
    refute inspector.links(from_page).any? { |link| link_to?(link, to) }, message(msg) {
      "Expected no link on page #{inspector.page_number(from_page)} to #{link_target(to)}"
    }
  end

  # Every link that names a destination lands on a page.
  def assert_links_resolve(subject, msg = nil)
    broken = pdf_inspector(subject).links.select { |link| link.dest && link.page.nil? }
    assert broken.empty?, message(msg) {
      'Links to undeclared destinations: ' +
        broken.map { |link| "page #{link.from_page} -> #{link.dest}" }.join(', ')
    }
  end

  # `expected` lists the outline's titles in order; an entry with children
  # is written `{ 'Title' => [children] }`. `depth: 1` compares the top level
  # only.
  def assert_outline(subject, expected, msg = nil, depth: nil)
    assert_equal expected, outline_shape(pdf_inspector(subject).outline, depth), msg
  end

  def assert_pdf_text_on_page(subject, page, expected, msg = nil)
    inspector = pdf_inspector(subject)
    text = inspector.text(page)
    found = expected.is_a?(Regexp) ? expected.match?(text) : text.include?(expected)
    assert found, message(msg) {
      "Expected #{expected.inspect} on page #{inspector.page_number(page)}, got:\n#{text}"
    }
  end

  private

  def pdf_inspector(subject)
    subject.is_a?(PdfInspector) ? subject : PdfInspector.new(subject)
  end

  def link_to?(link, target)
    target.is_a?(Integer) ? link.page == target : link.dest == target.to_s
  end

  def link_target(target) = target.is_a?(Integer) ? "page #{target}" : target.to_s

  def describe_links(links)
    return 'nothing' if links.empty?

    links.map { |link| link.dest || link.uri || "page #{link.page}" }.join(', ')
  end

  def outline_shape(items, depth)
    items.map do |item|
      next item.title if item.children.empty? || depth == 1

      { item.title => outline_shape(item.children, (depth - 1 if depth)) }
    end
  end
end
