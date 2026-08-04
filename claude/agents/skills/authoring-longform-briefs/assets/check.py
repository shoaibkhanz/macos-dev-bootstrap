#!/usr/bin/env python3
"""Structural verification of the HTML fragments, before rendering.

Every check here has caught a real defect in a real book.  They are cheap, they
run in under a second, and each one covers a failure mode that WeasyPrint does
NOT report: unstyled text, a lost TOC page number, a figure with no
walkthrough, a colour that turns to mud on e-ink.

Run it before every render and again after every fix:

    python3 check.py            # exit 0 = clean, 1 = problems
    python3 check.py --dir /path/to/build

Checks
------
 1  forbidden constructs in fragments (script/img/marker/mermaid/LaTeX/fences)
 2  tag balance, per fragment
 3  every TOC anchor exists exactly once; <h2> titles match the TOC verbatim
 4  figure numbers form a gapless sequence and each has a walkthrough
 5  greyscale only -- any non-grey hex is a defect
 6  <text class=... fill=...> in SVG (the class wins; the fill is a lie)
 7  class whitelist, derived from style.css plus per-fragment SVG <style>
 8  emphasis budget: <=1 dark box per chapter, keypanel only in front matter
 9  chapter/part shape: id + data-bm present (bookmark and running head)
10  straight quotes and apostrophes in prose (typographic hygiene)
"""

from __future__ import annotations

import argparse
import html as htmllib
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

FRAGMENT_RE = re.compile(r"^\d.*\.html$")

VOID = {"br", "hr", "img", "meta", "link", "input", "col", "source",
        "path", "polygon", "rect", "circle", "line", "ellipse", "polyline",
        "use", "stop", "image"}

FORBIDDEN = [
    (r"<script", "script tag"),
    (r"<img", "raster image (all art is inline SVG)"),
    (r"<marker", "SVG <marker> (unreliable in WeasyPrint; draw polygons)"),
    (r"</?html|</?head|</?body", "document-level tag in a body fragment"),
    (r"```", "markdown fence"),
    (r"\bmermaid\b", "mermaid reference"),
    (r"\\frac|\\text\{", "LaTeX (there is no maths typesetting)"),
]


