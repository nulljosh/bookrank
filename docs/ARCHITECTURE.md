# Architecture

Chapter summaries of the books you read. Open a book, pick a chapter, read it or listen to it. Web, iPhone, iPad, Mac, Android and desktop share one account and one table. There are no rankings anymore; the product went summaries-only on 2026-09-21.

## How it runs

**Web**: `index.html` is the landing page. `library.html` is the app: sign in, see your summaries, open one, read or listen chapter by chapter. `listen.js` is the player, shared with `share.html` so anyone with a link can listen without an account. Supabase holds auth and the `bookrank_summaries` table.

**iOS and macOS**: one SwiftUI codebase, two targets. `LibraryView` is a plain list of covers and titles, books you are partway through first. A book opens to its chapters (`SummaryDetailView`). A chapter opens to its text with one Listen button; the word being read is bold and dark and the rest of the line dims. `Speaker.swift` mirrors `listen.js` on AVSpeechSynthesizer.

**Android and desktop (KMP)**: a share-link reader. Paste a link, read that summary. No account, no list.

**Terminal**: `bookrank-tui <query>` searches summaries through `/api/search`; `bookrank-tui share <link>` reads one.

**Watch**: a standalone port of the old ranked shelf, read from bundled JSON. It predates the summaries pivot and has not moved yet (see roadmap).

## Web

| File | What it owns |
|---|---|
| `index.html` | Landing page: hero, cover wall built at runtime from `scripts/covers.json`, store links |
| `library.html` | The app: sign in (email, Apple, Google, GitHub), summary list, reader, editor, share button |
| `share.html` | Read-only player for a shared summary, keyed by `share_token`, no account needed |
| `profile.html` | Profile page: username, generated avatar, email and password changes, account deletion |
| `privacy.html` | Privacy policy |
| `listen.js` | The player: chapter parsing, one utterance at a time, next chapter prefetched, word and line highlight |
| `onboarding.js` | First-run onboarding modal |
| `webmcp.js` | Registers the WebMCP tools so an agent in the browser can search and read summaries |
| `sw.js` | Service worker: network first for pages, cache first for hashed assets |
| `tokens.css` | Design tokens shared with the portfolio |
| `devices.css` | Device frames for the landing page demo |
| `manifest.webmanifest`, `robots.txt`, `sitemap.xml`, `_redirects` | PWA manifest, crawler files, and the `/rankings.html` to `library.html` redirect |

## Tests

| File | What it checks |
|---|---|
| `listen.test.js` | The player against a fake speech synth: chaining, prefetch, resume, highlight |
| `narrate.test.js` | `/api/narrate` script parsing, intro only on chapter one, outro only on the last |
| `profile.test.js` | Avatar generation and username defaults |
| `books.test.js` | `books.json` integrity: no duplicate titles, required fields present |
| `goodreads.test.js` | Goodreads feed and profile parsing: titles, entities, pages, best-quote pick |
| `speak.test.js` | ElevenLabs character timings turned into word timings |
| `src/lib/tools.test.mjs` | Tool filtering, pagination and title resolution |
| `scripts/test-build.py` | `build.py` fails loudly on bad rows instead of silently dropping them |
| `scripts/test-speech-chunks.mjs` | Read-aloud chunks stay under 200 characters, nothing dropped, offsets map back |

## iOS and macOS

