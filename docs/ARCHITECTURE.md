# Architecture

![How Kernel fits together](../architecture.svg)

Your summaries live in one table on jaybulb-api (api.jaybulb.com, a Cloudflare Worker on D1). The web, iPhone, iPad and Mac all sign in there and read the same rows. Everything that costs money or needs a key (the narrator, the voices, page photos, Ask, payments) runs as Pages Functions beside the website at bookrank.jaybulb.com. Goodreads is read on your own device and never touches either server. The rules every platform shares are in [CLAUDE.md](../CLAUDE.md).

## Web

| File | What it owns |
|---|---|
| `index.html` | Landing page, with the real reader on a sample chapter |
| `library.html` | The app: sign in, your books, the reader and editor, highlights, Ask, Goodreads, the weekly goal |
| `share.html` | A shared summary for anyone with the link, no account |
| `profile.html`, `privacy.html` | Profile and account deletion; the privacy policy |
| `listen.js`, `listen.css` | The player: chapters, one line at a time, word highlight, speed, sleep, highlights |
| `marks.js` | Highlights merge across devices, Today's five, the Markdown export, `catchUp` for late listening saves |
| `goal.js` | The weekly listening goal |
| `covers.js` | Cover thumbnails and share links |
| `goodreads-parse.js` | Reads a signed-in Goodreads page into plain data, run on the device by the apps |
| `spark.js` | The jaybulb-api client: sign-in, refresh, rows, retries with backoff |
| `outbox.js` | Saves made offline, sent when the connection returns |
| `search.js`, `meaning.js` | Search inside chapters; search by meaning over an on-device index |
| `voices.js`, `card.js` | Narrator choice; highlight and year share cards |
| `kindle.js`, `epub.js`, `goodreads-export.js` | Imports: Kindle clippings and Readwise, EPUB, a Goodreads export CSV |
| `i18n.js`, `i18n/` | French, Spanish and German for the fixed text, by the browser's language |
| `public-profile.js` | Someone's public profile, and your switches for yours |
| `sw.js` | Service worker: the shelf and every book work offline |
| `onboarding.js`, `webmcp.js` | First-run pages; WebMCP tools for agents in the browser ([API](API.md)) |
| `tokens.css`, `devices.css`, `brand/`, `screens/` | Design tokens, landing frames, the brand kit at /brand, the landing's iPhone screens |

## Apps

One SwiftUI codebase builds `Kernel` (iPhone and iPad) and `KernelMac` from `ios/project.yml`.

| File | What it owns |
|---|---|
| `Views/LibraryView.swift` | The library: Continue card, search, Goodreads shelves; split view on iPad, three columns on the Mac |
| `Views/SummaryDetailView.swift` | A book's chapters and the chapter reader with the word that follows the voice |
| `Views/PlayerBar.swift`, `Views/NowPlaying.swift` | The mini player and the full player sheet |
| `Views/AddPagesView.swift`, `Views/AskView.swift` | A chapter from page photos; one question to a chapter |
| `Views/AccountView.swift` | Sign in, Goodreads, goal, voice meter, export, delete account |
| `Views/SplashView.swift`, `Views/OnboardingView.swift` | Launch splash and first-run pages |
| `Models/API.swift`, `Models/AuthStore.swift`, `Models/KeychainHelper.swift` | jaybulb-api rows and sign-in, tokens in the data-protection keychain |
| `Models/DataStore.swift`, `Models/Book.swift` | Summaries, covers, listen state and its merge |
| `Models/Speaker.swift` | The player on AVSpeechSynthesizer or the natural voice, downloads |
| `Models/Narrator.swift`, `Models/Goal.swift`, `Models/Nudge.swift` | Voice usage, the weekly goal, the daily review nudge |
| `Models/Goodreads.swift` | Goodreads sign-in in a web view; shelves stay on the device |
| `Models/WatchSync.swift`, `ios/KernelWatch/` | Lines for the watch app, retired since 2026-10-02 |
| `ios/UITests/`, `ios/scripts/shots.sh` | Store screenshots, headless, never with sound |

All paths above are under `ios/Kernel/` unless they say otherwise.

