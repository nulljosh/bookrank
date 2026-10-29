#!/bin/sh
# Regenerate every AppIcon PNG from icon.svg. ALWAYS use this — never export by hand.
# Renders each size natively at full resolution (fixes the recurring "art stuck in
# top-left corner" glitch from intrinsic-size exports) and flattens the rounded corners
# onto the icon's own bg color so each PNG is square-corner, full-bleed, no alpha
# (ASC requirements; iOS and macOS add their own mask).
# All sizes listed in Contents.json are regenerated together — the macOS slots went
# stale for months when only the 1024 was rebuilt.
set -e
cd "$(dirname "$0")/.."
BG="#c97a00"
DIR="ios/Kernel/Assets.xcassets/AppIcon.appiconset"
for SIZE in 1024 512 256 128 64 32 16; do
  DEST="$DIR/icon_$SIZE.png"
  SRC=brand/icon-tile.svg; [ "$SIZE" = 16 ] && SRC=brand/icon-small.svg   # three thin lines blur at 16 px
  rsvg-convert -w "$SIZE" -h "$SIZE" "$SRC" | magick - -background "$BG" -alpha remove -alpha off "$DEST"
  sips -g pixelWidth -g pixelHeight -g hasAlpha "$DEST" | grep -q 'hasAlpha: no'
  sips -g pixelWidth "$DEST" | grep -q "pixelWidth: $SIZE"
  echo "OK: $DEST"
done
