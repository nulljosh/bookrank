# Kernel Technical Whitepaper

**v70** | October 2026

You finish a book and a month later you remember one idea. Kernel keeps the rest: every chapter in plain words, read in a minute or explained aloud by one narrator while the words light up. Your summaries sit behind your account, and deleting the account deletes all of it. Free at [bookrank.jaybulb.com](https://bookrank.jaybulb.com), and $0.99 on iPhone, iPad and Mac.

## The shape

A list of books. Tap one, see its chapters. Tap a chapter, read it or press Play. Around that sit highlights, a question you can ask a chapter, a weekly listening goal, and your Goodreads shelves. Kernel used to rank books; that went away on 2026-09-21. The summaries are the product.

## Chapters

A summary is one markdown file. Chapters are the coarsest heading level that gives two or more sections, `#` before `##`. A lone heading with nothing under it is the book title. The web, the apps and the Android reader use this one rule, so a saved place means the same chapter everywhere.

## Listen

`/api/narrate` turns each chapter into a short script for one narrator who explains the ideas instead of reading the markdown. Only the first chapter opens and only the last closes, so a book plays as one narration. Each line becomes a natural voice with the time every word starts, from ElevenLabs, or Cloudflare's Aura-2 when ElevenLabs runs out, or the device voice past both caps. Every line is stored for good, so it is paid for once. The saved place is tied to the row's `updated_at`, which only moves when the text changes.

## Sync

Web and apps sign in to jaybulb-api, a Cloudflare Worker on D1, and read the same rows. Highlights merge across devices instead of the last save winning, and a listening place saved offline loses to one another device reached later (each place carries the time it was reached). Calls retry with backoff, and saves made with no connection wait in an outbox and go up when it returns. The web keeps every book on the device and works with no connection; the apps can download a book's audio and keep covers on disk.

## Finding things

Search looks inside every chapter and opens at the line. Search by meaning embeds each paragraph with `/api/embed` once and keeps the index on the device, so an idea is found without its words. Today's five brings back five highlights a day, the same five on every device.

## Languages

The apps and the web speak English, French, Spanish and German, and narration follows the interface language whatever language the notes are in.

## Covers

Every row carries its own cover. A title search alone picks the wrong book often enough to matter, so a cover is matched on title and author before it is saved.

## Getting summaries in

Photograph the pages in the app or on the web, and `/api/summarize-photo` reads each one; nothing is stored. The apps can also scan with the camera and read the pages on the device. EPUB and PDF files become a book with a chapter per section, and Kindle clippings, Readwise exports and a Goodreads export CSV come in as highlights or shelves. Joshua's own books come from photos in a private iCloud folder through the `summarize-books` skill and `scripts/import-summaries.py`.

## Goodreads

Goodreads closed its API in 2020 and made its shelves private on 2026-10-28. The apps open Goodreads' own sign-in page in a web view and read your shelves there. The cookies and shelves stay on your device and are never sent to Kernel.

## Paying

The apps cost $0.99, and each request proves it with StoreKit's signed AppTransaction, checked against Apple's root certificate with no Apple call. On the web, natural voices are a $1 Stripe payment.

## Sharing

A summary can be shared with a link. The link carries a random token, and only that summary's title, text, cover and narration come back for it; its preview card shows the title and cover. Stop sharing and the token is gone. A public profile, off by default, lists the books you shared, and only then may search engines index those pages.

## Limits and leaving

Every route that runs a model or reaches Goodreads has an hourly cap per person, counted in the edge cache. Export everything is one zip. Deleting an account also clears its voice records on Kernel's server and every copy on the device it is deleted from.

## License

Apache 2.0, 2026, Joshua Trommel
