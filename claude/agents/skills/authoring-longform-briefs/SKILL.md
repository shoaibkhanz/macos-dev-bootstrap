---
name: authoring-longform-briefs
description: Use when producing a print-quality long-form PDF — technical brief, monograph, course reader, handbook, book — from HTML/CSS via WeasyPrint, or when the request mentions weasyprint, print CSS, an e-ink/reMarkable document, a contents page with real page numbers, PDF bookmarks, or hand-authored greyscale SVG diagrams.
---

# Authoring long-form briefs

## Overview

A reproducible pipeline for a **157 × 210 mm, greyscale, EB Garamond** PDF that reads
like an academic monograph on an e-ink tablet and can be annotated by hand. The design
system, renderer, and both verification passes ship with this skill — you write prose
and SVG, nothing else.

Two rules carry more weight than the rest of this document combined:

- **Define before you use.** If the document says a word, the document has already
  explained that word. This is what lets one text serve a newcomer and an expert.
- **Explain every picture.** A figure without its numbered walkthrough is decoration.
  The walkthrough is where the argument actually lands.

## Quick start

```bash
SKILL=~/.claude/skills/authoring-longform-briefs
$SKILL/scripts/install-fonts.sh                       # once per machine
$SKILL/scripts/new-brief.sh ~/work/my-brief "Title" "Subtitle"
cd ~/work/my-brief && ./make.sh                       # check → render → verify
```

`new-brief.sh` copies the design system, creates a venv, and renders a valid
ten-page skeleton **before you have written anything**. Author into that skeleton.

## The loop

1. Write the contents in `00_front.html` first. Its anchors are the contract: every
   `<a href="#id">` must be matched by exactly one `id="id"` somewhere, and every
   `<h2 id="sN-M">` title must match its TOC line **verbatim**.
2. Add one fragment at a time: `NN_*.html`, discovered automatically in filename order.
3. `./make.sh` after every fragment. It is three seconds and it fails loudly.
4. Read the failures. Both checkers only report things that silently corrupt the book.

| Command | Proves |
|---|---|
| `./make.sh` | the whole loop: structure, render, PDF |
| `python3 check.py` | anchors, figure/walkthrough pairing, greyscale, class typos, tag balance, emphasis budget |
| `python3 verify_pdf.py out/x.pdf` | fonts actually embedded, TOC numbers true, bookmark tree nested, no LaTeX leak, no half-empty pages |

**The font check is the one that saves the document.** A missing font never errors;
WeasyPrint substitutes silently and the entire design collapses.

## Fragment contract

Fragment `00_front.html` opens `<html><head><body>` and never closes them; the build
appends the closing tags. **Every other fragment is a bare sequence of block elements** —
no doctype, no `<script>`, no `<img>`, no Mermaid, no LaTeX, no class the stylesheet
does not define.

```html
<div class="part" id="partN" data-bm="Part N &mdash; Title">…</div>

<h1 class="chapter" id="chN" data-bm="N. Short Title">
  <span class="num">Chapter Seven</span>
  The full chapter title
</h1>
<p class="lead">What this chapter is for. Never a summary of its conclusions.</p>

<h2 id="sN-M">N.M The section title</h2>
```

`data-bm` is not optional: it feeds both the PDF bookmark and the running head. Without
it you get `Chapter SevenThe full chapter title` in the outline.

## Emphasis is a budget

| Level | Component | Promote when | Budget (≈100 pp) |
|---|---|---|---|
| 1 | bold run-in | it is the claim of that paragraph | freely |
| 2 | `defn` | first formal definition of a term | every term, once |
| 3 | `box` | a reader could act correctly without it, but better with it | 1–2 per chapter |
| 4 | `quote` | the exact wording carries the weight | ~1 per major claim |
| 5 | `box dark` | a reader who skims past this reaches the **wrong** conclusion | **1 per chapter max** |
| 6 | `keypanel` | reading only this panel still yields the right decision | **2–4 in the document** |

Wanting a second dark box in a chapter means the chapter has two points and should be
two chapters. Title the loud elements with a **claim**, not a topic: "The property
everything else follows from", not "Security considerations".

## Diagrams

