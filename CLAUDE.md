# Spine

`spine.heyitsmejosh.com` — Joshua's book rankings/TBR site, renamed from "Books" 2026-07-18. GitHub repo renamed `nulljosh/books` → `nulljosh/spine`; local folder path (`~/Documents/Code/books`) intentionally left as-is. Split out from the `nulljosh.github.io` (echo) repo into its own repo+domain (was previously nested under echo, which made no sense — books and echo are unrelated projects).

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

## Imported from Books (tracker app).pdf (2026-06-21)
- [ ] Project name for planned iOS companion tracker app: "Digest" (decided, not applied — this repo is the separate live books.heyitsmejosh.com rankings site, unrelated to the new app).
- [ ] Build iOS companion app — BLOCKED, needs a backend decision (Supabase vs static JSON) before scaffolding. No API/data layer exists yet.

## iOS app icon — regeneration rule (2026-07-12)
The recurring TestFlight icon glitch (art rendered small/top-left with white fill) came from hand-exporting `icon.svg` (intrinsic 200×200, rounded corners) into the 1024 slot. Never export by hand: run `scripts/make-appicon.sh` — it renders the SVG at 1024, flattens rounded corners onto the bg color, and asserts 1024×1024/no-alpha.

## Repo separation (2026-07-13)
Decided: books stays its own repo — do NOT merge into lexly or notes. books/lexly/notes are separate products (own domains/apps); notes is the wiki.

## Roadmap (merged from ROADMAP.md, 2026-07-20)
Note: ROADMAP.md referred to the app as "books-ios"/"Books Mac" — that's stale, this repo's app is **Spine/Spinelist** (see rename note at top); ASC app IDs (`6787499076` iOS, `6787499349` macOS) are unaffected by the display-name rename.

**Chapter summaries in progress:**
- Pre-Calculus for Dummies: ch1–13 done, ch14–18 + loose Final HEICs remain (resume with `/summarize-books "PC For dummies"`), then merge + `./sync-summaries.sh` + badge.

**iOS/Mac Spinelist app — ASC submission in progress:**
- Icon, signing (`CODE_SIGN_STYLE: Automatic`, team `QMM486NPYC`), and ASC bundle ID registration are done.
- Remaining: fix the export blocker above, then archive+upload via `~/.claude/skills/icon-audit/ship.sh ~/Documents/Code/books/ios BooksApp` and `... BooksAppMac`; optionally rename the "books-ios" ASC app record to "Spine"/"Spinelist" in App Information; fill minimum ASC metadata (category, privacy) to clear "Prepare for Submission".

**Someday / Explore:**
- Once all book summaries are finished, integrate as quizzes/masterclasses in Lexly (cross-ref lexly roadmap) — first step of syncing several repos together.
- Goodreads integration ("sign in with Goodreads" companion sync) — Goodreads deprecated its public API for new developer keys in 2020, confirm current auth options exist before scoping. No deadline pinned.
- Landing page split: separate marketing page from the rankings-list homepage.
- iOS/Mac companion app ("Digest") — BLOCKED, needs a backend decision (Supabase vs static JSON) before scaffolding; no API/data layer exists yet. Multi-session project.
- Books skill: treat each raw folder as a chapter (auto-create chapter folders) in the summarize pipeline.
- Replace shell-script deps in the summarize pipeline with native implementation where sensible.
- Consider moving the Books iCloud folder into this repo (gitignore raws; commit only summarized pdf/html) — undecided.

**Known-done (verified 2026-07-20):** no raw HEICs remain anywhere in the iCloud source folder; no stray empty files in this repo.
