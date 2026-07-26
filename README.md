<img src="icon.svg" width="80">

# Spine

![license](https://img.shields.io/badge/license-MIT-green) [![GitHub](https://img.shields.io/badge/GitHub-nulljosh%2Fspine-black?logo=github)](https://github.com/nulljosh/spine)

A curated collection of book rankings based on Goodreads ratings and reviews.
Live at [spine.heyitsmejosh.com](https://spine.heyitsmejosh.com).

## Files

- `index.html` - Interactive book rankings with Apple Liquid design. Top section tracks library checkouts with a live due-date countdown (edit the `data-due` attribute on `#deadline` and the `.library` list to update). Books with chapter summaries get their own "Summaries" section; the full rankings list collapses behind a "Show all" toggle.
- `book_rankings.md` - Markdown version of the rankings
- Images of all books in the collection

## View the Rankings

Open `index.html` in your browser to view the interactive rankings with a beautiful glassmorphic UI.

## Top 5 Books

1. The Demon-Haunted World (4.38/5)
2. Bad Blood (4.32/5)
3. The New Jim Crow (4.36/5)
4. The Hard Thing About Hard Things (4.20/5)
5. The Black Swan (3.93/5)

## iOS App

`ios/Spine` (ASC record: **Spinework**) is a native SwiftUI app (rewritten from an earlier WKWebView wrapper, 2026-07-22) with a shared `SpineMac` target.

<img src="ios/screenshots/library.jpg" width="240">

## Project Map

![project map](architecture.svg)

## Roadmap

See `roadmap.md` in this repo root.