Hand-authored inline SVG on a `viewBox="0 0 480 H"` grid (480 px = the 127 mm text
column, so 1 unit = 1 px). Greyscale only — encode meaning in **line weight** (volume),
**dash** (optional or broken), **fill density** (emphasis). Draw arrowheads as
`<polygon>`; WeasyPrint's `<marker>` support is unreliable. Every figure is followed by
a `readfig` block of 4–6 numbered points, each opening with a bolded claim.

Full palette, label sizes, the six layouts that work, and the walkthrough recipe:
**`reference/design-system.md`**.

## Where the credibility comes from

The pipeline produces a well-set document; the method produces one worth reading.
Read **`reference/editorial-method.md`** before drafting. Its non-negotiables:

- Every load-bearing claim carries a name, a date and a URL — a reader must be able to
  check you.
- Search to orient, then read the primary source. Replacing commentary with the
  specification it described is the highest-yield research move there is.
- Report the **status field** and the **date** of anything with a lifecycle.
- Go looking for the counter-evidence and put it in. If your conclusions never moved
  during research, you were not researching.
- Name the commercial interest, once, plainly.
- State what your recommendation does **not** fix. Close with what you could not answer.

## Parallel authoring

For a long document, dispatch **one subagent per fragment**, each carrying: the exact
`id`s and `<h2>` titles from the contents, its figure numbers, the component vocabulary,
and this instruction — *write exactly one file; never touch `style.css`, `build.py`,
another fragment, or the source repository*. Figures are numbered **continuously across
the document**, so allocate ranges up front. Build and check only after the batch lands;
mid-flight builds just make agents collide.

## Gotchas that cost hours

| Symptom | Cause |
|---|---|
| Every TOC entry reads `1` | `counter-reset: page` breaks `target-counter`. Use the two-pass build; never restart the page counter. |
| Bookmark reads `Chapter OneHow to Read` | `bookmark-label` defaulted to `content()`. Set `attr(data-bm)`. |
| Running head is mangled the same way | `string-set: runhead attr(data-bm)`, not `content()`. |
| Everything nests under the title page | WeasyPrint gives every `h1`–`h6` a bookmark level. `bookmark-level: none` on title and part titles. |
| Arrowheads missing | SVG `<marker>`. Use polygons. |
| `$O(n)$` in the PDF | There is no maths typesetting. Write `<em>O</em>(n)`. |
| Page mostly blank | A tall `page-break-inside: avoid` block. Allow the break; put `page-break-after: avoid` on its header instead. |
| Design looks generic | A font silently substituted. `verify_pdf.py` catches it; `fc-list` confirms it. |
| macOS: `cannot load library 'libgobject-2.0-0'` | `DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib` must be set **before** python starts. `make.sh` does this. |

## Files

| Path | Role |
|---|---|
| `assets/style.css` | the design system — copy unchanged, never edit per-document |
| `assets/build.py` | fragment discovery + two-pass render |
| `assets/check.py` | ten structural checks on the HTML, pre-render |
| `assets/verify_pdf.py` | fonts, TOC truth, bookmarks, LaTeX, sparse pages, post-render |
| `assets/make.sh` | the three of them in order, with the macOS dyld fix |
| `assets/templates/` | four fragments that already render and demonstrate every component |
| `scripts/new-brief.sh` | scaffold a buildable brief in one command |
| `scripts/install-fonts.sh` | EB Garamond + JetBrains Mono, from GitHub, with verification |
| `reference/design-system.md` | components, diagrams, structure, renumbering discipline |
| `reference/editorial-method.md` | research, grounding, emphasis, argument construction |

## Adapting to another subject

Copy `style.css` and `build.py` unchanged; rewrite the front matter; choose a part
structure (*Foundations → Forces → Situation → Recommendation* for a decision brief;
*Foundations → Mechanics → Worked Examples → Reference* for a tutorial; *Background →
Methods → Findings → Implications* for a review). Keep the ratios: a figure every 5–6
pages, one grounded quote per major claim, one dark box per chapter. Keep both
appendices — a glossary grouped by layer and a source register graded by evidential
weight are what make the document usable six months later.
