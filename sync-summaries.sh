#!/usr/bin/env bash
set -euo pipefail
SRC="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books"
DEST="$(cd "$(dirname "$0")" && pwd)/summaries"
mkdir -p "$DEST"

for book_dir in "$SRC"/*/; do
  book="$(basename "$book_dir")"
  slug="$(echo "$book" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//')"

  md="$book_dir$slug-summary.md"
  if [[ -f "$md" ]]; then
    cp "$md" "$DEST/$slug.md"
    echo "Synced: $slug.md (markdown)"
    continue
  fi

  pdf=("$book_dir"*-summary*.pdf)
  if [[ -f "${pdf[0]:-}" ]]; then
    pdftotext -layout "${pdf[0]}" "$DEST/$slug.md"
    echo "Synced: $slug.md (pdftotext fallback)"
  fi
done
