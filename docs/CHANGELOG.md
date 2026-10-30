# Changelog

Every version of Kernel, newest first. Before 2026-10-28 the app was called Bookrank, and before that Uprighty, Spine and Books.


## 18.1.0 (2026-10-30)
One minor for rows 19 to 99 of the old roadmap table. They were tagged 19.0.0 to 99.0.0, one major per row, which inflated the number; those tags and GitHub releases are gone and the work is one release on top of Mac 18.0.0, the version Apple approved. Each row's note follows.

### Row 97 (2026-10-29)
In short: at the end of each chapter, one or two lines that sum it up, taken from the chapter's own key sentences. On the iPhone, iPad, Mac and the web.

### Row 96 (2026-10-29)
Key ideas at the top of each book: up to five, from the summary's own takeaways, numbered. Books without clear takeaways skip the card.

### Row 95 (2026-10-29)
Quiz me, under the In short card: up to three questions per chapter, each a sentence with one of the chapter's bold terms blanked out and choices from the same book. Pick one and it shows right or wrong, then your score. No model, nothing leaves the device.

### Row 91 (2026-10-29)
CarPlay is ready: your books as a list with the one you are partway through first, tap to keep listening, and the system's Now Playing for the rest. It switches on once Apple grants Kernel the CarPlay audio entitlement.

### Row 94 (2026-10-29)
Mark Read on Goodreads, from the chapters menu in Now Playing when you are signed in to Goodreads: the book's Goodreads page opens inside Kernel with your sign-in, you press Goodreads' own button, and Done refreshes your shelves. Kernel never presses it for you.

### Row 92 (2026-10-29)
Share to Kernel from Safari or any app on iPhone and iPad: a web page or some selected text, saved under a title you choose. The next time Kernel opens it becomes a book on your account, the page's own paragraphs with a link back. The share sheet never needs your sign-in.

### Row 90 (2026-10-29)
A Control Center control that plays or pauses the book you are listening to, on iPhone (iOS 18) and the Mac (macOS 26), and on the Lock Screen and Action button too. The Mac also gets the Continue and week widgets for its desktop.

### Row 89 (2026-10-29)
On the iPhone Lock Screen, a widget with the book you are reading, the time left and your week; and while Kernel plays, a Live Activity on the Lock Screen and in the Dynamic Island with the chapter, playing or paused, and the time left. Tap either to open the book.

### Row 88 (2026-10-29)
Home Screen widgets on iPhone and iPad: Continue shows the book you are partway through, its chapter and the time left, and the medium size adds the week's ring against your goal and a dot for each day you listened. Tap one and the book opens. The app writes what they show to a shared App Group; nothing goes over the network.

### Row 99 (2026-10-29)
Search by voice is already there: the keyboard's microphone on iPhone and iPad and dictation on the Mac and the web fill the search field, on the device. Kernel adds no mic of its own unless people miss one.

### Row 98 (2026-10-29)
Connections: press Connections on a highlight (long-press it in the apps) and the same idea shows up from your other books, from the search-by-meaning index each book already has, so most of the time nothing new is sent anywhere.

