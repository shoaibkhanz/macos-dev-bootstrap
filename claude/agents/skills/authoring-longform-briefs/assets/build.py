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
    return 0


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
