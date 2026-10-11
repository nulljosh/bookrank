# Bookrank loop handoff (2026-10-11, late morning)

## What the loop is

A parity and ship loop. The web app is the reference. Each feature the web has gets built into the iPhone and Mac apps (one shared SwiftUI source), then the next version goes out on both platforms with fresh screenshots and true review notes.

## Where things stand

- iOS 1.2.0 (build 202610110324) is WAITING_FOR_REVIEW: Goodreads shelves under the summaries, half-star ratings, a mini player on every screen, natural voices back on the installed apps.
- Mac 1.2.0 (build 202610111124) is WAITING_FOR_REVIEW. The Account sheet fix has shipped: it scrolls and wraps like iOS.
- Web is live at bookrank.heyitsmejosh.com with the same features.
- The installed apps still sign in through Supabase. `/api/speak`, `/api/narrate` and `/api/usage` accept their Supabase token as a fallback, and the per-user natural voice cap uses it too. Remove that fallback when the apps move to spark-api.
- The roadmap is mirrored to GitHub issues and pruned to open items.
- Uncommitted in the working tree: `ios/Bookrank.xcodeproj/project.pbxproj`, `ios/Bookrank/Info.plist` and `.asc/release/`. These belong to the Mac release run. Do not stage them by hand.

## Next, in order

1. Web mini player. `library.html` still has no mini player.
2. `/themes` skill: one markdown digest of the main themes in every summarized book on the account. No new UI.
3. Goodreads CSV import, for private profiles the RSS feed cannot see.
4. ElevenLabs minutes in Account: show the remaining natural-voice minutes, and make the fallback to the device voice a clear switch instead of a silent downgrade.

## Restart prompt

```
/loop Work Bookrank toward iOS and Mac parity, then ship. Repo: ~/Documents/Code/bookrank. Read docs/LOOP-HANDOFF.md first and work its Next list in order: web mini player, /themes skill, Goodreads CSV import, ElevenLabs minutes in Account. Run live QA on each step. Mac QA means the signed-in app driven with cliclick and screencapture, not screenshot mode. Keep App Review notes true every release, retake screenshots on every UI fix, and bump versions through project.yml. Do not stage the uncommitted Xcode project files or .asc/release. Commit progress by exact path. No subagents. Finish each step fully before the next.
```
