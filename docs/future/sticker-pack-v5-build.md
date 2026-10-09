# Sticker pack v5 — expressive widgets

Working file for the in-progress build. Status is kept current as items land.
If this session is interrupted, this file plus `git log` is the whole picture.

## Why this pack exists (read first)

The v2–v4 pack is seven widgets, all of them **forms**: a bounded thing you
commit to before you write (grid patch, hour axis, Eisenhower, habit strip, top
three, timeline ribbon, radial divider). In a brainstorm round the user cut
every *analytical* proposal offered — braces, arrows, 2x2s, comparison grids,
waiting-on lists — and kept only the *expressive* ones: ornament, a picture, a
verdict.

**The finding:** an analytical widget pays off later, if the structure you
imposed turns out to have been right. Ornament and a stamp pay off the instant
you place them. That is the same "man of the moment" rule from
`planner-content-review.md` §9, one level deeper than it was previously applied.

**Design rule for this pack:** a sticker earns its place if placing it is
immediately satisfying. Nothing here asks the user to fill in a form.

Two existing rules still bind:

- **Scale-free** (`stickers/base.rb`): a sticker may hold no opinion about the
  size of the page it lands on.
- **Whole grid boxes**: every sticker's width and height must be a whole number
  of boxes, or it stops landing on the planner's dot grid at 100%. Enforced by
  `test_sticker_dimensions_are_whole_grid_boxes`.

## Build list

| # | Item | File | Status |
|---|---|---|---|
| 0 | Backing opt-out (`backing_shape :none` / `backable?`) | `base.rb`, `backed.rb` | **done** |
| 1 | Ornament drawing vocabulary (volute, lance, radial repeat) | `ornament.rb` | **done** |
| 2 | Stamps — 16 words, two inks, blank frame (18 default / 34 with --all) | `stamp.rb` | **done** |
| 3 | Postmark roundel — circular stamp, text round the rim (4) | `postmark.rb` | **done** |
| 4 | Rosette — radial iron doily, clear centre (lance, scroll) | `rosette.rb` | **done** |
| 5 | Cartouche — horizontal iron frame, clear band (scroll, leaf) | `cartouche.rb` | **done** |
| 6 | Guilloche ring — engraved hypotrochoid band (9, 13 lobes) | `guilloche.rb` | **done** |
| 7 | Polaroid frame — instant film, window to draw in (portrait, wide) | `photo_frame.rb` | **done** |
| 8 | Photo corners — chamfered corners, single + set, 2 inks (4) | `photo_corners.rb` | **done** |
| 9 | Flag tags — 3 shapes x 3 colours (9) | `flag_tag.rb` | **done** |
| 10 | Colophon marks — fleuron, asterism, dinkus, tombstone, swash | `colophon.rb` | **done** |
| 11 | Venn — 2 and 3 circles | `venn.rb` | **done** |
| 12 | Ornamental divider with a gap for a word (plain, scroll) | `divider.rb` | **done** |
| 13 | Register everything, split pack into `forms` + `marks` | `generator.rb` | **done** |
| 14 | Tests — 16 new, suite at 1966 / 0 failures | `stickers_test.rb` | **done** |

All files live in `lib/bujo_pdf/stickers/`.

## Decisions already made

- **Font is built-in Helvetica-Bold, and that is settled.** The user reviewed
  the rendered stamps and approved it ("I like the font fine"), so the pack
  bundles no TTF. Stamps get their look from letter-spaced caps
  (`pdf.character_spacing`) and a double-rule frame.
- **No script or calligraphic faces, ever.** Stated flatly by the user. This
  binds the ornamental stickers most, because a cartouche or a colophon mark is
  exactly where a script face is the obvious temptation - resist it. Any
  lettering in this pack is upright and set in caps.
- **Stamps are not distressed.** Prawn has no noise or texture; faking broken
  edges by overlaying white shapes risks reading as dirt. Clean "office stamp",
  and the user's own rotation supplies the casual feel.
- **Stamp ink is semantic, not decorative.** Verdict / generative / status
  stamps are oxide red (an assertion should be loud). Provenance stamps are
  charcoal (archival, quieter). The other ink for each is available behind
  `--all`, reusing the idiom `GridPatch` already established for the dot patch.