class Balance(HTMLParser):
    """Tag-balance checker that tolerates HTML void elements and SVG."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.stack: list[tuple[str, int]] = []
        self.errors: list[str] = []

    def handle_starttag(self, tag: str, attrs: object) -> None:
        if tag not in VOID:
            self.stack.append((tag, self.getpos()[0]))

    def handle_startendtag(self, tag: str, attrs: object) -> None:
        return

    def handle_endtag(self, tag: str) -> None:
        if tag in VOID:
            return
        if not self.stack:
            self.errors.append(f"line {self.getpos()[0]}: stray </{tag}>")
            return
        if self.stack[-1][0] != tag:
            open_tag, line = self.stack[-1]
            self.errors.append(
                f"line {self.getpos()[0]}: </{tag}> closes <{open_tag}> opened at {line}")
            return
        self.stack.pop()


def stylesheet_classes(build_dir: Path) -> set[str]:
    """Every class name the stylesheet defines -- the vocabulary you may use."""
    css = (build_dir / "style.css").read_text(encoding="utf-8")
    css = re.sub(r"/\*.*?\*/", " ", css, flags=re.S)
    selectors = " ".join(re.findall(r"([^{}]+)\{", css))
    return set(re.findall(r"\.([A-Za-z][\w-]*)", selectors))


def toc_entries(front: str) -> tuple[list[str], dict[str, str]]:
    """Anchors and link text from the table of contents in the front matter."""
    ids: list[str] = []
    titles: dict[str, str] = {}
    for anchor, text in re.findall(r'<a href="#([A-Za-z0-9_-]+)"[^>]*>(.*?)</a>', front):
        ids.append(anchor)
        titles[anchor] = text
    return ids, titles


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Structural checks on the HTML fragments, before rendering.")
    parser.add_argument("--dir", type=Path, default=Path(__file__).parent)
    args = parser.parse_args(argv)
    build = args.dir.expanduser().resolve()

    problems: list[str] = []
    notes: list[str] = []

    paths = sorted(p for p in build.glob("*.html")
                   if FRAGMENT_RE.match(p.name) and p.name != "_combined.html")
    if not paths:
        print(f"no fragments in {build}")
        return 1
    front_path = paths[0]
    present = {p.name: p.read_text(encoding="utf-8") for p in paths}
    body_parts = [(name, text) for name, text in present.items() if name != front_path.name]
    whole = "\n".join(present.values())

    # 1 -- forbidden constructs -------------------------------------------------
    for name, text in body_parts:
        for pattern, why in FORBIDDEN:
            for match in re.finditer(pattern, text, re.I):
                line = text[: match.start()].count("\n") + 1
                problems.append(f"{name}:{line}: {why} -> {match.group(0)!r}")
        for match in re.finditer(r"\$[A-Za-z\\(]", text):
            before = text[max(0, match.start() - 400): match.start()]
            if before.rfind("<pre") > before.rfind("</pre>") or \
               before.rfind("<code") > before.rfind("</code>"):
                continue  # a shell variable inside code is fine
            line = text[: match.start()].count("\n") + 1
            notes.append(f"{name}:{line}: bare '$' outside code -> {match.group(0)!r}")

    # 2 -- tag balance ----------------------------------------------------------
    for name, text in present.items():
        parser_ = Balance()
        parser_.feed(text)
        if name == front_path.name:
            parser_.stack = [s for s in parser_.stack if s[0] not in {"html", "head", "body"}]
        problems.extend(f"{name}: {error}" for error in parser_.errors)
        problems.extend(f"{name}: <{tag}> opened at line {line} never closed"
                        for tag, line in parser_.stack)

    # 3 -- anchors and section titles ------------------------------------------
    required, titles = toc_entries(present[front_path.name])
    for anchor in required:
        hits = len(re.findall(rf'id="{re.escape(anchor)}"', whole))
        if hits == 0:
            problems.append(f"anchor #{anchor} is in the contents but defined nowhere "
                            "(its page number will silently vanish)")
        elif hits > 1:
            problems.append(f"anchor #{anchor} defined {hits} times")
    for name, text in body_parts:
        for sid, inner in re.findall(r'<h2 id="(s[0-9]+-[0-9]+)">(.*?)</h2>', text, re.S):
            want = titles.get(sid)
            if want is None:
                problems.append(f"{name}: <h2 id={sid}> is not in the contents")
                continue
            got, want = " ".join(inner.split()), " ".join(want.split())
            if got != want:
                problems.append(f"{name}: {sid} title mismatch\n     toc: {want}\n     doc: {got}")

    # 4 -- figures --------------------------------------------------------------
    seen: list[int] = []
    walkthroughs: list[int] = []
    for name, text in body_parts:
        seen += [int(m.group(1)) for m in re.finditer(r'class="fignum">Figure\s+(\d+)\.', text)]
        walkthroughs += [int(m.group(1))
                         for m in re.finditer(r'class="rf-title">Reading Figure\s+(\d+)', text)]
    if seen:
        duplicates = sorted({n for n in seen if seen.count(n) > 1})
        if duplicates:
            problems.append(f"duplicate figure numbers: {duplicates}")
        gaps = sorted(set(range(1, max(seen) + 1)) - set(seen))
        if gaps:
            problems.append(f"figure sequence has gaps: {gaps}")
        if sorted(seen) != seen:
            notes.append(f"figure numbers not in document order: {seen}")
        missing = sorted(set(seen) - set(walkthroughs))
        if missing:
            problems.append(f"figures with no 'Reading Figure N' walkthrough: {missing}")
        orphans = sorted(set(walkthroughs) - set(seen))
        if orphans:
            problems.append(f"walkthroughs with no figure: {orphans}")

    # 5 -- greyscale only -------------------------------------------------------
    for name, text in body_parts:
        for match in re.finditer(r"(?<!&)#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b", text):
            hexcode = match.group(1)
            if len(hexcode) == 3:
                hexcode = "".join(c * 2 for c in hexcode)
            red, green, blue = (int(hexcode[i:i + 2], 16) for i in (0, 2, 4))
            if not red == green == blue:
                line = text[: match.start()].count("\n") + 1
                problems.append(f"{name}:{line}: non-greyscale colour #{match.group(1)}")

    # 6 -- SVG fill that a class silently overrides -----------------------------
    for name, text in body_parts:
        for match in re.finditer(r'<text[^>]*class="[^"]*"[^>]*\sfill="', text):
            line = text[: match.start()].count("\n") + 1
            problems.append(f"{name}:{line}: <text class=... fill=...> "
                            'the class wins; use style="fill:..."')

    # 7 -- class whitelist ------------------------------------------------------
    known_base = stylesheet_classes(build)
    for name, text in body_parts:
        known = known_base | set(re.findall(r"\.([A-Za-z][\w-]*)\s*\{", text))
        for match in re.finditer(r'class="([^"]+)"', text):
            for cls in match.group(1).split():
                if cls not in known:
                    line = text[: match.start()].count("\n") + 1
                    problems.append(f"{name}:{line}: unknown class {cls!r} "
                                    "(renders unstyled; nothing will warn you)")

    # 8 -- emphasis budget ------------------------------------------------------
    for name, text in body_parts:
        if "atglance" in text and 'class="keypanel"' in text:
            pass  # front-matter panels live in the at-a-glance fragment
        elif 'class="keypanel"' in text:
            notes.append(f"{name}: keypanel outside the front matter "
                         "(budget: 2-4 in the whole document)")
        chunks = re.split(r'(<h1 class="chapter[^"]*"[^>]*>)', text)
        for index in range(1, len(chunks), 2):
            head, body = chunks[index], chunks[index + 1] if index + 1 < len(chunks) else ""
            count = len(re.findall(r'class="box dark"', body))
            if count > 1:
                cid = re.search(r'id="([^"]+)"', head)
                notes.append(f"{name}: {cid.group(1) if cid else '?'} has {count} dark boxes "
                             "(budget 1; a chapter with two points should be two chapters)")

    # 9 -- chapter and part shape -----------------------------------------------
    for name, text in body_parts:
        for match in re.finditer(r'<h1 class="chapter[^"]*"([^>]*)>', text):
            line = text[: match.start()].count("\n") + 1
            if "data-bm=" not in match.group(1):
                problems.append(f"{name}:{line}: chapter h1 without data-bm "
                                "(bookmark and running head both break)")
            if "id=" not in match.group(1):
                problems.append(f"{name}:{line}: chapter h1 without id")
        for match in re.finditer(r'<div class="part"([^>]*)>', text):
            if "data-bm=" not in match.group(1):
                line = text[: match.start()].count("\n") + 1
                problems.append(f"{name}:{line}: part divider without data-bm")

    # 10 -- straight quotes in prose --------------------------------------------
    for name, text in body_parts:
        stripped = re.sub(r"<svg.*?</svg>|<style.*?</style>|<pre.*?</pre>|"
                          r"<code.*?</code>|<[^>]+>", " ", text, flags=re.S)
        stripped = htmllib.unescape(stripped)
        count = stripped.count('"') + len(re.findall(r"(?<=\w)'(?=\w|\s)", stripped))
        if count:
            notes.append(f"{name}: {count} straight quote/apostrophe characters in prose "
                         "(use &ldquo; &rdquo; &rsquo;)")

    words = len(re.sub(r"<[^>]+>", " ", whole).split())
    print(f"fragments   : {len(present)}")
    print(f"figures     : {len(seen)}" + (f" (1-{max(seen)})" if seen else ""))
    print(f"words       : {words:,}")
    if notes:
        print(f"\nNOTES ({len(notes)}):")
        for note in notes[:60]:
            print("  .", note)
    if problems:
        print(f"\nPROBLEMS ({len(problems)}):")
        for problem in problems[:120]:
            print("  x", problem)
        return 1
    print("\nAll structural checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
