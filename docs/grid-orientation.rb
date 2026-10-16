# frozen_string_literal: true

# Draws docs/grid-orientation.svg: a to-scale US Letter page showing the
# 43x55 grid, both coordinate origins, the standard sidebar chrome, and one
# worked grid.rect conversion. 1 SVG unit = 1 PDF point.
#
#   ruby docs/grid-orientation.rb

require_relative '../lib/bujo_pdf'

S       = Styling::Grid::DOT_SPACING
PAGE_W  = Styling::Grid::PAGE_WIDTH
PAGE_H  = Styling::Grid::PAGE_HEIGHT
COLS    = Styling::Grid::COLS
ROWS    = Styling::Grid::ROWS

chrome  = BujoPdf::Layouts::ChromeSpec.new(left: :week_sidebar, right: :tab_sidebar)
content = chrome.content_area(COLS, ROWS)

PX = 80   # page origin within the SVG
PY = 90
PANEL_X = PX + PAGE_W + 50
W = PANEL_X + 330
H = PY + PAGE_H + 70

def gx(col) = (PX + (col * S)).round(2)
def gy(row) = (PY + (row * S)).round(2)
def fmt(n) = format('%.2f', n).sub(/\.?0+\z/, '')

EX = { col: 5, row: 10, w: 20, h: 15 }.freeze

out = []
out << %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{W} #{H}" width="#{W}" height="#{H}" font-family="Helvetica, Arial, sans-serif">)
out << <<~DEFS
  <defs>
    <marker id="ah-green" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#2e7d32"/></marker>
    <marker id="ah-orange" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#e65100"/></marker>
    <marker id="ah-blue" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#1565c0"/></marker>
  </defs>
  <rect width="100%" height="100%" fill="#ffffff"/>
DEFS

