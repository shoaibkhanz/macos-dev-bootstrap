#!/usr/bin/env bash
# Build the brief: structural check -> two-pass render -> PDF verification.
#
# macOS: WeasyPrint dlopen()s pango/gobject at import time, and dyld only
# consults DYLD_FALLBACK_LIBRARY_PATH from the process environment -- setting
# os.environ inside build.py is too late.  That is why this wrapper exists.
#
#   ./make.sh                       -> out/<dirname>.pdf
#   ./make.sh ~/Desktop/brief.pdf   -> that path
set -uo pipefail
cd "$(dirname "$0")"

if [[ "$(uname)" == "Darwin" ]]; then
  export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-/opt/homebrew/lib}"
fi

PY=./.venv/bin/python
[[ -x "$PY" ]] || PY=python3
OUT="${1:-out/$(basename "$PWD").pdf}"

echo "== structural check"
"$PY" check.py; CHECK=$?

echo
echo "== render"
"$PY" build.py --out "$OUT" || exit 1

echo
echo "== verify pdf"
"$PY" verify_pdf.py "$OUT" --combined _combined.html; VERIFY=$?

exit $(( CHECK != 0 || VERIFY != 0 ))
