# Bookrank

`bookrank.heyitsmejosh.com`, Joshua's book rankings/TBR site. Renamed from "Books" 2026-07-18, then repo+folder `spine`→`uprighty` 2026-07-29, then ASC app + GitHub repo + domain all renamed `uprighty`→`bookrank` 2026-08-07 (Uprighty was rejected as a duplicate ASC name). GitHub repo is now `nulljosh/bookrank`; local folder stays `~/Documents/Code/uprighty` (not renamed, matches this project's own pattern of folder lagging display name). Split out from the `nulljosh.github.io` (echo) repo into its own repo+domain (was previously nested under echo, which made no sense, books and echo are unrelated projects).

## Files
- `books.json`: **the single source of truth for every book list.** Edit this, nothing else.
- `scripts/build.py`: regenerates `rankings.html` (inside `<!-- generated:* -->` markers), `book_rankings.md`, and the three `ios/Bookrank/Resources/*.json` files from `books.json`. Run after every edit.
- `index.html`: landing page; hero is a cover wall built at runtime from `scripts/covers.json`
- `rankings.html`: the ranked shelf (search, sort, star ratings). Page chrome is hand-written; the book rows are generated, do not hand-edit inside the markers.
- `library.html`: private per-account chapter summaries
- `scripts/fetch-covers.py`: resolves an Open Library cover for every entry and writes it into `books.json` (then run `build.py`)

## Rule: one source of truth (2026-08-27)
`books.json` is authoritative. `book_rankings.md`, `rankings.html`'s rows and the iOS JSON resources are **generated**, never hand-edit them, the next `build.py` run overwrites the change.

The predecessor `scripts/export-books.py` required a `**Rating:**` line and silently skipped entries without one, so the shipping app carried **71 of 111** ranked books for months. `build.py` fails loudly instead, and `scripts/test-build.py` pins that regression. Rating and reviewCount are nullable in both `books.json` and `Book.swift`; keep them that way.

## Rule: the ranked list is unread-only (TBR)
When the user says they've read, finished, or are partway through a book and want it off the ranked list, remove its `"section": "ranked"` entry from `books.json`, renumber the remaining ranked entries sequentially, and run `scripts/build.py`. Don't remove a book just because they mention reading it unless they ask for removal.

The "Recently Read" and "Summaries" sections on `rankings.html` are separate from the ranked list and are allowed to hold finished books.

## Rule: no library checkout tracking (2026-08-22)
Every library book is returned. The old "Out From The Library" section, its `data-due` countdown badge and the matching iOS `DueDateBadge` exist only as history, do not reintroduce a checkout or due-date feature without a real data source. `ios/Bookrank/Resources/library.json` carries `loans: []`; the iOS view already renders nothing when it is empty, which is why only the web page ever went stale (its list was hardcoded inline).

## Chapter summaries (photographed books)
Raw phone photos of physical books, their per-chapter summaries, and merged book-level markdown live in iCloud Drive at `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/` (not in this repo, too large/private). That folder has its own `summarize.sh` and `CLAUDE.md`.

To expose a finished book's summary on the site:
1. In the iCloud folder, run `./summarize.sh "Book Name"`, converts photos to chapter `summary.md` files (deleting originals on success), then merges them into `<slug>-summary.md` in the book's folder.
2. In this repo, run `./sync-summaries.sh`, copies `<slug>-summary.md` into `summaries/<slug>.md` here.
3. Add a `<a href="summary.html?b=<slug>" class="badge">Summary</a>` link next to the matching book entry in `rankings.html`. `summary.html` renders `summaries/<slug>.md` client-side via `marked`.

Planned iOS companion tracker app name: "Digest" (decided, not applied, see roadmap.md "Someday / Explore" for status, blocked on a backend decision).

## iOS app icon, regeneration rule (2026-07-12)
The recurring TestFlight icon glitch (art rendered small/top-left with white fill) came from hand-exporting `icon.svg` (intrinsic 200×200, rounded corners) into the 1024 slot. Never export by hand: run `scripts/make-appicon.sh`, it renders the SVG natively at each size, flattens rounded corners onto the bg color, and asserts the expected pixel size/no-alpha.

The script originally rebuilt only the 1024 slot, so the seven macOS sizes in `Contents.json` silently kept art from an older `icon.svg` (2026-08-28). It now regenerates every size in one pass, keep it that way when adding a slot.

## Rule: a failed cover lookup is not a miss (2026-08-23)
`scripts/covers.json` caches `null` to mean "both Open Library and Google Books answered, neither had a cover", and ordinary re-runs skip those keys forever, so a wrong null is invisible and permanent. `lookup()` therefore must NOT catch exceptions around the Google Books fallback: a 429 (its unauthenticated daily quota is easy to exhaust), a policy block or any network error has to propagate so `main()` records it as `fail:` and leaves the cache alone. Swallowing it is what silently marked five real books "no cover" and made an earlier fix look like it hadn't worked.

Cover images cannot be fetched from a Claude Code web session: `openlibrary.org` is refused by the egress policy (403 on CONNECT) and the Google Books quota is usually spent. Run `python3 scripts/fetch-covers.py` locally instead. Use `--retry-misses` to re-query cached nulls.

## Xcode project renamed Spine → Bookrank (2026-08-23)
The Xcode scaffolding kept the original name long after the product stopped using it. Now: directory `ios/Bookrank`, project `ios/Bookrank.xcodeproj`, targets `Bookrank` / `BookrankMac` / `BookrankUITests`, schemes to match, `BookrankApp.swift`, `Bookrank.entitlements` / `BookrankMac.entitlements`. Built products are `Bookrank.app` / `BookrankMac.app` (`PRODUCT_NAME = $(TARGET_NAME)`).

Two lowercase `spine` strings are deliberate and must NOT be renamed:
- **`com.heyitsmejosh.spine`** (and `.spine.uitests`), the bundle identifier, bound to ASC record 6792376485. Changing it means a new app record, not a rename.
- **`@AppStorage("spine-theme")`** in `LibraryView.swift`, a persisted key on shipped devices. Renaming it silently resets every existing user's theme to system.

`project.pbxproj` is xcodegen output; it was renamed in place to stay in sync with `project.yml`, and regenerating it reproduces the same names.

## Repo separation (2026-07-13)
Decided: books stays its own repo, do NOT merge into lexly or notes. books/lexly/notes are separate products (own domains/apps); notes is the wiki.

## Roadmap
See `roadmap.md` in this repo root, not embedded here anymore. ASC app ID is **`6792376485`** (bundle `com.heyitsmejosh.spine`), one record carrying both iOS and macOS, verified via `asc apps list` 2026-08-13. (Earlier notes here listed `6787499076` iOS / `6787499349` macOS; those are wrong and match no live record.)