- **Ornament ink is `Ornament::IRON` (`7A756C`), not the pack default
  `AAAAAA`.** Ornament is looked at rather than written over, and it leans warm
  so it sits on the earth theme.
- **Weight contrast is what makes iron read as iron.** `Ornament::WEIGHTS` has
  four tiers; a single hairline repeated twelve times reads as a spirograph.
- **Ornament, photo frames and corners decline a card** (`backing_shape
  :none`). A card behind a doily fills the negative space that *is* the
  ornament; a card behind a photo frame fills the window.
- **Photo corners ship in two inks**: `dark` (a classic gummed photo corner)
  and `paper` (card-coloured, which reads as a slit cut in the page with the
  drawing tucked under it — the user's own description). The slit illusion
  cannot be done properly without knowing the page colour, so `paper` uses
  `Backed::CARD_COLOR` and accepts being approximate.

## What shipped

65 stickers in the default pack, up from 13; 82 with `--all`. Split in
`Generator` into two named halves:

- `forms` (15) — the old pack plus Venn. Accept a card.
- `marks` (50) — stamps, ornament, objects. All decline a card.

Delivered to `~/Dropbox/bujo-stickers-v5`.

## Findings from drawing it

Four things only showed up on the contact sheet, and all four are the same
lesson: generated ornament fails by being *too thin and too sparse*, never by
being too busy.

- **A symmetrical leaf with a dot in the middle is an eye.** The first
  cartouche end was unusable for this reason. Fixed with two offset leaves of
  different lengths, veined rather than dotted.
- **A guilloche needs about nine lobes before it stops looking like a tangle.**
  At 7 lobes the step per lobe is large enough that the curve crosses the band
  as a chord. 9 and 13 both read as engraving; 7 read as a pentagram.
  Documented on the `lobes` param so nobody re-adds it.
- **Unattached curls read as separate marks.** The scroll rosette only became
  ironwork when each volute got a stem tying it back to the radial bar.
- **A terminal under about half a box does not register at all** — it reads as
  a smudge on the end of a rule. Both the divider and the swash needed their
  volutes roughly doubled.

## Known consequence to watch

`Backed.wrap` now passes non-backable stickers through untouched, so a
`--backed` run emits them under their *plain* filenames. That breaks the old
guarantee that a backed run shares no filename with an unbacked one
(`test_card_slugs_never_collide_with_their_transparent_originals`). This is
correct — there is only one version of an unbackable sticker, so there is
nothing for a card to overwrite — but **the test has to be updated to assert
the narrower property**: backable stickers get `_card`, and no card collides
with its own transparent original.

## Commands

```bash
bundle exec rake test                 # IGNORE the exit code; SimpleCov fails a
                                      # pre-existing 15%/file minimum. Read the
                                      # "tests, assertions" line.
bin/bujo-pdf stickers --help
bin/bujo-pdf stickers --tag v5 --out ~/Dropbox/bujo-stickers-v5
bin/bujo-pdf stickers --all --tag v5all --out /tmp/stickers-all
```

## Open questions for the user

- **Rosette vs guilloche** — they came out as genuinely different moods
  (forged vs engraved), so both shipped. If only one gets used, drop the other.
- **Flag colours.** Three muted tones was a guess. Easy to change, easy to
  extend, but a fourth only earns its place if the first three are being told
  apart in use.
- **Do the paper photo corners read at all on the earth theme?** They are card
  colour against an unknown background by construction.

## Next, if this direction holds

Untouched territories from the brainstorm, in the order they looked strongest:

1. **Seals and badges** — wax seal, star badge, laurel wreath. Same code family
   as the rosette, so cheap now that `Ornament` exists. SUCCESS as a medal
   rather than as a verdict.
2. **Corner flourishes and a tiling border strip** — the frame family, which
   this build only touched through the photo frame.
3. **Emphasis marks** — starburst, a hand-drawn ellipse for circling a passage,
   a manicule. The expressive cousins of the arrows that got cut.
4. **Compass rose** — ornament that happens to have a job.
