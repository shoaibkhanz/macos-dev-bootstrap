#!/usr/bin/env python3
"""Assemble ordered HTML fragments and render them to PDF via WeasyPrint.

Why two passes
--------------
A table of contents with real page numbers cannot be built with CSS leaders
alone.  ``target-counter(attr(href), page)`` silently collapses every entry to
``1`` as soon as any element carries ``counter-reset: page`` -- and it fails
without erroring, so the document *looks* built.  The renderer therefore runs
in a loop: render, read the anchor-to-page map out of
``document.pages[i].anchors``, inject those numbers onto the TOC anchors as
``data-pg`` attributes, render again.  Injecting numbers changes line lengths,
which can change pagination, so the loop repeats until the map is identical to
the previous pass (usually 2-3 passes) or ``--max-passes`` is hit.

Fragments are discovered, not listed: every ``NN*.html`` in the build
directory, in filename order.  A fragment that does not exist yet is simply
absent, so a half-written document still renders -- which is what makes it
possible to build early and often.  ``_combined.html`` is generated output;
never edit it.

Usage
-----
    python3 build.py                        # -> out/<dirname>.pdf
    python3 build.py --out ~/Desktop/x.pdf
    python3 build.py --dir /path/to/build --max-passes 8
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from weasyprint import HTML

FRAGMENT_RE = re.compile(r"^\d.*\.html$")
ANCHOR_RE = re.compile(r'<a\s+href="#([A-Za-z0-9_.:-]+)"((?:\s+[^>]*?)?)>')
DATA_PG_RE = re.compile(r'\s+data-pg="[^"]*"')
# Components drawn with a border on all four sides: a break inside one leaves the border
# open at the page edge and drops the padding, so the body text touches the rule.
# `readfig` is deliberately absent -- it is ruled on one edge only and breaks cleanly.
BORDERED_COMPONENTS = {"keypanel", "box", "defn", "quote", "proscons"}


def fragments(build_dir: Path) -> list[Path]:
    """Ordered fragment list: every NN*.html in the directory, by filename."""
    return sorted(
        path
        for path in build_dir.glob("*.html")
        if FRAGMENT_RE.match(path.name) and path.name != "_combined.html"
    )


def assemble(build_dir: Path) -> str:
    """Concatenate the fragments and close the document opened by fragment 00."""
    chunks: list[str] = []
    for path in fragments(build_dir):
        chunks.append(path.read_text(encoding="utf-8"))
        print(f"  [ok]   {path.name}")
    if not chunks:
        raise SystemExit(f"no fragments found in {build_dir} (expected NN_*.html)")
    chunks.append("\n</body>\n</html>\n")
    return "\n".join(chunks)


def displayed_numbers(document) -> dict[str, int]:
    """Map each anchor name to the page number printed in the footer.

    The footer prints the physical page counter, which runs continuously from
    the title page, so physical index + 1 is the displayed number.  Do not
    restart the counter in CSS: see the module docstring.
    """
    physical: dict[str, int] = {}
    for index, page in enumerate(document.pages):
        for name in page.anchors:
            physical.setdefault(name, index)
    return {name: index + 1 for name, index in physical.items()}


def inject_toc_numbers(html: str, numbers: dict[str, int]) -> str:
    """Write computed page numbers onto internal anchors as ``data-pg``."""

    def replace(match: re.Match[str]) -> str:
        target, rest = match.group(1), DATA_PG_RE.sub("", match.group(2))
        page = numbers.get(target)
        if page is None:
            return f'<a href="#{target}"{rest}>'
        return f'<a href="#{target}"{rest} data-pg="{page}">'

    return ANCHOR_RE.sub(replace, html)


def _descendants(box):
    yield box
    for child in getattr(box, "children", ()) or ():
        yield from _descendants(child)


def audit_layout(document) -> int:
    """Report boxes that break the page frame.  Returns the defect count.

    Neither ``check.py`` (source text) nor ``verify_pdf.py`` (PDF objects) can see
    geometry, so this is the only place a table that runs off the right edge of the
    paper, or a bordered component that has quietly become three pages long, is
    detectable.  Both were shipped undetected once.
    """
    mm = 96 / 25.4
    wide: list[tuple[int, float, str]] = []
    spans: dict[int, tuple[str, list[int]]] = {}

    for number, page in enumerate(document.pages, start=1):
        page_box = page._page_box
        limit = page_box.content_box_x() + page_box.width
        worst: tuple[float, str] | None = None
        for box in _descendants(page_box):
            element = getattr(box, "element", None)
            if element is None or element.tag in ("html", "body"):
                continue
            try:
                overhang = box.position_x + box.margin_width() - limit
            except (AttributeError, TypeError):
                continue
            if overhang > 0.5 and (worst is None or overhang > worst[0]):
                classes = (element.get("class") or "").split()
                label = element.tag + ("." + ".".join(classes) if classes else "")
                worst = (overhang, label)
            names = set((element.get("class") or "").split())
            if names & BORDERED_COMPONENTS:
                key = id(element)
                label = sorted(names & BORDERED_COMPONENTS)[0]
                spans.setdefault(key, (label, []))[1].append(number)
        if worst is not None:
            wide.append((number, worst[0], worst[1]))

    split = [(label, sorted(set(pages))) for label, pages in spans.values() if len(set(pages)) > 1]

    print("\nLayout audit:")
    for number, overhang, label in wide:
        print(f"  overflow  p{number}: <{label}> runs {overhang / mm:.1f}mm past the measure")
    for label, pages in split:
        print(f"  split box .{label} spans pages {pages}")
    defects = len(wide) + len(split)
    print(f"  {defects} layout defect(s)" if defects else "  no layout defects")
    return defects


def build(build_dir: Path, out_pdf: Path, max_passes: int) -> int:
    print("Assembling fragments:")
    base_html = assemble(build_dir)
    combined = build_dir / "_combined.html"
    out_pdf.parent.mkdir(parents=True, exist_ok=True)

    html: str = base_html
    previous: dict[str, int] = {}
    document = None
    for attempt in range(1, max_passes + 1):
        combined.write_text(html, encoding="utf-8")
        document = HTML(filename=str(combined)).render()
        numbers = displayed_numbers(document)
        print(f"  pass {attempt}: {len(document.pages)} pages, {len(numbers)} anchors")
        if numbers == previous:
            print("  pagination stable")
            break
        previous = numbers
        html = inject_toc_numbers(base_html, numbers)
    else:
        print("  warning: pagination did not stabilise; TOC numbers may be off by one")
        combined.write_text(html, encoding="utf-8")
        document = HTML(filename=str(combined)).render()

    document.write_pdf(str(out_pdf))
    print(f"\n  pages : {len(document.pages)}")
    print(f"  size  : {out_pdf.stat().st_size / 1024:,.0f} KB")
    print(f"  path  : {out_pdf}")
    # The PDF is written either way: a layout defect is worth reading the report over,
    # not worth withholding the artefact you need in order to look at it.
    return 2 if audit_layout(document) else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Render ordered HTML fragments to a print-quality PDF.")
    parser.add_argument("--dir", type=Path, default=Path(__file__).parent,
                        help="build directory holding the fragments")
    parser.add_argument("--out", type=Path, default=None,
                        help="output PDF path (default: <dir>/out/<dirname>.pdf)")
    parser.add_argument("--max-passes", type=int, default=6)
    args = parser.parse_args(argv)

    build_dir = args.dir.expanduser().resolve()
    out_pdf = args.out or build_dir / "out" / f"{build_dir.name}.pdf"
    return build(build_dir, out_pdf.expanduser().resolve(), args.max_passes)


if __name__ == "__main__":
    sys.exit(main())
