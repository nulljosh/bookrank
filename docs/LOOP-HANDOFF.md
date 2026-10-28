# Kernel loop handoff (2026-10-28, midday)

## What the loop is

Take Kernel (ex-Bookrank) to 2.0.0 on iOS and Mac: brand, font and design system everywhere, a Liquid Glass and spacing pass, then ship both apps with fresh screenshots and true review notes. Web is the reference for features. Replies to Joshua stay under two lines, in plain English.

## Done 2026-10-28

- **Name.** Kernel, reserved on the editable app info of version 1.3.0 (iOS and Mac 1.3.0 exist in PREPARE_FOR_SUBMISSION). Subtitle "Chapter summaries, read aloud", descriptions say Kernel. Apple's probe found only Kernel, Exordium and Gravamen free out of about 130 real words.
- **Rename in code.** Targets `Kernel`/`KernelMac`, folder `ios/Kernel`, `Kernel.icon`. Persisted keys, bundle id, table, header, Pages project and Mac profile keep old names on purpose (listed in CLAUDE.md). GitHub repo and local folder are still `bookrank`.
- **Brand.** Icon: a summary that ends on a seed. Kernel gold (`#a56200` light, `#f5b83d` dark, icon `#f5b83d` to `#c97a00`). Kernel Sans (`scripts/gen_font.py`, Geist renamed, full stop redrawn as the seed). Brand kit page live at /brand. Landing redone Hermes-style with the tagline as the h1 and the real reader on a sample chapter. Library, profile and share pages use Kernel Sans and gold.
- **Cloudflare.** The apps sign in and sync through jaybulb-api, supabase-swift is gone, keychain uses the data-protection keychain. Signed-in walk passed on iPhone with a throwaway QA account (deleted after). Old 1.2.x builds keep working through `viaApp` and the Supabase fallback.
- **Security.** The free-voices header hole is closed; new builds prove purchase with StoreKit's AppTransaction (`functions/api/apple.js`, `apple.test.js`).
- **iPhone QA.** One title per screen on book and chapter pages, stronger heading sizes.
- **iCloud Books.** Every photo handled; System Design complete and synced into Kernel.

- **Later 2026-10-28.** Landing: covers from books.json, icon footer, scroll parallax, phone gutters. Listen is one narrator now (old two-host scripts rebuild). Voices fall back to Cloudflare Aura-2 when ElevenLabs runs out (own caps, cached forever). Apps: launch splash, first-run pages, true Kernel gold (`AccentColor` + `OnAccent`). Gap matrix in roadmap.md. summarize-books skill transcribes owned books word for word.

## Next, in order

Fixed 2026-10-28: listen saves no longer reset the resume point (updated_at rule); live on the web, in the apps from 3.0.0.


2.0.0 is in review on iOS and Mac (2026-10-28, builds 202610281242). Watch for App Review; answer anything in Resolution Center only with Joshua's yes.

1. **3.0.0 is built, waiting on 2.0.0.** Gap rows 1 to 5 are done and committed (minutes, Continue card, line skip, speed presets, sleep timer). Apple allows one version in review at a time, so the day 2.0.0 clears: create 3.0.0 on iOS and Mac (`asc versions create`), set What's New, fresh store shots (`sh ios/scripts/shots.sh`; if fastlane hangs in `simctl diagnose` after a passing test, take the PNGs from ~/Library/Caches/tools.fastlane/screenshots), `asc workflow run ship-ios VERSION:3.0.0`, then the Mac steps below. Mac: archive KernelMac, export with `ios/ExportOptionsMac.plist` (automatic signing), `asc builds upload --app 6792376485 --pkg ... --version --build-number`, `asc review submit`. Never let `xcodegen` alone rewrite `ios/Kernel/Info.plist` into a commit: restore it with git, the ship workflow patches it.
2. **Mac store screenshots** at 2880x1800 (this Mac's display is 1x, so render larger or skip).
3. **Icon and font A+.** Icon reads like a text glyph at small sizes; font: seeds on the other dots?
4. Cold launch shows ~3s white in the debug simulator; check a Release build.
5. **Highlights (gap row 6), in progress.** Adding a `highlights` column on D1 was blocked by the permission check (production change), so store them inside the row's `listen` JSON as `listen.marks: [{ch, text}]`. Every writer must carry `marks` along: web `save` in library.html, Swift `ListenState` (add an optional `marks`), and keep marks even when `listen.for` no longer matches. Apps: long-press a line in ChapterView to save it, a Highlights list on the book page. Web: a save button for the current line and a list under the reader. Send `updated_at` back on every save (see CLAUDE.md, updated_at rule).
6. **4.0.0**: gap rows 6 and 7 done (highlights, offline audio in the apps). Next row 8 (photograph pages in the app), then 9 (ask the chapter), 10 (weekly goal).

## Waiting on Joshua

- OK to add kernel.jaybulb.com to the `bookrank` Pages project (the permission check blocked it).
- Then the repo and folder rename to `kernel` (`/rename`).

## Restart prompt

```
/loop Kernel loop through 2.0.0, then 3.0.0, 4.0.0 and on to 10.0.0, in ~/Documents/Code/bookrank. Read docs/LOOP-HANDOFF.md first and work its Next list in order. Refresh any background task older than 5 minutes each tick. QA every visible change with screenshots in light and dark, never press Listen in a simulator, no GUI launches on Joshua's screen without asking. Use ASC_BYPASS_KEYCHAIN=1 for asc. Commit by exact path, push, deploy the web with wrangler pages deploy. Replies under 2 lines, plain English.
```
