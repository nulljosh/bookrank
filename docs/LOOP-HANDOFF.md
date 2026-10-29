# Kernel loop handoff

The loop takes Kernel to 100, one major per tick, from the Road to 100 table in roadmap.md. Each row: build it on every platform it names, take light and dark screenshots, mark it built, add a CHANGELOG entry, commit by path, tag `vN.0.0` and push the tag by name, make the GitHub release "Kernel N.0.0", deploy the web if it changed. Replies to Joshua stay under two lines, in plain English.

Joshua, 2026-10-28: loop to v50, run `/checkpoint` once v50 is tagged, then keep going to 100. v50 tagged and checkpointed 2026-10-29.

Next rows: **93** (narrator eval, waits on Workers AI) and **67** once iPhone 1.2.1 is no longer on sale. **100** is the release once those are done. Everything else is built and tagged.

## How to QA

- Web: headless Chrome over CDP with `prefers-color-scheme` set to light and dark, the site served by `npx wrangler pages dev dist`.
- Apps: `sh ios/scripts/shots.sh` on headless simulators (this Mac has no Simulator.app). Never press Listen; `Speaker.play` returns under `UITEST_PLAYER` and `UITEST_SNAPSHOT`. A hung `xcodebuild test` is usually a leftover runner: `pkill -f "xcodebuild test"; xcrun simctl shutdown all`.
- Mac by hand: `xcodebuild -scheme KernelMac -derivedDataPath <scratch> build CODE_SIGNING_ALLOWED=NO`, then `open -n KernelMac.app --args -kernel.onboarded YES -UITEST_SNAPSHOT 1`. One instance, killed afterwards.

## Store

Mac 2.0.0 is live; Mac 18.0.0 went to review 2026-10-28 (build 202610282009, the six 2880x1800 shots attached, notes mention Goodreads). iOS 2.0.0 is still waiting for review. When a platform clears, ship the newest tagged major on it the way [SHIPPING.md](SHIPPING.md) says, with `scripts/store-listing.sh` for the four languages, then `scripts/promo.sh` once it is live, and start the product page test in docs/store/ppo.md.

## Waiting on Joshua

Everything through 99 except 93 and 67 is built and tagged. What is left needs one of these first:

1. **Workers AI** (Workers Paid): row 93: the eval is built, run `node narrate-eval.mjs`, tune the prompt in functions/api/narrate.js until 9 of 9 pass (95 to 97 shipped without AI). On 2026-10-29 /api/narrate answered 502 for the QA account, so the model is still out.
2. **Deploy jaybulb-api** (`cd ~/Documents/Code/jaybulb-api && npx wrangler deploy`): the public profile (54) and listed share pages (57) are committed and tested but not live. The agent was not allowed to deploy the shared API.
3. **The App Group** is in the code (rows 88 to 90 and 92 are built); automatic signing registers it and the two extensions on the first archive (see SHIPPING.md).
4. **Apple's CarPlay audio entitlement** (request it at developer.apple.com/contact/carplay): row 91 is built and waits only on it; once granted, add `com.apple.developer.carplay-audio` to `ios/Kernel/Kernel.entitlements`.
5. Row 94 is built: Kernel opens the book's Goodreads page and Goodreads' own button marks it. Try it once signed in to Goodreads on a phone.
6. **Row 67** waits until iPhone 2.0.0 replaces 1.2.1 and no one runs the 1.2 builds.
7. **kernel.jaybulb.com** on the `bookrank` Pages project (Cloudflare blocked the agent).
8. **Checks only a person can do**: Apple Pencil highlights on an iPad (78), a book in its own Mac window (79), Scan pages (33), Shortcuts (35), Handoff (37), Spotlight (40), the signed-in Mac walk.

Row 100 is the release once these are in: ship the newest major on iPhone, iPad and Mac the way [SHIPPING.md](SHIPPING.md) says, then `scripts/promo.sh` and the product page test.

## Restart prompt

```
/loop Kernel loop to v100, in ~/Documents/Code/kernel. Read docs/LOOP-HANDOFF.md first, then build the next open row of the Road to 100 table in roadmap.md, one major per tick. Refresh any background task older than 5 minutes each tick. QA every visible change with screenshots in light and dark, never press Listen in a simulator, no GUI launches on Joshua's screen without asking. Use ASC_BYPASS_KEYCHAIN=1 for asc. Commit by exact path, push, deploy the web with wrangler pages deploy. Replies under 2 lines, plain English.
```
