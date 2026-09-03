<img src="icon.svg" width="80">

# Bookrank

![license](https://img.shields.io/badge/license-MIT-green) [![GitHub](https://img.shields.io/badge/GitHub-nulljosh%2Fbookrank-black?logo=github)](https://github.com/nulljosh/bookrank) [![App Store](https://img.shields.io/badge/App%20Store-iPhone%20%26%20iPad-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/us/app/bookrank/id6792376485) [![Mac App Store](https://img.shields.io/badge/Mac%20App%20Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/us/app/bookrank/id6792376485?mt=12)

Every book I've read, ranked. My shelf, not a product. Live at [bookrank.heyitsmejosh.com](https://bookrank.heyitsmejosh.com).

![landing page](screenshots/landing.jpg)

## Pages

- `index.html`: the landing page. A wall of covers from `scripts/covers.json`.
- `rankings.html`: the shelf. Search, stars, sort.
- `library.html`: private chapter summaries, in Supabase.
- `book_rankings.md`: the same rankings as plain markdown.

![rankings](screenshots/rankings.jpg)

## Covers

`scripts/fetch-covers.py` finds covers on Open Library and patches them into `rankings.html`. Images are hotlinked. Lookups are cached in `scripts/covers.json`.

```
python3 scripts/fetch-covers.py                 # fetch missing covers
python3 scripts/fetch-covers.py --dry-run       # list books with no cover
python3 scripts/fetch-covers.py --retry-misses  # re-query cached misses
```

## iOS App

`ios/Bookrank` is SwiftUI with a shared `BookrankMac` target, generated from `ios/project.yml` by xcodegen. The bundle ID is still `com.heyitsmejosh.spine`. It predates the rename and is bound to the App Store record, so it stays.

<img src="ios/screenshots/library.jpg" width="240">

## Apple Watch App

`watchos/BookrankWatch` is a standalone SwiftUI watch app (`WKWatchOnly`), generated from `watchos/project.yml` by xcodegen. Bundle ID `com.heyitsmejosh.spine.watchos`. It's a full local port, not a network client: the ranked shelf, to-read list and top picks are the same `books.json` / `library.json` / `picks.json` bundled into the iOS app, copied into `watchos/Resources` and read the same way, so it works with no pairing step and nothing goes stale offline. Per-account chapter summaries (Supabase) stay iOS/macOS-only; that needs a sign-in flow that doesn't belong on a watch face.

## More

[Project map](architecture.svg) · [Roadmap](roadmap.md) · [Whitepaper](WHITEPAPER.md) · [Agent tools](docs/API.md) (WebMCP; no HTTP API)
