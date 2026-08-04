# Design system reference

Everything a fragment author needs: the shape of the document, the component
vocabulary, the diagram conventions, and the gotchas that produce silent damage.

---

## 1. Why the page looks like this

| Decision | Reason |
|---|---|
| 157 × 210 mm (3:4) | fills a reMarkable screen without letterboxing |
| Greyscale only, including diagrams | e-ink renders colour as indistinct mid-greys, so meaning must be carried by shape, weight, fill density and dash |
| One typeface (EB Garamond) for body, headings, captions, tables, contents, running heads and diagram labels | hierarchy from size, weight, italic and small caps; a second family is the fastest way to make a document look templated |
| 10.6 pt on 1.52 leading at ~127 mm measure | e-ink has lower effective contrast than paper; tight leading reads as muddy |
| JetBrains Mono, static TTF | variable fonts render poorly in WeasyPrint |

**Non-goals.** No colour accents, drop shadows, rounded corners, icon sets, background
textures, sans-serif headings, or centred body text. If you find yourself reaching for a
visual flourish, add an explanatory sentence instead.

---

## 2. Document architecture

Structure in **parts** (full-bleed divider page) → numbered **chapters** → numbered
**sections**. A four-part shape that works for a decision brief:

| Part | Deliverable |
|---|---|
| At a Glance (front matter) | two or three `keypanel` blocks answering the questions the document is most often opened for — worth it above ~60 pages |
| I — Foundations | shared vocabulary. Define every term from the ground up; assume nothing |
| II — The Forces | measured facts, contested arguments, threat model: what constrains the decision |
| III — The Situation | the reader's actual context: existing estate, real constraints, organisational reality |
| IV — The Recommendation | reference architecture, build/buy per layer, phased plan, decision register |
| Appendices | glossary grouped by layer; source register graded by evidential weight |

### Numbering and anchoring

- Chapters: `id="chN"`, `data-bm="N. Title"`.
- Sections: `id="sN-M"`, `<h2>` text reading `N.M Title` — **verbatim identical** to the
  contents line, or the page number silently disappears.
- Part dividers: `id="partN"`, `data-bm="Part N — Title"`.
- Figures numbered **continuously across the whole document**, never per chapter.

### Renumbering discipline

Inserting a chapter mid-document: renumber **in descending order** (23→24, then 22→23,
then 21→22) or the replacements collide. Update in this order — chapter `id`, `data-bm`
prefix, the `<span class="num">Chapter Twenty-Three</span>` word form, every `<h2>N.M`,
every prose cross-reference (`Chapter 21`, `§21.3`), every figure number after the
insertion point, the contents. Then grep for stale references; `check.py` catches the
anchor half, not the prose half.

---

## 3. Component vocabulary

Use these and only these. Each has a distinct rhetorical job; reaching for the wrong one
is how documents start to look generic. An undefined class renders unstyled and nothing
warns you — `check.py` is what catches it.

