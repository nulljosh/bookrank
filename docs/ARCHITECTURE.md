# Architecture

A book ranking and summary site where users browse ranked books, write chapter-by-chapter summaries, and listen to summaries narrated as dialogue. The app ships on web (PWA), iOS, and Android (Kotlin Multiplatform).

## How it runs

**Web**: `index.html` is the landing page (hero, cover wall, app links). `rankings.html` displays the public ranked shelf (search, sort by rating, genre). `library.html` is the private per-account workspace: logged-in users see their own summaries, edit them, and listen to chapters read aloud. `listen.js` is the shared player (also used by `share.html` for shared links). Auth state is tracked via Supabase, session stored in browser localStorage.

**iOS**: `ios/Bookrank/BookrankApp.swift` is the entry point, renders `LibraryView`. Users sign in via `AccountView`, then browse the bundled rankings (from `books.json`), read/listen to their Supabase summaries, and manage account settings. `Speaker.swift` is the chapter player (mirrors `listen.js`), using AVSpeechSynthesizer. All summaries are fetched on sign-in and cached.

**Android/Desktop (KMP)**: `kmp/composeApp/src/commonMain/kotlin/com/nulljosh/bookrank/AppScreen.kt` is the shared entry point. Platform-specific `MainActivity.kt` (Android) and `Main.kt` (Desktop) initialize the Compose runtime.

## Web

| File | What it owns |
|---|---|
| `index.html` | Landing page, hero, cover wall (fetched from `scripts/covers.json` at runtime), app store links, feature callouts |
| `rankings.html` | Public ranked book list with search/sort/star ratings, pages generated from `books.json` by `scripts/build.py` |
| `library.html` | Private per-account summaries (Supabase bookrank_summaries table), full Markdown editor, share button, WebMCP bridge for Claude tools |
| `share.html` | Public view of a shared summary (via `share_token`), read-only player for anyone with the link |
| `profile.html` | User profile page (username, avatar generation), stats (books read, summaries written), account links |
| `privacy.html` | Privacy policy |
| `listen.js` | Shared chapter player (used by `library.html`, `share.html`), AVSpeechSynthesis polyfill for speaking summaries, chapter parsing from Markdown |
| `listen.test.js` | Unit tests for listen.js player with a fake speech synthesizer |
| `narrate.test.js` | Unit tests for API narration script parsing |
| `profile.test.js` | Unit tests for profile avatar SVG generation |
| `onboarding.js` | Reusable first-run onboarding modal (used by all Bookrank products) |
| `sw.js` | Service worker, network-first for pages, cache-first for hashed assets, v6 cache strategy |
| `books.test.js` | Unit tests for `books.json` data integrity (no duplicate ranks, no missing titles) |
| `tokens.css` | Design tokens (colors, fonts, spacing), synced from portfolio theme |
| `devices.css` | Responsive device frame CSS for landing page screenshots (iPhone, iPad, Mac frames) |
| `webmcp.js` | WebMCP tool registration for Claude integration in library.html |

## iOS

| File | What it owns |
|---|---|
| `ios/Bookrank/BookrankApp.swift` | App entry point, root scene, navigation setup, share overlay |
| `ios/Bookrank/Views/LibraryView.swift` | Main tab view: sections (Ranked, Summaries, Picks, Loans), search toggle, account sheet |
| `ios/Bookrank/Views/SummaryDetailView.swift` | Summary reader, chapter parsing from Markdown, chapter list navigation, Listen tab |
| `ios/Bookrank/Views/AccountView.swift` | Sign in, sign up, account deletion, username/avatar setup |
| `ios/Bookrank/Views/BadgeLabel.swift` | Small uppercase badge component |
| `ios/Bookrank/Views/DueDateBadge.swift` | Loan due-date countdown badge (historical, unused when loans array is empty) |
| `ios/Bookrank/Models/AuthStore.swift` | Supabase auth (email+password, biometric login), session management, metadata persistence |
| `ios/Bookrank/Models/DataStore.swift` | @Observable store, bundles `books.json`/`library.json`/`picks.json` at init, fetches `bookrank_summaries` table, coverage matching for book covers |
| `ios/Bookrank/Models/Book.swift` | Book struct (title, author, rank, Goodreads URL, optional rating), Library/TopPick containers, SummaryEntry for Supabase rows |
| `ios/Bookrank/Models/Speaker.swift` | Chapter player over AVSpeechSynthesizer, mirrors `listen.js` (fetches scripts via `/api/narrate`, reads Markdown blocks), chapter parsing |
| `ios/Bookrank/Models/KeychainHelper.swift` | macOS/iOS keychain storage for credentials |
| `ios/Bookrank/Models/SessionKeychainStorage.swift` | Supabase session storage in macOS data-protection keychain |
| `ios/UITests/PreviewScreenshot.swift` | Screenshot capture for App Store (via fastlane snapshot helper) |

## Cloudflare Functions (/api)