| File | What it owns |
|---|---|
| `ios/Bookrank/BookrankApp.swift` | App entry, root scene |
| `ios/Bookrank/Views/LibraryView.swift` | The list: covers and titles, search over titles and text, resume line, the Goodreads read-but-unsummarized section, empty and signed-out states, theme and account buttons |
| `ios/Bookrank/Views/SummaryDetailView.swift` | Chapter parsing, the chapter list for a book, and the chapter reader with the marker word highlight that the page follows, even through long paragraphs |
| `ios/Bookrank/Views/AccountView.swift` | Sign in with Apple or email, the Goodreads link with photo, quote and genres, export everything as markdown, password reset, sign out, delete account |
| `ios/Bookrank/Models/Speaker.swift` | The player on AVSpeechSynthesizer, two-host scripts from `/api/narrate`, `ListenControls` toolbar |
| `ios/Bookrank/Models/DataStore.swift` | Fetches `bookrank_summaries`, cover lookup (row cover, then `books.json` by title), share links, listen position saves, screenshot sample shelf |
| `ios/Bookrank/Models/AuthStore.swift` | Supabase email and password auth, session restore |
| `ios/Bookrank/Models/Book.swift` | `Book` (for cover matching), `SummaryEntry`, `ListenState` |
| `ios/Bookrank/Models/KeychainHelper.swift` | Small keychain read and write helper |
| `ios/Bookrank/Models/SessionKeychainStorage.swift` | Supabase session storage in the data-protection keychain |
| `ios/Bookrank/Resources/books.json` | Bundled copy of `books.json`, used only to match covers by title |
| `ios/Bookrank/Resources/summaries/` | Sample summaries for screenshot mode |
| `ios/project.yml` | xcodegen spec for the `Bookrank` and `BookrankMac` targets |
| `ios/scripts/prepare-plist.py` | Patches the plist keys xcodegen drops |
| `ios/UITests/PreviewScreenshot.swift` | App Store screenshots: list, chapters, chapter text, on the sample shelf |
| `ios/UITests/SnapshotHelper.swift` | fastlane snapshot helper |

## Watch

| File | What it owns |
|---|---|
| `watchos/BookrankWatchApp.swift` | Watch app entry |
| `watchos/ContentView.swift` | Tab view over the three lists |
| `watchos/Models/BookStore.swift` | Reads the bundled JSON off disk, no network |
| `watchos/Models/WatchModels.swift` | Same models as iOS, same three JSON files |
| `watchos/Views/ShelfView.swift` | Top of the old ranked shelf |
| `watchos/Views/ToReadView.swift` | Books flagged for later |
| `watchos/Views/TopPicksView.swift` | The curated picks list |
| `watchos/Resources/*.json` | `books.json`, `library.json`, `picks.json` copied from the iOS bundle |
| `watchos/project.yml` | xcodegen spec |

## KMP

| File | What it owns |
|---|---|
| `kmp/composeApp/src/commonMain/kotlin/com/nulljosh/bookrank/AppScreen.kt` | Share-link box and the shared summary reader with chapters |
| `kmp/shared/src/commonMain/kotlin/com/nulljosh/bookrank/BookrankClient.kt` | Calls the public `shared_summary` RPC, parses chapters with the same rule as web and iOS |
| `kmp/composeApp/src/androidMain/kotlin/com/nulljosh/bookrank/MainActivity.kt` | Android entry |
| `kmp/composeApp/src/desktopMain/kotlin/com/nulljosh/bookrank/Main.kt` | Desktop window |
| `kmp/settings.gradle.kts`, `kmp/composeApp/build.gradle.kts`, `kmp/shared/build.gradle.kts`, `kmp/gradle/libs.versions.toml` | Gradle build and pinned versions |

## Terminal

| File | What it owns |
|---|---|
| `tui/main.swift` + `Package.swift` | SwiftTUI one-shot card: live search through `/api/search`, or read a share link |

## Server

| File | What it owns |
|---|---|
| `functions/api/[[route]].js` | REST router over `src/lib/tools.js` (`/api/search` and friends) |
| `functions/mcp.js` | MCP over HTTP, JSON-RPC |
| `functions/api/narrate.js` | `/api/narrate`: turns a chapter into a two-host script, caches it on the row |
| `functions/api/goodreads.js` | `/api/goodreads`: reads a public Goodreads profile's shelf RSS (read, currently reading, to read) and, with `profile=1`, its photo, genres, about, interests and best quote. No credentials; Goodreads has no app sign-in |
| `functions/api/speak.js` | `/api/speak`: one line in a natural ElevenLabs voice (host A or B) with per-word start times. Each line is stored for good in KV (`TTS_KV`), so it is paid for once; a monthly character budget for the app and a daily one per account, over either it answers 429 and the player uses the device voice; chapter one uses the better model (`TTS_MODEL_BEST`), the rest the cheap one; voices and caps come from env. Share-token, or signed in and paid: the apps send `X-Bookrank-App` (paid upfront), the web needs the `paid:<user>` flag in KV, else 402 and the device voice |
| `functions/api/pay.js` | `/api/pay`: GET says whether the account has paid; POST opens a Stripe Checkout page for the $1 that unlocks natural voices on the web |
| `functions/api/stripe-webhook.js` | `/api/stripe-webhook`: checks Stripe's signature with WebCrypto, then writes `paid:<user>` to KV on a completed checkout |
| `functions/api/summarize-photo.js` | `/api/summarize-photo`: reads a book page photo with Workers AI, signed-in users only, nothing stored |
| `src/lib/tools.js` | The tool layer both the REST and MCP routes call |
| `supabase/functions/delete-account/index.ts` | Shared delete-account endpoint for every app on the spark project |
| `supabase/migrations/20260905_share_listen.sql` | `share_token` column plus the `shared_summary` and `cache_shared_script` RPCs |
| `wrangler.toml` | Pages config that makes `functions/` ship with the site, and binds the `TTS_KV` line store |

