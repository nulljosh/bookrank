# Changelog

Every tagged version of Kernel, newest first. Before 2026-10-28 the app was called Bookrank, and before that Uprighty, Spine and Books.

## 24.0.0 (2026-10-28)
Today's five: five of your highlights come back at the top of the library each day, the same five on every device, a new five tomorrow. Done puts them away until then.

## 23.0.0 (2026-10-28)
Export on the Highlights page saves every highlight as one Markdown file, by book and chapter, ready for Notes, Obsidian or anywhere else.

## 22.0.0 (2026-10-28)
Highlights: every line you saved, from every book, on one page. Tap one to open the book at that line, or share it as a square gold card with the book's name.

## 21.0.0 (2026-10-28)
Search by meaning: below the word matches, Close in meaning finds the lines that say what you typed in other words, and opens the book at that line. Each book is read once and kept on the device.

## 20.0.0 (2026-10-28)
Sort the library by recently edited, title, progress or shortest first, and show all books, the ones in progress or the ones not started. Each device remembers your pick.

## 19.0.0 (2026-10-28)
Collections: put a book in a group of your own from its page, and the library lists your collections A to Z, then everything else. The same on the apps and the web.

## 18.0.0 (2026-10-28)
Search finds words inside your chapters, not only titles. Each result shows the chapter and the line that matched, and opening it lands on that line, marked, in the apps and on the web.

## 17.0.0 (2026-10-28)
Add pages on the web works like the apps: a progress bar while each photo is read, the pages that could not be read named, and the new text selected in the editor so you can fix it before you save.

## 16.0.0 (2026-10-28)
Download on the web book page keeps a whole book's narration on the device, so it plays with no connection, like Download in the apps. Every line you have already heard is kept too.

## 15.0.0 (2026-10-28)
The web library works with no connection. Every book's text is kept on the device, not only the ones you opened, and an expired sign-in no longer logs you out while offline. The service worker keeps the pages, fonts and scripts, keeps your saved books across updates, and stops caching Goodreads answers.

## 14.0.0 (2026-10-28)
The launch splash follows the app's own theme from the first frame, navigation titles use Kernel Sans, and a launch-time test guards cold start (about 3 seconds in the simulator).

## 13.0.0 (2026-10-28)
The icon and type hold up small: a bold 16 px mark and favicon, small labels one step darker, and an 11 pt Mac footnote.

## 12.0.0 (2026-10-28)
New Mac App Store screenshots at 2880x1800. Play says Continue only when there is a place to go back to.

## 11.0.0 (2026-10-28)
iPad split view: your books on the left, the open book on the right.

## 10.0.0 (2026-10-28)
A book's date only moves when its text changes, not when you save your place or a highlight. The web player has one stylesheet.

## 9.0.0 (2026-10-28)
Highlights merge across devices instead of the last save winning.

## 8.0.0 (2026-10-28)
Week dots and a day streak on the reading goal in the apps, and the weekly goal on the web.

## 7.0.0 (2026-10-28)
Reader text size (apps menu, web A- and A+), and speed moves into a submenu.

## 6.0.0 (2026-10-28)
A Now Playing sheet opens from the mini player. The book page puts the cover first with a soft glow. Screenshot runs can never play audio.

## 5.0.0 (2026-10-28)
A Play or Continue button on the book page.

## 4.0.0 (2026-10-28)
Highlights, offline audio downloads, a chapter from photos of the pages, Ask the chapter a question, a weekly goal with smarter reminders, and Goodreads sign-in in the apps (shelves, reviews, progress, decimal ratings) with 8-bit book avatars.

## 3.0.0 (2026-10-28)
Minutes per chapter and per book, a Continue card on the library, skip a line back or forward, and a sleep timer. Saving your listening spot no longer loses it.

## 2.0.0 (2026-10-28)
Bookrank becomes Kernel: new name, gold brand, the Kernel Sans font, a launch splash and first-run pages. One narrator instead of two hosts, with Cloudflare Aura-2 as the backup voice. The apps and web sign in and sync through jaybulb-api on Cloudflare. Along the way since 1.0.5: $1 natural voices on the web, a voice usage meter, a daily review nudge, a Watch line from your summaries, the Mac three-column layout, a mini player, Goodreads shelves that fold and sort, and a fix for listen scripts leaking between books.

## 1.0.5 (2026-10-02)
Search your summaries by title or text, export everything as a zip, Listen keeps playing in the background, the page follows the spoken word, natural ElevenLabs voices with a device-voice fallback, offline shelf in the apps, and your Goodreads profile in the app.

## 1.0.2 (2026-10-01)
Summaries only: the ranked shelf retired on web and apps. A plain list that opens into chapters, real covers, Sign in with Apple, Face ID sign-in, first-run onboarding, Goodreads linking with read books that have no summary yet, and DOMPurify on shared summaries.

## 1.0.1 (2026-09-06)
Everything from the first import on 2026-06-18: the ranked book list split out of the portfolio, chapter summaries from phone photos, the native SwiftUI app for iPhone and Mac, per-user accounts, read-aloud that grew into Listen (an explainer, speed, chapter navigation, saved progress, share links), the profile page, WebMCP tools and /api plus /mcp on Cloudflare Pages, an installable web app, light and dark mode, a terminal app and a Kotlin Multiplatform scaffold.
