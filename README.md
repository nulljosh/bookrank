<img src="icon.svg" width="80">

# Bookrank

![license](https://img.shields.io/badge/license-MIT-green) [![GitHub](https://img.shields.io/badge/GitHub-nulljosh%2Fbookrank-black?logo=github)](https://github.com/nulljosh/bookrank) [![App Store](https://img.shields.io/badge/App%20Store-iPhone%20%26%20iPad-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/us/app/bookrank/id6792376485) [![Mac App Store](https://img.shields.io/badge/Mac%20App%20Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/us/app/bookrank/id6792376485?mt=12)

A personal shelf of book rankings. Live at [bookrank.heyitsmejosh.com](https://bookrank.heyitsmejosh.com).

![landing page](screenshots/landing.jpg)

## Pages

- `index.html` — landing page, cover wall built from `scripts/covers.json`.
- `rankings.html` — the ranked shelf: search, star ratings, sorting.
- `library.html` — private chapter summaries (Supabase).
- `book_rankings.md` — markdown version of the rankings.

![rankings](screenshots/rankings.jpg)

## Covers

`scripts/fetch-covers.py` resolves covers from Open Library and patches `rankings.html`. Images are hotlinked; lookups cache in `scripts/covers.json`.

```
python3 scripts/fetch-covers.py                 # fetch missing covers
python3 scripts/fetch-covers.py --dry-run       # list books with no cover
python3 scripts/fetch-covers.py --retry-misses  # re-query cached misses
```

## iOS App

`ios/Bookrank` — SwiftUI, shared `BookrankMac` target, generated from `ios/project.yml` via xcodegen. Bundle ID stays `com.heyitsmejosh.spine` (predates the rename, bound to the ASC record).

<img src="ios/screenshots/library.jpg" width="240">

## More

[Project map](architecture.svg) · [Roadmap](roadmap.md) · [Whitepaper](WHITEPAPER.md) · [Agent tools](docs/API.md) (WebMCP; no HTTP API)