| Component | Markup | Use for |
|---|---|---|
| Lead paragraph | `<p class="lead">` | one per chapter, straight after the `h1`; states what the chapter is for |
| Definition | `<div class="defn"><span class="term">Term</span><p>…</p></div>` | the first formal definition of a term |
| Grounded quote | `<div class="quote"><p class="q-text">…</p><p class="q-src"><span class="who">Name</span>, role, <em>Work</em>, date<span class="url">domain/path</span></p></div>` | verbatim source material, always with attribution *and* URL |
| Box | `<div class="box"><div class="box-title">…</div>…</div>` | a caveat, an aside, a "how to recognise this" note |
| Dark box | `<div class="box dark">` | a conclusion that must not be skimmed past — one per chapter |
| Plain box | `<div class="box plain">` | a rule-bounded aside with no fill |
| Key panel | `<div class="keypanel"><div class="kp-head">Title <span class="kp-tag">developed in ch. N</span></div><div class="kp-body"><p class="kp-punch">…</p>…</div></div>` | the two to four load-bearing statements of the whole document |
| Figure | `<figure><svg…></svg><figcaption><span class="fignum">Figure N.</span> …</figcaption></figure>` | any diagram |
| Walkthrough | `<div class="readfig"><div class="rf-title">Reading Figure N</div><ol>…</ol></div>` | **mandatory** after every figure |
| Table | `<table>` / `<table class="long">` + `<p class="tcap">` | comparisons; `long` only if it must break across pages |
| Pros/cons | `<table class="proscons">` with `<li class="plus">` / `<li class="minus">` | two-sided decisions; the `+`/`–` markers come from CSS |
| Before/after | `<table class="beforeafter">` with `<td class="was">` | what a change obsoletes; `was` strikes through |
| Code | `<pre><code>` + `<p class="codecap">` | always captioned; `class="long"` if it may break |
| Glossary | `<dl class="gloss">` | appendix A only |
| Source register | `<ul class="srclist">` with `<span class="sid">[S1]</span>` and `<span class="srcline">url</span>` | appendix B only |
| Section break | `<hr class="sec">` | a beat inside a section, used sparingly |
| Small caps | `<span class="sc">must</span>` | normative keywords in prose |

### Prose rules

- British English. Em dashes with spaces around them, written `&mdash;`.
- `&rsquo;`, `&ldquo;`, `&rdquo;` — never straight quotes in prose.
- Justification and hyphenation are set in CSS; do not override them.
- Every chapter opens with a `lead` and ends without a summary — the next chapter's lead
  does that work.
- Itemise, do not summarise: if a construct has nine fields, the document has a nine-row
  table with a column for what each field *is* and a column for what its *job* is.

### Density floors for a substantial chapter

1,800–2,800 words of prose · 2–5 tables · 3–7 captioned code blocks · 2–4 grounded
quotes · 3–8 definitions · 1–2 boxes · at most one dark box · the figures allocated to
it, each with a walkthrough. These are floors, not caps.

---

## 4. Diagram conventions

Hand-authored inline SVG. No diagramming library, no generated images, no Mermaid —
none give the typographic control needed to sit inside a book page.

### Geometry

```html
<svg viewBox="0 0 480 H" width="480" height="H" xmlns="http://www.w3.org/2000/svg">
```

480 px ≈ the 127 mm text column at 96 dpi, so **1 SVG unit = 1 px on the page**. `H` is
usually 190–300; above ~320 the figure cannot share a page with its walkthrough.

### Palette — greyscale, semantic

| Role | Fill | Stroke |
|---|---|---|
| Ordinary element | `#ffffff` | `#111` at 0.7–0.8 |
| Existing / given / infrastructure | `#e6e6e6`–`#ededed` | `#111` at 0.7 |
| Selected / emphasised | `#cfcfcf` | `#111` at 0.7 |
| Focus of the diagram | `#2f2f2f` with `#fff` text | `#111` at 0.8 |
| Bad / disabled / removed | `#c0c0c0` | `#111`, `stroke-dasharray:2.5 1.5` |
| Connector | none | `#111` at 0.85–0.9 |
| Weak / optional connector | none | `#777` at 0.6, dashed `3 2` |

