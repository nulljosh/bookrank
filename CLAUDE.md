# Kernel (ex-Bookrank)

Chapter summaries of the books you own, read or listen to, on the web, iPhone, iPad and Mac. Renamed Bookrank to Kernel on 2026-10-28; earlier names were Books, Spine and Uprighty. Folder `~/Documents/Code/bookrank`, repo `nulljosh/bookrank`, ASC app `6792376485` (one record, iOS and Mac). History is in `docs/CHANGELOG.md`, the plan in `roadmap.md`, the loop state in `docs/LOOP-HANDOFF.md`.

**Old names kept on purpose** (renaming breaks installs, settings or the API): bundle id `com.heyitsmejosh.spine`, `spine-theme`, the `bookrank_summaries` table, `bookrank.*` UserDefaults and localStorage keys, the `bookrank` onboarding key, the `bookrank-data` cache, the `X-Bookrank-App` header, the KMP package `com.nulljosh.bookrank`, the Pages project `bookrank`, the Mac profile "Bookrank Mac App Store", and bookrank.jaybulb.com.

## Map
- `library.html`: the web app (your summaries, the player, highlights, Ask, Goodreads). Its data layer is `rows`; every read goes through `cached()` so it works offline.
- `listen.js` + `listen.css`: the player, shared by `library.html` and `share.html`. `marks.js` merges highlights, `goal.js` the weekly goal.
- `spark.js`: the client for jaybulb-api (api.jaybulb.com). `functions/api/`: speak, narrate, ask, goodreads, apple receipts.
- `sw.js`: the service worker. Bump `CACHE` on every web change that touches a precached file.
- `ios/`: SwiftUI app for iPhone, iPad and Mac from `ios/project.yml`. Run `git checkout ios/Kernel/Info.plist` after xcodegen or xcodebuild.
- `books.json`: feeds the public /api, the MCP tools and cover matching.
- Deploy the web: `sh scripts/build-site.sh` then `npx wrangler pages deploy dist --project-name bookrank --branch main`. A push deploys nothing.

## Rules
- **updated_at moves only on content edits.** jaybulb-api ignores a client `updated_at` and stamps a new one only when `content` is in the body. `listen.for` must equal the row's `updated_at` or the saved position and scripts are dropped.
- **Auth listener.** `onAuthStateChange` fires on every tab focus and refresh. `library.html` reacts only when signed-in state flips, or the list rebuilds and playback dies.
- **Chapters** are the coarsest heading level with two or more, `#` before `##`. `Speaker.swift`, `listen.js` and the KMP reader follow the same rule.
- **Covers.** Never save a cover from a title-only search, and never cache a failed lookup as a miss. Icons come from `scripts/make-appicon.sh`, never a hand export.
- **Goodreads** cookies and shelves stay on the device. Never send them to the server, and never sign in as Joshua.
- **No audio in QA.** `Speaker.play` returns under `UITEST_PLAYER` and `UITEST_SNAPSHOT`; never press Listen in a simulator.
- **Screenshots on every UI change**, light and dark: `sh ios/scripts/shots.sh` (headless simulators, shut down after). On the Mac pass flags dash-style (`-UITEST_SNAPSHOT 1`), or AppKit opens them as files.
- **Store screenshots** avoid objectionable book text (The Contrarian, The Optimist).

## Auth and paying
Web and apps sign in through jaybulb-api. The apps keep the refresh token in the data-protection keychain and refresh single-flight (refresh tokens are single use). Natural voices are paid for by the App Store price: new builds send StoreKit's AppTransaction as `X-Kernel-Receipt`, checked in `functions/api/apple.js`. Builds up to 1.2.1 still send `X-Bookrank-App` with a Supabase token; keep that path and the Supabase project until nobody runs 1.2.x.
