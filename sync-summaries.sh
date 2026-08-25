#!/usr/bin/env bash
set -euo pipefail
SRC="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books"
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$ROOT/summaries"
APP_DEST="$ROOT/ios/Bookrank/Resources/summaries"
mkdir -p "$DEST" "$APP_DEST"

# ponytail: every write goes through here. A routine run on 2026-08-17 replaced a complete
# 498KB summary with a stale 304KB copy and four chapters survived only because they were
# still in git. Refuse a materially smaller overwrite; FORCE=1 to override.
SHRINK_PCT="${SHRINK_PCT:-80}"
safe_cp() {
  local src="$1" dst="$2"
  if [[ -f "$dst" && "${FORCE:-0}" != "1" ]]; then
    local new old
    new=$(wc -c < "$src"); old=$(wc -c < "$dst")
    if (( old > 0 && new * 100 < old * SHRINK_PCT )); then
      echo "SKIP $dst: incoming ${new}b is under ${SHRINK_PCT}% of existing ${old}b (FORCE=1 to override)" >&2
      return 1
    fi
  fi
  cp "$src" "$dst"
}

if [[ "${SELFCHECK:-0}" == "1" ]]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  printf '%0.sx' {1..1000} > "$tmp/big"; printf '%0.sx' {1..100} > "$tmp/small"
  cp "$tmp/big" "$tmp/dst"
  safe_cp "$tmp/small" "$tmp/dst" && { echo "FAIL: shrink was allowed"; exit 1; }
  [[ $(wc -c < "$tmp/dst") -eq 1000 ]] || { echo "FAIL: dst was modified"; exit 1; }
  FORCE=1 safe_cp "$tmp/small" "$tmp/dst" || { echo "FAIL: FORCE did not override"; exit 1; }
  [[ $(wc -c < "$tmp/dst") -eq 100 ]] || { echo "FAIL: FORCE did not write"; exit 1; }
  cp "$tmp/big" "$tmp/dst2"; safe_cp "$tmp/big" "$tmp/dst2" || { echo "FAIL: same-size blocked"; exit 1; }
  echo "self-check OK"; exit 0
fi

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
    safe_cp "$md" "$DEST/$out_slug.md" || continue
    safe_cp "$md" "$APP_DEST/$out_slug.md" || true
    echo "Synced: $out_slug.md (markdown)"
    continue
  fi

  pdf=("$book_dir"*-summary*.pdf)
  if [[ -f "${pdf[0]:-}" ]]; then
    pdftotext -layout "${pdf[0]}" "$DEST/$slug.md"
    safe_cp "$DEST/$slug.md" "$APP_DEST/$slug.md" || true
    echo "Synced: $slug.md (pdftotext fallback)"
  fi
done
