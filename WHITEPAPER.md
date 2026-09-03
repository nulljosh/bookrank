# Bookrank Technical Whitepaper

**v1.0.1** | August 2026

A ranked shelf of books, with private chapter summaries per user. Users sign up
with email, keep notes only they can read, and can delete the account and all of
it in one step. Live at [bookrank.heyitsmejosh.com](https://bookrank.heyitsmejosh.com)
and on the iOS and Mac App Stores. It used to live in the portfolio repo. Books
and a portfolio have nothing to do with each other, so it moved.

## Ranking List

`index.html` (the live site) and `book_rankings.md` (markdown source) hold
the same ranked list in parallel, neither is generated from the other, so
both must be edited together. The list is TBR-only: a book is removed only
when the user says they've finished it or explicitly asks it removed, not
merely because they mention reading it. On removal, remaining entries are
renumbered sequentially in both files.

## Chapter Summary Pipeline

Physical books are photographed page-by-page into a private iCloud folder
(outside this repo, too large/private for git). The `summarize-books` skill reads those photos
directly rather than shelling out (the old `summarize.sh` ran headless
`claude -p` as a subprocess, which both fought iCloud eviction and once let a
permission-prompt string get saved as a "summary" and delete the source
photos). It produces per-chapter `summary.md` files, then merges them into one
`<slug>-summary.md`. This repo's `sync-summaries.sh` copies that merged file
into `summaries/<slug>.md`, and a link is added next to the matching book
entry in `index.html` pointing at `summary.html?b=<slug>`, which renders the
markdown client-side via `marked`, no server-side rendering.

## Design

Shares the portfolio's `tokens.css` and `fonts/` for visual consistency with
the rest of heyitsmejosh.com.

## Security / Privacy

The list tracks what is worth reading, not what is checked out, there is no
checkout, due-date, or library-loan tracking, and none is planned.

Static site, no backend, no accounts. Raw book photos never enter this repo
,  they stay in a private iCloud folder and only the derived text summaries
are published.

## License

MIT 2026, Joshua Trommel