## Limits

Every route that calls a model or another site is capped per person (by IP) per hour in `src/lib/quota.js`: narrate 120, ask 60, embed 600, summarize-photo 120, goodreads 60, then a 429. The counts live in the edge cache, so they cost nothing and write no KV. The natural voices keep their own daily and monthly character budgets in KV (`speak.js`). Narrate, ask, embed and summarize-photo also need a sign-in or a share token; the Stripe webhook checks its signature. Every page is served with `_headers`: no framing, no plugins, HSTS, and no camera, microphone or location. Page text from users is escaped before it is written as HTML, and avatars load only as images.

## Startup budget

The app's own work before the first frame stays under 50 ms: `KernelApp.init` (fonts, the navigation bar font, the notification delegate) and `DataStore.init` (books.json and the offline library). Everything else that is slow waits for `.task` after the first frame. Measured 2026-10-29 on the iPhone 17 Pro Max simulator, Release build: 2.2 s cold launch, of which about 1.4 s is the simulator loading its own runtime, about 0.25 s is SwiftUI and UIKit, and about 30 ms is Kernel.

`SpeedWalk/testLaunchTime` measures cold launch five times. For the breakdown, record a trace and read the main thread:

```
xcrun xctrace record --template 'Time Profiler' --device <simulator id> --time-limit 4s --output launch.trace --launch -- <path to Kernel.app> -kernel.onboarded YES
```

## Share-link readers

`kmp/` (Android and desktop, Kotlin Multiplatform) and `tui/` (`kernel-tui`, SwiftTUI) open a share link and read that summary, no account. Both still ask the old Supabase project for shared rows, so links made since the move to jaybulb-api do not open there yet (open in roadmap.md).

## Server

| File | What it does |
|---|---|
| `functions/api/narrate.js` | Turns a chapter into a one-narrator script (Workers AI, Llama 3.3), cached on the row |
| `functions/api/speak.js` | One line in a natural voice with word timings: ElevenLabs, then Cloudflare Aura-2, then the device voice. Every line stored for good in KV, with monthly and daily caps |
| `functions/api/ask.js` | Answers a question from one chapter's notes, metered like the voices |
| `functions/api/summarize-photo.js` | Reads a photographed page, nothing stored |
| `functions/api/embed.js` | Embeds paragraphs for search by meaning (Workers AI, bge-small) |
| `functions/api/forget.js` | Clears an account's voice counters, $1 record and stored narration before it is deleted |
| `functions/share.js` | The book's title and cover in a share link's preview; indexable only with a public profile |
| `src/lib/quota.js` | The hourly cap per person on every model and Goodreads route |
| `functions/api/goodreads.js` | The public Currently Reading box; everything else needs the sign-in on the device |
| `functions/api/apple.js` | Checks StoreKit's AppTransaction (`X-Kernel-Receipt`) to prove an app was bought |
| `functions/api/pay.js`, `functions/api/stripe-webhook.js` | The $1 web unlock and the webhook that flags the account |
| `functions/api/usage.js` | How much voice you and the app have used |
| `functions/api/[[route]].js`, `functions/mcp.js`, `src/lib/tools.js` | The public read-only /api and /mcp over `books.json` |
| `wrangler.toml` | Binds Workers AI and the `TTS_KV` store |
| `supabase/` | The old backend, kept until 1.2.x builds age out |

## Tests and scripts

`node --test` runs the web and server tests (`*.test.js`, `src/lib/tools.test.mjs`); `scripts/test-build.py` and `scripts/test-speech-chunks.mjs` cover the build and speech chunking. `scripts/build-site.sh` builds `dist/`. `scripts/make-appicon.sh` renders every icon, `scripts/gen_font.py` builds Kernel Sans, `scripts/fetch-covers.py` finds covers, `scripts/import-summaries.py` and `sync-summaries.sh` bring summaries in from iCloud, and `scripts/summary-to-masterclass.py` converts one for Patois. `scripts/build.py` still expects the retired rankings page (open in roadmap.md). The ad is built by `ad/make.py` from `ad/ad.txt`.
