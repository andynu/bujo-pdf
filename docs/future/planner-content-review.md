# Planner Content Review

A review of *what the planner contains* and *how it is sequenced* — not the code
architecture. Written against `:standard_planner` as generated for 2026
(`planner_2026.pdf`, 92 pages).

Status: discussion document. Findings are grouped so they can be triaged into
bd issues independently.

---

## 1. Inventory

Actual page sequence from the recipe (`lib/bujo_pdf/pdfs/standard_planner.rb`),
for year 2026:

| Pages | Count | Type | Chrome |
|-------|-------|------|--------|
| 1 | 1 | `seasonal` — year at a glance, 12 mini months, season bands | sidebars |
| 2–3 | 2 | `index` — numbered lines 1–100, two columns, page-number boxes | **none** |
| 4–5 | 2 | `future_log` — 6 months per page, 2 ruled columns each | sidebars |
| 6 | 1 | `year_events` — 31×12 day grid, weekend shading | sidebars |
| 7 | 1 | `year_highlights` — same grid, different heading | sidebars |
| 8 | 1 | `multi_year` — 4 years in columns | **none** |
| 9–77 | 69 | `weekly` ×53, `quarterly_planning` ×4, `monthly_review` ×12 (interleaved) | weekly: sidebars; quarter/review: **none** |
| 78–85 | 8 | `grid_showcase`, `grids_overview`, then dot / graph / lined / isometric / perspective / hexagon | overview only |
| 86 | 1 | `tracker_example` — habit + mood/energy examples | **none** |
| 87 | 1 | `reference` — stylus calibration / line-weight reference | **none** |
| 88 | 1 | `daily_wheel` — 24-hour radial | **none** |
| 89 | 1 | `year_wheel` — 12-month radial | **none** |
| 90–92 | 3 | `collection` ×3 (books, project ideas, recipes) | **none** |

### Page classes that exist but are never used

Registered in `PageRegistry`, absent from every recipe:

- `monthly_overview` (`lib/bujo_pdf/pages/monthly_overview.rb`) — month header,
  mini calendar, notes area. This is almost exactly the missing month view.
- `visual_toc` (`lib/bujo_pdf/pages/visual_toc.rb`) — a rendered table of
  contents, as opposed to the hand-written `index`.
- `scratch`

---

## 2. Sequencing

### 2.1 Monthly reviews sat one month ahead of their content — FIXED

The recipe inserted month pages *before* the first week of that month. So
`review_1` ("January 2026 / Monthly Review", with prompts "What Worked" /
"What Didn't Work") appeared on page 11, between week 1 and week 2 — asking for
a retrospective on January before January had happened.

The *slot* was right; only the label was wrong. The page titled "February" sat
immediately after January's last week, which is where January's review belongs.

Fixed by emitting month M's review *after* month M's last week, with December's
review flushed after the final week. See §2.3 for the new order.

### 2.2 Week 1 was orphaned outside its month — FIXED

`Week#primary_month` returned `nil` when the week started in the previous
calendar year (week 1 of 2026 starts Dec 29, 2025). The interleaving loop
skipped `nil`, so week 1 was emitted *before* Q1 planning and the January
outline entry. This affects every year where Jan 1 falls Tue–Sun.

Root cause was a naming/semantics mismatch: `primary_month` promised "the month
this week mostly belongs to" but implemented "month of the start date, or nil if
out of year" — a *year-boundary* signal being read as a *month* value.

Fixed by adding `Week#interleaving_month`, which never returns nil for a week
that overlaps the year. `primary_month` is unchanged (it still reports the
year-boundary condition, which other callers may want).

Related, still open: weeks that straddle a month boundary file under their
*start* month, not their majority month. Week 14 of 2026 (Mar 30 – Apr 5) has
five of seven days in April but files under March.

### 2.3 Current order at a month/quarter boundary

```
... week 5 (last January week)
    monthly_review  January      <- review of the month just finished
    quarterly_planning Q2        <- only when a new quarter starts here
    week 6 (first February week)
```

and at the head of the year:

```
    quarterly_planning Q1
    week 1
    week 2 ...
```

and at the tail:

```
    week 53
    monthly_review  December
```

### 2.4 Front matter ordering — OPEN

Current: seasonal → index → future log → events → highlights → multi-year.

Issues: the Index is a *reference* you return to, not page-2 reading; the future
log is the thing actually filled out first; multi-year (widest lens) sits last
among the year views.

Candidate order: multi-year → seasonal → future log → events → highlights, with
the Index moved to the back alongside the collections.

### 2.5 Back matter has no organising principle — OPEN

Eight grid pages, four template pages, and the collections run together with no
separator. The seven grid templates in particular read as a demo of the
library's capabilities rather than a deliberate part of the product.

---

## 3. Navigation: ~35 pages are dead ends — OPEN

