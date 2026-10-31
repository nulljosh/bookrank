# Kernel loop handoff (2026-10-30, evening)

## What the loop is

The loop takes the open feature rows in roadmap.md, one at a time. A feature is a minor and a fix is a patch. A major only on Joshua's call, with a Mobbin pass and a film. Never aim the loop at a version number. Each feature is built on every platform its row names, checked with light and dark screenshots, marked built, added to the CHANGELOG, committed by exact path, tagged and pushed by name, and released on GitHub. The web is deployed when it changed. Replies to Joshua stay under two lines, in plain English.

QA: web in headless Chrome with light and dark set, served by `npx wrangler pages dev dist`. Apps with `sh ios/scripts/shots.sh` on headless simulators. Never press Listen in a simulator. No GUI launches on Joshua's screen without asking.

## Where things stand

- The repo is at 20.0.0, tagged and the GitHub Latest release. Zero open issues, zero open PRs, zero stale branches, CI green on 20.0.0.
- The iPhone and Mac builds for 19.0.0 are waiting for App Review.
- Every feature row in roadmap.md is built except row 67 (waits until 1.2.1 is off sale) and the rows that need Workers AI or Joshua's checks.
- Workers AI is out of its free daily allowance (since 2026-10-28), so narration, Ask and the Aura-2 fallback fail until the paid plan, which is Joshua's call.
- Media files under `ad/` and `.asc/release/` are untracked on purpose and stay out of git.

## Next, in order

1. When the 19.0.0 builds clear review on iPhone and Mac, submit 20.0 on both platforms the way [SHIPPING.md](SHIPPING.md) says. Add the French store name in the same pass with `asc apps rename --locale fr-FR --name Noyau`, since the app info is locked while 19.0.0 is in review. Then run `scripts/store-listing.sh` for the four languages, and `scripts/promo.sh` once it is live.
2. Joshua's checks, listed in roadmap.md: the icon and font at 16 to 32 px, the Workers AI decision, Scan pages on a real iPhone, Shortcuts actions, Handoff, Spotlight, the signed-in Mac walk, Listen with the screen locked, Goodreads in dark mode, merging highlights across two devices, and the summaries still to photograph or finish.
3. Then the loop picks the next open feature row in roadmap.md.

## Restart prompt

```
/loop Kernel loop, in ~/Documents/Code/kernel. Read docs/LOOP-HANDOFF.md first, then take the next open feature row in roadmap.md (skip rows marked waits, and anything that needs Joshua's check). Each feature is a minor and each fix a patch. Never pick a version number yourself, and never start a major, which is Joshua's call. Build it on every platform the row names, QA with light and dark screenshots, never press Listen in a simulator, and no GUI launches on Joshua's screen without asking. Refresh any background task older than 5 minutes each tick. Use ASC_BYPASS_KEYCHAIN=1 for asc. Commit by exact path, push, and deploy the web with wrangler pages deploy if it changed. Stop when no open feature row is left. Replies under 2 lines, plain English.
```
