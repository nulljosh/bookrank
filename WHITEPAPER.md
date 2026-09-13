# Bookrank Technical Whitepaper

**v1.0.1** | August 2026

A ranked shelf of books, with private chapter summaries per user. It exists
because a to-be-read list scattered across notes apps and memory is useless
the moment you're standing in a bookstore; a public rank forces the honesty
a private list doesn't. Users sign up
with email, keep notes only they can read, and can delete the account and all of
it in one step, because chapter summaries are personal reading notes, not
content anyone else should see by default. Live at [bookrank.heyitsmejosh.com](https://bookrank.heyitsmejosh.com)
and on the iOS and Mac App Stores. It used to live in the portfolio repo. Books
and a portfolio have nothing to do with each other, so it moved.

## Ranking List

`books.json` is the single source of truth; `index.html`, `book_rankings.md`, and the iOS
resource JSON are all generated from it by `scripts/build.py`, run after
every edit, rather than hand-kept in sync, because a prior generator that
silently skipped malformed entries shipped an app carrying 71 of 111 ranked
books for months without anyone noticing. The list is TBR-only: a book is removed only
when the user says they've finished it or explicitly asks it removed, not
merely because they mention reading it, because "mentioned reading it" and "actually done" are
different facts and conflating them would wrongly empty the shelf. On removal, remaining entries are
renumbered sequentially.

## Chapter Summary Pipeline

Physical books are photographed page-by-page into a private iCloud folder
(outside this repo, too large/private for git). The `summarize-books` skill reads those photos
directly rather than shelling out, because the old `summarize.sh` ran headless
`claude -p` as a subprocess, which both fought iCloud eviction and once let a
permission-prompt string get saved as a "summary" and delete the source
photos. It produces per-chapter `summary.md` files, then merges them into one
`<slug>-summary.md`. This repo's `sync-summaries.sh` copies that merged file
into `summaries/<slug>.md`, and a link is added next to the matching book
entry in `index.html` pointing at `summary.html?b=<slug>`, which renders the
markdown client-side via `marked`, no server-side rendering needed for text
that's already just markdown.

## Design

Shares the portfolio's `tokens.css` and `fonts/` for visual consistency with
the rest of heyitsmejosh.com, since a second design system for one more app
in the same portfolio would be needless upkeep.

## Security / Privacy

The list tracks what is worth reading, not what is checked out. There is no
checkout, due-date, or library-loan tracking, and none is planned, because
every library book eventually comes back and a due-date feature was found
tracking nothing real.

Static site, no backend, no accounts. Raw book photos never enter this repo
,  they stay in a private iCloud folder and only the derived text summaries
are published.

## License

MIT 2026, Joshua Trommel
