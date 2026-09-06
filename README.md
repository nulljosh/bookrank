<img src="icon.svg" width="80">

# Bookrank

![license](https://img.shields.io/badge/license-MIT-green) [![GitHub](https://img.shields.io/badge/GitHub-nulljosh%2Fbookrank-black?logo=github)](https://github.com/nulljosh/bookrank) [![App Store](https://img.shields.io/badge/App%20Store-iPhone%20%26%20iPad-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/us/app/bookrank/id6792376485) [![Mac App Store](https://img.shields.io/badge/Mac%20App%20Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/us/app/bookrank/id6792376485?mt=12)

Rank the books you've read, keep private chapter notes on the ones that mattered. Free on the web, iPhone, iPad and Mac. Live at [bookrank.heyitsmejosh.com](https://bookrank.heyitsmejosh.com).

**Terminal:** `swift build && ./.build/debug/bookrank-tui "the optimist"`, or `bookrank-tui share <link>` to read a shared summary. See [tui/](tui/). The KMP app (`kmp/`, Android and desktop) opens share links too.

![landing page](screenshots/landing.jpg)

## Pages

- `index.html`: the landing page. A wall of covers from `scripts/covers.json`.
- `rankings.html`: the shelf. 111 ranked books with search, stars and sort, built from `books.json` by `scripts/build.py`.
- `library.html`: your account. Sign up with email, keep chapter summaries that only you can read, delete the account and everything with it in one step.

- `book_rankings.md`: the shelf as plain markdown, generated from the same source.

## Listen

Every summary can be played, not just read. "Explain it" turns each chapter into a short two-host conversation (Workers AI, `functions/api/narrate.js`) that explains the ideas and why they matter; "Read the notes" speaks the markdown as written. Voices are the device's own, a short list in your language.

The transcript follows the voice: the current line is highlighted, the current word marked, and the page scrolls with it. Chapters sit in a sidebar. A progress bar runs across the top of the window. The next chapter is prepared while the current one plays, so there is no gap at the boundary. Pause always works, even while a chapter is loading. Where you stopped, and the generated scripts, are saved on your account, so the web, iPhone and Mac all pick up at the same line. Summaries you have started sit under "Currently playing" at the top of the list.

## Share

Any summary can be shared with a private link (`share.html?t=…`). The link opens the text and the audio for that one summary, and nothing else: no position, no account, no list. Stop sharing and the link dies. Covers for the list are matched to `books.json`, then looked up on Open Library and saved to the row.

Tests: `node --test` (`listen.test.js`, `narrate.test.js`, `books.test.js`).

![rankings](screenshots/rankings.jpg)

## Covers

`scripts/fetch-covers.py` finds covers on Open Library and patches them into `rankings.html`. Images are hotlinked. Lookups are cached in `scripts/covers.json`.

```
python3 scripts/fetch-covers.py                 # fetch missing covers
python3 scripts/fetch-covers.py --dry-run       # list books with no cover
python3 scripts/fetch-covers.py --retry-misses  # re-query cached misses
```

## iOS and macOS apps

`ios/Bookrank` is SwiftUI with a shared `BookrankMac` target. Same shelf, same account, same private summaries, same Listen and Share as the web. Generated from `ios/project.yml` by xcodegen. The bundle ID is still `com.heyitsmejosh.spine`. It predates the rename and is bound to the App Store record, so it stays.

<img src="ios/screenshots/library.jpg" width="240">

## Apple Watch App

`watchos/BookrankWatch` is a standalone SwiftUI watch app (`WKWatchOnly`), generated from `watchos/project.yml` by xcodegen. Bundle ID `com.heyitsmejosh.spine.watchos`. It's a full local port, not a network client: the ranked shelf, to-read list and top picks are the same `books.json` / `library.json` / `picks.json` bundled into the iOS app, copied into `watchos/Resources` and read the same way, so it works with no pairing step and nothing goes stale offline. Per-account chapter summaries (Supabase) stay iOS/macOS-only; that needs a sign-in flow that doesn't belong on a watch face.

## More

[Project map](architecture.svg) · [Roadmap](roadmap.md) · [Whitepaper](WHITEPAPER.md) · [Agent tools](docs/API.md) (WebMCP; no HTTP API)
