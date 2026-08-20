<img src="icon.svg" width="80">

# Bookrank

![license](https://img.shields.io/badge/license-MIT-green) [![GitHub](https://img.shields.io/badge/GitHub-nulljosh%2Fbookrank-black?logo=github)](https://github.com/nulljosh/bookrank) [![App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/us/app/bookrank/id6792376485)

A curated collection of book rankings based on Goodreads ratings and reviews.
Live at [bookrank.heyitsmejosh.com](https://bookrank.heyitsmejosh.com).

## Files

- `index.html` - Interactive rankings (Apple Liquid design). Tracks library checkouts with a live due-date countdown — edit the `data-due` attribute on `#deadline` to update. Summarized books get a "Summaries" section; the rest collapse behind "Show all".
- `book_rankings.md` - Markdown version of the rankings
- Images of all books in the collection

## iOS App

`ios/Spine` (ASC record: **Bookrank**) is a native SwiftUI app (rewritten from an earlier WKWebView wrapper, 2026-07-22) with a shared `SpineMac` target.

<img src="ios/screenshots/library.jpg" width="240">

## Project Map

![project map](architecture.svg)

## Roadmap

See `roadmap.md` in this repo root.


## Whitepaper

[Technical whitepaper](WHITEPAPER.md)