## Data and scripts

| File | What it owns |
|---|---|
| `books.json` | The old book list. Kept for cover matching and the watch app; nothing on the web reads it for display |
| `summaries/` | Summary markdown, one file per book, synced from iCloud Drive |
| `scripts/covers.json` | Cover lookup cache. `null` means both sources answered with nothing |
| `scripts/build.py` | Regenerates the iOS and watch JSON from `books.json`, fails loudly on bad rows |
| `scripts/fetch-covers.py` | Finds covers on Open Library and Google Books, writes them into `books.json` |
| `scripts/import-summaries.py` | Uploads `summaries/*.md` into the owner's private rows |
| `scripts/summary-to-masterclass.py` | Converts a summary into Lexly masterclass JSON |
| `scripts/make-appicon.sh` | Renders `icon.svg` to every app icon size and checks the pixels |
| `scripts/build-site.sh` | Builds `dist/`: landing at `/`, app beside it |
| `sync-summaries.sh` | Copies finished summaries from iCloud Drive into `summaries/` |

## The ad

| File | What it owns |
|---|---|
| `ad/ad.txt` | The script. Eight sentences, one visual each, no version number |
| `ad/make.py` | Builds the ad: ElevenLabs reads the script with per-character timings, every cut lands on a sentence, real screenshots sit in an ink bezel on the paper, type cards, end on the mark, voice ducked over the music |
| `ad/music.py` | The Joshua Tree music bed (numpy only), cut to the ad's length by `make.py` |
| `ad/shots/` | The screenshots the ad uses, copied from the fastlane run |
| `ad/ad-poster.jpg` | The frame the README and landing show before play |

## External services

**Supabase (spark project)**: auth (email, Apple, Google, GitHub, X), the `bookrank_summaries` table with per-account RLS, the `listen` jsonb (scripts and position), the `cover` column, share RPCs.

**authmail**: a Cloudflare Worker that brands every auth email per app and sends it through Resend.

**Claude** (through `/api/narrate`): writes the two-host scripts, cached on the row.

**Workers AI**: page photo reading in `/api/summarize-photo`.

**Goodreads**: public shelf RSS and profile page, read by `/api/goodreads` and linked from the profile page.

**Open Library, Amazon covers**: cover images, stored on each row's `cover` column.

## Gotchas

**Covers live on the row.** Every summary row carries its own `cover`. Title search alone picks the wrong book (it once gave The Optimist a Matt Ridley cover and AI in Business a Hamlet title page), so covers are checked by title and author before they are saved.

**Bundle ID stays.** `com.heyitsmejosh.spine` is bound to ASC record 6792376485. `@AppStorage("spine-theme")` is a persisted key on shipped devices; renaming it resets every user's theme.

**One chapter rule everywhere.** iOS `parseChapters`, web `listen.js chapters()` and KMP `chapters()` use the coarsest heading level that yields two or more. If they disagree, playback lands in the wrong chapter.

**Listen position is tied to content.** `listen.for` must equal the row's `updated_at` or the saved scripts and position are thrown away.

**Auth events.** `onAuthStateChange` fires on every tab focus. `library.html` only reacts when the signed-in state flips, or it rebuilds the list and kills playback.

**Summaries are private.** RLS keeps each account to its own rows. Nothing bundled contains user data.
