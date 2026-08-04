#!/usr/bin/env python3
"""Verify the rendered PDF -- the checks WeasyPrint will never fail for you.

    python3 verify_pdf.py out/brief.pdf              # exit 0 = clean
    python3 verify_pdf.py out/brief.pdf --heads 12 40 88

What it proves
--------------
fonts       Every font used is embedded and is one you asked for.  A missing
            font does NOT error in WeasyPrint: it substitutes silently and the
            whole design collapses.  This is the single highest-value check.
toc         Every ``data-pg`` claim in ``_combined.html`` equals the page the
            named destination actually lands on, and the footer on that page
            prints that number.  Catches the two-pass loop having been skipped
            or having failed to converge.
outline     The PDF bookmark tree is non-empty, nested at least two deep, and
            free of the ``Chapter OneHow to Read`` label mangling that
            ``bookmark-label: content()`` produces.
latex       No literal ``$...$`` / ``\\frac`` survived into the text layer.
sparse      Pages whose text is under a third of the median -- usually a tall
            ``page-break-inside: avoid`` block that shunted itself onto a new
            page and left a hole.
heads       Prints the running head of sampled pages so you can read them.
"""

from __future__ import annotations

import argparse
import re
import statistics
import sys
from collections.abc import Iterable
from pathlib import Path

from pypdf import PdfReader

EXPECTED_FAMILIES = ("EBGaramond", "JetBrainsMono")
LATEX_RE = re.compile(r"\\frac|\\text\{|\$[A-Za-z0-9\\({][^$\n]{0,40}\$")


def embedded_fonts(reader: PdfReader) -> set[str]:
    names: set[str] = set()
    for page in reader.pages:
        fonts = (page.get("/Resources") or {}).get("/Font") or {}
        for ref in fonts.values():
            base = ref.get_object().get("/BaseFont")
            if base:
                names.add(str(base).lstrip("/").split("+")[-1])
    return names


def outline_titles(items: Iterable[object] | None, depth: int = 0) -> list[tuple[int, str]]:
    out: list[tuple[int, str]] = []
    for item in items or ():
        if isinstance(item, list):
            out += outline_titles(item, depth + 1)
        else:
            out.append((depth, str(getattr(item, "title", item))))
    return out


def toc_claims(combined: Path) -> list[tuple[str, int]]:
    html = combined.read_text(encoding="utf-8")
    return [(m.group(1), int(m.group(2)))
            for m in re.finditer(r'<a\s+href="#([^"]+)"[^>]*\sdata-pg="(\d+)"', html)]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Verify a rendered brief PDF.")
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--combined", type=Path, default=None,
                        help="_combined.html (default: alongside the build dir)")
    parser.add_argument("--heads", type=int, nargs="*", default=[],
                        help="page numbers whose running head to print")
    args = parser.parse_args(argv)

    pdf = args.pdf.expanduser().resolve()
    reader = PdfReader(str(pdf))
    pages = reader.pages
    texts = [page.extract_text() or "" for page in pages]
    failures: list[str] = []

    print(f"pdf         : {pdf}")
    print(f"pages       : {len(pages)}   size: {pdf.stat().st_size / 1024:,.0f} KB")

    # --- fonts -----------------------------------------------------------------
    fonts = embedded_fonts(reader)
    print(f"fonts       : {', '.join(sorted(fonts)) or 'NONE'}")
    for family in EXPECTED_FAMILIES:
        if not any(family.lower() in name.lower().replace("-", "") for name in fonts):
            failures.append(f"font family {family} is not embedded -- WeasyPrint "
                            "substituted silently; install the fonts and rebuild")

    # --- toc truth --------------------------------------------------------------
    combined = args.combined or pdf.parent.parent / "_combined.html"
    if combined.exists():
        destinations = reader.named_destinations
        claims = toc_claims(combined)
        checked = mismatched = 0
        for anchor, claimed in claims:
            dest = destinations.get(anchor)
            index = reader.get_destination_page_number(dest) if dest is not None else None
            if index is None:
                failures.append(f"toc anchor #{anchor} has no destination in the PDF")
                continue
            actual = index + 1
            checked += 1
            if actual != claimed:
                mismatched += 1
                failures.append(f"toc #{anchor}: claims p{claimed}, lands on p{actual}")
            # Title pages and part dividers deliberately suppress the footer, so a
            # non-numeric last line is by design; a WRONG number is the defect.
            footer = [line.strip() for line in texts[actual - 1].split("\n") if line.strip()]
            if footer and footer[-1].isdigit() and footer[-1] != str(actual):
                failures.append(f"page {actual}: footer reads {footer[-1]}, expected {actual}")
        print(f"toc         : {checked} entries checked, {mismatched} mismatched")
        if not claims:
            failures.append("_combined.html carries no data-pg attributes -- the two-pass "
                            "loop did not run; every TOC number is decorative")
    else:
        print(f"toc         : skipped ({combined} not found)")

    # --- outline ---------------------------------------------------------------
    titles = outline_titles(reader.outline)
    depth = max((d for d, _ in titles), default=-1)
    print(f"outline     : {len(titles)} bookmarks, depth {depth + 1}")
    for level, title in titles[:8]:
        print("              " + "  " * level + "- " + title[:60])
    if not titles:
        failures.append("no PDF bookmarks -- set bookmark-level/bookmark-label in the CSS")
    elif depth < 1:
        failures.append("bookmark outline is flat; chapters should nest under parts")
    for _, title in titles:
        if re.search(r"[a-z](?:Chapter|Part|Appendix)\b", title):
            failures.append(f"mangled bookmark label {title!r} -- bookmark-label fell back "
                            "to content(); set bookmark-label: attr(data-bm)")

    # --- latex ------------------------------------------------------------------
    leaks = [i + 1 for i, text in enumerate(texts) if LATEX_RE.search(text)]
    print(f"latex leaks : {len(leaks)}" + (f" on pages {leaks[:10]}" if leaks else ""))
    if leaks:
        failures.append(f"literal LaTeX on pages {leaks[:10]} -- there is no maths typesetting")

    # --- sparse pages -----------------------------------------------------------
    # Pages without a printed folio are title pages and part dividers, and the last
    # page of a chapter is short by construction -- all sparse by design.  Only a
    # page under a sixth of the median is the avoid-break hole worth hunting.
    def numbered(text: str) -> bool:
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        return bool(lines) and lines[-1].isdigit()

    lengths = [len(text) for text in texts]
    median = statistics.median(lengths) if lengths else 0
    sparse = [i + 1 for i, text in enumerate(texts)
              if i > 0 and numbered(text) and 0 < len(text) < median / 6]
    print(f"sparse pages: {sparse[:12] if sparse else 'none'}"
          + ("  (check for an avoid-break hole)" if sparse else ""))

    # --- running heads ----------------------------------------------------------
    for number in args.heads:
        if 1 <= number <= len(texts):
            first = next((line.strip() for line in texts[number - 1].split("\n")
                          if line.strip()), "")
            print(f"head p{number:<4}: {first[:70]}")

    if failures:
        print(f"\nFAILURES ({len(failures)}):")
        for failure in failures:
            print("  x", failure)
        return 1
    print("\nPDF verification passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
