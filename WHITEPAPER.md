# Bookrank Technical Whitepaper

**v1.0.1** | October 2026

Chapter summaries of the books you actually read. You finish a book and a month later you remember one idea. Bookrank keeps the rest: every chapter, in plain words, readable in a minute or played aloud as two people talking it through. Your summaries are yours. They sit behind your account, and deleting the account deletes all of it. Live at [bookrank.heyitsmejosh.com](https://bookrank.heyitsmejosh.com) and on the iOS and Mac App Stores.

## The shape

A list of books. Tap one, see its chapters. Tap a chapter, read it or press Listen. That is the whole app. It used to rank books too; on 2026-09-21 that went away. The summaries are the product.

## Chapters

A summary is one markdown file. Chapters are the coarsest heading level that gives two or more sections, `#` before `##`. A lone heading with nothing under it is the book title, not a chapter. The web player, the iOS reader and the Android reader all use this one rule, so a saved position means the same chapter everywhere.

## Listen

Each chapter becomes a short script for two hosts, written by `/api/narrate` and cached on the row. Only the first chapter opens with an intro and only the last closes, so a book plays as one conversation instead of twenty. The player speaks one line at a time and prefetches the next chapter so there is no gap. The word being read is bold and dark, the rest of the line dims, and the screen follows along. The saved position is tied to the row's `updated_at`: edit the summary and the old scripts are thrown away instead of reading stale text.

## Covers

Every row carries its own cover. Searching by title alone picks the wrong book often enough to matter (one search gave The Optimist a different author's book and AI in Business a Hamlet title page), so a cover is matched on title and author and checked before it is saved.

## Getting summaries in

Pages are photographed into a private iCloud folder that never touches this repo. The `summarize-books` skill reads the photos directly and writes one summary per chapter, then merges them into one file. `sync-summaries.sh` copies it into `summaries/`, and `scripts/import-summaries.py` uploads it to the owner's private rows.

## Sharing

A summary can be shared with a link. The link carries a random token; a security-definer RPC returns only the title, text, cover and cached scripts for that token. Stop sharing and the token is gone.

## Platforms

Web and PWA, iPhone, iPad and Mac from one SwiftUI codebase, Android and desktop through Kotlin Multiplatform as a share-link reader, a terminal card, and a watch app that still shows the old shelf. All of them talk to one Supabase table.

## Security and privacy

Row-level security keeps each account to its own rows. Auth emails come from our own branded sender. Raw page photos stay in iCloud; only the text summaries are stored. Account deletion goes through one shared endpoint and removes everything.

## License

MIT 2026, Joshua Trommel