out << %(<text x="#{PX}" y="32" font-size="22" font-weight="bold" fill="#222">The page grid: #{COLS} columns x #{ROWS} rows of #{S}pt (5mm) boxes</text>)
out << %(<text x="#{PX}" y="54" font-size="13" fill="#555">Drawn to scale on US Letter (#{PAGE_W} x #{PAGE_H}pt). Pages are written in grid coordinates; GridSystem converts them to Prawn points.</text>)

# Page
out << %(<rect x="#{PX}" y="#{PY}" width="#{PAGE_W}" height="#{PAGE_H}" fill="#fafafa" stroke="#999" stroke-width="1"/>)

# Chrome regions (standard_with_sidebars)
lw = content[:col]
rw = COLS - content[:col] - content[:width_boxes]
out << %(<rect x="#{gx(0)}" y="#{gy(0)}" width="#{fmt(lw * S)}" height="#{fmt(ROWS * S)}" fill="#ede7f6"/>)
out << %(<rect x="#{gx(COLS - rw)}" y="#{gy(0)}" width="#{fmt(rw * S)}" height="#{fmt(ROWS * S)}" fill="#ede7f6"/>)
out << %(<rect x="#{gx(content[:col])}" y="#{gy(0)}" width="#{fmt(content[:width_boxes] * S)}" height="#{fmt(ROWS * S)}" fill="none" stroke="#7e57c2" stroke-width="1" stroke-dasharray="4 3"/>)

# Unused slack: the grid stops short of the page's right and bottom edges
slack_b = (PAGE_H - (ROWS * S)).round(2)
slack_r = (PAGE_W - (COLS * S)).round(2)
out << %(<rect x="#{PX}" y="#{gy(ROWS)}" width="#{PAGE_W}" height="#{slack_b}" fill="#ffebee"/>)
out << %(<rect x="#{gx(COLS)}" y="#{PY}" width="#{slack_r}" height="#{PAGE_H}" fill="#ffebee"/>)

# Grid lines (faint) and dots at every intersection
(0..COLS).each { |c| out << %(<line x1="#{gx(c)}" y1="#{gy(0)}" x2="#{gx(c)}" y2="#{gy(ROWS)}" stroke="#e6e6e6" stroke-width="0.5"/>) }
(0..ROWS).each { |r| out << %(<line x1="#{gx(0)}" y1="#{gy(r)}" x2="#{gx(COLS)}" y2="#{gy(r)}" stroke="#e6e6e6" stroke-width="0.5"/>) }
(0..ROWS).each { |r| (0..COLS).each { |c| out << %(<circle cx="#{gx(c)}" cy="#{gy(r)}" r="0.9" fill="#b0b0b0"/>) } }

# Every 5th line a little darker so counting is easy
(0..COLS).step(5) { |c| out << %(<line x1="#{gx(c)}" y1="#{gy(0)}" x2="#{gx(c)}" y2="#{gy(ROWS)}" stroke="#cfcfcf" stroke-width="0.8"/>) }
(0..ROWS).step(5) { |r| out << %(<line x1="#{gx(0)}" y1="#{gy(r)}" x2="#{gx(COLS)}" y2="#{gy(r)}" stroke="#cfcfcf" stroke-width="0.8"/>) }

# Rulers: a column/row number labels the box to its right/below
col_marks = (0...COLS).step(5).to_a | [COLS - 1]
row_marks = (0...ROWS).step(5).to_a | [ROWS - 1]
col_marks.each { |c| out << %(<text x="#{fmt(gx(c) + (S / 2))}" y="#{PY - 6}" font-size="10" text-anchor="middle" fill="#2e7d32">#{c}</text>) }
row_marks.each { |r| out << %(<text x="#{PX - 6}" y="#{fmt(gy(r) + (S / 2) + 3.5)}" font-size="10" text-anchor="end" fill="#2e7d32">#{r}</text>) }
out << %(<text x="#{fmt(PX + (PAGE_W / 2))}" y="#{PY - 22}" font-size="11" text-anchor="middle" fill="#2e7d32">col</text>)
out << %(<text x="#{PX - 32}" y="#{fmt(PY + (PAGE_H / 2))}" font-size="11" text-anchor="middle" fill="#2e7d32" transform="rotate(-90 #{PX - 32} #{fmt(PY + (PAGE_H / 2))})">row</text>)

# Chrome labels
out << %(<text x="#{fmt(gx(lw / 2.0))}" y="#{gy(40)}" font-size="11" fill="#5e35b1" text-anchor="middle" transform="rotate(-90 #{fmt(gx(lw / 2.0))} #{gy(40)})">:week_sidebar  cols 0-#{lw - 1}</text>)
out << %(<text x="#{fmt(gx(COLS - (rw / 2.0)))}" y="#{gy(40)}" font-size="10" fill="#5e35b1" text-anchor="middle" transform="rotate(-90 #{fmt(gx(COLS - (rw / 2.0)))} #{gy(40)})">:tab_sidebar  col #{COLS - 1}</text>)
cc = content[:col]
cw = content[:width_boxes]
out << %(<rect x="#{fmt(gx(cc + (cw / 2.0)) - 120)}" y="#{fmt(gy(32) - 13)}" width="240" height="36" rx="3" fill="#fafafa" fill-opacity="0.9"/>)
out << %(<text x="#{fmt(gx(cc + (cw / 2.0)))}" y="#{gy(32)}" font-size="12" fill="#5e35b1" text-anchor="middle">content area: cols #{cc}-#{cc + cw - 1} (#{cw} wide)</text>)
out << %(<text x="#{fmt(gx(cc + (cw / 2.0)))}" y="#{fmt(gy(32) + 16)}" font-size="11" fill="#5e35b1" text-anchor="middle">use_layout :standard_with_sidebars</text>)

# Worked example rect
ex_x, ex_y = gx(EX[:col]), gy(EX[:row])
ex_w, ex_h = EX[:w] * S, EX[:h] * S
out << %(<rect x="#{ex_x}" y="#{ex_y}" width="#{fmt(ex_w)}" height="#{fmt(ex_h)}" fill="#1e88e5" fill-opacity="0.15" stroke="#1565c0" stroke-width="2"/>)
out << %(<text x="#{fmt(ex_x + 8)}" y="#{fmt(ex_y + 20)}" font-size="13" font-weight="bold" fill="#0d47a1">grid.rect(#{EX[:col]}, #{EX[:row]}, #{EX[:w]}, #{EX[:h]})</text>)
out << %(<text x="#{fmt(ex_x + 8)}" y="#{fmt(ex_y + 38)}" font-size="11" fill="#0d47a1">col #{EX[:col]}, row #{EX[:row]}, #{EX[:w]} wide, #{EX[:h]} tall</text>)
# width / height dimension arrows
dy = ex_y + ex_h + 14
out << %(<line x1="#{ex_x}" y1="#{fmt(dy)}" x2="#{fmt(ex_x + ex_w)}" y2="#{fmt(dy)}" stroke="#1565c0" stroke-width="1" marker-start="url(#ah-blue)" marker-end="url(#ah-blue)"/>)
out << %(<rect x="#{fmt(ex_x + (ex_w / 2) - 68)}" y="#{fmt(dy - 7)}" width="136" height="14" fill="#fafafa"/>)
out << %(<text x="#{fmt(ex_x + (ex_w / 2))}" y="#{fmt(dy + 4)}" font-size="11" fill="#0d47a1" text-anchor="middle">#{EX[:w]} boxes = #{fmt(EX[:w] * S)}pt</text>)
dx = ex_x + ex_w + 14
out << %(<line x1="#{fmt(dx)}" y1="#{ex_y}" x2="#{fmt(dx)}" y2="#{fmt(ex_y + ex_h)}" stroke="#1565c0" stroke-width="1" marker-start="url(#ah-blue)" marker-end="url(#ah-blue)"/>)
out << %(<text x="#{fmt(dx + 6)}" y="#{fmt(ex_y + (ex_h / 2))}" font-size="11" fill="#0d47a1">#{EX[:h]} boxes</text>)
out << %(<text x="#{fmt(dx + 6)}" y="#{fmt(ex_y + (ex_h / 2) + 14)}" font-size="11" fill="#0d47a1">= #{fmt(EX[:h] * S)}pt</text>)
# corner callout: where Prawn sees the top-left corner
out << %(<circle cx="#{ex_x}" cy="#{ex_y}" r="4" fill="#1565c0"/>)
gp = BujoPdf::GridRect.new(EX[:col], EX[:row], EX[:w], EX[:h])
out << %(<rect x="#{fmt(ex_x - 8)}" y="#{fmt(ex_y - 35)}" width="320" height="32" fill="#fafafa" fill-opacity="0.92"/>)
out << %(<text x="#{fmt(ex_x - 4)}" y="#{fmt(ex_y - 22)}" font-size="11" fill="#0d47a1">top-left corner in Prawn points:</text>)
out << %(<text x="#{fmt(ex_x - 4)}" y="#{fmt(ex_y - 8)}" font-size="11" font-family="Menlo, Consolas, monospace" fill="#0d47a1">x = grid.x(#{EX[:col]}) = #{fmt(gp.x)}   y = grid.y(#{EX[:row]}) = #{fmt(gp.y)}</text>)

# Grid origin (top-left)
out << %(<circle cx="#{PX}" cy="#{PY}" r="6" fill="#2e7d32"/>)
out << %(<line x1="#{PX + 10}" y1="#{gy(3)}" x2="#{gx(6)}" y2="#{gy(3)}" stroke="#2e7d32" stroke-width="2.5" marker-end="url(#ah-green)"/>)
out << %(<line x1="#{gx(0.7)}" y1="#{PY + 10}" x2="#{gx(0.7)}" y2="#{gy(6)}" stroke="#2e7d32" stroke-width="2.5" marker-end="url(#ah-green)"/>)
out << %(<text x="#{gx(6) + 6}" y="#{gy(3) + 4}" font-size="11" font-weight="bold" fill="#2e7d32">col +</text>)
out << %(<text x="#{gx(0.7) + 4}" y="#{gy(6) + 14}" font-size="11" font-weight="bold" fill="#2e7d32">row +</text>)

# Prawn origin (bottom-left)
py0 = PY + PAGE_H
out << %(<circle cx="#{PX}" cy="#{py0}" r="6" fill="#e65100"/>)
out << %(<line x1="#{PX - 18}" y1="#{py0 - 10}" x2="#{PX - 18}" y2="#{fmt(py0 - 100)}" stroke="#e65100" stroke-width="2.5" marker-end="url(#ah-orange)"/>)
out << %(<text x="#{PX - 24}" y="#{fmt(py0 - 108)}" font-size="11" font-weight="bold" fill="#e65100" text-anchor="end">y +</text>)
out << %(<line x1="#{PX + 10}" y1="#{py0 + 22}" x2="#{PX + 100}" y2="#{py0 + 22}" stroke="#e65100" stroke-width="2.5" marker-end="url(#ah-orange)"/>)
out << %(<text x="#{PX + 106}" y="#{py0 + 26}" font-size="11" font-weight="bold" fill="#e65100">x +</text>)
out << %(<text x="#{PX - 10}" y="#{py0 + 44}" font-size="12" fill="#e65100">Prawn origin (0, 0): bottom-left, y grows upward</text>)

# Slack callout
out << %(<text x="#{fmt(PX + PAGE_W - 4)}" y="#{py0 + 26}" font-size="11" fill="#c62828" text-anchor="end">pink: #{slack_b}pt below row #{ROWS - 1} and #{slack_r}pt right of col #{COLS - 1} are off-grid</text>)

# Side panel
lines = [
  [:h, 'Two coordinate systems'],
  [:g, 'Grid (what pages write)'],
  [:t, 'origin top-left, (col 0, row 0)'],
  [:t, "cols 0-#{COLS - 1} rightward, rows 0-#{ROWS - 1} downward"],
  [:t, 'units are boxes, fractions allowed'],
  [:sp],
  [:o, 'Prawn (what the PDF uses)'],
  [:t, 'origin bottom-left, (0, 0)'],
  [:t, "x 0-#{PAGE_W}pt rightward, y 0-#{PAGE_H}pt upward"],
  [:sp],
  [:h, 'Conversion (GridSystem)'],
  [:m, "grid.x(col)   = col * #{S}"],
  [:m, "grid.y(row)   = #{PAGE_H} - row * #{S}"],
  [:m, "grid.width(n) = n * #{S}"],
  [:m, 'grid.rect(col, row, w, h)'],
  [:t, '  -> GridRect: grid and point accessors'],
  [:sp],
  [:h, 'Things that bite'],
  [:t, 'grid.y returns a big number for row 0:'],
  [:t, '  row 0 is the top, Prawn y is from the bottom.'],
  [:t, 'Prawn text_box at: is the top-left corner,'],
  [:t, '  but its y is still measured from the bottom.'],
  [:t, 'Link rects are [left, bottom, right, top]:'],
  [:t, '  bottom = grid.y(row + h), top = grid.y(row).'],
  [:t, 'Inside a bounding_box, (0, 0) moves to the'],
  [:t, "  box's bottom-left."],
  [:sp],
  [:h, 'Component verbs take grid units'],
  [:m, 'h1(5, 2, "Title")'],
  [:m, 'ruled_lines(5, 5, 30, 20)'],
  [:m, 'box(*grid.rect(5, 10, 20, 15))']
]
y = PY + 4
lines.each do |kind, text|
  case kind
  when :sp then y += 10
  when :h
    y += 6
    out << %(<text x="#{PANEL_X}" y="#{y}" font-size="14" font-weight="bold" fill="#222">#{text}</text>)
    y += 20
  when :g, :o
    out << %(<circle cx="#{PANEL_X + 5}" cy="#{y - 4}" r="5" fill="#{kind == :g ? '#2e7d32' : '#e65100'}"/>)
    out << %(<text x="#{PANEL_X + 16}" y="#{y}" font-size="12" font-weight="bold" fill="#{kind == :g ? '#2e7d32' : '#e65100'}">#{text}</text>)
    y += 18
  when :m
    out << %(<text x="#{PANEL_X}" y="#{y}" font-size="11.5" font-family="Menlo, Consolas, monospace" fill="#333">#{text.gsub('"', '&quot;')}</text>)
    y += 17
  else
    indent = text[/\A */].size * 6
    out << %(<text x="#{PANEL_X + indent}" y="#{y}" font-size="12" fill="#444">#{text.strip}</text>)
    y += 17
  end
end

out << '</svg>'
File.write(File.join(__dir__, 'grid-orientation.svg'), out.join("\n") + "\n")
puts "wrote docs/grid-orientation.svg (#{W}x#{H})"
