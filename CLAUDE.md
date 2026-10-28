# Kernel (ex-Bookrank)

Chapter summaries of the books you own, read or listened to. Renamed Bookrank to **Kernel** on 2026-10-28: the ASC name is reserved on the editable 1.3.0 app info (Apple's probe: Kernel, Exordium and Gravamen were the only free real words out of about 130), the code, Xcode targets (`Kernel`, `KernelMac`, `ios/Kernel/`), icon (`Kernel.icon`) and font (Kernel Sans) are renamed. Earlier names: Books, Spine, Uprighty, Bookrank. Folder is `~/Documents/Code/bookrank`.

**Still on old names on purpose** (renaming breaks installs, saved settings or the API): bundle id `com.heyitsmejosh.spine`, `spine-theme`, the `bookrank_summaries` table, `bookrank.*` UserDefaults and localStorage keys (`rate`, `voice`, `mode`, `natural`, `explain`, `nudge`, `biometric.email`), the `bookrank` onboarding key, the `bookrank-data` cache, the `X-Bookrank-App` header, the KMP package `com.nulljosh.bookrank`, the Pages project `bookrank`, the Mac provisioning profile "Bookrank Mac App Store", and bookrank.jaybulb.com (keeps serving; kernel.jaybulb.com waits on adding the custom domain).

## Pivot: summaries only (2026-09-21)
The product is chapter summaries. No rankings, no recommendations, no lists on the web. `rankings.html` and `book_rankings.md` are deleted; `/rankings.html` 301s to `library.html` via `_redirects`. `books.json` stays only because the iOS/macOS shelf and cover matching still read it. iOS/macOS (2026-10-02): `LibraryView` is a plain list of covers and titles; a book opens to its chapters, a chapter to its text with one Listen button. KMP is a share-link reader and the TUI searches summaries, both done. The watch app was retired 2026-10-02 (never shipped). `books.json` stays: it feeds the public /api and MCP tools and the cover fallback. Every summary row has a verified `cover` (24 of 24, 2026-10-02); never save a cover from a title-only search.

## Files
- `books.json`: **the single source of truth for every book list.** Edit this, nothing else.
- `scripts/build.py`: regenerates `rankings.html` (inside `<!-- generated:* -->` markers), `book_rankings.md`, and the three `ios/Kernel/Resources/*.json` files from `books.json`. Run after every edit.
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
Every library book is returned. The old "Out From The Library" section, its `data-due` countdown badge and the matching iOS `DueDateBadge` exist only as history, do not reintroduce a checkout or due-date feature without a real data source. `ios/Kernel/Resources/library.json` carries `loans: []`; the iOS view already renders nothing when it is empty, which is why only the web page ever went stale (its list was hardcoded inline).

## Chapter summaries (photographed books)
Raw phone photos of physical books, their per-chapter summaries, and merged book-level markdown live in iCloud Drive at `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Misc/Books/` (not in this repo, too large/private). That folder has its own `summarize.sh` and `CLAUDE.md`.

To expose a finished book's summary on the site:
1. In the iCloud folder, run `./summarize.sh "Book Name"`, converts photos to chapter `summary.md` files (deleting originals on success), then merges them into `<slug>-summary.md` in the book's folder.
2. In this repo, run `./sync-summaries.sh`, copies `<slug>-summary.md` into `summaries/<slug>.md` here.
3. Add a `<a href="summary.html?b=<slug>" class="badge">Summary</a>` link next to the matching book entry in `rankings.html`. `summary.html` renders `summaries/<slug>.md` client-side via `marked`.

## Listen (2026-09-05)
`bookrank_summaries.listen` jsonb = `{ for: <updated_at>, chapters: { "<i>": [{host, line}] }, pos: {ch, line} }`. `for` must equal the row's `updated_at` (PostgREST ISO form, `to_jsonb(updated_at) #>> '{}'` in SQL) or the scripts and position are discarded. The player is `listen.js` (shared by `library.html` and `share.html`; `listen.test.js` drives it with a fake synth). One utterance in flight at a time, chained; the next chapter's script is prefetched. Chapters = the coarsest heading level yielding two or more, `#` before `##`; `Speaker.swift` / `parseChapters` and the KMP `chapters()` follow the same rule. `functions/api/narrate.js` takes `ch`/`total` so only chapter 1 opens and only the last closes (the repeated-intro bug).

**Auth listener rule:** `onAuthStateChange` fires on every tab focus and hourly refresh. `library.html` only reacts when the signed-in state actually flips; reacting to every event rebuilt the list and killed playback.

**Share:** `share_token` column + `shared_summary(t)` / `cache_shared_script(t, ch, script)` security-definer RPCs (`supabase/migrations/20260905_share_listen.sql`). The RPC returns title/content/cover/scripts only. `/api/narrate` accepts `token` in place of a session and caches the result on the row.

**Covers:** row `cover` column, filled by the web on first sight: `books.json` fuzzy match, then Open Library title/general search probed through work/ISBN/edition image URLs (`coverCandidates`). Misses are never cached.

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

## Screenshots, every time the UI changes (2026-10-02)
Joshua's rule: fresh screenshots on every minor or major bump AND every UI fix or glitch patch, without being asked. Run `sh ios/scripts/shots.sh` from the repo root (store set via fastlane snapshot into `ios/fastlane/screenshots/en-US`, plus the signed-out sign-in and create screens as QA PNGs), read the PNGs and fix what looks wrong before shipping, then refresh the README and landing images and attach the new set to the next App Store version. Headless simulators only, shut them down after.

## The loop
Parity and ship loop (iOS and Mac catch up to the web, then ship). Handoff at `docs/LOOP-HANDOFF.md`: what the loop is, where things stand, next in order, restart prompt in a code fence. App Review lesson: keep review notes true every release; if Apple asks for proof, Joshua records 20 seconds on a real phone showing the feature working.

## Native auth: Cloudflare from 1.3 (2026-10-28)
From 1.3 the iOS/Mac apps sign in against jaybulb-api like the web (`Models/API.swift`: refresh token in the data-protection keychain, access token in memory, single-flight refresh because refresh tokens are single use; `AuthStore` does email, Sign in with Apple and delete account; `DataStore` reads and PATCHes `/rest/bookrank_summaries`). supabase-swift is gone. Old Supabase sessions are dead, so everyone signs in once after the update, and email users reset their password once (passwords never moved off Supabase). `KeychainHelper` sets `kSecUseDataProtectionKeychain`, or the Mac asks for the login password (the Lexly 2.1(a) rejection).

Paying for natural voices: the App Store price. New builds send StoreKit's AppTransaction JWS as `X-Kernel-Receipt`; `functions/api/apple.js` verifies the x5c chain to a pinned Apple Root CA - G3, Apple's receipt markers, the signature and the bundle id (`apple.test.js` runs it against a throwaway chain in `test/fixtures/apple`). Builds up to 1.2.1 still send `X-Bookrank-App` with a Supabase token and the anon key as `apikey`; `viaApp` in `speak.js` and the Supabase fallback in `narrate.js` keep them working. Remove both, and the Supabase project, once nobody runs 1.2.x.

## Mac layout (2026-10-11)
`LibraryView` is a `NavigationSplitView` on macOS: books (sidebar list style), chapters with the cover up top (`SummaryDetailView` with a `chapter` binding), then `ChapterView`. iOS keeps the `NavigationStack`. `UITEST_ACCOUNT` opens the Account sheet at launch for screenshots; `UITEST_SNAPSHOT` also fills the Goodreads shelves with sample rows. On the Mac pass them as `-UITEST_ACCOUNT 1` (`CommandLine.flag` reads both forms): AppKit treats a bare argument as a file to open and never shows the window, which is why "snapshot mode opens no window" looked like a SwiftUI bug. The Account form is `.formStyle(.grouped)` on the Mac; the default columns style neither scrolls nor wraps.
