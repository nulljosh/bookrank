Note: karma/flair requirements unknown, check first. Public post, not beta-only.

Title: Built a book-ranking site with generated audio chapter summaries

Body:
Bookrank is a static site: a ranked shelf built from books.json, with index.html, a markdown export and the iOS resource JSON all generated from that one file by a build script, run after every edit, instead of hand-kept in sync.

The interesting part was the summary playback. Every chapter summary can be played, not just read: "Explain it" turns the chapter into a short two-host conversation generated through Workers AI, and the transcript highlights the current line and word while it plays, with the next chapter prepared ahead of time so there's no gap between them. Progress and generated scripts save to the account so web, iPhone and Mac pick up at the same line.

No backend beyond that, no accounts required to browse the shelf. Free to use.

https://bookrank.heyitsmejosh.com
