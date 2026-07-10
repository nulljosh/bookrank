# Books Technical Whitepaper

**v1.0** | July 2026

Books is a static to-be-read (TBR) ranking site: a hand-maintained, ranked
list of unread books, plus optional AI-generated chapter summaries for books
Joshua has actually finished. Live at
[books.heyitsmejosh.com](https://books.heyitsmejosh.com). Split out of the
portfolio repo since books and the portfolio are unrelated projects.

## Ranking List

`index.html` (the live site) and `book_rankings.md` (markdown source) hold
the same ranked list in parallel — neither is generated from the other, so
both must be edited together. The list is TBR-only: a book is removed only
when the user says they've finished it or explicitly asks it removed, not
merely because they mention reading it. On removal, remaining entries are
renumbered sequentially in both files.

## Chapter Summary Pipeline

Physical books are photographed page-by-page into a private iCloud folder
(outside this repo — too large/private for git). A `summarize.sh` script
there feeds the photos through an LLM (headless `claude -p`, run with
`--dangerously-skip-permissions` after a prior bug let a permission-prompt
string get saved as a "summary" and then delete the source photos) to produce
per-chapter `summary.md` files, then merges them into one
`<slug>-summary.md`. This repo's `sync-summaries.sh` copies that merged file
into `summaries/<slug>.md`, and a link is added next to the matching book
entry in `index.html` pointing at `summary.html?b=<slug>`, which renders the
markdown client-side via `marked` — no server-side rendering.

## Design

Shares the portfolio's `tokens.css` and `fonts/` for visual consistency with
the rest of heyitsmejosh.com.

## Security / Privacy

Static site, no backend, no accounts. Raw book photos never enter this repo
— they stay in a private iCloud folder and only the derived text summaries
are published.

## License

MIT 2026, Joshua Trommel
