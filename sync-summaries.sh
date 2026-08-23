#!/usr/bin/env bash
set -euo pipefail
SRC="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books"
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$ROOT/summaries"
APP_DEST="$ROOT/ios/Bookrank/Resources/summaries"
mkdir -p "$DEST" "$APP_DEST"

# ponytail: book folders can be nested one level (e.g. "for dummies/<book>"), so scan
# both the top level and one level down instead of assuming a fixed depth.
for book_dir in "$SRC"/*/ "$SRC"/*/*/; do
  [[ -d "$book_dir" ]] || continue
  book="$(basename "$book_dir")"
  slug="$(echo "$book" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//')"

  shopt -s nullglob
  md_matches=("$book_dir"*"$slug-summary.md")
  shopt -u nullglob
  md="${md_matches[0]:-}"
  if [[ -z "$md" ]]; then
    # slug from folder name may not exactly match the summary's own filename slug
    shopt -s nullglob
    md_matches=("$book_dir"*-summary.md)
    shopt -u nullglob
    md="${md_matches[0]:-}"
  fi
  if [[ -n "$md" && -f "$md" ]]; then
    out_slug="$(basename "$md" -summary.md)"
    cp "$md" "$DEST/$out_slug.md"
    cp "$md" "$APP_DEST/$out_slug.md"
    echo "Synced: $out_slug.md (markdown)"
    continue
  fi

  pdf=("$book_dir"*-summary*.pdf)
  if [[ -f "${pdf[0]:-}" ]]; then
    pdftotext -layout "${pdf[0]}" "$DEST/$slug.md"
    cp "$DEST/$slug.md" "$APP_DEST/$slug.md"
    echo "Synced: $slug.md (pdftotext fallback)"
  fi
done
