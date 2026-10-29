## Road to 100 (2026-10-28)
One row is one major version in the repo, tagged when it is built and QA'd in light and dark. Apple reviews one version at a time, so the store gets the newest tagged major each time the last one clears review. Summaries stay the heart of the app; Goodreads and the rest sit around them. The last rows before 100 wait on something outside the code: Workers AI (Workers Paid), Joshua's Goodreads sign-in, an App Group for widgets and extensions (set up once in Xcode with Joshua's account), and Apple's CarPlay entitlement; rows move freely; "ask by voice" was dropped as more chat. Rows 5 to 100 are proposals built from the gap matrix, the A+ pass, the code review and the braindumps below; reorder freely. The watch app stays retired (2026-10-02).

| v | What | Where | Status |
|---|---|---|---|
| 3 | Gap rows 1 to 5: minutes, Continue card, line skip, speed presets, sleep timer; resume fix | apps, web | built |
| 4 | Gap rows 6 to 10: highlights, offline audio, add pages, ask the chapter, weekly goal; Goodreads sign-in; book avatars; review fixes | apps, web | built |
| 5 | A big Play / Continue button on the book page (A1) | apps, web | built |
| 6 | Now Playing sheet: big cover, time left, line skip, speed, sleep, chapters (A2) | apps (the web reader already is one) | built |
| 7 | Reader text size and line spacing (A3) | apps, web | built |
| 8 | Goal streak dots under the ring (A4), weekly goal on the web | apps, web | built |
| 9 | Highlights merge across devices instead of last writer wins (review item a) | apps, web | built (three-way merge on save: marks.js and ListenState.merge) |
| 10 | `updated_at` moves only on content edits, in jaybulb-api (review b); one listen stylesheet (review c) | api, web | built (jaybulb-api `touch: ["content"]`, listen.css) |
| 11 | iPad pass: reading column, split view, screenshots | iPad | built (two-column split view on regular width, testIPad) |
| 12 | Mac store screenshots at 2880x1800, signed-in Mac walk | Mac | built (6 shots in ios/fastlane/screenshots/mac, captured at 1440x900 on a 1080p screen and scaled 2x; attach to the next version; signed-in walk is Joshua's step) |
| 13 | Icon and Kernel Sans A+ at small sizes | all | built (16 px icon and favicon redrawn bolder: brand/icon-small.svg; small labels secondary not tertiary; Mac footnote 11 pt) |
| 14 | Cold launch: Release build timing, no white flash | apps | built (Release launch about 3 s in the simulator, Settings 3.6 s; splash follows the app theme from frame one; nav titles get Kernel Sans; iOS launch screen still follows the phone) |
| 15 | Web offline mode: the shelf and chapters work with no connection | web | built |
| 16 | Web offline audio: Download on the web book page | web | built (every line heard or downloaded is kept on the device; Download fetches the rest) |
| 17 | Web Add pages parity: per-photo progress, edit before save | web | built (Add pages button, progress bar, failed pages named, new text selected in the editor until Save) |
| 18 | Search inside chapter text, results jump to the line | apps, web | built (matching line under each result; the book opens on the notes at that line, marked; testSearch) |
| 19 | Collections: put books in your own groups | apps, web | built (one collection per book, a `collection` column on jaybulb-api; library groups A to Z, then Library; testCollections) |
| 20 | Sort and filter the library (recent, title, progress, length) | apps, web | built (Recently edited, Title, Progress, Shortest first; All, In progress, Not started; kept per device; testSortFilter) |
| 21 | Search by meaning: find an idea even when the words differ, no chat | apps, web | built (bge-small through /api/embed, vectors kept per book version in Cache Storage and Application Support; Apple NLEmbedding and NLContextualEmbedding were tried and ranked the right line last; UI checked with a stand-in embedder, the 0.6 floor still to tune on the real model) |
| 22 | All highlights in one place; share a highlight as an image card | apps, web | built (Highlights button on the library, a 1080 gold card from card.js and HighlightCard; the app card is rendered only when shared, not yet seen in a shot) |
| 23 | Export highlights and notes as Markdown | apps, web | built (highlights, by book and chapter: marksMarkdown and exportMarkdown; notes join when row 29 lands) |
| 24 | Daily review: five highlights resurface on a schedule | apps, web | built (Today's five on the library, the same five on every device by FNV of the day, Done until tomorrow; a daily shuffle, not spaced repetition) |
| 25 | Your own note under any chapter | apps, web | built (a `notes` JSON column on jaybulb-api, not in listen, so old builds cannot drop it; in the export too) |
| 26 | "Summarize this" on a Goodreads read book opens Add pages with the title filled in | apps | built (long-press or swipe a Goodreads row; testSummarizeFromGoodreads) |
| 27 | Reading stats: books per year, pages, average rating (Goodreads plus Kernel) | apps, web | built (Your reading under the library: books, chapters, hours, highlights, notes; the apps add Goodreads books finished per year and the average rating; pages wait on page counts from Goodreads) |
| 28 | Year in review | apps, web | built (Share your 2026 under Your reading: a gold card with the year, books finished and summarized, highlights, hours and one highlight; yearCard and YearCard) |
| 29 | Goodreads on the web through your Goodreads export file | web | built (goodreads-export.js parses the CSV in the browser, kept per account in localStorage, cleared on sign-out; never sent to the server) |
| 30 | Import Kindle highlights (My Clippings.txt) | apps, web | built (kindle.js and Kindle.swift; each book gets a Kindle highlights chapter or becomes a new book; only new lines; the app import path checked by parse and UI, not yet with a signed-in write) |
| 31 | Import highlights from a Readwise or Apple Books export | apps, web | built (Readwise CSV through the Kindle path, a Readwise highlights chapter; Apple Books has no export file, so it is out) |
| 32 | Import an EPUB or PDF you own into chapters | apps, web | built (epub.js and Ebook.swift unzip in place, a chapter per spine section; PDF in the apps by outline or ten pages at a time; web PDF waits on a PDF reader worth its size) |
| 33 | Scan pages with the document camera in Add pages | iPhone, iPad | built (VisionKit document camera, flat cropped pages through the same reader; only on a device with a camera, so not seen in the simulator yet) |
| 34 | Read the page text on the device before upload, so photos never leave it | apps | built (Pages: Keep the exact words reads each page with Vision on the device, accurate then fast; no upload, works with no AI quota; checked with a rendered page on the Mac) |
| 35 | Shortcuts: add a summary, play my book, next chapter (braindump 2026-08-19) | apps | built (App Intents: Add a summary, Play or pause, Next chapter, with Siri phrases; in the built metadata; the simulator's Shortcuts app did not list them, check on a device) |
| 36 | Siri: "continue my book" | apps | built (ContinueBookIntent opens the book you are partway through and plays it; testContinueMyBook with a silent stand-in) |
| 37 | Handoff: pick up the same chapter on the Mac | apps | built (NSUserActivity on the book page, web library link for devices without the app; needs two devices to see) |
| 38 | Mac menu bar mini player | Mac | built (MenuBarExtra while a book is loaded: chapter, play or pause, a line back or forward, next chapter; shots from -UITEST_MENUBAR_SHOT) |
| 39 | Mac keyboard map and a command palette | Mac | built (a Listen menu holds every listening shortcut; ⌘K finds a book or action; works from an iPad keyboard too; shot on iPhone, the Mac sheet not yet seen) |
| 40 | Spotlight finds your summaries and highlights | apps | built (CoreSpotlight index rebuilt when the library loads, books and highlights, a result opens its book; the simulator's Home Screen search did not show it, check on a device) |
| 41 | API and MCP routes to create, read and update summaries (braindump 2026-08-19) | api | built (/api/summaries GET, POST, PATCH and four MCP tools, your token passed through to jaybulb-api; live 401 without one) |
| 42 | Pick the narrator voice, per book | apps, web | built (Alice or George, remembered per book like speed; voices.js split from listen.js; the Aura fallback stays one voice) |
| 43 | Download the next chapter's audio on Wi-Fi ahead of time | apps | built (while a chapter plays on Wi-Fi, not cellular or Low Data Mode, the next one's lines are fetched and kept with the book; no visible change, so build-checked) |
| 44 | Storage screen: what is downloaded, how big, remove it | apps | built (CHANGELOG 44.0.0) |
| 45 | Sleep timer fades out; shake to add ten minutes | iPhone | built (CHANGELOG 45.0.0) |
| 46 | Accessibility: VoiceOver on every screen, largest text sizes, Reduce Motion | apps, web | built (CHANGELOG 46.0.0) |
| 47 | Languages: French, Spanish and German interface | apps, web | built (CHANGELOG 47.0.0) |
| 48 | Narrate a chapter in your own language | apps, web | built; not heard live (CHANGELOG 48.0.0) |
| 49 | Localized screenshots and listings | store | built; goes up with the next version (CHANGELOG 49.0.0) |
| 50 | First-run pages offer the Goodreads sign-in | apps | built (CHANGELOG 50.0.0) |
| 51 | Empty states and error messages A+ on every screen | apps, web | built (CHANGELOG 51.0.0) |
| 52 | Account reorganized: Listening, Goodreads, Notifications, Data | apps, web | built (CHANGELOG 52.0.0) |
| 53 | Notifications: weekly recap, quiet hours | apps | built (CHANGELOG 53.0.0) |
| 54 | Public profile: the shelf and highlights you choose to share | web | built; live once Joshua deploys jaybulb-api (CHANGELOG 54.0.0) |
| 55 | Share links with cover preview cards | web | built (CHANGELOG 55.0.0) |
| 56 | Landing refresh with real app screens and the Goodreads story | web | built (CHANGELOG 56.0.0) |
| 57 | Opt-in public pages for shared summaries | web | built; live once Joshua deploys jaybulb-api (CHANGELOG 57.0.0) |
| 58 | 500-book library stays smooth (Goodreads scale) | apps, web | built (CHANGELOG 58.0.0) |
| 59 | Covers cached on disk | apps | built (CHANGELOG 59.0.0) |
| 60 | Startup time budget with an Instruments pass | apps | built (CHANGELOG 60.0.0) |
| 61 | On-device error log you can export when something breaks | apps | built (CHANGELOG 61.0.0) |
| 62 | Retry with backoff on every network call; saves queue while offline | apps, web | built (CHANGELOG 62.0.0) |
| 63 | Listen position merges across devices by time | apps, web | built (CHANGELOG 63.0.0) |
| 64 | Security sweep: auth, rate limits on every model route, KV caps | api | built (CHANGELOG 64.0.0; caps in docs/ARCHITECTURE.md) |
| 65 | Export everything you have as one file | apps, web | built (CHANGELOG 65.0.0) |
| 66 | Account deletion also clears usage counters and audio caches | api, apps | built (CHANGELOG 66.0.0) |
| 67 | Retire `viaApp`, the Supabase fallback and the Supabase project (once 1.2.x is gone) | api | waits: iPhone 1.2.1 is still the live version (2.0.0 in review) |
| 68 | kernel.jaybulb.com and the repo rename | web, repo | built (CHANGELOG 68.0.0; kernel.jaybulb.com waits on Joshua) |
| 69 | Swift unit tests (parsers, goal, nudges) run in CI | apps | built (CHANGELOG 69.0.0) |
| 70 | Simulator UI walks run in CI | apps | built (CHANGELOG 70.0.0; the walk step is non-blocking until its first green run) |
| 71 | Docs to 100 percent | repo | built (CHANGELOG 71.0.0) |
| 72 | Web polish pass to match the apps (apple skill) | web | built (CHANGELOG 72.0.0) |
| 73 | Web keyboard shortcuts and a focus mode | web | built (CHANGELOG 73.0.0) |
| 74 | Read mode: page by page without audio, position saved | apps, web | built (CHANGELOG 74.0.0; the apps need iOS 18 or macOS 15 for it) |
| 75 | Kernel Sans italic and bold for quotes | all | built (CHANGELOG 75.0.0) |
| 76 | Sepia reading theme | apps, web | built (CHANGELOG 76.0.0) |
| 77 | True black for OLED | apps | built (CHANGELOG 77.0.0) |
| 78 | iPad: Stage Manager windows, Pencil highlights | iPad | built (CHANGELOG 78.0.0; Pencil needs a real iPad to try) |
| 79 | Mac: one window per book | Mac | built (CHANGELOG 79.0.0; build-checked, Joshua to try it: right-click a book) |
| 80 | Promotional text and in-app events each release | store | built (CHANGELOG 80.0.0; first run with the next live version, since today's promo text names features 1.2.1 lacks) |
| 81 | Two screenshot sets tested on the product page | store | open |
| 82 | Second Mobbin pass against the best apps; close what is left | all | open |
| 83 | apple skill audit of every screen, zero findings | all | open |
| 84 | Security and privacy audit, zero findings | all | open |
| 85 | Performance audit, zero regressions | all | open |
| 86 | Docs, README, WHITEPAPER and landing final pass | repo, web | open |
| 87 | Release candidate: every row above on iPhone, iPad, Mac and web | all | open |
| 88 | Home Screen widgets: Continue and the weekly ring | iPhone, iPad, Mac | open |
| 89 | Lock Screen widget and a Live Activity while listening | iPhone | open |
| 90 | Control Center control for the current book | iPhone, Mac | open |
| 91 | CarPlay audio | iPhone | open |
| 92 | Share extension: save text or a web article as a summary | apps | open |
| 93 | Narrator quality: an eval set of chapters, prompt tuned against it | api | open |
| 94 | Mark a book read on Goodreads from the app (signed-in web view) | apps | open |
| 95 | Quiz me: three questions per chapter, answers checked | apps, web | open |
| 96 | Key ideas card at the top of each book | apps, web | open |
| 97 | Two-line recap at the end of each chapter in Listen | apps, web | open |
| 98 | Connections: the same idea across your books | apps, web | open |
| 99 | Search by voice: dictate into search, on the device | apps | open (the keyboard mic and Mac dictation already do this; build only a visible mic if people miss it) |
| 100 | Kernel 100 | all | open |

## Open outside the table
- [ ] Workers AI ran out of its 10,000 free daily neurons on 2026-10-28 (narration scripts, Ask, page photos and the Aura-2 fallback fail until 00:00 UTC). Workers Paid is $5 a month (Joshua's call). Then tune the meaning floor (0.6) on real bge scores.
- [ ] Add kernel.jaybulb.com to the `bookrank` Pages project (Joshua: Cloudflare dashboard, Pages, bookrank, Custom domains). Then point canonical, sitemap, OG, the apps and the launch kit at it; the old host keeps serving.
- [ ] The Android, desktop and terminal readers still read shared summaries from Supabase, so links made since the move to jaybulb-api do not open there. Point them at jaybulb-api's share route.
- [ ] `scripts/build.py` still writes the retired rankings page and `book_rankings.md`. Cut it down to the iOS copy of `books.json`.
- [ ] `metadata/` holds the old rankings listing. Pull the live Kernel text from App Store Connect before the next `asc metadata push`.
- [ ] Joshua's checks: Scan pages on a real iPhone (v33), Kernel's actions in the Shortcuts app (v35), Handoff between iPhone and Mac (v37), Spotlight results (v40), the signed-in Mac walk, Listen on a real phone with the screen locked, Goodreads in iOS dark mode, two devices merging highlights.
- [ ] The web player shows merged highlights only after the next toggle or a reopen.
- [ ] The Mac Account sheet looks empty in screenshot mode.
- [ ] Summaries still to photograph or finish: The Man Who Solved the Market (cover only), Physics I For Dummies (cover only), the rest of AI in Business and macOS Tahoe (both returned to the library, photos are the only source), The Optimist chapters 15 to 17.
- [ ] `content/masterclasses/` (15 books from Patois) has no reader. Import them as summaries or drop them.
- [ ] The launch kit in `launch/` still pitches the old ranked shelf.

## Hazard
`sync-summaries.sh` copies iCloud over the repo, it does not merge. On 2026-08-17 it replaced a full The Optimist with a shorter iCloud copy, and git was the only place four chapters still lived. After every sync run `git diff --stat` and treat a summary that got smaller as a bug, never a change to commit.

History is in [docs/CHANGELOG.md](docs/CHANGELOG.md) and git. How to ship is in [docs/SHIPPING.md](docs/SHIPPING.md).
