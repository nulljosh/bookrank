# Books Roadmap

## Apple: The First 50 Years — COMPLETE (2026-07-20)
All 50 chapters (Introduction through Acknowledgments/Sources) photographed, summarized, and merged into `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/Apple/apple-summary.md`. All raw HEICs deleted (0 remain in the Apple folder). Synced to `summaries/apple.md`, badge already present on index.html.

## Someday / Explore
- [ ] From Books.pdf note (imported 2026-07-19): once all book summaries are finished, integrate as quizzes/masterclasses in Lexly (cross-ref lexly repo roadmap) — first step of syncing several repos together.

## Pre-Calculus for Dummies — in progress (2026-07-13)
Photos live in iCloud `Books/PC For dummies/` (misnamed folder; it's Pre-Calculus For Dummies).
- ch1–13 summarized (summary.md per chapter), raw HEICs deleted
- Remaining: ch14 (32 imgs), ch15 (9), ch16 (9), `Final /17-18` (7) + loose Final HEICs IMG_2902–2908 (sort by number into a chapter first)
- Then: merge chapter summaries → `pre-calculus-for-dummies-summary.md`, run `./sync-summaries.sh`, add Summary badge to index.html + book_rankings.md, push
- Resume with: `/summarize-books "PC For dummies"`

Pending user scans: Jim Simons (The Man Who Solved the Market), Calculus, remaining Dummies books.

## iCloud summarize pipeline — all caught up (2026-07-04)

**Newton** — all chapters done, PDF merged. Nothing pending.

**Machine Learning for Dummies** — all chapters done (1-3, 4-6, 7-9, 10, 11, 12) 2026-07-04. Nothing pending.

**Exercise Science for Dummies** — all chapters done (1-2 through 16-18) 2026-07-04. Nothing pending.

**Agentic AI for Dummies** — ch2–15 all done, PDF merged. Nothing pending.

**AI Investing for Dummies** — ch1–3 done, PDF merged. Nothing pending.

No raw photos remain in the iCloud source folder for any book as of 2026-07-04.

## Bigger asks, not started (raised 2026-07-04, deferred — weekly budget was at 86%)
- **Goodreads sync**: read-only import of shelf into book_rankings.md/index.html. Scoped, one-session-sized.
- **Landing page split**: separate marketing/landing page from the rankings-list homepage. Design + build.
- **iOS/Mac companion app ("Digest")**: BLOCKED — needs a backend decision (Supabase vs static JSON) before scaffolding; no API/data layer exists yet. Multi-session project, not a quick add. See repo CLAUDE.md "Imported from Books (tracker app).pdf" section.

## iOS/Mac WKWebView wrapper — ASC submission in progress (2026-07-04)
`ios/BooksApp` (WKWebView wrapper, not "Digest" — separate from the blocked companion app above) builds and runs clean for both `BooksApp` (iOS) and `BooksAppMac` targets, verified in simulator/local run this session.

Done:
- App icon generated from `icon.svg` → `Assets.xcassets/AppIcon.appiconset` (1024x1024, no alpha), wired via `ASSETCATALOG_COMPILER_APPICON_NAME` in `project.yml`
- `CODE_SIGN_STYLE: Automatic` + `DEVELOPMENT_TEAM: QMM486NPYC` added to both targets
- Bundle IDs registered in ASC: `com.heyitsmejosh.books` (iOS), `com.heyitsmejosh.books.mac` (macOS)
- ASC app records created via browser: **books-ios** (app ID `6787499076`, iOS, `com.heyitsmejosh.books`) — note: named "books-ios" not "Books" due to a form mixup, rename under App Information whenever; **Books Mac** (app ID `6787499349`, macOS, `com.heyitsmejosh.books.mac`) — named correctly
- `ios/BooksApp/Assets.xcassets` + `project.yml` changes committed and pushed (commit `830b741`)

Remaining:
1. Archive + upload using the existing ship pipeline: `~/.claude/skills/icon-audit/ship.sh ~/Documents/Code/books/ios BooksApp` and `... BooksAppMac` (uses `-allowProvisioningUpdates`, auto-creates profiles against the existing distribution certs — no new certs needed, team already has `iPhone Distribution` and `3rd Party Mac Developer Application` certs for QMM486NPYC)
2. Optionally rename "books-ios" app record to "Books" in App Information
3. Fill minimum ASC metadata (category, privacy) to get past "Prepare for Submission"; screenshots/description can follow once a build is processing

## After summaries are done
1. `cd ~/Documents/Code/books && ./sync-summaries.sh`
2. Add `<a href="summary.html?b=<slug>" class="badge">Summary</a>` in `index.html` for each new book (see Agentic AI entry for pattern)
3. Update `book_rankings.md` in parallel (both files must stay in sync)
4. Commit + push

## Known issues fixed
- `summarize.sh`: subprocess was inheriting `CLAUDE_CODE_SESSION_ID` and hallucinating. Fixed with `env -u` to strip session vars before calling `claude -p`.
- PC for Dummies ch1–7: photos permanently lost (bad summary passed validation, originals deleted). Needs re-photographing.
- Agentic AI ch12: photos permanently lost same way. Summary was later recovered manually.

## From Icons.pdf / Asc.pdf (imported 2026-07-12)
- [ ] books-ios: build + screenshots + metadata + submit (icon fixed 2026-07-12 via scripts/make-appicon.sh)
- [ ] Books Mac: same, after books-ios

## 2026-07-14 dump
- [ ] Finish processing remaining raw book files
- [ ] Add Calculus for Dummies
- [ ] Books skill: treat each raw folder as a chapter (auto-create chapter folders), then normal pipeline
- [ ] Replace shell-script deps with native implementation where sensible
- [ ] Delete empty files left after raw removal
- [ ] Merge ROADMAP.md into CLAUDE.md; refresh CLAUDE.md
- [ ] Consider moving Books iCloud folder into repo (gitignore raws; commit only summarized pdf/html)

## From Spine.pdf (imported 2026-07-19)
- [ ] Goodreads integration — "sign in with Goodreads" style auth/sync, described as making Spine "a Goodreads companion." Sizeable feature: needs Goodreads API/OAuth research (note: Goodreads deprecated its public API in 2020 for new developer keys — confirm current auth options exist before scoping further), a books-read/shelf sync mechanism, and UI for the linked state. No scope/deadline pinned yet.
