# Kernel loop handoff

The loop takes Kernel to 100, one major per tick, from the Road to 100 table in roadmap.md. Each row: build it on every platform it names, take light and dark screenshots, mark it built, add a CHANGELOG entry, commit by path, tag `vN.0.0` and push the tag by name, make the GitHub release "Kernel N.0.0", deploy the web if it changed. Replies to Joshua stay under two lines, in plain English.

Joshua, 2026-10-28: loop to v50, run `/checkpoint` once v50 is tagged, then keep going to 100.

Next row: **18, Search inside chapter text, results jump to the line**.

## How to QA

- Web: headless Chrome over CDP with `prefers-color-scheme` set to light and dark, the site served by `npx wrangler pages dev dist`.
- Apps: `sh ios/scripts/shots.sh` on headless simulators (this Mac has no Simulator.app). Never press Listen; `Speaker.play` returns under `UITEST_PLAYER` and `UITEST_SNAPSHOT`. A hung `xcodebuild test` is usually a leftover runner: `pkill -f "xcodebuild test"; xcrun simctl shutdown all`.
- Mac by hand: `xcodebuild -scheme KernelMac -derivedDataPath <scratch> build CODE_SIGNING_ALLOWED=NO`, then `open -n KernelMac.app --args -kernel.onboarded YES -UITEST_SNAPSHOT 1`. One instance, killed afterwards.

## Store

2.0.0 is in review on iOS and Mac. When it clears, ship the newest tagged major the way [SHIPPING.md](SHIPPING.md) says.

## Waiting on Joshua

- kernel.jaybulb.com on the `bookrank` Pages project (Cloudflare blocked the agent from adding it).
- The signed-in Mac walk and the other checks listed in roadmap.md.

## Restart prompt

```
/loop Kernel loop to v100, in ~/Documents/Code/kernel. Read docs/LOOP-HANDOFF.md first, then build the next open row of the Road to 100 table in roadmap.md, one major per tick. Refresh any background task older than 5 minutes each tick. QA every visible change with screenshots in light and dark, never press Listen in a simulator, no GUI launches on Joshua's screen without asking. Use ASC_BYPASS_KEYCHAIN=1 for asc. Commit by exact path, push, deploy the web with wrangler pages deploy. Replies under 2 lines, plain English.
```
