#!/bin/sh
# Regenerate the iOS AppIcon 1024 PNG from icon.svg. ALWAYS use this — never export by hand.
# Renders at full 1024 (fixes the recurring "art stuck in top-left corner" glitch from
# intrinsic-size exports) and flattens the rounded corners onto the icon's own bg color
# so the PNG is square-corner, full-bleed, no alpha (ASC requirements; iOS adds the mask).
set -e
cd "$(dirname "$0")/.."
BG="#0f172a"
DEST="ios/BooksApp/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
rsvg-convert -w 1024 -h 1024 icon.svg | magick - -background "$BG" -alpha remove -alpha off "$DEST"
sips -g pixelWidth -g pixelHeight -g hasAlpha "$DEST" | grep -q 'hasAlpha: no'
sips -g pixelWidth "$DEST" | grep -q 'pixelWidth: 1024'
echo "OK: $DEST"
