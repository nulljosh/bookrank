# Bookrank

`spine.heyitsmejosh.com` (domain unchanged) — Joshua's book rankings/TBR site, renamed from "Books" 2026-07-18, then repo+folder renamed `spine` → `uprighty` 2026-07-29 (matches the ASC app name). GitHub repo is now `nulljosh/uprighty`; local folder is `~/Documents/Code/uprighty`. Split out from the `nulljosh.github.io` (echo) repo into its own repo+domain (was previously nested under echo, which made no sense — books and echo are unrelated projects).

## Files
- `index.html` — the live site (uses shared `tokens.css` + `fonts/` copied from the portfolio repo for consistent design)
- `book_rankings.md` — markdown source of the same ranked list (maintained in parallel, not auto-generated from/to index.html — both must be edited together)

## Rule: this is an unread-only (TBR) list
When the user says they've read, finished, or are partway through a book and want it off the list, remove its entry from **both** `book_rankings.md` and `index.html`, then renumber remaining entries sequentially in both files. Don't remove a book just because they mention reading it unless they ask for removal.

## Chapter summaries (photographed books)
Raw phone photos of physical books, their per-chapter summaries, and merged book-level markdown live in iCloud Drive at `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/` (not in this repo — too large/private). That folder has its own `summarize.sh` and `CLAUDE.md`.

To expose a finished book's summary on the site:
1. In the iCloud folder, run `./summarize.sh "Book Name"` — converts photos to chapter `summary.md` files (deleting originals on success), then merges them into `<slug>-summary.md` in the book's folder.
2. In this repo, run `./sync-summaries.sh` — copies `<slug>-summary.md` into `summaries/<slug>.md` here.
3. Add a `<a href="summary.html?b=<slug>" class="badge">Summary</a>` link next to the matching book entry in `index.html` (see the Agentic AI for Dummies entry in the library list for the pattern). `summary.html` renders `summaries/<slug>.md` client-side via `marked`.

Planned iOS companion tracker app name: "Digest" (decided, not applied — see roadmap.md "Someday / Explore" for status, blocked on a backend decision).

## iOS app icon — regeneration rule (2026-07-12)
The recurring TestFlight icon glitch (art rendered small/top-left with white fill) came from hand-exporting `icon.svg` (intrinsic 200×200, rounded corners) into the 1024 slot. Never export by hand: run `scripts/make-appicon.sh` — it renders the SVG at 1024, flattens rounded corners onto the bg color, and asserts 1024×1024/no-alpha.

## Repo separation (2026-07-13)
Decided: books stays its own repo — do NOT merge into lexly or notes. books/lexly/notes are separate products (own domains/apps); notes is the wiki.

## Roadmap
See `roadmap.md` in this repo root — not embedded here anymore. ASC app IDs (`6787499076` iOS, `6787499349` macOS) are unaffected by the display-name rename.
