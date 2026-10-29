## Road to 100 (2026-10-28)
One row is one major version in the repo, tagged when it is built and QA'd in light and dark. Apple reviews one version at a time, so the store gets the newest tagged major each time the last one clears review. Summaries stay the heart of the app; Goodreads and the rest sit around them. Rows 36 to 39 need Workers AI, so they wait for Workers Paid (Joshua, 2026-10-29); "ask by voice" was dropped as more chat. Rows 5 to 100 are proposals built from the gap matrix, the A+ pass, the code review and the braindumps below; reorder freely. The watch app stays retired (2026-10-02).

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
| 33 | Scan pages with the document camera in Add pages | iPhone, iPad | open |
| 34 | Read the page text on the device before upload, so photos never leave it | apps | open |
| 35 | Mark a book read on Goodreads from the app (signed-in web view) | apps | open |
| 36 | Quiz me: three questions per chapter, answers checked | apps, web | open |
| 37 | Key ideas card at the top of each book | apps, web | open |
| 38 | Two-line recap at the end of each chapter in Listen | apps, web | open |
| 39 | Connections: the same idea across your books | apps, web | open |
| 40 | Search by voice: dictate into search, on the device | apps | open (the keyboard mic and Mac dictation already do this; build only a visible mic if people miss it) |
| 41 | Shortcuts: add a summary, play my book, next chapter (braindump 2026-08-19) | apps | open |
| 42 | Siri: "continue my book" | apps | open |
| 43 | Home Screen widgets: Continue and the weekly ring | iPhone, iPad, Mac | open |
| 44 | Lock Screen widget and a Live Activity while listening | iPhone | open |
| 45 | Control Center control for the current book | iPhone, Mac | open |
| 46 | CarPlay audio | iPhone | open |
| 47 | Handoff: pick up the same chapter on the Mac | apps | open |
| 48 | Mac menu bar mini player | Mac | open |
| 49 | Mac keyboard map and a command palette | Mac | open |
| 50 | Spotlight finds your summaries and highlights | apps | open |
| 51 | Share extension: save text or a web article as a summary | apps | open |
| 52 | API and MCP routes to create, read and update summaries (braindump 2026-08-19) | api | open |
| 53 | Pick the narrator voice, per book | apps, web | open |
| 54 | Narrator quality: an eval set of chapters, prompt tuned against it | api | open |
| 55 | Download the next chapter's audio on Wi-Fi ahead of time | apps | open |
| 56 | Storage screen: what is downloaded, how big, remove it | apps | open |
| 57 | Sleep timer fades out; shake to add ten minutes | iPhone | open |
| 58 | Accessibility: VoiceOver on every screen, largest text sizes, Reduce Motion | apps, web | open |
| 59 | Languages: French, Spanish and German interface | apps, web | open |
| 60 | Narrate a chapter in your own language | apps, web | open |
| 61 | Localized screenshots and listings | store | open |
| 62 | First-run pages offer the Goodreads sign-in | apps | open |
| 63 | Empty states and error messages A+ on every screen | apps, web | open |
| 64 | Account reorganized: Listening, Goodreads, Notifications, Data | apps, web | open |
| 65 | Notifications: weekly recap, quiet hours | apps | open |
| 66 | Public profile: the shelf and highlights you choose to share | web | open |
| 67 | Share links with cover preview cards | web | open |
| 68 | Landing refresh with real app screens and the Goodreads story | web | open |
| 69 | Opt-in public pages for shared summaries | web | open |
| 70 | 500-book library stays smooth (Goodreads scale) | apps, web | open |
| 71 | Covers cached on disk | apps | open |
| 72 | Startup time budget with an Instruments pass | apps | open |
| 73 | On-device error log you can export when something breaks | apps | open |
| 74 | Retry with backoff on every network call; saves queue while offline | apps, web | open |
| 75 | Listen position merges across devices by time | apps, web | open |
| 76 | Security sweep: auth, rate limits on every model route, KV caps | api | open |
| 77 | Export everything you have as one file | apps, web | open |
| 78 | Account deletion also clears usage counters and audio caches | api, apps | open |
| 79 | Retire `viaApp`, the Supabase fallback and the Supabase project (once 1.2.x is gone) | api | open |
| 80 | kernel.jaybulb.com and the repo rename | web, repo | built (repo nulljosh/kernel, folder kernel with a bookrank link, auth mails say Kernel; kernel.jaybulb.com waits on Joshua adding it to the Pages project) |
| 81 | Swift unit tests (parsers, goal, nudges) run in CI | apps | open |
| 82 | Simulator UI walks run in CI | apps | open |
| 83 | Docs to 100 percent | repo | open |
| 84 | Web polish pass to match the apps (apple skill) | web | open |
| 85 | Web keyboard shortcuts and a focus mode | web | open |
| 86 | Read mode: page by page without audio, position saved | apps, web | open |
| 87 | Kernel Sans italic and bold for quotes | all | open |
| 88 | Sepia reading theme | apps, web | open |
| 89 | True black for OLED | apps | open |
| 90 | iPad: Stage Manager windows, Pencil highlights | iPad | open |
| 91 | Mac: one window per book | Mac | open |
| 92 | Promotional text and in-app events each release | store | open |
| 93 | Two screenshot sets tested on the product page | store | open |
| 94 | Second Mobbin pass against the best apps; close what is left | all | open |
| 95 | apple skill audit of every screen, zero findings | all | open |
| 96 | Security and privacy audit, zero findings | all | open |
| 97 | Performance audit, zero regressions | all | open |
| 98 | Docs, README, WHITEPAPER and landing final pass | repo, web | open |
| 99 | Release candidate: every row above on iPhone, iPad, Mac and web | all | open |
| 100 | Kernel 100 | all | open |