### Row 87 (2026-10-29)
Release candidate. Every row through 86 checked together: on iPhone all 9 unit tests and 22 walks pass; on iPad the unit tests and six walks pass in dark mode; the Mac Release build succeeds; the web's 50 tests pass and every live page answers. CI's walks never really ran before (the book texts are private, so GitHub's shelf was empty): the test shelf now falls back to the public sample under each title, CI runs the walks that need only titles, and Storage is reached through Account so the same walk works on iPad.

### Row 86 (2026-10-29)
The final docs pass: the whitepaper and README cover reading your way (themes, shortcuts, iPad windows and Pencil, a Mac window per book) and the security headers, and the landing's third step says your place is saved whether you read or listen. The landing's newer text now reads in French, Spanish and German too, and "Get the kernel" no longer comes out as "get the app".

### Row 85 (2026-10-29)
A performance audit with no regressions since 58 and 60: the web still shows 500 books in about 130 ms and searches them in about 20, and the iPhone app launches and scrolls a 500-book shelf as fast as before. The numbers live in a table in docs/ARCHITECTURE.md for the next audit.

### Row 84 (2026-10-29)
A security and privacy audit. Every place the web writes HTML escapes what users typed, avatars load only as images, every server route needs its sign-in and has its cap, and an account deletion clears everything. The one gap, response headers, is closed: the site can no longer be framed by another, browsers keep to HTTPS, and pages never ask for the camera, microphone or location.

### Row 83 (2026-10-29)
An Apple-style pass over the web: every button, picker and field is one 44 point height, buttons and pickers are capsules with a drawn chevron, search has a magnifier, and keyboard focus is a soft ring in the accent. The apps already use the system's own controls.

### Row 82 (2026-10-29)
A second look at Blinkist, Shortform, Readwise Reader and Headway. Kernel already has their continue card, weekly goal and stats, audio or text, highlights, offline and imports; the web player now also says how much of the chapter is left, like the apps. What remains (key ideas, exercises, a coach) waits on Workers AI.

### Row 81 (2026-10-29)
A second screenshot set for the App Store's product page test: the same three screens in dark mode, iPhone and iPad, against today's light set. The plan is in docs/store/ppo.md; it starts once the version in the screenshots is the one on sale.

### Row 80 (2026-10-29)
Each release now refreshes the App Store's promotional text (`scripts/promo.sh`, on the newest live version of each platform, no review needed) and can carry an in-app event, planned in docs/store/events.md. The first run waits for the next version, so the text never names a feature the live app lacks.

### Row 79 (2026-10-29)
On the Mac, right-click a book and choose Open in New Window to read it in a window of its own, next to your library. Every window shares the same books.

### Row 78 (2026-10-29)
On iPad, Kernel opens in more than one window, for Stage Manager and Split View, and Apple Pencil highlights: double tap or squeeze to highlight the line you are on, again to remove it. A flaky CI walk now waits for each menu.

### Row 77 (2026-10-29)
A Black appearance in the apps: dark mode with the chapter reader on true black, so an OLED screen lights only the words.

### Row 76 (2026-10-29)
A sepia reading theme: warm paper and brown ink for long reading. On the web it sits beside the text size buttons with Auto, Light and Dark; in the apps it is under Account > Appearance and colours the chapter reader.

### Row 75 (2026-10-29)
Kernel Sans has an italic and a bold italic now, built from Geist's own like the uprights and ending each sentence on the same seed. Highlights, Today's five and a Goodreads quote are set in it, and the share card in the bold italic.

### Row 74 (2026-10-29)
Reading saves your place too, not only listening: scroll a chapter with no audio and, once you stop, the line at the top becomes where you left off, on the web and in the apps (iOS 18 and macOS 15 or later).

### Row 73 (2026-10-29)
Keyboard shortcuts on the web: Space plays or pauses, j and k move between chapters, h highlights, / searches, n starts a summary, and ? lists them all. f is a focus mode that leaves only the chapter and the play controls; Esc leaves it.

### Row 72 (2026-10-29)
The web library looks more like the apps on a phone: the title gets its own line with the buttons under it, dates read "Oct 27" in your language instead of 2026-10-27, and Delete is red so it cannot be mistaken for Save.

### Row 71 (2026-10-29)
Docs caught up with everything through 70: the whitepaper (sync, finding things, languages, sharing, limits), the README's feature list, the architecture map of every web file and server route, and how to run the apps' tests. Every local link checked.

### Row 70 (2026-10-29)
CI walks the iPhone app on a simulator after the unit tests: search, sort and filter, the command palette, Account and the sleep timer menu, on the silent screenshot shelf.

### Row 69 (2026-10-29)
The apps' rules have unit tests (ios/Tests): chapters, search, the notes split into lines, highlights merging, the offline catch-up, Kindle clippings, Today's five, durations and the morning line. They run on every push on a macOS runner.

### Row 68 (2026-10-29)
Bookrank is Kernel everywhere it can be: the repo is nulljosh/kernel, the folder is kernel, and the sign-in mails say Kernel. kernel.jaybulb.com goes live once it is added to the Pages project. (67.0.0, retiring the old Supabase path, waits until no one runs the 1.2 apps.)

### Row 66 (2026-10-29)
Deleting your account now also clears Kernel's voice records about you (usage, the $1 record, narration made from your books) and every copy on the device you delete from. The privacy policy is rewritten to say what Kernel actually keeps and sends.

### Row 65 (2026-10-29)
Export everything is one zip, on the web and in the apps: every book as Markdown with its chapter notes, your highlights and notes together, a JSON copy of every row, and your Goodreads shelves.

### Row 64 (2026-10-29)
A security pass: every route that runs a model or reaches Goodreads now has an hourly cap per person on top of its sign-in check, so one caller cannot run up the bill. Webhook signatures and input checks reviewed.

### Row 63 (2026-10-29)
Where you stopped follows the latest device: a place saved offline no longer drags another device back when it finally goes up, and highlights from both stay.

### Row 62 (2026-10-29)
A flaky connection no longer loses your place: calls are retried, and what you save offline (where you stopped, highlights, notes, collections) waits on the device and goes up when you are back online.

### Row 61 (2026-10-29)
When something breaks, Account > Data > Export error log hands you a text file of what went wrong lately, to send with a bug report. It stays on your device until you share it.

### Row 60 (2026-10-29)
A startup budget: Kernel's own work before the first screen stays under 50 ms (it measures about 30), checked with an Instruments trace and a launch-time test.

Rows 59 and before, and 18.0.0 and earlier: [CHANGELOG-1-59.md](CHANGELOG-1-59.md).
