# Kernel loop handoff (2026-10-22, early morning)

## What the loop is

A parity and ship loop. The web app is the reference. Each feature the web has gets built into the iPhone and Mac apps (one shared SwiftUI source), then the next version goes out on both platforms with fresh screenshots and true review notes.

## Where things stand

- iOS and Mac 1.2.1 (chapter mix-up fixed; listen scripts no longer leak between books) were in review at the 2026-10-21 checkpoint. Check App Store Connect before submitting anything new.
- The credentials check is done: no service keys in the repo or its history.
- Web is live at bookrank.heyitsmejosh.com with the same features as the apps.
- The installed apps still sign in through Supabase. `/api/speak`, `/api/narrate` and `/api/usage` accept their Supabase token as a fallback, and the per-user natural voice cap uses it too. Remove that fallback when the apps move to spark-api.
- Roadmap ingested from Apple Notes on 2026-10-21: a navigation rework (profile into Settings in the bottom nav, search at the top; P1) and a macOS app QA pass (P2).
- Check `git status` before staging anything. As of 2026-10-11 the Xcode project files and `.asc/release/` were uncommitted from the Mac release run; do not stage them by hand.

## Next, in order

1. Navigation: profile into Settings in the bottom nav, search at the top (P1).
2. Web mini player. `library.html` had none on 2026-10-11, so confirm before starting.
3. QA the macOS app (P2).
4. `/themes` skill: one markdown digest of the main themes in every summarized book on the account. No new UI.
5. Goodreads CSV import, for private profiles the RSS feed cannot see.
6. ElevenLabs minutes in Account: show the remaining natural-voice minutes, and make the fallback to the device voice a clear switch instead of a silent downgrade.

## Restart prompt

```
/loop Work Kernel toward iOS and Mac parity, then ship. Repo: ~/Documents/Code/kernel. Read docs/LOOP-HANDOFF.md first and work its Next list in order. Run live QA on each step. Mac QA means the signed-in app driven with cliclick and screencapture, not screenshot mode. Keep App Review notes true every release, retake screenshots on every UI fix, and bump versions through project.yml. Do not stage the uncommitted Xcode project files or .asc/release. Commit progress by exact path. No subagents. Finish each step with a live QA pass before moving to the next.
```
