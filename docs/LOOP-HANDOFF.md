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

1. **Kernel Sans and gold in the apps.** Bundle `fonts/KernelSans-*.otf` in both targets, register at launch (Coda's `Theme.fontsRegistered` pattern), a `Font.kernel(...)` helper, use it for titles first. The accent colour is already gold in `AccentColor`; check the voice usage bar and other hard-coded blues.
2. **Liquid Glass pass** (`liquid-glass` skill): glass only on bars, toolbars, mini player; nothing on rows. Then the Jony Ive spacing pass (`apple` skill) on every screen, iPhone and Mac, light and dark.
3. **Mac QA** signed in: one instance, trap-kill, never press Listen, no GUI launches without asking Joshua first.
4. **Icon and font A+.** Icon reads like a "text" glyph at small sizes; try the seed bolder or the lines shorter. Font: decide whether `:` `;` `!` `?` `i` `j` dots become seeds too.
5. **Gap matrix rows** in `roadmap.md`, one minor version each, after 2.0.0 ships. Also: cold launch shows ~3s of white in the debug simulator before the splash; check a Release build.
6. **Ship 2.0.0** on iOS and Mac: bump `project.yml`, new screenshots (`ios/scripts/shots.sh` names simulators this Mac lacks; use iPhone 17 Pro and iPad Pro 13), review notes that mention the one-time sign-in after the update, upload, submit. Use `ASC_BYPASS_KEYCHAIN=1` for every `asc` call.

## Waiting on Joshua

- OK to add kernel.jaybulb.com to the `bookrank` Pages project (the permission check blocked it).
- Then the repo and folder rename to `kernel` (`/rename`).

## Restart prompt

```
/loop Kernel loop through 2.0.0, then 3.0.0, 4.0.0 and on to 10.0.0, in ~/Documents/Code/bookrank. Read docs/LOOP-HANDOFF.md first and work its Next list in order. Refresh any background task older than 5 minutes each tick. QA every visible change with screenshots in light and dark, never press Listen in a simulator, no GUI launches on Joshua's screen without asking. Use ASC_BYPASS_KEYCHAIN=1 for asc. Commit by exact path, push, deploy the web with wrangler pages deploy. Replies under 2 lines, plain English.
```
