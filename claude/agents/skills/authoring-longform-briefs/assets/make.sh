#!/usr/bin/env bash
# Build the brief: structural check -> two-pass render + layout audit -> PDF verification.
#
# macOS: WeasyPrint dlopen()s pango/gobject at import time, and dyld only
# consults DYLD_FALLBACK_LIBRARY_PATH from the process environment -- setting
# os.environ inside build.py is too late.  That is why this wrapper exists.
#
#   ./make.sh                                  -> out/<dirname>.pdf
#   ./make.sh ~/Desktop/brief.pdf              -> that path
#   ./make.sh --install ~/Vault/PDFs/Brief.pdf -> also copy there, once every stage is clean
set -uo pipefail
cd "$(dirname "$0")"

if [[ "$(uname)" == "Darwin" ]]; then
  export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-/opt/homebrew/lib}"
fi

INSTALL=""
if [[ "${1:-}" == "--install" ]]; then
  INSTALL="${2:?--install needs a destination path}"
  shift 2
fi

PY=./.venv/bin/python
[[ -x "$PY" ]] || PY=python3
OUT="${1:-out/$(basename "$PWD").pdf}"

echo "== structural check"
"$PY" check.py; CHECK=$?

echo
echo "== render"
"$PY" build.py --out "$OUT"; RENDER=$?
[[ -f "$OUT" ]] || exit 1

echo
echo "== verify pdf"
"$PY" verify_pdf.py "$OUT" --combined _combined.html; VERIFY=$?

STATUS=$(( CHECK != 0 || RENDER != 0 || VERIFY != 0 ))

# A snapshot is only worth taking of a clean build; a half-broken PDF sitting in a
# reading library is worse than no PDF, because nothing there will tell you it is stale.
if [[ -n "$INSTALL" ]]; then
  echo
  if (( STATUS )); then
    echo "== install skipped: a stage above failed"
  else
    mkdir -p "$(dirname "$INSTALL")"
    cp "$OUT" "$INSTALL"
    echo "== installed"
    echo "  $INSTALL"
    echo "  $(cksum < "$INSTALL" | cut -d' ' -f1) bytes-checksum, matches $(cksum < "$OUT" | cut -d' ' -f1)"
  fi
fi

exit $STATUS