Everything declared `chrome: false` loses both sidebars, and for most page types
nothing replaces them.

| Page type | Count | Links off the page |
|---|---|---|
| `index` | 2 | **none at all** |
| `quarterly_planning` | 4 | prev/next quarter; weeks in the 12-week grid |
| `monthly_review` | 12 | prev/next month only |
| grid templates | 7 | none (group cycling declared, but chrome is off) |
| `tracker_example`, `reference`, wheels | 4 | none |
| `collection` | 3 | none |

On an iPad this means tapping the Index tab strands you — the only way out is
the reader app's page scrubber, which defeats the purpose of building internal
navigation at all.

Fix is cheap: these pages don't need the full week sidebar, but they should
carry the right-hand tab strip, or at minimum a "Year" home link.
`chrome: { left: false, right: :tab_sidebar }` per page, or a narrower
`:minimal_nav` sidebar.

### 3.1 The Index is structurally unusable — OPEN

Each of the 100 index lines has a page-number box, but **no page in the document
prints a page number**. The classic bullet-journal index technique cannot be
performed. Options: print page numbers in the footer, or replace the Index with
the already-written `visual_toc`.

### 3.2 Missing tabs — OPEN

The right-hand tab strip offers Year, Future, Events, Highlights, Multi, Grids.
There is no tab for Index, Month, or Collections.

---

## 4. Structural gaps

### 4.1 No month view — OPEN

The hierarchy jumps from the seasonal calendar (whole year, tiny) straight to the
weekly page (one week, huge). There is no "what does October look like" page.

`MonthlyOverview` exists and is unused. Twelve of them would complete
year → quarter → month → week, and would give the left sidebar's month letters
somewhere to point.

This interacts with §2.1: the alternative fix considered there was to split the
monthly page into a forward-looking **Monthly Plan** at month start and a
backward-looking **Monthly Review** at month end. `MonthlyOverview` is ~80% of
that plan page. Decision still open.

### 4.2 Events and Highlights are the same page twice — OPEN

Both are 31×12 day grids from `year_at_glance_base.rb`;
`year_at_glance_highlights.rb` is 43 lines of subclass. Two near-identical grids
one page apart is a place to lose track of which is which. Either differentiate
them visually or collapse to one.

### 4.3 Collections don't continue — OPEN

Three collection pages, one page each. A filled "Books to Read" has nowhere to
go. Consider a `pages:` count per collection in `config/collections.yml`.

---

## 5. Per-page component notes

### `weekly` — the core page

Daily strip is 9 of 55 rows (17%): seven columns, four ruled lines each, ~3mm
apart. The remaining 44 rows are Cornell notes — cues 10 cols / notes 30 cols /
summary 9 rows.

This is a deliberate bet: the week is a container, and the real writing is
unstructured. Worth checking against a year of actual use:

- Did the daily columns get filled, or were four cramped lines too few to bother?
- Was the Cornell **cues** column used as cues, or just as more writing space?
  It costs 25% of the page and only pays off if it earns it.

Absent from the weekly page: habit/tracker strip, "top 3 for the week", any
indication of which month you're in, week-of-year progress beyond the sidebar.

### `quarterly_planning`

Three goal lines plus a 12-week grid with one ruled line per week; the week rows
are clickable links to the weekly pages.

**Bug — OPEN:** `WEEKS_PER_QUARTER = 12` is hardcoded, but quarters contain ~13
weeks. One week per quarter is silently missing from the grid, and because
`calculate_first_week_of_quarter` derives the start from the quarter's first day,
the grids do not tile the year. Worth checking Q4 against a calendar.

### `monthly_review`

Three prompts with generous ruled space, and no data on the page. It asks for
reflection with zero reference material to reflect on. Adding a mini-calendar of
the month, a linked list of that month's week numbers, and the quarter goals
would make it a much better reflection surface.

### `future_log`

Six months per page, two ruled columns each. Solid. No link from a future-log
month to that month's pages.

### `year_events` / `year_highlights`

31×12 grid with weekend shading and `dates.yml` / iCal integration.

**Note — CORRECTED:** an earlier draft of this document claimed the date/calendar
integration was unused because `config/dates.yml` and `config/calendars.yml` are
absent from the repo (only `.example` files are checked in). That was wrong. The
2026 planner the user actually generated is full of configured events — holidays
("Christmas Day", "Columbus Day (Regional)", "Martin Luther King Jr Day"),
birthdays ("Nora's Birthday", "Ben's Birthday", "Maggie Ann's Birthday") and
anniversaries ("Whitehead Anniversary", "Moved to 455 Anniversary") appear on the
weekly pages and throughout the year grids. The config files are simply kept
outside version control. The feature is live and working.

### `tracker_example`

