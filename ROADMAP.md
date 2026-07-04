# Books Roadmap

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
- ASC app records: in progress via browser (New App dialog) — confirm both "Books" (iOS) and "Books Mac" (macOS) got created

Remaining:
1. Confirm both app records exist: `asc apps list --bundle-id com.heyitsmejosh.books,com.heyitsmejosh.books.mac`
2. Archive + upload using the existing ship pipeline: `~/.claude/skills/icon-audit/ship.sh ~/Documents/Code/books/ios BooksApp` and `... BooksAppMac` (uses `-allowProvisioningUpdates`, auto-creates profiles against the existing distribution certs — no new certs needed, team already has `iPhone Distribution` and `3rd Party Mac Developer Application` certs for QMM486NPYC)
3. Fill minimum ASC metadata (category, privacy) to get past "Prepare for Submission"; screenshots/description can follow once a build is processing
4. Commit the `ios/BooksApp/Assets.xcassets` + `project.yml` changes (not yet committed as of this session)

## After summaries are done
1. `cd ~/Documents/Code/books && ./sync-summaries.sh`
2. Add `<a href="summary.html?b=<slug>" class="badge">Summary</a>` in `index.html` for each new book (see Agentic AI entry for pattern)
3. Update `book_rankings.md` in parallel (both files must stay in sync)
4. Commit + push

## Known issues fixed
- `summarize.sh`: subprocess was inheriting `CLAUDE_CODE_SESSION_ID` and hallucinating. Fixed with `env -u` to strip session vars before calling `claude -p`.
- PC for Dummies ch1–7: photos permanently lost (bad summary passed validation, originals deleted). Needs re-photographing.
- Agentic AI ch12: photos permanently lost same way. Summary was later recovered manually.
