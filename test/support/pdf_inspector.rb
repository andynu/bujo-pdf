# frozen_string_literal: true

require 'pathname'
require 'stringio'
require 'pdf/reader'

# Reads a rendered PDF back so tests can check navigation through the file
# itself rather than through the code that drew it. The subject is a
# Prawn::Document, PDF bytes, or a path (String or Pathname).
#
# Pages are numbered from 1, as a PDF viewer shows them.
class PdfInspector
  UTF16_BOM = "\xFE\xFF".b.freeze

  # A link annotation. `dest` is the named destination it points at (nil for
  # an explicit page reference or a URI); `page` is the page it lands on, nil
  # when the name is not declared or the link leaves the document.
  Link = Struct.new(:from_page, :rect, :dest, :page, :uri, keyword_init: true)

  OutlineItem = Struct.new(:title, :page, :children, keyword_init: true)

  def initialize(subject)
    @subject = subject
  end

  def bytes
    @bytes ||= case @subject
               when Prawn::Document then @subject.render
               when Pathname then File.binread(@subject)
               when String then @subject.start_with?('%PDF') ? @subject : File.binread(@subject)
               else raise ArgumentError, "Cannot read a PDF from #{@subject.class}"
               end
  end

  def reader
    @reader ||= PDF::Reader.new(StringIO.new(bytes))
  end

  def page_count = reader.page_count

  def text(page) = reader.page(page_number(page)).text

  # A page number, or the page a named destination points at.
  def page_number(page_or_dest)
    return page_or_dest if page_or_dest.is_a?(Integer)

    destinations.fetch(page_or_dest.to_s) do
      raise KeyError, "No named destination #{page_or_dest.to_s.inspect}"
    end
  end

  # Named destinations from the catalog's /Dests name tree: name => page.
  def destinations
    @destinations ||= begin
      tree = catalog_names[:Dests]
      tree ? name_tree_pairs(tree).to_h { |key, dest| [name(key), explicit_page(dest)] } : {}
    end
  end

  # Link annotations on one page, or on every page when none is given.
  def links(page = nil)
    pages = page ? [page_number(page)] : (1..page_count).to_a
    pages.flat_map { |number| page_links(number) }
  end

  def outline
    @outline ||= begin
      outlines = objects.deref_hash(catalog[:Outlines])
      outlines ? outline_items(outlines[:First]) : []
    end
  end

  private

  def objects = reader.objects
  def catalog = objects.deref_hash(objects.trailer[:Root])
  def catalog_names = objects.deref_hash(catalog[:Names]) || {}

  # [name, value] pairs from a name tree, whether its entries sit in the root
  # node's /Names or in leaves under /Kids.
  def name_tree_pairs(node)
    node = objects.deref_hash(node)
    return objects.deref_array(node[:Names]).each_slice(2).to_a if node[:Names]

    objects.deref_array(node[:Kids]).flat_map { |kid| name_tree_pairs(kid) }
  end

  def page_links(number)
    annots = objects.deref_array(reader.page(number).attributes[:Annots]) || []
    annots.filter_map do |ref|
      annot = objects.deref_hash(ref)
      link(number, annot) if annot[:Subtype] == :Link
    end
  end

  def link(number, annot)
    action = objects.deref_hash(annot[:A]) || {}
    target = annot[:Dest] || (action[:D] if action[:S] == :GoTo)
    dest = objects.deref(target)
    named = dest.is_a?(String) || dest.is_a?(Symbol)

    Link.new(from_page: number, rect: objects.deref_array(annot[:Rect]).map { |n| objects.deref(n) },
             dest: (name(dest) if named), page: target && target_page(dest),
             uri: action[:URI] && decode(objects.deref(action[:URI])))
  end

  def outline_items(ref)
    items = []
    while ref
      item = objects.deref_hash(ref)
      action = objects.deref_hash(item[:A]) || {}
      target = item[:Dest] || (action[:D] if action[:S] == :GoTo)
      items << OutlineItem.new(title: decode(objects.deref(item[:Title])),
                               page: target && target_page(objects.deref(target)),
                               children: outline_items(item[:First]))
      ref = item[:Next]
    end
    items
  end

  def target_page(dest)
    dest.is_a?(String) || dest.is_a?(Symbol) ? destinations[name(dest)] : explicit_page(dest)
  end

  # Prawn writes a name inside an action dictionary as a UTF-16 text string
  # and one directly under /Dest as bytes; both read back as the same name.
  def name(dest) = dest.is_a?(Symbol) ? dest.to_s : decode(dest)

  # The page of an explicit destination: [page_ref, :Fit, ...], or a
  # dictionary holding one under /D.
  def explicit_page(dest)
    dest = objects.deref(dest)
    dest = objects.deref(dest[:D]) if dest.is_a?(Hash)
    index = objects.page_references.index(dest.first)
    index + 1 if index
  end

  def decode(title)
    return title.dup.force_encoding(Encoding::UTF_8) unless title.b.start_with?(UTF16_BOM)

    title.b.byteslice(2..).force_encoding(Encoding::UTF_16BE).encode(Encoding::UTF_8)
  end
end
