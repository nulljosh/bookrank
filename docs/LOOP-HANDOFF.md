# Kernel loop handoff

The loop takes Kernel to 100, one major per tick, from the Road to 100 table in roadmap.md. Each row: build it on every platform it names, take light and dark screenshots, mark it built, add a CHANGELOG entry, commit by path, tag `vN.0.0` and push the tag by name, make the GitHub release "Kernel N.0.0", deploy the web if it changed. Replies to Joshua stay under two lines, in plain English.

Joshua, 2026-10-28: loop to v50, run `/checkpoint` once v50 is tagged, then keep going to 100. v50 tagged and checkpointed 2026-10-29.

Next row: **82, Second Mobbin pass against the best apps; close what is left**. Row 67 waits until iPhone 1.2.1 is no longer the live version. Rows 88 to 99 wait on Joshua (Workers Paid, Goodreads sign-in, an App Group in Xcode for widgets and extensions, Apple's CarPlay entitlement); build them when those are in place.

## How to QA

- Web: headless Chrome over CDP with `prefers-color-scheme` set to light and dark, the site served by `npx wrangler pages dev dist`.
- Apps: `sh ios/scripts/shots.sh` on headless simulators (this Mac has no Simulator.app). Never press Listen; `Speaker.play` returns under `UITEST_PLAYER` and `UITEST_SNAPSHOT`. A hung `xcodebuild test` is usually a leftover runner: `pkill -f "xcodebuild test"; xcrun simctl shutdown all`.
- Mac by hand: `xcodebuild -scheme KernelMac -derivedDataPath <scratch> build CODE_SIGNING_ALLOWED=NO`, then `open -n KernelMac.app --args -kernel.onboarded YES -UITEST_SNAPSHOT 1`. One instance, killed afterwards.

## Store

Mac 2.0.0 is live; Mac 18.0.0 went to review 2026-10-28 (build 202610282009, the six 2880x1800 shots attached, notes mention Goodreads). iOS 2.0.0 is still waiting for review. When a platform clears, ship the newest tagged major on it the way [SHIPPING.md](SHIPPING.md) says, with `scripts/store-listing.sh` for the four languages, then `scripts/promo.sh` once it is live, and start the product page test in docs/store/ppo.md.

## Waiting on Joshua

- Deploy jaybulb-api (`npx wrangler deploy` in ~/Documents/Code/jaybulb-api) so the public profile lookup from 54.0.0 and the listed flag from 57.0.0 go live. The agent was not allowed to deploy the shared API.

- kernel.jaybulb.com on the `bookrank` Pages project (Cloudflare blocked the agent from adding it).
- The signed-in Mac walk and the other checks listed in roadmap.md, including a book in its own Mac window (79.0.0) and Apple Pencil highlights on an iPad (78.0.0).

## Restart prompt

```
/loop Kernel loop to v100, in ~/Documents/Code/kernel. Read docs/LOOP-HANDOFF.md first, then build the next open row of the Road to 100 table in roadmap.md, one major per tick. Refresh any background task older than 5 minutes each tick. QA every visible change with screenshots in light and dark, never press Listen in a simulator, no GUI launches on Joshua's screen without asking. Use ASC_BYPASS_KEYCHAIN=1 for asc. Commit by exact path, push, deploy the web with wrangler pages deploy. Replies under 2 lines, plain English.
```