## Open outside the table
- [ ] Workers AI ran out of its 10,000 free daily neurons on 2026-10-28 (narration scripts, Ask, page photos and the Aura-2 fallback fail until 00:00 UTC). Workers Paid is $5 a month (Joshua's call). Then tune the meaning floor (0.6) on real bge scores.
- [ ] Add kernel.jaybulb.com to the `bookrank` Pages project (Joshua: Cloudflare dashboard, Pages, bookrank, Custom domains). Then point canonical, sitemap, OG, the apps and the launch kit at it; the old host keeps serving.
- [ ] The Android, desktop and terminal readers still read shared summaries from Supabase, so links made since the move to jaybulb-api do not open there. Point them at jaybulb-api's share route.
- [ ] `scripts/build.py` still writes the retired rankings page and `book_rankings.md`. Cut it down to the iOS copy of `books.json`.
- [ ] `metadata/` holds the old rankings listing. Pull the live Kernel text from App Store Connect before the next `asc metadata push`.
- [ ] Joshua's checks: the signed-in Mac walk, Listen on a real phone with the screen locked, Goodreads in iOS dark mode, two devices merging highlights.
- [ ] The web player shows merged highlights only after the next toggle or a reopen.
- [ ] The Mac Account sheet looks empty in screenshot mode.
- [ ] Summaries still to photograph or finish: The Man Who Solved the Market (cover only), Physics I For Dummies (cover only), the rest of AI in Business and macOS Tahoe (both returned to the library, photos are the only source), The Optimist chapters 15 to 17.
- [ ] `content/masterclasses/` (15 books from Patois) has no reader. Import them as summaries or drop them.
- [ ] The launch kit in `launch/` still pitches the old ranked shelf.

## Hazard
`sync-summaries.sh` copies iCloud over the repo, it does not merge. On 2026-08-17 it replaced a full The Optimist with a shorter iCloud copy, and git was the only place four chapters still lived. After every sync run `git diff --stat` and treat a summary that got smaller as a bug, never a change to commit.

History is in [docs/CHANGELOG.md](docs/CHANGELOG.md) and git. How to ship is in [docs/SHIPPING.md](docs/SHIPPING.md).