Labelled "Tracker Ideas — examples to spark your creativity, adapt these to your
needs". It is a brochure, not a tool: one page of suggestions you cannot
actually use. Twelve real monthly habit trackers would be worth more.

### `daily_wheel` / `year_wheel`

Striking radial pages — one copy of each in a year-long planner. A single daily
wheel is a curiosity rather than a tool.

### `reference`

Stylus calibration / line-weight reference. Genuinely useful for a digital
planner. Consider moving it to the very front or very back.

### `index`

See §3.1.

---

## 6. Ideas backlog

### Sequencing and structure

- Month spreads (overview + review pairs) — closes the year→week gap (§4.1)
- Move Index and collections to the back; lead with the future log (§2.4)
- Print page numbers, or swap Index for `visual_toc` (§3.1)
- Give every `chrome: false` page a minimal nav strip (§3)

### New page types

- **Weekly review** — likely a block on the weekly page rather than a new page
- **Year in pixels** — 365-cell mood/energy grid, one page
- **Someday/maybe + project list** — collection-style but structured
- **Brain dump / parking lot** — interleaved quarterly
- **People log** — birthdays, gift ideas, who you owe a call
- **Reading/watching log** with rating columns (today's collections are blank dot grid)
- **Financial / subscription tracker** — annual, one page
- **Meeting notes template** in the back-matter section
- **Yearly retrospective + next-year setup** at the very end

### New component verbs

- `habit_strip(col, row, width, days:)` — the tracker grid as a reusable verb,
  droppable into weekly and monthly pages
- Use the existing `mini_month` on monthly review, quarterly planning, and future log
- `progress_bar` / week-of-year indicator
- `checkbox_list(n)` — for goals and top-3s
- `linked_week_chips` — a row of clickable week numbers for month and quarter pages

---

## 7. Open questions

1. **Monthly page shape.** Keep one combined review page at month end (current,
   after the §2.1 fix), or split into Plan (month start) + Review (month end)?
   The split is the reason to finally wire up `MonthlyOverview`.
2. **Which pages actually got used?** Nine months of ink on the iPad copy is
   worth more than every inference above — especially for the Cornell cues
   column, the daily strip, the Index, the grid templates, and the collections.

---

## 8. Measured usage, 2026 planner (as of 2026-09-18)

Derived by pixel-diffing the user's annotated iPad export against a template
generated from the same code revision. Method and caveats in §8.4.

**38 of 92 pages carry handwriting.**

### 8.1 What gets used

| Section | Used | Total | Notes |
|---|---|---|---|
| Weekly pages | 32 | 53 | every week 1-38 except 2, 7, 9, 10, 11, 15 |
| Monthly reviews | 0 | 12 | 4 pages show marks; user confirms none were used meaningfully |
| Quarterly planning | 1 | 4 | Q1 only |
| Year events | 1 | 1 | handwritten additions on the grid |
| Everything else | 0 | 22 | see §8.2 |

The weekly page is the product. Usage is also *accelerating*: weeks 1-18 have
gaps (6 of 18 skipped), weeks 19-38 are unbroken — twenty consecutive weeks. The
last used page is week 38, which is the current week, so the planner is in
active daily use rather than abandoned.

Ink volume varies enormously between weekly pages: from 33 changed pixels (a
single diagonal day-strike) to 26,000 (week 18, which is full — daily columns,
Cornell cues, notes, a sticker). Both extremes are legitimate use.

### 8.2 What has never been touched

- **Index** (2 pages) — consistent with §3.1: it cannot be used without page numbers.
- **Future log** (2 pages) — never used once, despite being front matter.
- **Year highlights** (1 page) — while Year *events*, one page earlier, is used.
  Strong evidence for §4.2: two near-identical grids, only one gets adopted.
- **Multi-year overview** (1 page)
- **Seasonal calendar** (1 page) — the opening page of the book.
- **8 monthly reviews**, **3 quarterly planning** pages
- **All 8 grid pages**, **tracker example**, **reference/calibration**,
  **daily wheel**, **year wheel**
- **All 3 collection pages**

That is 22 distinct page types plus the unused weeks — roughly 54 pages of the
92 that have never been marked.

### 8.3 What this implies

1. **The back matter is inert.** 15 consecutive pages (78-92: grids, tracker,
   wheels, collections) have zero marks. (An earlier draft called this "dead
   weight" and recommended cutting it; see §9 — the direction is to redesign,
   not delete.)
2. **Monthly review is effectively unused.** Four pages carry marks, but the
   user confirms not one was used meaningfully — they are incidental, not
   reflection. Treat the monthly review as 0/12.
3. **Quarterly planning was used once, in Q1** — the classic new-year burst.
4. **The future log is the biggest surprise.** It is a core bullet-journal
   construct, given 2 pages of prime front matter, and used zero times. Either
   drop it or find out what would make it stick.
5. **Year events beat year highlights** decisively. Collapse them (§4.2).
6. **The month view gap (§4.1) is untested** — there is no month page to have
   been used or ignored. Adding it remains a hypothesis, not a validated need.

### 8.4 Method

`pdftoppm` both PDFs to 100-DPI grayscale, compare per pixel. Three confounds
had to be removed before any signal appeared:

1. **The iPad app stamps a footer** (`planner_2026` / `N of 92`) on every page.
   Cropping below row 1275 removes it. Above the footer the two renders align
   *exactly* — a blank page diffs to literally zero pixels.
2. **The iOS re-export renders bold text heavier** than the original. This
   produces a halo around every heading, proportional to how much bold text the
   page has — which is why text-heavy pages looked "changed" and grid pages did
   not. Fixed by masking out any changed pixel within ~5px of existing template
   ink (`MinFilter(11)`).
3. **Printed calendar events** exist in the user's copy but not in the template
   (the config files are not in the repo, see §5). These are indistinguishable
   from ink by pixel count — "Maggie's Anniversary" scores the same as a light
   handwritten note. Separated by shape: printed labels are ~8-16px tall glyph
   runs; handwriting produces connected components 18px and taller. Classifying
   on max component height separates them cleanly.

Every borderline page was then verified by eye. Two would have been misclassified
by pixel count alone: page 76 (only "* Christmas Day", no ink) and page 6 (looks
like pure event noise, but contains handwritten "Josh", "outing", "BEA", "+4").

Extract of the 38 annotated pages: `~/Dropbox/planner_2026_annotated.pdf`.

---

## 9. Design direction: build for the present tense

Two constraints now govern this work, both stated by the user after seeing §8.

**9.1 "I'm a man of the moment mainly."**

This is the organising insight, and it explains the usage data exactly. Every
page that failed asks the user to look either *backward* or *forward*:

| Page | Asks you to | Used |
|---|---|---|
| Weekly | be in this week | 32/53 |
| Monthly review | look back at a finished month | 0/12 |
| Quarterly planning | commit to a future quarter | 1/4 |
| Future log | schedule things not yet thought about | 0/2 |
| Year events | see what is coming (reference) | 1/1 |

The split is not effort, novelty, or position in the book. It is tense. The
pages used are the ones that describe *now* or serve as reference you consult in
the moment. The pages unused are the ones that require a ritual — a habit of
returning at a boundary you have to notice and honour.

**Design rule:** a page earns its place if it is worth opening *today*, with no
habit required. Prefer reference surfaces and low-friction capture over prompts,
goal-setting, and scheduled review.

Note that §2.1 — moving monthly reviews to the end of their month — is still the
right sequencing fix, but it will not by itself make those pages get used. It
corrects an obvious wrongness; it does not address the tense problem.

**9.2 "All things are worth fixing."**

The recommendation to cut the inert back matter is withdrawn. Low usage is to be
read as a design failure of the page, not as evidence its purpose is unwanted.
Every unused page gets a redesign proposal, not a deletion proposal.

### 9.3 Re-reading the unused pages under this rule

Each of these needs a present-tense redesign rather than removal:

- **Monthly review** — retrospective prompts are the wrong tense. What would be
  useful mid-month is a month-at-a-glance *reference*: mini calendar, this
  month's configured events, linked week chips, open space. That is close to the
  unused `MonthlyOverview` class (§4.1), which means the month-view gap and the
  monthly-review failure are the same problem with one solution.

- **Future log** — fails because capture requires first deciding *when*. An
  undated capture surface ("things that will matter later") is lower friction
  than twelve month buckets. Worth testing before assuming the construct itself
  is wrong.

- **Index** — a hand-maintained index is pure overhead for this user, on top of
  being structurally impossible without page numbers (§3.1). The auto-generated
  `visual_toc` is the zero-maintenance answer.

- **Collections** — blank dot grid, unreachable (§3), no tab. Capture has to be
  possible from wherever you are, or it will not happen.

- **Grid pages** — eight one-off templates at the back is a library demo. A
  present-tense user wants scratch space *where they are*: fewer grid types,
  more copies, interleaved through the year rather than pooled at the end.

- **Quarterly planning** — used once, in Q1, the classic new-year burst. Fold
  the useful part (the linked 12-week grid) into the month page and drop the
  goal prompts, or make it much lighter.

- **Year highlights** — superseded by year events in practice (§4.2). Collapse.

- **Tracker example** — a brochure, not a tool (§5). Make it real or make it
  twelve.

### 9.4 The prerequisite

Navigation (§3) is the cheapest and highest-leverage item, and it gates most of
the above. A present-tense user will not navigate to a page that cannot be
reached in one tap from where they are standing. Roughly 35 pages are currently
dead ends. Fixing chrome on those pages is a small change that makes every
content redesign above actually reachable.
