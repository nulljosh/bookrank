# Kernel loop handoff (2026-10-28, evening)

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

**The loop now runs to Kernel 100.** The plan is the "Road to 100" table at the top of roadmap.md: one row per major, built on every platform the row names, QA'd with light and dark screenshots, marked built, tagged `vN.0.0` (push the tag by name), committed by path, pushed, web deployed. 3.0 and 4.0 are built and tagged. Next row: **12, Mac store screenshots at 2880x1800, signed-in Mac walk**. UI tests: no audio ever plays under UITEST_PLAYER or UITEST_SNAPSHOT (Speaker.play returns), and a hung `xcodebuild test` is usually a leftover runner: `pkill -f "xcodebuild test"; xcrun simctl shutdown all`.

Store: 2.0.0 is in review on iOS and Mac (builds 202610281242). The day it clears, ship the newest tagged major (not 3.0): `asc versions create`, What's New, fresh shots (`sh ios/scripts/shots.sh`; if fastlane hangs in `simctl diagnose`, take the PNGs from ~/Library/Caches/tools.fastlane/screenshots), `asc workflow run ship-ios VERSION:<v>`, then the Mac (archive KernelMac, export with `ios/ExportOptionsMac.plist`, `asc builds upload --pkg`, `asc review submit`). Review notes must mention the Goodreads sign-in (Goodreads' own page in a web view, nothing sent to Kernel). Never let `xcodegen` rewrite `ios/Kernel/Info.plist` into a commit.

Goodreads (G1) works with Joshua's account on the Mac Debug build (420 read, 413 rated, 11 reading with pages, 8 reviews, 2026-10-28). The owner's list differs from the public one: ratings are `data-rating="3.0"`, an empty review is a "Write a review" link.

Testing on this Mac: there is no Simulator.app (headless simctl only), so a hands-on test for Joshua is the Mac Debug build: `xcodebuild -scheme KernelMac -derivedDataPath <scratch> build CODE_SIGNING_ALLOWED=NO`, then `open -n KernelMac.app --args -kernel.onboarded YES -UITEST_SNAPSHOT 1` (add `-GOODREADS_SYNC 1` to force a sync). Ask before opening it; one instance.

## Waiting on Joshua

- OK to add kernel.jaybulb.com to the `bookrank` Pages project (the permission check blocked it).
- Then the repo and folder rename to `kernel` (`/rename`).

## Restart prompt

```
/loop Kernel loop to v100, in ~/Documents/Code/bookrank. Read docs/LOOP-HANDOFF.md first, then build the next open row of the Road to 100 table in roadmap.md, one major per tick. Refresh any background task older than 5 minutes each tick. QA every visible change with screenshots in light and dark, never press Listen in a simulator, no GUI launches on Joshua's screen without asking. Use ASC_BYPASS_KEYCHAIN=1 for asc. Commit by exact path, push, deploy the web with wrangler pages deploy. Replies under 2 lines, plain English.
```
