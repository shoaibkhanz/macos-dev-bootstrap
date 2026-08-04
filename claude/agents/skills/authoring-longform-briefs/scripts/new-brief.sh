#!/usr/bin/env bash
# Scaffold a buildable long-form brief: assets + venv + a four-fragment
# skeleton that already renders to a valid PDF.  One command, zero decisions.
#
#   new-brief.sh ~/work/my-brief "The Title" "The subtitle"
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$HERE/../assets"

# macOS: WeasyPrint dlopen()s pango/gobject at import time and dyld only reads
# this variable from the process environment -- it must be set before python starts.
if [[ "$(uname)" == "Darwin" ]]; then
  export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-/opt/homebrew/lib}"
  if [[ ! -e /opt/homebrew/lib/libgobject-2.0.dylib ]]; then
    echo "!! pango is missing: brew install pango gdk-pixbuf libffi" >&2
  fi
fi

TARGET="${1:?usage: new-brief.sh <dir> [title] [subtitle]}"
TITLE="${2:-Untitled Brief}"
SUBTITLE="${3:-A long-form technical brief}"

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
cp "$ASSETS"/style.css "$ASSETS"/build.py "$ASSETS"/check.py "$ASSETS"/verify_pdf.py "$ASSETS"/make.sh "$TARGET/"
chmod +x "$TARGET/make.sh"

shopt -s nullglob
for f in "$ASSETS"/templates/*.html; do
  base="$(basename "$f")"
  [[ -e "$TARGET/$base" ]] && { echo "keep   $base (exists)"; continue; }
  sed -e "s|{{TITLE}}|$TITLE|g" -e "s|{{SUBTITLE}}|$SUBTITLE|g" \
      -e "s|{{DATE}}|$(date '+%-d %B %Y')|g" "$f" > "$TARGET/$base"
  echo "write  $base"
done

cd "$TARGET"
if [[ ! -x .venv/bin/python ]]; then
  echo "== python environment"
  if command -v uv >/dev/null 2>&1; then
    uv venv --python 3.12 .venv >/dev/null
    VIRTUAL_ENV="$TARGET/.venv" uv pip install --quiet weasyprint pypdf
  else
    python3 -m venv .venv
    ./.venv/bin/pip install --quiet --upgrade pip weasyprint pypdf
  fi
fi
./.venv/bin/python -c 'import weasyprint; print("weasyprint", weasyprint.__version__)' \
  || { echo "!! weasyprint cannot import -- install its system libraries, then rerun" >&2; exit 1; }

echo
echo "== first build"
./make.sh || true

cat <<EOF

Scaffold ready in $TARGET
  1. edit 00_front.html   -- title block and the contents (anchors are the contract)
  2. write NN_*.html      -- one fragment per part; they are discovered automatically
  3. ./make.sh            -- check, render, verify; run it after every fragment
EOF
