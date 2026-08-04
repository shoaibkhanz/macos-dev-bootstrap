#!/usr/bin/env bash
# Install EB Garamond + JetBrains Mono so fontconfig, and therefore WeasyPrint,
# resolves them by family name.  A missing font never errors -- it substitutes
# silently and the design collapses -- so this script ends in a verification
# you must read.
#
# Google Fonts is often unreachable from sandboxes; GitHub is.  Static TTFs
# only: WeasyPrint renders variable fonts poorly.
set -euo pipefail

WORK="${TMPDIR:-/tmp}/brief-fonts"
mkdir -p "$WORK" && cd "$WORK"

case "$(uname)" in
  Darwin) DEST="$HOME/Library/Fonts" ;;
  *)      DEST="/usr/share/fonts/truetype/custom" ;;
esac
mkdir -p "$DEST" 2>/dev/null || { DEST="$HOME/.local/share/fonts"; mkdir -p "$DEST"; }

echo "== EB Garamond -> $DEST"
for f in Regular Italic Bold BoldItalic SemiBold Medium; do
  curl -sfL -o "EBGaramond-$f.ttf" \
    "https://raw.githubusercontent.com/octaviopardo/EBGaramond12/master/fonts/ttf/EBGaramond-$f.ttf" \
    && cp "EBGaramond-$f.ttf" "$DEST/" || echo "   (skipped $f)"
done

echo "== JetBrains Mono -> $DEST"
curl -sfL -o jbm.zip \
  "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
unzip -o -q jbm.zip "fonts/ttf/JetBrainsMono-Regular.ttf" \
  "fonts/ttf/JetBrainsMono-Bold.ttf" "fonts/ttf/JetBrainsMono-Italic.ttf"
cp fonts/ttf/JetBrainsMono-*.ttf "$DEST/"

command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true

if [[ "$(uname)" == "Darwin" ]] && ! brew list pango >/dev/null 2>&1; then
  echo
  echo "!! pango is missing: WeasyPrint will not import."
  echo "   brew install pango gdk-pixbuf libffi"
fi

echo
echo "== verification (both families must appear)"
if command -v fc-list >/dev/null 2>&1; then
  fc-list | grep -iE "garamond|jetbrains" | sed 's/.*: //' | sort -u
else
  ls "$DEST" | grep -iE "garamond|jetbrains"
fi