Encode meaning in visual properties: **line weight for volume** (3 px for "lots of data
crosses here" against 0.7 px for "a little"), **dash for optional or broken**, **fill
density for emphasis**.

### Typography inside SVG

```html
<style>
  .l{font-family:"EB Garamond",serif;font-size:9px;fill:#111}
  .lc{font-family:"EB Garamond",serif;font-size:9px;fill:#111;text-anchor:middle}
  .t{font-family:"EB Garamond",serif;font-size:9.6px;fill:#111;text-anchor:middle;font-weight:bold}
  .s{font-family:"EB Garamond",serif;font-size:7.8px;fill:#555;text-anchor:middle}
  .m{font-family:"JetBrains Mono",monospace;font-size:7.2px;fill:#111;text-anchor:middle}
  .b{fill:#fff;stroke:#111;stroke-width:0.8}
  .bg{fill:#ececec;stroke:#111;stroke-width:0.7}
  .bd{fill:#2f2f2f;stroke:#111;stroke-width:0.8}
  .a{stroke:#111;stroke-width:0.9;fill:none}
</style>
```

Titles 9.4–9.8 px · body labels 8.2–9.5 px · annotations 7.1–8 px · monospace 6.8–7.4 px.
White text on the dark fill must be set with `style="fill:#fff"` — an attribute
`fill="#fff"` loses to the class, which is a defect `check.py` reports.

### Arrowheads

**Do not use SVG `<marker>`.** WeasyPrint's support is unreliable. Draw every head:

```html
<path d="M92 44 L138 44" class="a"/>
<polygon points="144,44 136,40.5 136,47.5" fill="#111"/>   <!-- right -->
<polygon points="44,44 52,40.5 52,47.5" fill="#111"/>      <!-- left  -->
<polygon points="44,90 40.5,82 47.5,82" fill="#111"/>      <!-- down  -->
```

### Six layouts that work

1. **Before/after split** — vertical `#bbb` rule at x=240, bold title over each half, the
   same elements drawn twice with different treatment.
2. **Layer stack** — full-width bands, numbered on the left, the layer that matters dark.
3. **Pipeline** — boxes left to right with polygon arrows, dashed return path beneath.
4. **Two-axis quadrant** — two orthogonal concerns, and why only one quadrant is coherent.
5. **Sequence** — participants across the top, dashed lifelines descending, steps as
   monospace digits down the left margin.
6. **Bar chart** — hand-plotted bars, light `#ddd` gridlines, values right-aligned in
   monospace outside each bar.

Most diagrams benefit from a full-width summary bar at the bottom stating the single
conclusion the reader should take away.

### The walkthrough — mandatory

4–6 numbered points, each opening with a bolded claim, covering roughly in order:

1. what the most visually prominent element is, and why it is prominent;
2. what a specific visual property *encodes* (weight, shading, dashing);
3. the relationship or growth rate the diagram is really about;
4. what the diagram deliberately does **not** show;
5. the one sentence the reader should leave with.

Write them as if talking a colleague through the picture. They are the highest-value
prose in the document.

---

## 5. Gotchas

1. **`counter-reset: page` silently breaks `target-counter(attr(href), page)`.** Every
   TOC entry collapses to `1` with no warning, and the footer does not reset either.
   Hence the two-pass build; page numbering runs continuously from the title page.
2. **`bookmark-label` defaults to `content()`**, which concatenates children without
   spaces: `Chapter OneHow to Read This`. Always `bookmark-label: attr(data-bm)`.
3. **Running heads have the same defect.** `string-set: runhead attr(data-bm)`.
4. **WeasyPrint gives every `h1`–`h6` a bookmark level**, so the title-page heading
   becomes the root and everything nests under it. `bookmark-level: none` on title and
   part titles.
5. **SVG `<marker>` is unreliable.** Polygons.
6. **No maths typesetting.** `$O(n)$` renders literally; write `<em>O</em>(n)`.
7. **Variable fonts render poorly.** Static TTFs only.
8. **`page-break-inside: avoid` on a tall element** pushes it wholesale to the next page
   and leaves a hole. Allow the break; set `page-break-after: avoid` on its header.
9. **Missing fonts do not error.** Verify with `fc-list` before the first build and with
   `verify_pdf.py` after every build.
10. **Grep for stale cross-references after any renumbering** — `Chapter 17`, `§17.3`,
    `#ch17`, `Figure 19`, `Reading Figure 19` all move together.
11. **macOS only:** WeasyPrint `dlopen()`s pango at import time and dyld reads
    `DYLD_FALLBACK_LIBRARY_PATH` only from the process environment. Setting it inside
    Python is too late; `make.sh` exports it before the interpreter starts.