| File | What it owns |
|---|---|
| `functions/api/[[route]].js` | REST router, dispatches to `callTool()` in `src/lib/tools.js`, error handling |
| `functions/mcp.js` | WebMCP over HTTP, JSON-RPC transport for Claude integration |
| `functions/api/narrate.js` | POST `/api/narrate`: takes chapter text + number, calls Claude to generate dialogue script (two hosts A/B), caches result on `bookrank_summaries.listen` |
| `functions/api/summarize-photo.js` | POST `/api/summarize-photo`: multipart upload, reads image with Workers AI Vision, returns text summary, auth-gated to signed-in users |

## Data and models

| File | What it owns |
|---|---|
| `books.json` | Single source of truth: ranked books (title, author, Goodreads URL, rating, rank), sections (ranked, picks, recently read, summaries), generated to `rankings.html` and iOS JSON resources |
| `summaries/` | User-written chapter summaries, one `.md` file per book (copied from iCloud Drive via `sync-summaries.sh`) |
| `scripts/covers.json` | Cache of book cover URLs, fetched from Open Library / Google Books by `scripts/fetch-covers.py`, nullable entries for books with no cover |
| `iOS/Bookrank/Resources/books.json` | Generated from `books.json` by `build.py`, bundled into app (curated ranked list) |
| `iOS/Bookrank/Resources/library.json` | Generated from `books.json` by `build.py`, bundled into app (loan/checkout metadata, empty loans array) |
| `iOS/Bookrank/Resources/picks.json` | Generated from `books.json` by `build.py`, bundled into app (recommended picks) |
| `iOS/Bookrank/Resources/summaries/` | Pre-packaged summaries in app bundle |

## Build and generation

| File | What it owns |
|---|---|
| `scripts/build.py` | Regenerates `rankings.html` rows and iOS JSON resources from `books.json`, fails loudly on invalid data (duplicates, missing ratings) |
| `scripts/test-build.py` | Unit tests for `build.py`, ensures no regression on the "71 of 111" bug |
| `scripts/fetch-covers.py` | Queries Open Library and Google Books for cover URLs, caches results in `scripts/covers.json` |
| `scripts/make-appicon.sh` | Renders `icon.svg` to all iOS app icon sizes, asserts correct dimensions and no alpha channel |
| `scripts/build-site.sh` | Composes final site: landing at `/`, web app at `/app/` |
| `sync-summaries.sh` | Syncs chapter summaries from iCloud Drive into `summaries/` (read-only in this repo) |
| `scripts/prepare-plist.py` | Post-xcodegen plist patch: injects keys xcodegen drops (CFBundleVersion, CFBundleShortVersion) |
| `iOS/UITests/SnapshotHelper.swift` | Fastlane snapshot library for App Store screenshot capture |

## KMP (Kotlin Multiplatform)

| File | What it owns |
|---|---|
| `kmp/composeApp/src/commonMain/kotlin/com/nulljosh/bookrank/AppScreen.kt` | Shared Compose UI, library list, ranking view |
| `kmp/composeApp/src/androidMain/kotlin/com/nulljosh/bookrank/MainActivity.kt` | Android activity entry |
| `kmp/composeApp/src/desktopMain/kotlin/com/nulljosh/bookrank/Main.kt` | Desktop window setup |

## TUI (Terminal)

| File | What it owns |
|---|---|
| `tui/main.swift` + `Package.swift` | Quick-reference card: ranked books with ratings and Goodreads links (NOT a live mirror, static data from `books.json`) |

## External services

**Supabase (spark project)**: auth (email+password), `bookrank_summaries` table (user summaries), `bookrank_summaries.listen` JSONB (narration scripts and playback position), per-account RLS.

**Claude API** (via `/api/narrate`): generates two-host dialogue scripts for chapters, called during summary reading on iOS/web, results cached in the database.

**Workers AI Vision**: photo OCR via `/api/summarize-photo`, requires signed-in user, no persistence (photo never written to disk/R2/Supabase).

**Open Library + Google Books**: book cover lookups, results cached in `scripts/covers.json`.

## Gotchas

**Data integrity**: `books.json` is the canonical source. Generated files (`rankings.html`, iOS resources) must be regenerated by `build.py` after any edit, never hand-edited.

**Cover caching**: `null` entries in `scripts/covers.json` mean "both APIs returned nothing", persisting forever. Never swallow exceptions; let network errors propagate so failed lookups are not cached as misses.

**Single-source bundle IDs**: `com.heyitsmejosh.spine` is bound to ASC record 6792376485, do not rename without recreating the app record. `@AppStorage("spine-theme")` is a persisted key on shipped devices, renaming it silently resets every user's theme.

**Chapter parsing**: iOS `Speaker.parseChapters()`, web `listen.js chapters()`, and KMP `chapters()` all follow the same rule: coarsest heading level yielding two or more (e.g., `#` before `##`). Mismatch between platforms causes playback issues.

**Listen auth**: `onAuthStateChange` fires on every tab focus. `library.html` only reacts when sign-in state *flips*, not on every event, to avoid killing playback during rebuild.

**Summaries are private**: `library.html` shows only the logged-in user's summaries (RLS enforced). No bundled content contains user data.
