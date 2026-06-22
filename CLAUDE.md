# Books Repo

`books.heyitsmejosh.com` — Joshua's book rankings/TBR site. Split out from the `nulljosh.github.io` (echo) repo into its own repo+domain (was previously nested under echo, which made no sense — books and echo are unrelated projects).

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

## Resolved 2026-06-21
- [x] PC for Dummies summary missing — root cause: `summarize.sh`'s headless `claude -p` call hit a permission prompt instead of reading the images, wrote that prompt text as if it were the summary, and the script's "non-empty = success" check deleted the original chapter photos anyway. Fixed in `summarize.sh` (now uses `--dangerously-skip-permissions` + validates output isn't a permission-request before deleting sources). Garbage summary files and the "Summary" badge for PC for Dummies were removed — chapters 1-7 have no surviving photos and need to be re-photographed from scratch.
